#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <values.h>
#include "format.h"
#include "polygon.h"
#include "scale.h"
#include "defaults.h"

/* getopt options */
static char *optstr = "dqm:s:e:v:p:i:o:";

/* local functions */
int unify(), unify_poly();
void usage(), parse_args();

/* external functions */
extern int rdmask(), wrmask();
extern int prune_poly(), touch_poly();
extern int room_poly();
extern int garea();
extern void advise_fmt();
extern void copy_poly(), poly_poly();
extern void free_poly();
extern void msg(char *, ...);
extern void scale();

polygon *polys[NPOLYSMAX];

/*------------------------------------------------------------------------------
  Main program.
*/
int main(argc, argv)
int argc;
char *argv [];
{
    int ifile, nadj, nfiles, npoly, npolys;

    /* default output format */
    fmt.out = keywords[POLYGON];
    /* default is to renumber output polygons with new id numbers */
    fmt.newid = 'n';

    /* parse arguments */
    parse_args(argc, argv);

    /* at least one input and output filename required as arguments */
    if (argc - optind < 2) {
	if (optind > 1 || argc - optind == 1) {
	    fprintf(stderr, "%s requires at least 2 arguments: infile and outfile\n", argv[0]);
	    usage();
	    exit(1);
	} else {
	    usage();
	    exit(0);
	}
    }

    msg("---------------- unify ----------------\n");

    /* tolerance angle for multiple intersections */
    if (mtol != 0.) {
	scale (&mtol, munit, 's');
	munit = 's';
	msg("multiple intersections closer than %g%c will be treated as coincident\n", mtol, munit);
	scale (&mtol, munit, 'r');
	munit = 'r';
    }

    /* advise data format */
    advise_fmt(&fmt);

    /* read polygons */
    npoly = 0;
    nfiles = argc - 1 - optind;
    for (ifile = optind; ifile < optind + nfiles; ifile++) {
	npolys = rdmask(argv[ifile], &fmt, &polys[npoly], NPOLYSMAX - npoly);
	if (npolys == -1) exit(1);
	npoly += npolys;
    }
    if (nfiles >= 2) {
        msg("total of %d polygons read\n", npoly);
    }
    if (npoly == 0) {
	msg("stop\n");
	exit(0);
    }

    /* unify polygons */
    nadj = unify(polys, &npoly);

    ifile = argc - 1;
    npoly = wrmask(argv[ifile], &fmt, polys, npoly);
    if (npoly == -1) exit(1);

    exit(0);
}

/*------------------------------------------------------------------------------
*/
void usage()
{
    printf("usage:\n");
    printf("unify [-d] [-q] [-s<n>] [-e<n>] [-vo|-vn] [-p<n>] [-i<f>[<n>][u]] [-o<f>[u]] infile1 [infile2] ... outfile\n");
#include "usage.h"
}

/*------------------------------------------------------------------------------
*/
#include "parse_args.c"

/*------------------------------------------------------------------------------
  Unify two polygons poly1 and poly2, if possible.

   Input: *poly1, poly2 = pointers to polygon structures.
  Output: if poly1 and poly2 were unified, then *poly1 contains unified polygon;
	  if poly1 and poly2 were not unified, then *poly1 is unchanged.
  Return value: -1 = error occurred;
	        0 = poly1 and poly2 were not unified;
	        1 = poly1 and poly2 were unified.
*/
int unify_poly(poly1, poly2)
polygon **poly1, *poly2;
{
/* number of extra caps to allocate to polygon, to allow for expansion */
#define DNP		4
    static polygon *poly = 0x0;

    int bnd, bndin, bndout, bnd1, bnd2, i, ier, i1, i2, np, verb;
    double area, areain, tol;
    polygon *polyin, *polyout;

    bnd = 0;
    /* look for single boundary dividing poly1 and poly2 */
    for (i1 = 0; i1 < (*poly1)->np; i1++) {
	if (bnd >= 2) break;
	for (i2 = 0; i2 < poly2->np; i2++) {
	    if ((*poly1)->cm[i1] == - poly2->cm[i2]
		&& (*poly1)->rp_(0, i1) == poly2->rp_(0, i2)
		&& (*poly1)->rp_(1, i1) == poly2->rp_(1, i2)
		&& (*poly1)->rp_(2, i1) == poly2->rp_(2, i2)) {
		bnd++;
		if (bnd >= 2) break;
		bnd1 = i1;
		bnd2 = i2;
	    }
	}
    }

    /* poly1 and poly2 are not separated by a single boundary */
    if (bnd != 1) return(0);

    /* make sure poly contains enough space for intersection */
    np = (*poly1)->np + poly2->np;
    ier = room_poly(&poly, np, DNP, 0);
    if (ier == -1) {
	fprintf(stderr, "unify_poly: failed to allocate memory for polygon of %d caps\n", np + DNP);
	return(-1);
    }

    /* check whether areas of poly1 and poly2 equal subareas of unified poly */
    for (i = 0; i < 2; i++) {
	if (i == 0) {
	    polyin = poly2;
	    polyout = *poly1;
	    bndin = bnd2;
	    bndout = poly2->np + bnd1;
	} else {
	    polyin = *poly1;
	    polyout = poly2;
	    bndin = bnd1;
	    bndout = (*poly1)->np + bnd2;
	}
	/* area of polyin */
	tol = mtol;
	verb = 1;
	ier = garea(polyin, &tol, &verb, &areain);
	if (ier) return(-1);
	/* intersection of polyin and polyout (in that order!) */
	poly_poly(polyin, polyout, poly);
	/* suppress coincident boundaries */
	touch_poly(poly);
	/* suppress excluding boundary of unified poly */
	poly->cm[bndout] = 2.;
	/* subarea of unified poly */
	verb = 0;
	ier = garea(poly, &tol, &verb, &area);
	if (ier == -1) return(-1);
	if (ier || area != areain) break;
    }

    /* do not unify poly1 and poly2 */
    if (ier || area != areain) return(0);

    /* suppress dividing boundary */
    poly->cm[bndin] = 2.;

    /* prune unified polygon */
    if (prune_poly(poly) == -1) return(-1);

    /* make sure poly1 contains enough space */
    np = poly->np;
    ier = room_poly(poly1, np, DNP, 0);
    if (ier == -1) {
	fprintf(stderr, "split_poly: failed to allocate memory for polygon of %d caps\n", np + DNP);
	return(-1);
    }

    /* copy unified polygon into poly1 */
    copy_poly(poly, *poly1);

    return(1);
}

