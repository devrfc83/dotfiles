#!/usr/bin/env bash
set -euo pipefail

echo "Instalando pgFormatter..."
cd /tmp
rm -rf pgFormatter
git clone https://github.com/darold/pgFormatter.git pgFormatter
cd pgFormatter
perl Makefile.PL
make
sudo make install
cd ~
rm -rf /tmp/pgFormatter
echo "$(pg_format --version) instalado."
