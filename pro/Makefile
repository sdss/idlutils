#
# IDL support utilities for spectro2d and the fibermapper
#
SHELL = /bin/sh
#
SUBDIRS = fits math plot yanny TeXtoIDL image misc slatec

all :;

#
# Install things in their proper places in $(IDLUTILS_DIR)
#
install :
	@ for f in $(SUBDIRS); do \
		(mkdir $(IDLUTILS_DIR)/pro/$$f; \
		echo Copying $$f; \
		cp $$f/*.pro $(IDLUTILS_DIR)/pro/$$f ); \
	done

clean :
	- /bin/rm -f *~ core
	@ for f in $(SUBDIRS); do \
		(cd $$f ; echo In $$f; /bin/rm -f core *~ ); \
	done
