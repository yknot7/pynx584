# Alpine, apk add --allow-untrusted pynx584-1-r0.apk , python3 -m http.server 8000


# Maintainer: Tim S
pkgname=pynx584
pkgver=1
pkgrel=0
pkgdesc="Python interface and server for NetworX NX-584 alarm panels"
url="https://github.com/yknot7/pynx584"
arch="noarch"
license="GPL-3.0-or-later"

depends="python3 py3-flask py3-prettytable py3-pyserial py3-stevedore py3-requests"
makedepends="python3-dev py3-setuptools py3-wheel py3-build py3-installer"

source="$pkgname-$pkgver.tar.gz::https://github.com/yknot7/pynx584/archive/refs/tags/v$pkgver.tar.gz"
builddir="$srcdir/$pkgname-$pkgver"

build() {
    python3 -m build --wheel --no-isolation
}

package() {
    python3 -m installer --destdir="$pkgdir" dist/*.whl

    # -------------------------
    # 1) config.ini
    # -------------------------
    install -Dm644 /dev/null "$pkgdir/root/config.ini"
    cat > "$pkgdir/root/config.ini" <<'EOF'
[config]
max_zone = 26
idle_time_heartbeat_seconds = 10

[zones]
1 = FRONT DOOR
2 = GAR.TO HOUSE DR.
3 = LOW.REAR DOOR
4 = 1FL.PLAY RM.MOT.
5 = 1FL.PLAY RM.WD.
6 = 1FL.FT.RT.BRM.WD
7 = 1FL.LIVING MOT.
8 = 1FL.LAUNDRY WD.
10 = 1FL.RR.BDRM.WD.
11 = 2FL.NOOK.BATH.WD
12 = 2FL.NOOK MOTION
13 = GARAGE DOOR
14 = GARAGE WINDOW
15 = FRONT DR.MOTION
16 = FT.DINING WINDOW
17 = FAMILY WINDOW
18 = FAMILY REAR DOOR
19 = FAMILY MOTION
20 = NOOK REAR DOOR
21 = TOP LT.BRM.LT.WD
22 = TOP.LT.BRM.RT.WD
23 = TOP LT.BRM.DOOR
24 = TOP F.RT.HALL.DR
25 = MST.CLOSET WINDO
26 = MST.BDRM.DOOR
9 = 1FL.LIVING RR.WD
EOF

    # -------------------------
    # 2) OpenRC service
    # -------------------------
    install -Dm755 /dev/null "$pkgdir/etc/init.d/nx584_server"
    cat > "$pkgdir/etc/init.d/nx584_server" <<'EOF'
#!/sbin/openrc-run

command="/usr/bin/nx584_server"
command_args="--serial /dev/USB0 --baud 9600 --config /root/config.ini"
pidfile="/run/nx584_server.pid"
name="nx584_server"

depend() {
    need localmount
    after net
}
EOF
    chmod +x "$pkgdir/etc/init.d/nx584_server"

    # -------------------------
    # 3) Enable service on install
    # -------------------------
    install -Dm755 /dev/null "$pkgdir/etc/profile.d/nx584_enable.sh"
    cat > "$pkgdir/etc/profile.d/nx584_enable.sh" <<'EOF'
#!/bin/sh
if ! rc-service nx584_server status >/dev/null 2>&1; then
    rc-update add nx584_server default >/dev/null 2>&1
    rc-service nx584_server start >/dev/null 2>&1
fi
EOF
    chmod +x "$pkgdir/etc/profile.d/nx584_enable.sh"

    # -------------------------
    # 4) Dynamic MOTD (every login)
    # -------------------------
    install -Dm755 /dev/null "$pkgdir/etc/profile.d/nx584_motd.sh"
    cat > "$pkgdir/etc/profile.d/nx584_motd.sh" <<'EOF'
#!/bin/sh
IP=$(ip -4 addr show scope global | awk '/inet/ {sub(/\/.*/, "", $2); print $2; exit}')
cat <<EOM

NX584 CONFIG PATH: /root/config.ini

Start server:
$ nx584_server --serial /dev/USB0 --baud 9600 --config /root/config.ini

Help:
$ nx584_client arm-stay
$ nx584_client arm-exit
$ nx584_client arm-auto
$ nx584_client disarm --master 1234

Server running on IP: ${IP:-unknown}, port 5007

EOM
EOF
    chmod +x "$pkgdir/etc/profile.d/nx584_motd.sh"
}
