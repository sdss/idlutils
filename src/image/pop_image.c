#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include "export.h"

/******************************************************************************/
IDL_LONG pop_image
  (int         argc,
   void    *   argv[])
{
   IDL_LONG    npts;
   float    *  xvec;
   float    *  yvec;
   float    *  wvec;
   IDL_LONG    nx;
   IDL_LONG    ny;
   float    *  image;
   IDL_LONG    iassign;

   IDL_LONG    ipt;
   IDL_LONG    ix1;
   IDL_LONG    iy1;
   IDL_LONG    retval = 1;
   float       dx;
   float       dy;

   /* Allocate pointers from IDL */
   npts = *((IDL_LONG *)argv[0]);
   xvec = (float *)argv[1];
   yvec = (float *)argv[2];
   wvec = (float *)argv[3];
   nx = *((IDL_LONG *)argv[4]);
   ny = *((IDL_LONG *)argv[5]);
   image = (float *)argv[6];
   iassign = *((IDL_LONG *)argv[7]);

   if (iassign == 0) {

      /* NGP assignment */

      for (ipt=0; ipt < npts; ipt++) {
         ix1 = floor(xvec[ipt]+0.5);
         iy1 = floor(yvec[ipt]+0.5);

         if (ix1 >= 0 && ix1 < nx && iy1 >= 0 && iy1 < ny)
          image[ix1+iy1*nx] += wvec[ipt];
      }
   } else if (iassign == 1) {

      /* CIC assignment */

      for (ipt=0; ipt < npts; ipt++) {
         ix1 = floor(xvec[ipt]);
         iy1 = floor(yvec[ipt]);

         dx = ix1 + 1 - xvec[ipt];
         dy = iy1 + 1 - yvec[ipt];

         if (ix1 >= 0 && ix1 < nx && iy1 >= 0 && iy1 < ny)
          image[ix1+iy1*nx] += wvec[ipt] * dx * dy;
         if (ix1+1 >= 0 && ix1+1 < nx && iy1 >= 0 && iy1 < ny)
          image[ix1+1+iy1*nx] += wvec[ipt] * (1.0 - dx) * dy;
         if (ix1 >= 0 && ix1 < nx && iy1+1 >= 0 && iy1+1 < ny)
          image[ix1+(iy1+1)*nx] += wvec[ipt] * dx * (1.0 - dy);
         if (ix1+1 >= 0 && ix1+1 < nx && iy1+1 >= 0 && iy1+1 < ny)
          image[ix1+1+(iy1+1)*nx] += wvec[ipt] * (1.0 - dx) * (1.0 - dy);
      }

   }

   return retval;
}

