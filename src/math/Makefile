#
# IDL support utilities for spectro2d and the fibermapper
#
SHELL = /bin/sh
#
.c.o :
	$(CC) -c $(CCCHK) $(CFLAGS) $(X_CFLAGS) $*.c
#
CFLAGS  = -I$(IDL_DIR)/external $(SDSS_CFLAGS) -DCHECK_LEAKS

LIB = $(IDLUTILS_DIR)/lib

RECIPES = nrecipes.o nrutil.o
OBJECTS = \
	arravsigclip.o \
	arravsigmask.o \
	arrmedian.o \
	$(RECIPES)

all : $(LIB)/libmath.$(SO_EXT)


$(LIB)/libmath.$(SO_EXT): $(OBJECTS)
	$(LD) $(X_LD_FLAGS) -o $(LIB)/libmath.$(SO_EXT) $(OBJECTS)
#	nm -s ../lib/libmath.$(SO_EXT)

#
# Install things in their proper places in $(IDLUTILS_DIR)
#
install :;

clean :
	- /bin/rm -f *~ core *.o so_locations
