; wrapper for djs_iterstat
; D. Finkbeiner 14 Oct 1999

function djsig, x

  djs_iterstat, x, sigma=sigma

  return,sigma
end
