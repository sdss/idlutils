###############################################################################
# Sloan Digital Sky Survey (SDSS)
# IDL support code for products: idlmapper, idlspec2d
#
# S. Burles & D. Schlegel
###############################################################################

SHELL = /bin/sh
#
SUBDIRS = TeXtoIDL coord fits image math misc plot slatec yanny

all :;

#
# Install things in their proper places in $(IDLUTILS_DIR)
#
install :
	@ for f in $(SUBDIRS); do \
		(mkdir $(IDLUTILS_DIR)/pro/$$f; \
		echo Copying $$f; \
		cp $$f/* $(IDLUTILS_DIR)/pro/$$f ); \
	done
	-@ cp Makefile $(IDLUTILS_DIR)/pro

clean :
	- /bin/rm -f *~ core
	@ for f in $(SUBDIRS); do \
		(cd $$f ; echo In $$f; /bin/rm -f core *~ ); \
	done
