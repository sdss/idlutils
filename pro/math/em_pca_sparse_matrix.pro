;+
; NAME:
;    em_pca_sparse_matrix
; PURPOSE: (one line)
;    Perform E-M PCA to get first k principal components of large sparse matrix
; DESCRIPTION:
;    Uses Sam Roweis's algorithm (described in em_pca.pro in detail)
;    but takes an initial sparse matrix rather than a data set as
;    input. (in the lle_sm format)
; CATEGORY:
;    Mathematical
; CALLING SEQUENCE:
;    em_pca_sparse_matrix, matrix, k, eigenvec, hidden [, tol=, $
;       maxiter=, niter=, /verbose]
; INPUTS:
;    matrix - sparse matrix to be PCAd
;    k - number of eigenvectors desired (<p)
; OPTIONAL INPUT PARAMETERS:
;    tol - tolerance of convergence (default 0.)
;    maxiter - maximum number of iterations (default 20)
; KEYWORD PARAMETERS:
;    /verbose - verbose output
;    /nofix - don't do the final real PCA
; OUTPUTS:
;    eigenvec - [p,k] matrix of k leading eigenvectors
; OPTIONAL OUTPUTS:
;    niter - number of iterations used
; COMMON BLOCKS:
; SIDE EFFECTS:
; BUGS:
;    not completed yet
; RESTRICTIONS:
;    Does not implement Sam's Sensible-PCA procedure
; PROCEDURE:
; MODIFICATION HISTORY:
;    2003-01-26 - Written by Michael Blanton (NYU)
;-
pro em_pca_sparse_matrix, matrix, p, k, eigenvec, tol=tol, maxiter=maxiter, $
                          niter=niter, verbose=verbose, nofix=nofix, $
                          noortho=noortho

; set defaults
if(n_elements(tol) eq 0) then tol=0.
if(n_elements(maxiter) eq 0) then maxiter=20

; check args
if (n_params() lt 1) then begin
    print, 'Syntax - em_pca_sparse_matrix, matrix, p, k, eigenvec [, tol=, $ '
    print, '          maxiter=, niter=, /verbose]'
    return
endif

; check dimensions
if(k gt p) then begin
    splog, 'k must be less than or equal to p!'
    splog, 'k= '+string(k)
    splog, 'p= '+string(p)
    return
endif

; initial conditions
eigenvec=dblarr(p,k)
eigenvec[0:k-1,0:k-1]=identity(k)

niter=0L
diff=tol*2.+1.
while(niter lt maxiter and diff gt tol) do begin
    if(keyword_set(verbose)) then splog,'niter= '+string(niter)
    hidden=(invert(transpose(eigenvec)#eigenvec)#transpose(eigenvec))
    oldeigenvec=eigenvec
    mathidden=lle_sm_full(lle_sm_mult(matrix,lle_sm(transpose(hidden))))
    eigenvec=mathidden#invert(hidden#mathidden)
    if(tol gt 0.) then begin
        diff=0.
        for i=0, k-1 do begin
            diff=diff+abs(total(oldeigenvec[*,i]*eigenvec[*,i],/double))
        endfor
        if(keyword_set(verbose)) then splog,'diff= '+string(diff)
    endif
    niter=niter+1L
endwhile

if(NOT keyword_set(noortho)) then begin
;   Orthonormalize
    for b = 0l, k-1l do begin
;       orthogonalize
        for bp = 0l, b-1l do begin
            dot=total(eigenvec[*,b]*eigenvec[*,bp],/double)
            eigenvec[*,b]=eigenvec[*,b]-dot*eigenvec[*,bp]
        endfor 
        
;       normalize
        dot=total(eigenvec[*,b]^2,/double)
        dot=1./sqrt(dot)
        eigenvec[*,b]=eigenvec[*,b]*dot
    endfor 

    if(NOT keyword_set(nofix)) then begin
;       project variables onto new coordinates
        hidden=transpose(eigenvec)# $
          lle_sm_full(lle_sm_mult(matrix,lle_sm(eigenvec)))
        eval_hidden= eigenql(hidden,eigenvectors=evec_hidden)
        eigenvec=eigenvec[*,*]#transpose(evec_hidden)
    endif
endif

return

end
