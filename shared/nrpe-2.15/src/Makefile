###############################
# Makefile for NRPE
#
# Last Modified: 08-13-2007
###############################

srcdir=.

# Source code directories
SRC_INCLUDE=./../include
CFG_INCLUDE=../include

CC=gcc
CFLAGS=-g -O2 -I/usr/include/openssl -I/usr/include -DHAVE_CONFIG_H -I $(CFG_INCLUDE) -I $(SRC_INCLUDE)
LDFLAGS= -L/usr/lib64  -lssl -lcrypto
SOCKETLIBS= -lnsl
LIBWRAPLIBS= -lwrap
OTHERLIBS=

CP=@CP@

prefix=/usr/local/nagios
exec_prefix=${prefix}
CFGDIR=${prefix}/etc
BINDIR=${exec_prefix}/bin
SBINDIR=${exec_prefix}/sbin
LIBEXECDIR=${exec_prefix}/libexec
INSTALL=/usr/bin/install -c
NAGIOS_INSTALL_OPTS=-o nagios -g nagios
NRPE_INSTALL_OPTS=-o nagios -g nagios

# Generated automatically from configure script
SNPRINTF_O=


all: nrpe check_nrpe

nrpe: $(srcdir)/nrpe.c $(srcdir)/utils.c $(srcdir)/acl.c $(SRC_INCLUDE)/nrpe.h $(SRC_INCLUDE)/utils.h $(SRC_INCLUDE)/common.h $(CFG_INCLUDE)/config.h $(SRC_INCLUDE)/acl.h $(SNPRINTF_O)
	$(CC) $(CFLAGS) -o $@ $(srcdir)/nrpe.c $(srcdir)/utils.c $(srcdir)/acl.c $(LDFLAGS) $(SOCKETLIBS) $(LIBWRAPLIBS) $(SNPRINTF_O) $(OTHERLIBS)

check_nrpe: $(srcdir)/check_nrpe.c $(srcdir)/utils.c $(SRC_INCLUDE)/utils.h $(SRC_INCLUDE)/common.h $(CFG_INCLUDE)/config.h
	$(CC) $(CFLAGS) -o $@ $(srcdir)/check_nrpe.c $(srcdir)/utils.c $(LDFLAGS) $(SOCKETLIBS) $(OTHERLIBS)

install:
	$(MAKE) install-plugin
	$(MAKE) install-daemon

install-plugin:
	$(INSTALL) -m 775 $(NAGIOS_INSTALL_OPTS) -d $(DESTDIR)$(LIBEXECDIR)
	$(INSTALL) -m 775 $(NAGIOS_INSTALL_OPTS) check_nrpe $(DESTDIR)$(LIBEXECDIR)

install-daemon:
	$(INSTALL) -m 775 $(NAGIOS_INSTALL_OPTS) -d $(DESTDIR)$(BINDIR)
	$(INSTALL) -m 775 $(NRPE_INSTALL_OPTS) nrpe $(DESTDIR)$(BINDIR)

clean:
	rm -f core nrpe check_nrpe $(SNPRINTF_O)
	rm -f *~ */*~
	rm -rf nrpe.dSYM check_nrpe.dSYM

distclean: clean
	rm -f Makefile

devclean: distclean
