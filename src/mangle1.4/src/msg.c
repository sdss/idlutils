/*------------------------------------------------------------------------------
� A J S Hamilton 2001
------------------------------------------------------------------------------*/
#include <stdio.h>
#include "manglefn.h"

#ifdef GCC
# include <stdarg.h>
#endif
#ifdef Linux
# include <stdarg.h>
#endif
#ifdef Darwin
# include <stdarg.h>
#endif
#ifdef SunOS
# include <sys/varargs.h>
#endif

extern int verbose;

/*------------------------------------------------------------------------------
  Print messages.
*/
void msg(char *fmt, ...)
{
    va_list args;

    if (verbose) {
	va_start(args, fmt);
	vfprintf(stderr,fmt, args);
	va_end(args);
	fflush(stderr);
    }
}
