/* This solves for the parameters alpha and beta of a (standard) Beta distribution, 
   given the (weigthed) average of ln(x_i) where x_i~Beta(alpha,beta).
   
   Derivation of the logL function yields a system of two equations (see mysolver):
   
   (1)   \frac {\sum (w_i * ln(    gamma_i)) / \sum (w_i)} = \psi(alpha) - \psi(alpha + beta)
   (2)   \frac {\sum (w_i * ln(1 - gamma_i)) / \sum (w_i)} = \psi(beta)  - \psi(alpha + beta)
   
   where \psi is the Digamma Function (derivative of ln(Gamma(x)))
   */

program define solve_beta_params_ml, rclass

	// syntax -- get the weighted averages of ln(gamma)
	syntax , weightedAvgOfLnGamma(real) weightedAvgOfLn1_Gamma(real) avgOfWeights(real) [verbose debug init_alpha(real 1) init_beta(real 1)]
	
	if ("`verbose'" != "") {
		if ("`debug'" != "") {
			local debug = ", 1"
		}
		noisily mata: encapsulate_optimize(`weightedAvgOfLnGamma', `weightedAvgOfLn1_Gamma', `avgOfWeights', (`init_alpha', `init_beta'), "params" `debug')
	}

	mata: encapsulate_optimize(`weightedAvgOfLnGamma', `weightedAvgOfLn1_Gamma', `avgOfWeights', (`init_alpha', `init_beta'), "none")
	
	// return the parameters as scalars
	return scalar beta = scalar(___beta)
	return scalar alpha = scalar(___alpha)
	
	scalar drop ___alpha ___beta
end

mata:

void mysolver(todo, p, constants_from_data, lnf, S, H)
{
	alpha   = p[1]
	beta    = p[2]
	lnf_vector = ((digamma(alpha) - digamma(alpha+beta))   \   
				(digamma(beta)  - digamma(alpha+beta)))       :- constants_from_data
	lnf = lnf_vector'*lnf_vector // Euclidean distance of lnf from (0,0): lnf_vector(1)^2 + lnf_vector(2)^2
}

void encapsulate_optimize(	real scalar weightedAvgOfLnGamma, real scalar weightedAvgOfLn1_Gamma, ///
							real scalar avgOfWeights, ///
							real rowvector initial_vals, ///
							string scalar tracelevel, | real scalar debug) {
	// put the arguments in column vector format
	constants_from_data = 	( weightedAvgOfLnGamma \  ///
							  weightedAvgOfLn1_Gamma )     :/ 	avgOfWeights
							 

	S = optimize_init()

	optimize_init_evaluator(S, &mysolver())

	optimize_init_evaluatortype(S, "d0")

	optimize_init_params(S, initial_vals)

	optimize_init_argument(S, 1, constants_from_data)

	optimize_init_which(S,  "min" )

	if (args() > 5 & debug == 1) {
		optimize_init_conv_maxiter(S, 4  )
	}
	
	optimize_init_tracelevel(S, tracelevel)

	optimize_init_conv_ptol(S, 1e-16)

	optimize_init_conv_vtol(S, 1e-16)

	p = optimize(S)

	// push the parameters back
	st_numscalar("___alpha", p[1])
	st_numscalar("___beta", p[2])
}

end
