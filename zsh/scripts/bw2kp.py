#!/usr/bin/env python3
# bw2kp: exporta el almacén de Bitwarden a una base de KeePassXC (KP_PATH).
# Lee del entorno BW_SERVER, BW_CLIENTID, BW_CLIENTSECRET y BW_PASSWORD (Bitwarden)
# y KP_PATH y KP_PASSWORD (la base de KeePassXC; la contraseña debe ser otra).
# Usa la orden bw y la biblioteca pykeepass (python3-pykeepass, packages.txt).
# KeePassXC admite una sola URL por entrada: cada URI de un elemento de Bitwarden
# genera una entrada, y el TOTP va en el atributo «otp», que KeePassXC usa para
# sus códigos. Se instala como ~/.local/bin/bw2kp (scripts/lib/links.sh).
import base64
import copy
import json
import os
import re
import subprocess
import tempfile
import uuid
from urllib.parse import quote, urlsplit
from xml.sax.saxutils import escape

from pykeepass import create_database

# 1. Validar variables de entorno requeridas
REQUIRED_ENVS = [
    "BW_SERVER",
    "BW_CLIENTID",
    "BW_CLIENTSECRET",
    "BW_PASSWORD",
    "KP_PATH",
    "KP_PASSWORD",
]
for env in REQUIRED_ENVS:
    if not os.getenv(env):
        raise ValueError(f"ENV {env} required.")

KP_PATH = os.getenv("KP_PATH")
db_dir = os.path.dirname(KP_PATH)
if db_dir and not os.path.exists(db_dir):
    os.makedirs(db_dir, exist_ok=True)

# Se escribe junto a KP_PATH para que os.replace sea atómico (mismo sistema de archivos)
temp_path = os.path.join(db_dir, "temp_db.kdbx") if db_dir else "temp_db.kdbx"
BW_PASSWORD = os.getenv("BW_PASSWORD")
KP_PASSWORD = os.getenv("KP_PASSWORD")
if KP_PASSWORD == BW_PASSWORD:
    # Con la misma contraseña, descubrir una abriría las dos copias de los secretos
    raise ValueError("KP_PASSWORD debe ser distinta de BW_PASSWORD.")


def run_cmd(command, allowed_err=[]):
    """Ejecuta comandos del sistema de forma síncrona controlando errores permitidos."""
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        err_msg = result.stderr or result.stdout
        allowed = any(err in err_msg for err in allowed_err)
        if not allowed:
            raise RuntimeError(f"Command failed: {command}\nError: {err_msg}")
    return result.stdout


def etiqueta_uri(uri):
    """Nombre corto de una URI para distinguir las entradas de un mismo elemento."""
    return urlsplit(uri).hostname or uri


def uri_otpauth(totp, nombre, usuario):
    """URI otpauth que lee KeePassXC, o None si el elemento no tiene TOTP.

    Bitwarden guarda el secreto en base32 o ya como URI otpauth://.
    """
    if not totp:
        return None
    if totp.startswith("otpauth://"):
        return totp
    etiqueta = f"{nombre}:{usuario}" if usuario else nombre
    secreto = totp.replace(" ", "")
    return f"otpauth://totp/{quote(etiqueta)}?secret={secreto}&issuer={quote(nombre)}"


def obtener_grupo(db, nombre):
    """Grupo de primer nivel con ese nombre, creado si no existe."""
    grupo = db.find_groups(group=db.root_group, recursive=False, name=nombre, first=True)
    return grupo or db.add_group(db.root_group, nombre)


TIPO_CLAVE_SSH = 5  # tipo de elemento de Bitwarden para claves SSH
TIPOS_SIN_RESPALDO = (3, 4)  # tarjetas e identidades: no se respaldan


def pem_de_clave(key_value):
    """Clave privada PKCS#8 en PEM, a partir de la de Bitwarden (base64, o base64url)."""
    der = base64.b64decode(key_value + "=" * (-len(key_value) % 4), altchars=b"-_")
    b64 = base64.b64encode(der).decode()
    lineas = [b64[i : i + 64] for i in range(0, len(b64), 64)]
    return "-----BEGIN PRIVATE KEY-----\n" + "\n".join(lineas) + "\n-----END PRIVATE KEY-----\n"


