#
# IDL support utilities for spectro2d and the fibermapper
#
SHELL = /bin/sh
#
.c.o :
	$(CC) -c $(CCCHK) $(CFLAGS) $*.c
#
CFLAGS  = $(SDSS_CFLAGS) -DCHECK_LEAKS -I../include

SUBDIRS = doc goddard lib pro src

all :
	@ for f in $(SUBDIRS); do \
		(cd $$f ; echo In $$f; $(MAKE) $(MFLAGS) all ); \
	done

#
# Install things in their proper places in $(IDLUTILS_DIR)
#
install :
	@echo "You should be sure to have updated before doing this."
	@echo "You will be installing in \$$IDLUTILS_DIR=$$IDLUTILS_DIR"
	@echo ""
	@echo "I'll give you 5 seconds to think about it"
	@echo sleep 5
	@echo
	@if [ "$(IDLUTILS_DIR)" = "" ]; then \
		echo You have not specified a destination directory >&2; \
		exit 1; \
	fi 
	@ rm -rf $(IDLUTILS_DIR)
	@ mkdir $(IDLUTILS_DIR)
	@ for f in $(SUBDIRS); do \
		(mkdir $(IDLUTILS_DIR)/$$f; cd $$f ; echo In $$f; $(MAKE) $(MFLAGS) install ); \
	done

clean :
	- /bin/rm -f *~ core
	@ for f in $(SUBDIRS); do \
		(cd $$f ; echo In $$f; $(MAKE) $(MFLAGS) clean ); \
	done
