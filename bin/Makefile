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
	/bin/cp Makefile $(IDLUTILS_DIR)/bin
	/bin/cp build_links $(IDLUTILS_DIR)/bin
	/bin/cp evilinstall $(IDLUTILS_DIR)/bin
	/bin/cp evilmake $(IDLUTILS_DIR)/bin
	/bin/cp eviltarball $(IDLUTILS_DIR)/bin
	/bin/cp install_ups_table $(IDLUTILS_DIR)/bin
	/bin/cp memtrack $(IDLUTILS_DIR)/bin
	/bin/cp pstogif $(IDLUTILS_DIR)/bin

clean :
	- /bin/rm -f *~ core
