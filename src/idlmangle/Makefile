###############################################################################
# Routines for interfacing idl with mangle
#
# M.R. Blanton
###############################################################################

SHELL = /bin/sh
#
INC = ../../include
CFLAGS  = -I$(IDLUTILS_DIR)/src/mangle1.4/src -DCHECK_LEAKS -I$(INC)
#
.c.o : $(IDLUTILS_DIR)/src/mangle1.4/src/polygon.h export.h 
	$(CC) -c $(CCCHK) $(CFLAGS) $(IDL_FLAG) $*.c

LIB = $(IDLUTILS_DIR)/lib
BIN = $(IDLUTILS_DIR)/bin

RECIPES = 
OBJECTS = \
	idl_garea.o \
	idl_where_polygons_overlap.o \
	idl_vmid.o \
	idl_gverts.o 

all : $(LIB)/libidlmangle.$(SO_EXT) 

$(LIB)/libidlmangle.$(SO_EXT): $(OBJECTS) $(IDLUTILS_DIR)/lib/libmangle.a
	$(LDF77) $(X_LD_FLAGS) -o $(LIB)/libidlmangle.$(SO_EXT) $(OBJECTS) \
		-lmangle -L$(IDLUTILS_DIR)/lib

install :
	-@ cp *.c $(IDLUTILS_DIR)/src/idlmangle
	-@ cp *.h $(IDLUTILS_DIR)/src/idlmangle
	-@ cp Makefile $(IDLUTILS_DIR)/src/idlmangle

clean :
	- /bin/rm -f *~ core *.o so_locations
