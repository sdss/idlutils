#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <polygon.h>
#include "export.h"

int garea(polygon *poly, double *tol, IDL_LONG verb, double *area); 
polygon *new_poly(int npmax);

#define FREEVEC(a) {if((a)!=NULL) free((char *) (a)); (a)=NULL;}
static void free_memory()
{
}

#define DEG2RAD .01745329251994

/********************************************************************/
IDL_LONG idl_where_polygons_overlap
  (int      argc,
   void *   argv[])
{
	polygon *poly;
  IDL_LONG ncaps,maxncaps, nmatch, *matchncaps, *ismatch;
  double *x, *cm, *xmatch, *cmmatch;
	
	IDL_LONG i,j,k;
	IDL_LONG retval=1;
	double    tol,area;
	IDL_LONG  verbose;

  tol=0.;
  verbose=0;

	/* 0. allocate pointers from IDL */
	i=0;
  x=(double *) argv[i]; i++;
  cm=(double *) argv[i]; i++;
  ncaps=*((IDL_LONG *) argv[i]); i++;
  xmatch=(double *) argv[i]; i++;
  cmmatch=(double *) argv[i]; i++;
  maxncaps=*((IDL_LONG *) argv[i]); i++;
  nmatch=*((IDL_LONG *) argv[i]); i++;
  matchncaps=((IDL_LONG *) argv[i]); i++;
  ismatch=((IDL_LONG *) argv[i]); i++;

	poly=new_poly(ncaps+maxncaps);
  
  for(j=0;j<ncaps;j++) {
    poly->cm[j]=cm[j];
    for(k=0;k<3;k++) 
      poly->rp[j][k]=x[j*3+k];
  }

  for(i=0;i<nmatch;i++) {
    poly->np=ncaps+matchncaps[i];
    for(j=0;j<matchncaps[i];j++) {
      poly->cm[ncaps+j]=cmmatch[i*maxncaps+j];
      for(k=0;k<3;k++) 
        poly->rp[ncaps+j][k]=xmatch[i*maxncaps*3+j*3+k];
    }
    retval=garea(poly, &tol, verbose, &area);
    if(area>0.) 
      ismatch[i]=1; 
    else 
      ismatch[i]=0; 
  }
  
  free_poly(poly);
	return retval;
}

/******************************************************************************/

