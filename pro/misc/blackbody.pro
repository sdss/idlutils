function blackbody, lambda, T

	; Lambda is in angstroms

	c = 2.99792e18 ; Ang/s	
	hc = 1.988e-6  ; erg * A

	wave = double(lambda)
	answer = 2.0e16*hc*c/(wave^5) * 1.0/(exp(1.43868e8/(wave*T)) - 1.0)

	;
	;	Answer is in ergs/s cm^-2 Ang^-1 ster^-1
	;
	

	return, answer
end 


