#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <polygon.h>
#include "export.h"

static int nv_int;
static int nve_int;
static double *ve_p_int=NULL;
static double *angle_p_int=NULL;
static int *ipv_p_int=NULL;
static int *ev_p_int=NULL;

int gverts(polygon *poly, int vcirc, double *tol, int *nv, int nve, 
					 double **ve_p, double **angle_p, int **ipv_p, int *nev, 
					 int *nev0, int **ev_p);

#define FREEVEC(a) {if((a)!=NULL) free((char *) (a)); (a)=NULL;}
static void free_memory()
{
	FREEVEC(ve_p_int);
	FREEVEC(angle_p_int);
	FREEVEC(ipv_p_int);
	FREEVEC(ev_p_int);
}

#define DEG2RAD .01745329251994

/********************************************************************/
IDL_LONG idl_gverts
  (int      argc,
   void *   argv[])
{
	polygon *poly;
	double    tol;
	IDL_LONG vcirc;
	IDL_LONG *nv;
	IDL_LONG nve;
	double *ve_p;
	double *angle_p;
	IDL_LONG *ipv_p;
	IDL_LONG *nev;
	IDL_LONG *nev0;
	IDL_LONG *ev_p;
	
	IDL_LONG i,j,k,l;
	IDL_LONG retval=1;

	poly=(polygon *) malloc(sizeof(polygon));

	/* 0. allocate pointers from IDL */
	i=0;
	poly->rp = (double *)argv[i]; i++;
	poly->cm = (double *)argv[i]; i++;
	poly->np = *((IDL_LONG *)argv[i]); i++;
	poly->npmax = poly->np;
	tol = *((double *)argv[i]); i++;
	vcirc = *((IDL_LONG *)argv[i]); i++;
	nv = ((IDL_LONG *)argv[i]); i++;
	nve_int =nve = *((IDL_LONG *)argv[i]); i++;
	ve_p = ((double *)argv[i]); i++;
	angle_p = ((double *)argv[i]); i++;
	ipv_p = ((IDL_LONG *)argv[i]); i++;
	nev = ((IDL_LONG *)argv[i]); i++;
	nev0 = ((IDL_LONG *)argv[i]); i++;
	ev_p = ((IDL_LONG *)argv[i]); i++;
	
	/* 1. call gverts */
	if((*nv)==0) {
		/* 1a. if this is first call, we first must get numbers (can't do
       idl memory allocation inside here :( */
		retval=gverts(poly, vcirc, &tol, &nv_int, nve, &ve_p_int, &angle_p_int, 
									&ipv_p_int, (int *) nev, (int *) nev0, &ev_p_int);
	} else {
		/* 1b. we know sizes, so we can do the real thing */
		retval=gverts(poly, vcirc, &tol, &nv_int, nve, &ve_p_int, &angle_p_int, 
									&ipv_p_int, (int *) nev, (int *) nev0, &ev_p_int);

		/* copy vertices */
		for(i=0;i<(nv_int+4)*nve*3;i++) {
			ve_p[i]=ve_p_int[i];
		}
		
		/* copy others */
		for(i=0;i<(nv_int+4);i++) {
			angle_p[i]=angle_p_int[i];
			ev_p[i]=ev_p_int[i];
			ipv_p[i]=ipv_p_int[i];
		}
	}
	
	(*nv)=nv_int;
	FREEVEC(poly);
	free_memory();
	return retval;
}

/******************************************************************************/

