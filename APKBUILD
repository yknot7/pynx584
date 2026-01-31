# Alpine

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
}

sha512sums="
acfd59ac7d151b695a28bd23a7d6e43143ee2527c9dcc4482eab36203c2da06fd43dd2371e947267897f1f509a40e8375255b45a242f1416725301c1bcc0031f  pynx584-1.tar.gz
"
