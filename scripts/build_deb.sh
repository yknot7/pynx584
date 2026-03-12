#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PKGNAME="pynx584"

VERSION=$(python3 - <<'PY'
import re
from pathlib import Path
text = Path('setup.py').read_text()
m = re.search(r"version='([^']+)'", text)
if not m:
    raise SystemExit('Version not found in setup.py')
print(m.group(1))
PY
)

DEBVER="${VERSION}-1"
ARCH="all"
OUT_DIR="${ROOT_DIR}/dist"
STAGE_DIR=$(mktemp -d)
PKG_DIR="${STAGE_DIR}/${PKGNAME}_${DEBVER}_${ARCH}"

mkdir -p "${OUT_DIR}"
mkdir -p "${PKG_DIR}/DEBIAN"
mkdir -p "${PKG_DIR}/usr/bin"
mkdir -p "${PKG_DIR}/usr/lib/python3/dist-packages"
mkdir -p "${PKG_DIR}/usr/share/doc/${PKGNAME}"
mkdir -p "${PKG_DIR}/lib/systemd/system"
mkdir -p "${PKG_DIR}/etc/default"

cat > "${PKG_DIR}/DEBIAN/control" <<EOF2
Package: ${PKGNAME}
Version: ${DEBVER}
Section: utils
Priority: optional
Architecture: ${ARCH}
Depends: python3, python3-requests, python3-stevedore, python3-prettytable, python3-serial, python3-flask
Maintainer: Local Builder <builder@localhost>
Description: NX584/NX8E Interface Library and Server
 A tool to interact with NetworX alarm panels via NX584/NX8E modules.
EOF2

cat > "${PKG_DIR}/DEBIAN/templates" <<'EOF2'
Template: pynx584/serial
Type: string
Default: /dev/serial/by-id/usb-1a86_USB2.0-Ser_-if00-port0
Description: Serial device path for the NX584 interface
 Enter the serial device path used to connect to the panel.

Template: pynx584/baud
Type: string
Default: 9600
Description: Serial baud rate for the NX584 interface
 Enter the baud rate to use for the serial connection.

Template: pynx584/config
Type: string
Default: /mnt/data/nx584/config.ini
Description: Path to config.ini
 Enter the path to the configuration file for pynx584.
EOF2

cat > "${PKG_DIR}/DEBIAN/config" <<'EOF2'
#!/bin/sh
set -e

. /usr/share/debconf/confmodule

db_input high pynx584/serial || true
db_input high pynx584/baud || true
db_input high pynx584/config || true

db_go || true
EOF2

cat > "${PKG_DIR}/DEBIAN/postinst" <<'EOF2'
#!/bin/sh
set -e

. /usr/share/debconf/confmodule

update_kv() {
    key="$1"
    val="$2"
    file="$3"
    if [ -f "$file" ] && grep -q "^${key}=" "$file"; then
        tmp=$(mktemp)
        sed "s|^${key}=.*|${key}=${val}|" "$file" > "$tmp"
        cat "$tmp" > "$file"
        rm -f "$tmp"
    else
        echo "${key}=${val}" >> "$file"
    fi
}

db_get pynx584/serial
SERIAL="$RET"

db_get pynx584/baud
BAUD="$RET"

db_get pynx584/config
CONFIG="$RET"

DEFAULT_FILE="/etc/default/pynx584"
if [ ! -f "$DEFAULT_FILE" ]; then
    : > "$DEFAULT_FILE"
fi

update_kv "SERIAL" "$SERIAL" "$DEFAULT_FILE"
update_kv "BAUD" "$BAUD" "$DEFAULT_FILE"
update_kv "CONFIG" "$CONFIG" "$DEFAULT_FILE"

chmod 0644 "$DEFAULT_FILE"

if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload || true
    systemctl enable --now pynx584.service || true
fi
EOF2

cat > "${PKG_DIR}/DEBIAN/postrm" <<'EOF2'
#!/bin/sh
set -e

if command -v systemctl >/dev/null 2>&1; then
    systemctl disable --now pynx584.service || true
    systemctl daemon-reload || true
fi
EOF2

chmod 0755 "${PKG_DIR}/DEBIAN/config" "${PKG_DIR}/DEBIAN/postinst" "${PKG_DIR}/DEBIAN/postrm"
chmod 0644 "${PKG_DIR}/DEBIAN/control" "${PKG_DIR}/DEBIAN/templates"

cat > "${PKG_DIR}/etc/default/pynx584" <<'EOF2'
SERIAL=/dev/serial/by-id/usb-1a86_USB2.0-Ser_-if00-port0
BAUD=9600
CONFIG=/mnt/data/nx584/config.ini
EOF2

cat > "${PKG_DIR}/lib/systemd/system/pynx584.service" <<'EOF2'
[Unit]
Description=NX584 server
After=network.target

[Service]
Type=simple
EnvironmentFile=-/etc/default/pynx584
ExecStart=/usr/bin/nx584_server --serial ${SERIAL} --baudrate ${BAUD} --config ${CONFIG}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF2

install -m 0755 "${ROOT_DIR}/nx584_server" "${PKG_DIR}/usr/bin/nx584_server"
install -m 0755 "${ROOT_DIR}/nx584_client" "${PKG_DIR}/usr/bin/nx584_client"
cp -a "${ROOT_DIR}/nx584" "${PKG_DIR}/usr/lib/python3/dist-packages/"
cp -a "${ROOT_DIR}/README.rst" "${PKG_DIR}/usr/share/doc/${PKGNAME}/README.rst"

DEB_PATH="${OUT_DIR}/${PKGNAME}_${DEBVER}_${ARCH}.deb"

dpkg-deb --build --root-owner-group "${PKG_DIR}" "${DEB_PATH}"

echo "Built ${DEB_PATH}"
