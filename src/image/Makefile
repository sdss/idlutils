###############################################################################
# Sloan Digital Sky Survey (SDSS)
# IDL support code for products: idlmapper, idlspec2d
#
# S. Burles & D. Schlegel
###############################################################################

SHELL = /bin/sh
#
.c.o :
	$(CC) -c $(CCCHK) $(CFLAGS) $(X_CFLAGS) $*.c
#
CFLAGS  = -I$(IDL_DIR)/external $(SDSS_CFLAGS) -DCHECK_LEAKS

LIB = $(IDLUTILS_DIR)/lib

OBJECTS = \
	pop_image.o

all : $(LIB)/libimage.$(SO_EXT)


$(LIB)/libimage.$(SO_EXT): $(OBJECTS)
	$(LD) $(X_LD_FLAGS) -o $(LIB)/libimage.$(SO_EXT) $(OBJECTS)
#	nm -s ../lib/libimage.$(SO_EXT)

#
# Install things in their proper places in $(IDLUTILS_DIR)
#
install : 
	-@ cp *.c $(IDLUTILS_DIR)/src/image
	-@ cp *.h $(IDLUTILS_DIR)/src/image
	-@ cp Makefile $(IDLUTILS_DIR)/src/image

clean :
	- /bin/rm -f *~ core *.o so_locations
