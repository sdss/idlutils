#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include "polygon.h"

/* add a parent to the polygon parent list */
void add_parent(polygon *poly, int parent) 
{
	int i;
	for(i=0;i<poly->nparents;i++) 
		if(poly->parent_polys[i]==parent)
			return;
	if(poly->parent_polys==0x0) 
		poly->parent_polys= (int *) malloc(1*sizeof(int));
	else 
		poly->parent_polys= (int *)
			realloc((void *) poly->parent_polys, (poly->nparents+1)*sizeof(int));
	poly->parent_polys[poly->nparents]=parent;
	poly->nparents++;
} /* end add_parent */

