###############################################################################
# Sloan Digital Sky Survey (SDSS)
# IDL support code for products: idlmapper, idlspec2d
#
# S. Burles & D. Schlegel
###############################################################################

SHELL = /bin/sh
#
default :
	echo "Please invoke this makefile using sdssmake"
all :;

install :
	$(SDSSTOOLS_DIR)/bin/install_ups_table idlutils.table \
							$(IDLUTILS_DIR)/ups
clean :
	rm -f *~ core *.bak *.orig *.old .#* #*#
