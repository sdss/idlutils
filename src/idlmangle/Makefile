###############################################################################
# Routines for interfacing idl with mangle
#
# M.R. Blanton
###############################################################################

SHELL = /bin/sh
#
CFLAGS  = -I$(IDL_DIR)/external -I$(VAGC_DIR)/mangle1.2 -DCHECK_LEAKS
#
.c.o : $(VAGC_DIR)/mangle1.2/polygon.h export.h 
	$(CC) -c $(CCCHK) $(CFLAGS) $(IDL_FLAG) $*.c

LIB = $(VAGC_DIR)/lib
BIN = $(VAGC_DIR)/bin

RECIPES = 
OBJECTS = \
	idl_garea.o \
	idl_gverts.o 

all : $(LIB)/libidlmangle.$(SO_EXT) 

$(LIB)/libidlmangle.$(SO_EXT): $(OBJECTS) $(VAGC_DIR)/mangle1.2/libmangle.a
	$(LD) -shared $(X_LD_FLAGS) -o $(LIB)/libidlmangle.$(SO_EXT) $(OBJECTS) \
		-lmangle $(MAKE_FTNLIB) -L/usr/lib/gcc-lib/i386-redhat-linux/2.96 \
		-L$(VAGC_DIR)/mangle1.2

install : 

clean :
	- /bin/rm -f *~ core *.o so_locations
