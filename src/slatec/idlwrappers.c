#include <stdio.h>
#include <math.h>
#include <string.h>
#include <stdlib.h>
#include "export.h"

void bvalu_(float *t, float *a, IDL_LONG *n, IDL_LONG *k, 
         IDL_LONG *ideriv, float *x, IDL_LONG *inbv, float *w, float *retval);

void efc_(IDL_LONG *ndata, float *xdata, float *ydata, float *sddata, 
         IDL_LONG *nord, IDL_LONG *nbkpt, float *bkpt, IDL_LONG *mdein, 
         IDL_LONG *mdeout, float *coeff, IDL_LONG *lw, float *w);

/*  void main() 
{
  float t[7] = {0.0,0.0,0.0,1.0,2.0,2.0,2.0};
  float a[4] = {0.986643,   0.0398163,    0.793884,    0.376582};
  IDL_LONG k = 3;
  IDL_LONG n = 4;
  IDL_LONG ideriv = 0;
  float x = 0.8;
  IDL_LONG inbv   = 1;
  float w[100];
  float value = 0.0;

  bvalu_(t, a, &n, &k, &ideriv, &x, &inbv, w, &value);

} */

IDL_LONG efc_idl
 (int      argc,
   void *   argv[])
{
  IDL_LONG *ndata;
  float *xdata;
  float *ydata; 
  float *sddata;
  IDL_LONG *nord;
  IDL_LONG *nbkpt;
  float  *bkpt;
  IDL_LONG *mdein;
  IDL_LONG *mdeout;
  float *coeff;
  IDL_LONG *lw;
  float  *w;

  int argct = 0;
  ndata  = (IDL_LONG *)argv[argct++];
  xdata  = (float *)argv[argct++];
  ydata  = (float *)argv[argct++];
  sddata = (float *)argv[argct++];
  nord   = (IDL_LONG*)argv[argct++];
  nbkpt  = (IDL_LONG*)argv[argct++];
  bkpt   = (float *)argv[argct++];
  mdein  = (IDL_LONG*)argv[argct++];
  mdeout = (IDL_LONG*)argv[argct++];
  coeff  = (float *)argv[argct++];
  lw     = (IDL_LONG*)argv[argct++];
  w      = (float *)argv[argct++];

  efc_(ndata, xdata, ydata, sddata, nord, nbkpt, bkpt, mdein, mdeout, 
       coeff, lw, w);

  return *mdeout;

} 
  
IDL_LONG bvalu_idl
 (int      argc,
   void *   argv[])
{
  float *t;
  float *a; 
  IDL_LONG *n;
  IDL_LONG *k;
  IDL_LONG *ideriv;
  float *x; 
  IDL_LONG *ndata;
  IDL_LONG *inbv;
  float  *w;
  float *value;
  int i;

  int argct = 0;
  t = (float *)argv[argct++];
  a = (float *)argv[argct++];
  n = (IDL_LONG *)argv[argct++];
  k = (IDL_LONG *)argv[argct++];
  ideriv = (IDL_LONG *)argv[argct++];
  x      = (float *)argv[argct++];
  ndata  = (IDL_LONG *)argv[argct++];
  inbv   = (IDL_LONG *)argv[argct++];
  w      = (float *)argv[argct++];
  value   = (float *)argv[argct++];

  for (i=0;i<*ndata;i++)    
    bvalu_(t, a, n, k, ideriv, &x[i], inbv, w, &value[i]);

  return 0;
} 
  



