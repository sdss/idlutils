#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include "export.h"

/******************************************************************************/
IDL_LONG grow_obj
  (int         argc,
   void    *   argv[])
{
   IDL_LONG    nx;
   IDL_LONG    ny;
   IDL_LONG *  image;
   IDL_LONG *  mask;
   IDL_LONG    iloc;
   IDL_LONG    putval;
   IDL_LONG    qdiag;
   IDL_LONG *  ilist;

   IDL_LONG    jfirst;
   IDL_LONG    jlast;
   IDL_LONG    iloc1;
   IDL_LONG    retval = 0;

   /* Allocate pointers from IDL */
   nx = *((IDL_LONG *)argv[0]);
   ny = *((IDL_LONG *)argv[1]);
   image = (IDL_LONG *)argv[2];
   mask = (IDL_LONG *)argv[3];
   iloc = *((IDL_LONG *)argv[4]);
   putval = *((IDL_LONG *)argv[5]);
   qdiag = *((IDL_LONG *)argv[6]);
   ilist = (IDL_LONG *)argv[7];

   /* Only do anything if the starting pixel should be assigned. */
   jfirst = 0;
   jlast = -1;
   while (image[iloc] != 0 && mask[iloc] <= 0) {

      mask[iloc] = putval;
      retval++;

      /* Mark any neighboring left-right-up-down pixels */
      iloc1 = iloc - 1;
      if (image[iloc1] != 0 && mask[iloc1] == 0) {
         mask[iloc1] = -1;
         ilist[++jlast] = iloc1;
      }
      iloc1 = iloc + 1;
      if (image[iloc1] != 0 && mask[iloc1] == 0) {
         mask[iloc1] = -1;
         ilist[++jlast] = iloc1;
      }
      iloc1 = iloc - ny;
      if (image[iloc1] != 0 && mask[iloc1] == 0) {
         mask[iloc1] = -1;
         ilist[++jlast] = iloc1;
      }
      iloc1 = iloc + ny;
      if (image[iloc1] != 0 && mask[iloc1] == 0) {
         mask[iloc1] = -1;
         ilist[++jlast] = iloc1;
      }

      /* Mark any neighboring diagonal pixels */
      if (qdiag) {
         iloc1 = iloc - 1 - nx;
         if (image[iloc1] != 0 && mask[iloc1] == 0) {
            mask[iloc1] = -1;
            ilist[++jlast] = iloc1;
         }
         iloc1 = iloc + 1 - nx;
         if (image[iloc1] != 0 && mask[iloc1] == 0) {
            mask[iloc1] = -1;
            ilist[++jlast] = iloc1;
         }
         iloc1 = iloc - 1 + nx;
         if (image[iloc1] != 0 && mask[iloc1] == 0) {
            mask[iloc1] = -1;
            ilist[++jlast] = iloc1;
         }
         iloc1 = iloc + 1 + nx;
         if (image[iloc1] != 0 && mask[iloc1] == 0) {
            mask[iloc1] = -1;
            ilist[++jlast] = iloc1;
         }
      }

      /* Determine next central pixel location */
      if (jfirst <= jlast) {
         iloc = ilist[jfirst++];
      } else {
         iloc = 0;
      }
   }

   return retval;
}

