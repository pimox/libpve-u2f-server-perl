include /usr/share/dpkg/pkg-info.mk
include /usr/share/dpkg/architecture.mk

PACKAGE=libpve-u2f-server-perl

BUILDSRC := $(PACKAGE)-$(DEB_VERSION_EPOCH_UPSTREAM)

DESTDIR=
PREFIX=/usr
LIBDIR=$(PREFIX)/lib
DOCDIR=$(PREFIX)/share/doc/$(PACKAGE)
PERLDIR=$(PREFIX)/share/perl5

PERL_ARCHLIB != perl -MConfig -e 'print $$Config{archlib};'
PERL_INSTALLVENDORARCH != perl -MConfig -e 'print $$Config{installvendorarch};'
PERL_APIVER != perl -MConfig -e 'print $$Config{debian_abi}//$$Config{version};'
PERL_CC != perl -MConfig -e 'print $$Config{cc};'
PERLSODIR=$(PERL_INSTALLVENDORARCH)/auto
CFLAGS := -shared -fPIC -O2 -Werror -Wtype-limits -Wall -Wl,-z,relro \
	-D_FORTIFY_SOURCE=2 -I$(PERL_ARCHLIB)/CORE -DXS_VERSION=\"1.0\"

CFLAGS += `pkg-config --cflags u2f-server`
LIBS += `pkg-config --libs u2f-server`

DEB=$(PACKAGE)_$(DEB_VERSION_UPSTREAM_REVISION)_$(DEB_BUILD_ARCH).deb
DSC=$(PACKAGE)_$(DEB_VERSION_UPSTREAM_REVISION).dsc

GITVERSION:=$(shell git rev-parse HEAD)

all:

ppport.h:
	perl -MDevel::PPPort -e 'Devel::PPPort::WriteFile();'

U2F.c: U2F.xs
	xsubpp U2F.xs > U2F.xsc
	mv U2F.xsc U2F.c

U2F.so: U2F.c ppport.h
	$(PERL_CC) $(CFLAGS) -o U2F.so U2F.c $(LIBS)

.PHONY: dinstall
dinstall: deb
	dpkg -i $(DEB)

.PHONY: install
install: PVE/U2F.pm U2F.so
	install -D -m 0644 PVE/U2F.pm $(DESTDIR)$(PERLDIR)/PVE/U2F.pm
	install -D -m 0644 -s U2F.so $(DESTDIR)$(PERLSODIR)/PVE/U2F/U2F.so

.PHONY: $(BUILDSRC)
$(BUILDSRC):
	rm -rf $(BUILDSRC)
	mkdir $(BUILDSRC)
	rsync -a debian Makefile PVE U2F.xs base64.h $(BUILDSRC)/
	echo "git clone git://git.proxmox.com/git/libpve-u2f-server-perl.git\\ngit checkout $(GITVERSION)" > $(BUILDSRC)/debian/SOURCE

.PHONY: deb
deb: $(DEB)
$(DEB): $(BUILDSRC)
	cd $(BUILDSRC); dpkg-buildpackage -b -us -uc
	lintian $(DEB)

.PHONY: dsc
dsc: $(DSC)
$(DSC): $(BUILDSRC)
	cd $(BUILDSRC); dpkg-buildpackage -S -us -uc -d -nc
	lintian $(DSC)

.PHONY: clean
clean:
	rm -rf *~ ${BUILDSRC} *.deb *.changes *.buildinfo *.dsc *.tar.gz
	find . -name '*~' -exec rm {} ';'

.PHONY: distclean
distclean: clean


.PHONY: upload
upload: $$DEB)
	tar cf - $(DEB) | ssh repoman@repo.proxmox.com -- upload --product pve --dist stretch --arch $(ARCH)
