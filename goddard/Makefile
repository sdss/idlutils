#
# IDL support utilities for spectro2d and the fibermapper
#
SHELL = /bin/sh
#
SUBDIRS = data pro

all :;

#
# Install things in their proper places in $(IDLUTILS_DIR)
#
install :
	@ for f in $(SUBDIRS); do \
		(mkdir $(IDLUTILS_DIR)/goddard/$$f; \
		echo Copying $$f; \
		cp $$f/*.pro $(IDLUTILS_DIR)/goddard/$$f ); \
	done

clean :
	- /bin/rm -f *~ core
	@ for f in $(SUBDIRS); do \
		(cd $$f ; echo In $$f; /bin/rm -f core *~ ); \
	done