/*------------------------------------------------------------------------------
  Unify polygons.

   Input: poly = array of pointers to polygons.
	  npoly = pointer to number of polygons.
  Output: polys = array of pointers to polygons;
  Return value: number of polygons unified,
		or -1 if error occurred.
*/
int unify(poly, npoly)
int *npoly;
#ifdef GCC
polygon *poly[*npoly];
#else
polygon *poly[];
#endif
{
#define WARNMAX		8
    int dnadj, i, j, unified, nadj, pass;

    nadj = 0;

    /* discard polygons that have zero weight */
    dnadj = 0;
    for (i = 0; i < *npoly; i++) {
	if (!poly[i]) continue;
	if (poly[i]->weight == 0.) {
	    if (WARNMAX > 0 && dnadj == 0)
		msg("unify: the following polygons have zero weight and are being discarded:\n");
	    if (dnadj < WARNMAX) {
		msg(" %d", (fmt.newid == 'o')? poly[i]->id : i);
	    } else if (dnadj == WARNMAX) {
		msg(" ... more\n");
	    }
            dnadj++;
	    free_poly(poly[i]);
	    poly[i] = 0x0;
        }
    }
    if (WARNMAX > 0 && dnadj > 0 && dnadj <= WARNMAX) msg("\n");
    if (dnadj > 0) msg("unify: %d polygons with zero weight were discarded\n", dnadj);
    nadj += dnadj;

    /* discard polygons that are null */
    dnadj = 0;
    for (i = 0; i < *npoly; i++) {
	if (!poly[i]) continue;
	/* prune polygon (should really already have been done by balkanize) */
	if (prune_poly(poly[i]) == -1) {
	    fprintf(stderr, "failed to prune polygon %d; continuing\n", (fmt.newid == 'o')? poly[i]->id : i);
	    continue;
	}
	if (poly[i]->np > 0 && poly[i]->cm[0] == 0.) {
	    if (dnadj == 0) msg("warning from unify: following polygons have zero area and are being discarded:\n");
            msg(" %d", (fmt.newid == 'o')? poly[i]->id : i);
            dnadj++;
	    free_poly(poly[i]);
	    poly[i] = 0x0;
        }
    }
    if (dnadj > 0) {
	msg("\n");
	msg("unify: %d polygons with zero area were discarded\n", dnadj);
    }
    nadj += dnadj;

    /* unify repeatedly, until no more unification occurs */
    pass = 0;
    do {
	/* try unifying each polygon in turn ... */
	pass++;
	dnadj = 0;
	for (i = 0; i < *npoly; i++) {
	    if (!poly[i]) continue;

	    /* ... with another polygon */
	    for (j = i+1; j < *npoly; j++) {
		if (!poly[j]) continue;
		/* only unify polygons with the same weight */
		if (poly[i]->weight != poly[j]->weight) continue;

		/* try unifying polygons */
		unified = unify_poly(&poly[i], poly[j]);
		if (unified == -1) {
		    if (WARNMAX/2 > 0 && dnadj > 0 && dnadj <= WARNMAX/2) msg("\n");
		    fprintf(stderr, "failed to unify polygons %d & %d; continuing\n",
			(fmt.newid == 'o')? poly[i]->id : i, (fmt.newid == 'o')? poly[j]->id : j);
		    continue;
		}
		/* polygons were unified */
		if (unified) {
		    if (WARNMAX/2 > 0 && dnadj == 0)
			msg("unify pass %d: the following polygons are being unified:\n", pass);
		    if (dnadj < WARNMAX/2) {
			msg(" (%d %d)", (fmt.newid == 'o')? poly[i]->id : i, (fmt.newid == 'o')? poly[j]->id : j);
		    } else if (dnadj == WARNMAX/2) {
			msg(" ... more\n");
		    }
		    free_poly(poly[j]);
		    poly[j] = 0x0;
		    dnadj++;
		}
	    }
	}
	if (WARNMAX/2 > 0 && dnadj > 0 && dnadj <= WARNMAX/2) msg("\n");
	msg("unify pass %d: %d polygons unified\n", pass, dnadj);
	nadj += dnadj;
    } while (dnadj);

    /* copy down polygons */
    j = 0;
    for (i = 0; i < *npoly; i++) {
	if (poly[i]) {
	    poly[j] = poly[i];
	    j++;
	}
    }
    *npoly = j;

    /* assign new polygon id numbers */
    if (fmt.newid == 'n') {
	for (i = 0; i < *npoly; i++) {
	    poly[i]->id = i;
	}
    }

    /* advise */
    msg("unify: %d polygons discarded or unified\n", nadj);

    return(nadj);
}