def base64url(texto):
    """Normaliza base64 o base64url a base64url sin relleno (lo que usa WebAuthn)."""
    return texto.replace("+", "-").replace("/", "_").rstrip("=")


def credential_id_webauthn(credential_id):
    """El ID de credencial como lo envía el navegador: base64url de sus bytes.

    Bitwarden lo guarda como UUID (sus 16 bytes son el ID real) o, en el formato
    antiguo, como «b64.» seguido del base64url.
    """
    if credential_id.startswith("b64."):
        return base64url(credential_id[4:])
    try:
        return base64url(base64.b64encode(uuid.UUID(credential_id).bytes).decode())
    except ValueError:
        return base64url(credential_id)


ICONO_LLAVE = "13"  # el icono que KeePassXC pone a las passkeys que importa


def agregar_passkey(db, item, credencial, destino):
    """Una entrada por passkey, igual a la que crea KeePassXC al importar un .passkey:
    atributos KPEX_PASSKEY_*, con el ID, el user handle y la clave protegidos."""
    rp = credencial.get("rpId") or ""
    usuario = credencial.get("userName") or ""
    titulo = f"{item['name']} ({rp})" if rp else f"{item['name']} (passkey)"
    metadatos = copy.deepcopy(credencial)
    metadatos["keyValue"] = "(en la passkey de KeePassXC)"
    entrada = db.add_entry(
        destino,
        titulo,
        usuario,
        "",
        url=f"https://{rp}" if rp else "",
        notes=f"Passkey de Bitwarden.\n{json.dumps(metadatos, indent=2)}",
        icon=ICONO_LLAVE,
    )
    entrada.set_custom_property(
        "KPEX_PASSKEY_CREDENTIAL_ID",
        credential_id_webauthn(credencial.get("credentialId") or ""),
        protect=True,
    )
    entrada.set_custom_property("KPEX_PASSKEY_FLAG_BE", "1")
    entrada.set_custom_property("KPEX_PASSKEY_FLAG_BS", "1")
    entrada.set_custom_property(
        "KPEX_PASSKEY_PRIVATE_KEY_PEM", pem_de_clave(credencial["keyValue"]), protect=True
    )
    entrada.set_custom_property("KPEX_PASSKEY_RELYING_PARTY", rp)
    entrada.set_custom_property("KPEX_PASSKEY_USERNAME", usuario)
    entrada.set_custom_property(
        "KPEX_PASSKEY_USER_HANDLE", base64url(credencial.get("userHandle") or ""), protect=True
    )


def descargar_adjuntos(item):
    """Descarga los adjuntos del elemento; su contenido no va en el JSON de las notas."""
    adjuntos = []
    # mkdtemp crea el directorio con permisos 0700; XDG_RUNTIME_DIR es un tmpfs del usuario
    for adjunto in item.get("attachments") or []:
        with tempfile.TemporaryDirectory(dir=os.getenv("XDG_RUNTIME_DIR")) as tmp:
            ruta = os.path.join(tmp, "adjunto")
            result = subprocess.run(
                [
                    "bw",
                    "get",
                    "attachment",
                    adjunto["id"],
                    "--itemid",
                    item["id"],
                    "--output",
                    ruta,
                ],
                capture_output=True,
                text=True,
            )
            if result.returncode != 0:
                detalle = result.stderr or result.stdout
                raise RuntimeError(f"bw get attachment falló: {detalle}")
            with open(ruta, "rb") as f:
                datos = f.read()
        adjuntos.append((adjunto["fileName"], datos))
    return adjuntos


