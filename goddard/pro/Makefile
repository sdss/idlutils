#
# IDL support utilities for spectro2d and the fibermapper
#
SHELL = /bin/sh
#
SUBDIRS = database fits_bintable image misc sdas_table tv \
	astro disk_io fits_table jhuapl plot structure \
	astrom fits idlphot math sdas tape_io

all :;

#
# Install things in their proper places in $(IDLUTILS_DIR)
#
install :
	@ for f in $(SUBDIRS); do \
		(mkdir $(IDLUTILS_DIR)/goddard/pro/$$f; \
		echo Copying $$f; \
		cp $$f/*.pro $(IDLUTILS_DIR)/goddard/pro/$$f ); \
	done

clean :
	- /bin/rm -f *~ core
	@ for f in $(SUBDIRS); do \
		(cd $$f ; echo In $$f; /bin/rm -f core *~ ); \
	done
