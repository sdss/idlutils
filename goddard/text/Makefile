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
	-@ cp Makefile $(IDLUTILS_DIR)/goddard/text
	-@ cp README $(IDLUTILS_DIR)/goddard/text
	-@ cp *.doc $(IDLUTILS_DIR)/goddard/text
	-@ cp *.tex $(IDLUTILS_DIR)/goddard/text
	-@ cp *.txt $(IDLUTILS_DIR)/goddard/text

clean :
	- /bin/rm -f *~ core
