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
   IDL_LONG    xstart;
   IDL_LONG    ystart;
   IDL_LONG    putval;
   IDL_LONG    qdiag;

   IDL_LONG    xi;
   IDL_LONG    yi;
   IDL_LONG    xnext;
   IDL_LONG    ynext;
   IDL_LONG    iloc;
   IDL_LONG    retval = 0;

   /* Allocate pointers from IDL */
   nx = *((IDL_LONG *)argv[0]);
   ny = *((IDL_LONG *)argv[1]);
   image = (IDL_LONG *)argv[2];
   mask = (IDL_LONG *)argv[3];
   xstart = *((IDL_LONG *)argv[4]);
   ystart = *((IDL_LONG *)argv[5]);
   putval = *((IDL_LONG *)argv[6]);
   qdiag = *((IDL_LONG *)argv[7]);

   /* Only do anything if the starting pixel should be assigned. */
   xi = xstart;
   yi = ystart;
   while (xi >= 0 && image[xi+yi*nx] != 0 && mask[xi+yi*nx] <= 0) {
      xnext = -1;
      ynext = -1;

      mask[xi+yi*nx] = putval;
      retval++;

      /* Mark any neighboring left-right-up-down pixels */
      if (yi > 0) {
         iloc = xi + (yi-1)*nx;
         if (image[iloc] != 0 && mask[iloc] == 0) {
            mask[iloc] = -1;
            xnext = xi;
            ynext = yi-1;
         }
      }
      if (xi > 0) {
         iloc = (xi-1) + yi*nx;
         if (image[iloc] != 0 && mask[iloc] == 0) {
            mask[iloc] = -1;
            xnext = xi-1;
            ynext = yi;
         }
      }
      if (xi < nx-1) {
         iloc = (xi+1) + yi*nx;
         if (image[iloc] != 0 && mask[iloc] == 0) {
            mask[iloc] = -1;
            xnext = xi+1;
            ynext = yi;
         }
      }
      if (yi < ny-1) {
         iloc = xi + (yi+1)*nx;
         if (image[iloc] != 0 && mask[iloc] == 0) {
            mask[iloc] = -1;
            xnext = xi;
            ynext = yi+1;
         }
      }

      /* Mark any neighboring diagonal pixels */
      if (qdiag == 1) {
         if (xi > 0 && yi > 0) {
            iloc = (xi-1) + (yi-1)*nx;
            if (image[iloc] != 0 && mask[iloc] == 0) {
               mask[iloc] = -1;
               xnext = xi-1;
               ynext = yi-1;
            }
         }
         if (xi < nx-1 && yi > 0) {
            iloc = (xi+1) + (yi-1)*nx;
            if (image[iloc] != 0 && mask[iloc] == 0) {
               mask[iloc] = -1;
               xnext = xi+1;
               ynext = yi-1;
            }
         }
         if (xi > 0 && yi < ny-1) {
            iloc = (xi-1) + (yi+1)*nx;
            if (image[iloc] != 0 && mask[iloc] == 0) {
               mask[iloc] = -1;
               xnext = xi-1;
               ynext = yi+1;
            }
         }
         if (xi < nx-1 && yi < ny-1) {
            iloc = (xi+1) + (yi+1)*nx;
            if (image[iloc] != 0 && mask[iloc] == 0) {
               mask[iloc] = -1;
               xnext = xi+1;
               ynext = yi+1;
            }
         }
      }

      /* Determine next central pixel location */
      if (xnext >= 0) {
         xi = xnext;
         yi = ynext;
      } else {
         xi = 0;
         yi = 0;
         while (xi < nx && yi < ny && mask[xi+yi*nx] != -1) {
            xi++;
            if (xi == nx) {
               xi = 0;
               yi++;
            }
         }
         if (yi == ny) yi = 0; /* This happens when we're all done */
      }
   }

   return retval;
}

