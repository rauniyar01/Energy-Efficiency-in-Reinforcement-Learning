#include "mex.h"
#include <math.h>
#include <stdlib.h>

#define POINT_1     prhs[0]
#define POINT_2     prhs[1]
#define ADDITION    plhs[0]

/* The computational routine */
void add_lns_c(double *p1, double *p2, double *z)
{
    if (abs(p1[0] - p2[0]) >= 36.043653389117155)	
    {                                                   // 2^52-1 = 4503599627370495.	log of that is 36.043653389117155867651465390794
		z[0] = max(p1[0], p2[0]);                        // this branch is necessary, to avoid shifted_a_ln = a_ln - b_ln having too big value	
    }
	else
    {
		z[0] = log(exp(p1[0] - p2[0]) + 1) + p2[0]; 
    }   
}

/* The gateway function */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[])
{
    double *p1, *p2, *o1;
    
    p1 = mxGetPr(POINT_1);
    p2 = mxGetPr(POINT_2);
    ADDITION = mxCreateDoubleMatrix(1, 1, mxREAL);
    o1 = mxGetPr(ADDITION);

    add_lns_c(p1, p2, o1);
}