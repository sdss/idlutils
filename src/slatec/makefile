#$Id: makefile,v 1.3 1999-10-22 21:56:57 scott Exp $
#
#  Copyright (c) 1988-1998, Research Systems Inc.  All rights reserved.
#  This software includes information which is proprietary to and a
#  trade secret of Research Systems, Inc.  It is not to be disclosed
#  to anyone outside of this organization. Reproduction by any means
#  whatsoever is  prohibited without express written permission.
#
#  makefile for CALL_EXTERNAL examples, UNIX platforms
#
#  This is a recursive makefile. The default target "all" detects which
#  operating system you are on, sets system specific macros, and then
#  calls make again to build the target "libs".  Specifying a target
#  other than "all","clean", or "tidy" will NOT set all required macros
#  and will probably produce incorrect results.
#
SHELL=/bin/sh
# 	The following macro might need to be edited if the location
#	of IDL is not the standard location on your system.
#IDL_DIR = /usr/local/rsi/idl


# The following macros establish general defaults. They are overridden
# in the "all" rule as needed to satisfy a given platform's requirements.

CC		= cc
C_FLAGS		= -I$(IDL_DIR)/external -c $(CFLAGS) 
LD 		= ld
SHELL		= /bin/sh
#platform specific C compiler flags (redefined below)
X_CFLAGS	=
#platform specific linker flags
X_LD_FLAGS	=

SO_EXT		=so

# The following is the default entry point. This section will determine
# what system we are on, set the correct flags and call this same makefile
# again with the correct flags.

all :
	@echo "OS type detected: "`uname`
	@case `uname` in \
	"SunOS") if [  -d /proc ]; then \
			make libslatecidl.$(SO_EXT) \
			"SO_EXT=so" \
			"CC=cc" \
			"LD=cc" \
			"X_CFLAGS=-K pic " \
			"X_LD_FLAGS=-G "; \
		fi \
	;; \
	"HP-UX") make libslatecidl.$(SO_EXT) \
		"SO_EXT=sl" \
		"CC=cc" \
		"LD=ld" \
		"X_CFLAGS=+z -Aa -D_HPUX_SOURCE" \
		"X_LD_FLAGS=-b";; \
	"IRIX" ) make libslatecidl.$(SO_EXT) \
		"SO_EXT=so" \
		"CC=cc" \
		"LD=ld" \
		"X_CFLAGS=-32 -KPIC" \
		"X_LD_FLAGS=-shared -32";; \
	"IRIX64" ) make libslatecidl.$(SO_EXT) \
		"SO_EXT=so" \
		"CC=cc" \
		"LD=ld" \
		"X_CFLAGS=-32 -KPIC -o32" \
		"X_LD_FLAGS=-shared -32";; \
	"OSF1" )  make libslatecidl.$(SO_EXT) \
		"SO_EXT=so" \
		"CC=cc" \
		"LD=ld" \
		"X_LD_FLAGS=-S -shared";; \
	"Linux" ) make libslatecidl.$(SO_EXT) \
		"SO_EXT=so" \
		"CC=gcc" \
		"f77=g77" \
		"LD=g77" \
		"X_CFLAGS=-O -Wall" \
		"X_LD_FLAGS=-shared" ;;\
	*) echo "This system is not supported" ;; \
	esac


.c.o :
	$(CC) $(C_FLAGS) $(X_CFLAGS) $*.c

.f.o :
	$(F77) $(C_FLAGS) $(X_CFLAGS) $*.f



objs = bint4.o bndacc.o bndsol.o bnfac.o bnslv.o bsplvn.o bspvd.o bspvn.o \
bvalu.o chkder.o csevl.o d1mach_Linux.o dasum.o daxpy.o dbint4.o dbintk.o dbndac.o \
dbndsl.o dbnfac.o dbnslv.o dbspvd.o dbspvn.o dbvalu.o dckder.o dcopy.o \
dcsevl.o ddot.o defc.o defcmn.o denorm.o derf.o derfc.o dfdjc3.o dfspvn.o \
dgeco.o dgefa.o dgefs.o dgesl.o dh12.o dintrv.o dmpar.o dnls1.o dnls1e.o \
dp1vlu.o dpcoef.o dpolft.o dpsort.o dqrfac.o dqrslv.o dscal.o dsidi.o \
dsifa.o dsort.o dswap.o dwupdt.o efc.o efcmn.o enorm.o erf.o erfc.o fdjac3.o \
fdump.o h12.o i1mach_Linux.o idamax.o idlwrappers.o initds.o inits.o intrv.o \
isort.o j4save.o lmpar.o pcoef.o polfit.o pvalue.o qrfac.o qrsolv.o  \
r1mach_Linux.o radb2.o radb3.o radb4.o radb5.o radbg.o radf2.o radf3.o \
radf4.o radf5.o radfg.o rand.o rfftb.o rfftb1.o rfftf.o rfftf1.o rffti.o \
rffti1.o rgauss.o runif.o rwupdt.o saxpy.o scopy.o sdot.o snls1.o snls1e.o \
sscal.o ssort.o sswap.o xercnt.o xerhlt.o xermsg.o xerprn.o xersve.o \
xgetua.o xsetf.o 

libslatecidl.$(SO_EXT): $(objs)
	$(LD) $(X_LD_FLAGS) -o ../../lib/libslatecidl.$(SO_EXT) $(objs) 
#	nm -s ../../lib/libslatecidl.$(SO_EXT)

tidy :
	rm -f *.o

clean : tidy
	rm -f *.so *.sl *.a
