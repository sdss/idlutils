###############################################################################
# Sloan Digital Sky Survey (SDSS)
# IDL support code for products: idlmapper, idlspec2d
#
# S. Burles & D. Schlegel
###############################################################################

SHELL = /bin/sh
#
all :;
#
# Install things in their proper places in $(IDLUTILS_DIR)
#
install :
	/bin/cp Makefile $(IDLUTILS_DIR)/filters
	/bin/cp README $(IDLUTILS_DIR)/filters
	/bin/cp *.* $(IDLUTILS_DIR)/filters

clean :
	- /bin/rm -f *~ core
