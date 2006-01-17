;+
; NAME:
;   hogg_mcmc_step
; PURPOSE:
;   Make one step in a Markov Chain Monte Carlo.
; INPUTS:
;   seed       - random number seed for randomu()
;   pars       - initial parameters (can be an array or structure)
;   like       - initial likelihood
;   step_func  - function that takes a step in parameter space
;   like_func  - function that computes the likelihood
; KEYWORDS:
;   log        - like_func returns log_e(likelihood), not straight
;                likelihood
; OUTPUTS:
;   newpars    - new parameters
;   newlike    - new likelihood
; BUGS:
;   - I made up the algorithm based on things I sort-of remember.
; REVISION HISTORY:
;   2005-03-31  started - Hogg
;-
pro hogg_mcmc_step, seed,pars,like,step_func,like_func,newpars,newlike,log=log
if (NOT keyword_set(like)) then like= call_function(like_func,pars)
repeat begin
    newpars= call_function(step_func,seed,pars)
    newlike= call_function(like_func,newpars)
    if keyword_set(log) then $
      likeratio= newlike-logsum([newlike,like]) $
    else $
      likeratio= newlike/(newlike+like)
    randomnumber= randomu(seed)
    if keyword_set(log) then randomnumber= alog(randomnumber)
endrep until ((newlike GT like) OR $
              randomnumber LT likeratio)
return
end