def ajustes_agente_ssh(archivo_clave):
    """Adjunto KeeAgent.settings: lo que lee la pestaña «SSH Agent» de KeePassXC.

    Carga la clave adjunta en el agente SSH al abrir la base y la quita al cerrarla.
    """
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<EntrySettings xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <AllowUseOfSshKey>true</AllowUseOfSshKey>
  <AddAtDatabaseOpen>true</AddAtDatabaseOpen>
  <RemoveAtDatabaseClose>true</RemoveAtDatabaseClose>
  <UseConfirmConstraintWhenAdding>false</UseConfirmConstraintWhenAdding>
  <UseLifetimeConstraintWhenAdding>false</UseLifetimeConstraintWhenAdding>
  <LifetimeConstraintDuration>600</LifetimeConstraintDuration>
  <Location>
    <SelectedType>attachment</SelectedType>
    <AttachmentName>{escape(archivo_clave)}</AttachmentName>
    <SaveAttachmentToTempFile>false</SaveAttachmentToTempFile>
    <FileName />
  </Location>
</EntrySettings>
""".encode()


def nombre_archivo(nombre, extension):
    """Nombre de archivo seguro a partir del nombre del elemento."""
    return re.sub(r"[^\w.-]+", "_", nombre).strip("_") + extension


ATRIBUTOS_RESERVADOS = ("Title", "UserName", "Password", "URL", "Notes", "otp")
CAMPO_OCULTO = 1  # tipo de campo personalizado de Bitwarden: oculto


def campos_personalizados(item):
    """Campos personalizados del elemento, como atributos: (nombre, valor, protegido).

    Los de tipo oculto se protegen. Si el nombre choca con un atributo propio de
    KeePassXC o se repite, se le agrega un sufijo para no perder ninguno.
    """
    atributos, usados = [], set(ATRIBUTOS_RESERVADOS)
    for campo in item.get("fields") or []:
        nombre, valor = campo.get("name"), campo.get("value")
        if not nombre or valor in (None, ""):
            continue
        if nombre.startswith("KPEX_"):  # prefijo de los atributos de las passkeys
            nombre = f"campo {nombre}"
        base, n = nombre, 1
        while nombre in usados:
            n += 1
            nombre = f"{base} ({n})"
        usados.add(nombre)
        atributos.append((nombre, valor, campo.get("type") == CAMPO_OCULTO))
    return atributos


def agregar_elemento(db, item, folders, organizaciones):
    """Crea una entrada por URI del elemento (una sin URL si no tiene ninguna).

    Los elementos de una organización van a su grupo; los personales, a su carpeta.
    """
    org_id = item.get("organizationId")
    folder_id = item.get("folderId")
    if org_id and org_id in organizaciones:
        destino = organizaciones[org_id]
    elif folder_id and folder_id in folders:
        destino = obtener_grupo(db, folders[folder_id])
    else:
        destino = db.root_group

    nombre = item["name"]
    login = item.get("login") or {}
    uris = [u["uri"] for u in login.get("uris") or [] if u.get("uri")] or [""]
    username = login.get("username") or ""
    password = login.get("password") or ""
    otp = uri_otpauth(login.get("totp"), nombre, username)

    # Adjuntos: la clave privada SSH y los archivos de Bitwarden, como adjuntos reales
    adjuntos = []
    notes = item.get("notes") or ""
    clave_ssh = item.get("sshKey") or {}
    if item.get("type") == TIPO_CLAVE_SSH and clave_ssh.get("privateKey"):
        archivo_clave = nombre_archivo(nombre, ".key")
        adjuntos.append((archivo_clave, clave_ssh["privateKey"].encode()))
        adjuntos.append(("KeeAgent.settings", ajustes_agente_ssh(archivo_clave)))
        # La privada va adjunta; la pública y la huella, en las notas
        publica = f"Clave pública: {clave_ssh.get('publicKey') or ''}"
        huella = f"Huella: {clave_ssh.get('keyFingerprint') or ''}"
        notes = "\n".join(filter(None, [notes, publica, huella]))
    adjuntos.extend(descargar_adjuntos(item))

    # Las passkeys van a sus propias entradas
    credenciales = login.get("fido2Credentials") or []
    campos = campos_personalizados(item)

    for uri in uris:
        # Con varias URI, el nombre de cada entrada lleva el sitio para distinguirlas
        titulo = nombre if len(uris) == 1 else f"{nombre} ({etiqueta_uri(uri)})"
        entrada = db.add_entry(destino, titulo, username, password, url=uri, notes=notes)
        if otp:
            entrada.otp = otp
        for atributo, valor, protegido in campos:
            entrada.set_custom_property(atributo, valor, protect=protegido)
        for archivo, datos in adjuntos:
            entrada.add_attachment(db.add_binary(datos), archivo)

    for credencial in credenciales:
        agregar_passkey(db, item, credencial, destino)


def build_db():
    # 2. Crear BD temporal de KeePassXC
    if os.path.exists(temp_path):
        os.remove(temp_path)
    db = create_database(temp_path, password=KP_PASSWORD)
    print(f"{temp_path} created.")

    # 3. Obtener carpetas y crearlas
    list_folders = run_cmd("bw list folders")
    folder_json = json.loads(list_folders) if list_folders.strip() else []
    folders = {}
    print(f"{len(folder_json)} folders to create.")
    for folder in folder_json:
        if not folder.get("id") or not folder.get("name"):
            continue
        folders[folder["id"]] = folder["name"]
        obtener_grupo(db, folder["name"])

    # 4. Organizaciones: un grupo por cada una, con sus elementos dentro
    list_orgs = run_cmd("bw list organizations")
    org_json = json.loads(list_orgs) if list_orgs.strip() else []
    # Grupo nuevo por organización, con prefijo para distinguirlo de las carpetas
    organizaciones = {
        o["id"]: db.add_group(db.root_group, f"Org: {o['name']}")
        for o in org_json
        if o.get("id") and o.get("name")
    }
    print(f"{len(organizaciones)} organizations.")

    # 5. Obtener elementos y guardarlos, una entrada por URI
    list_items = run_cmd("bw list items")
    item_json = json.loads(list_items) if list_items.strip() else []
    respaldables = [i for i in item_json if i.get("type") not in TIPOS_SIN_RESPALDO]
    omitidos = len(item_json) - len(respaldables)
    print(f"{len(respaldables)} items to create ({omitidos} cards/identities skipped).")
    for item in respaldables:
        agregar_elemento(db, item, folders, organizaciones)

    db.save()


def comprobar_sin_sesion():
    """Sale si bw ya tiene una sesión iniciada: no se cierra una sesión ajena."""
    estado = json.loads(run_cmd("bw status --raw")).get("status")
    if estado != "unauthenticated":
        raise SystemExit(
            f"bw ya tiene una sesión iniciada (estado: {estado}). "
            "Ejecuta bw logout y vuelve a intentarlo."
        )


def main():
    comprobar_sin_sesion()

    # 1. Configurar e iniciar sesión en Bitwarden
    run_cmd(f"bw config server {os.getenv('BW_SERVER')}", allowed_err=["creating"])
    print(f"Server set to {os.getenv('BW_SERVER')}.")

    run_cmd("bw login --apikey", allowed_err=["logged in"])
    print(f"Logged in as {os.getenv('BW_CLIENTID')}.")

    run_cmd("bw lock")
    session_out = run_cmd("bw unlock --passwordenv BW_PASSWORD")
    if 'BW_SESSION="' not in session_out:
        raise RuntimeError(session_out)

    print("Vault unlocked.")
    bw_session = session_out.split('BW_SESSION="')[1].split('"')[0]
    os.environ["BW_SESSION"] = bw_session

    try:
        build_db()
        # 5. Reemplazar la base final solo cuando la temporal está completa
        os.replace(temp_path, KP_PATH)
        print(f"{temp_path} renamed to {KP_PATH}.")
    except Exception:
        # No dejar una base a medias; KP_PATH anterior no se ha tocado
        if os.path.exists(temp_path):
            os.remove(temp_path)
        raise
    finally:
        # 6. Limpieza y cierre de sesión, pase lo que pase
        run_cmd("bw lock")
        print("Vault locked.")
        run_cmd("bw logout", allowed_err=["You are not logged in"])
        print("Logged out.")


if __name__ == "__main__":
    main()
