#
# IDL support utilities for spectro2d and the fibermapper
#
SHELL = /bin/sh
#
all :

#
# Install things in their proper places in $(IDLUTILS_DIR)
#
install :
	@ rm -rf $(IDLUTILS_DIR)/doc/www
	@ mkdir $(IDLUTILS_DIR)/doc/www
	- cp *.txt $(IDLUTILS_DIR)/doc
	- cp www/*.html $(IDLUTILS_DIR)/doc/www

clean :
	- /bin/rm -f *~ core www/*~ www/core


