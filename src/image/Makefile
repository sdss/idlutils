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
CFLAGS  = -I$(IDL_DIR)/external $(SDSS_CFLAGS) -DCHECK_LEAKS -I$(IDLUTILS_DIR)/include

LIB = $(IDLUTILS_DIR)/lib

OBJECTS = \
	grow_obj.o pop_image.o \
	idl_photfrac.o \
	photfrac.o \
	idl_interp_profmean.o \
	ppvalu.o \
	tautsp.o \
	interv.o \
	interp_profmean.o \
	p_cisi.o \
	p_midpnt.o \
	p_qromo.o \
	p_polint.o \
	p_utils.o 

all : $(LIB)/libimage.$(SO_EXT)

$(LIB)/libimage.$(SO_EXT): $(OBJECTS) ph.h export.h
	$(LD) $(X_LD_FLAGS) -o $(LIB)/libimage.$(SO_EXT) $(OBJECTS) -lg2c -L/usr/lib/gcc-lib/i386-redhat-linux/2.96
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
