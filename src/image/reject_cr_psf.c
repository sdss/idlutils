#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "ph.h"

/*
 * reject_cr_psf.c
 *
 * Based on an estimate of the PSF, reject pixels in an image 
 * which appear to have violated the PSF bounds, and are thus likely
 * to be PSFs. Does not alter original image, just returns the indices
 * of the rejected pixels. 
 *
 * Uses RHL's prescription for this a la the PHOTO paper. 
 *
 * Does not check edge pixels at ALL. 
 *
 * Mike Blanton
 * 10/2003 */

#define PI 3.14159265358979
#define FREEVEC(a) {if((a)!=NULL) free((char *) (a)); (a)=NULL;}

int reject_cr_psf(float *image, 
                  float *image_ivar, 
                  int xnpix, 
                  int ynpix,
                  float nsig, /* number of sigma above background required */
                  float psfvals[2], /* psf value at radii of 1 pix and 
                                       sqrt(2) pix */
                  float cfudge, /* number of sigma inconsistent with
                                   PSF required */
                  float c2fudge, /* fudge factor applied to PSF */
                  short *rejected)
{
  float sigmaback[4],back[4],im,ival,lval,invsigma;
  int i,j,nreject,lastreject;
  
  nreject=0;
  lastreject=-1;
  for(j=1;j<ynpix-1;j++) {
    for(i=1;i<xnpix-1;i++) {
      rejected[j*xnpix+i]=0;
      if(image_ivar[j*xnpix+i]>0.) {
        invsigma=sqrt(image_ivar[j*xnpix+i]);
        im=image[j*xnpix+i];
        
        /* check if it exceeds background for ALL four pairs */
        ival=invsigma*im;
        back[0]=0.5*(image[j*xnpix+(i-1)]+image[j*xnpix+(i+1)]);
        if(ival<back[0]*invsigma+nsig) continue;
        back[1]=0.5*(image[(j-1)*xnpix+i]+image[(j+1)*xnpix+i]);
        if(ival<back[1]*invsigma+nsig) continue;
        back[2]=0.5*(image[(j-1)*xnpix+(i-1)]+image[(j+1)*xnpix+(i+1)]);
        if(ival<back[2]*invsigma+nsig) continue;
        back[3]=0.5*(image[(j+1)*xnpix+(i-1)]+image[(j-1)*xnpix+(i+1)]);
        if(ival<back[3]*invsigma+nsig) continue;

        /* if it does, now check if ANY pair violates PSF conditions */
        sigmaback[0]=
          0.5*sqrt(1./image_ivar[j*xnpix+(i-1)]+ 
                   1./image_ivar[j*xnpix+(i+1)]);
        lval=(ival-cfudge)*c2fudge*psfvals[0];
        if(lval>invsigma*(back[0]+cfudge*sigmaback[0])) {
          rejected[j*xnpix+i]=lastreject;
          lastreject=j*xnpix+i;
          image[j*xnpix+i]=back[0];
          nreject++;
          continue;
        }
        sigmaback[1]=
          0.5*sqrt(1./image_ivar[(j-1)*xnpix+i]+ 
                   1./image_ivar[(j+1)*xnpix+i]);
        if(lval>invsigma*(back[1]+cfudge*sigmaback[1])) {
          rejected[j*xnpix+i]=lastreject;
          lastreject=j*xnpix+i;
          image[j*xnpix+i]=back[1];
          nreject++;
          continue;
        }
        sigmaback[2]=
          0.5*sqrt(1./image_ivar[(j-1)*xnpix+(i-1)]+ 
                   1./image_ivar[(j+1)*xnpix+(i+1)]);
        lval=(ival-cfudge)*c2fudge*psfvals[1];
        if(lval>invsigma*(back[2]+cfudge*sigmaback[2])) {
          rejected[j*xnpix+i]=lastreject;
          lastreject=j*xnpix+i;
          image[j*xnpix+i]=back[2];
          nreject++;
          continue;
        }
        sigmaback[3]=
          0.5*sqrt(1./image_ivar[(j+1)*xnpix+(i-1)]+ 
                   1./image_ivar[(j-1)*xnpix+(i+1)]);
        if(lval>invsigma*(back[3]+cfudge*sigmaback[3])) {
          rejected[j*xnpix+i]=lastreject;
          lastreject=j*xnpix+i;
          image[j*xnpix+i]=back[3];
          nreject++;
          continue;
        }
        
      } /* end if */
    } /* end for j */
  } /* end for i */
  
  return(0);
  
} /* end photfrac */
