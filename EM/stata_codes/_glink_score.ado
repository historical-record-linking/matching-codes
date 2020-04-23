/*
*Dear future Alvaro, these are the differences wrt the original ado files:
1. link_score2: I add priors like Santi (using empirical distribution;, the option to have a "match enriched sample" using the ado file "_gmatch_enriched_sample.ado"; and impose to have a decreasing LR in the prior distributions as Santi.
2. Also, in my_matching_em I include the option to have the "default priors" which means to have p_match_guess (the guess of probability of a match) to be the one that Santi uses, which introduces a relevant restriction in page 16 of his paper (that the matches should not be greater than the number of observations of the smallest dataset).
3. Other additional options are just to export or report things I would want to see.
4. I tested all ado with Helen's data and they worked fine (though the adjustment was irrelevant).
5. This is the same version that the one in .../EM_example_code_helen_20_11_2018, so don't make changes here!!
*/



program define _glink_score
	version 10, missing

	//	1.a. Define distance variables and the functional form. 
	//		 For example, whether birth year agrees or not is Bernoulli with probability p. 
	//		 Jaro-Winkler distance of last names can be distributed Beta(a,b)
	//  1.b. Define convergence parameters (optional)
												
	gettoken newvartype 0 : 0
	//0 contains what user typed. newvartype contains the first word mentioned.
	//usa los mismos tipos de variables que los usados por los usuarios... mira la linea 67 donde se usa `newvartype'
	gettoken newvarname 0 : 0
	gettoken eqs  0 : 0
								/* 	variables w/ 			   |types of        | upper bound	|distance between  |maximum number of   |name of matrix      | print
									observed       			   |distribution    | on the prob	|parameter matrices|iterations          |containing initial  | internal
									distances	   			   |of distances    | to be a 		|that defines      |                    |guesses of distance | stuff to 
															   |                | true match	|convergence       |                    |distribution params | screen   */
	syntax varlist(min=1)  /*[if] [in]*/, Distribs(string) MAXPmatch(real) Count(string) [STOPat(real 0.00001) MAXIter(integer 3000) INITial(string)  PMatchguess(real 0.15) /* 
												| print	     | print more | save each 
												| iterations | stuff      | iteration's
												| stuff to   |            | results in 
												| screen     |            | this file 
												|            |            | (requires verbose)
											*/  verbose        debug        post2(string)  /*Blockvar(varlist) */ wexp(string)] //wexp son los weights!

	//el segundo valor en "real 0.0005", etc. es el default value
	
  di "STEP 1 : INITIALIZE"
  
	tempvar weightvar weightedScore
	//weights...
	
	qui gen `newvartype' `weightvar' 		= .
	qui gen 			 `weightedScore' 	= .
	
	//  DEFINE DEFAULTS AND OTHER INNER PROGRAM SETTINGS HERE
	local allowed_distribs "binary beta betau01 categorical"
	local default_binary_p_M	= .2
	local default_binary_p_U	= .05
	local default_beta_a_M 		= 1
	local default_beta_b_M		= 4
	local default_beta_a_U 		= 1
	local default_beta_b_U	 	= 1
	local default_betau01_a_M 	= `default_beta_a_M'
	local default_betau01_b_M	= `default_beta_b_M'
	local default_betau01_a_U 	= `default_beta_a_U'
	local default_betau01_b_U	= `default_beta_b_U'
	local default_betau01_p0_M 	= .6
	local default_betau01_p1_M	= 0.001
	local default_betau01_p0_U 	= .05
	local default_betau01_p1_U	= .4
  
  *Prior for PMatchguess
  //Santi lo define como: maximo numero que podria ser matcheado (i.e. obs de A) / total de potential matches
	
	// 1.c. Input validation
	// Make sure number of distribs matches number of distancevars
	if (`: word count `varlist'' != `: word count `distribs'') {
		di as error "The number of distribs must match the number of distance variables as they represent their respective distribs"
		error 197
	}
	
	// Make sure distribs are in the allowed set of possible distribs
	local uniq_distribs : list uniq distribs
	if (!`: list uniq_distribs in allowed_distribs') {
		di as error "Some (or all of the) distribs are unfamiliar distribution types. Allowed distribution types are |`allowed_distribs'|"
		error 197
	}
	
	// 1.d. Create the matrix of distribution parameters (to be iterated over)
	
	// The matrix will have the parameters in the columns and the match/nonmatch classes in the rows.
	// That is, say distance variables (first names' Jaro Winkler distance, last names' Jaro Winkler distance, 0 if same birth state and 1 otherwise)
	// Then, say, "`varlist'" == "frst_dist last_dist state_diff" and "`distribs'" == "beta beta binary"
	// each beta has 2 parameters (alpha, beta) and a binary variable has just one parameter: p. 
	// Thus, the matrix will have 5 columns, and 2 rows one for matches and one for nonmatches:
	//
	// parameter:  |  first_name   |    last_name  | state
	//             |  alpha | beta |  alpha | beta |   p
	// class (rows)|   (1)  |  (2) |   (3)  |  (4) |  (5)
	// ----------------------------------------------------
	//     matches |  ...   |  ... |   ...  |  ... |  ...
	//  nonmatches |  ...   |  ... |   ...  |  ... |  ...
	// ----------------------------------------------------
	//
	local params_list ""

	matrix params = (. \ .) // initial matrix must not be empty. we will add columns according to the distribs and then delete the first column
	local distribs_count = 1
	local categ_count = 1
	foreach type in `distribs' {
		local varname : word `distribs_count' of `varlist'
		if ("`type'" == "binary") {
			matrix params = params , (`default_binary_p_M'  \ /*
								*/	  `default_binary_p_U')
			di "Remember, binary variables should be distance, not agreement. If a pair agrees on a value, then `varname' should be 0"
			local params_list "`params_list' `varname'_p"
		}
		else if ("`type'" == "beta") {
			matrix params = params , (`default_beta_a_M', `default_beta_b_M' \ /*
								*/	  `default_beta_a_U', `default_beta_b_U')
			local params_list "`params_list' `varname'_a `varname'_b"
		}
		else if ("`type'" == "betau01")  {
			matrix params = params , (`default_betau01_a_M', `default_betau01_b_M', `default_betau01_p0_M', `default_betau01_p1_M' \ /*
								*/	  `default_betau01_a_U', `default_betau01_b_U', `default_betau01_p0_U', `default_betau01_p1_U')
			local params_list "`params_list' `varname'_a `varname'_b `varname'_p0 `varname'_p1"
		}
		else if ("`type'"== "categorical") {
			// Determine how many levels are there for the variable that is categorical
			// (specifically, get the k-th word in the distancevars list where k is this type's order in the list of distribs)
			levelsof `varname', local(values)
			
			// Initialize proportion parameters: probabilities for each value will be set to 1/k 
			// for the unmatched distribution.
			// For the matched it will be the following expression: {1/k + [(k-1)/2 - (i-1)]/(k^2)}
			// which is both decreasing in i (which is increasing in the value) and sums up to 1.
			// At the same time create dummy variables for all values
			local k : word count `values' 
			local valuesnames ""

      //------------------------------------------------------------------------      
      //NEW PRIORS LIKE SANTI: total count and matrix for distribs
      qui sum `count'
      scalar total0 = `r(sum)'

      //------------------------------------------------------------------------
			
			matrix valuesDict`categ_count' = J(1, `k', .)
			//note categ_count is updated in each iteration over variables/distributions
			
      
			forvalues i = 1/`k' {
				tempvar cat_`categ_count'_`i'
				local value : word `i' of `values' //give the value in position i in values (that are for example 1 2 3 4)
				
				gen byte `cat_`categ_count'_`i'' = `varname' == `value' if ~mi(`varname') //if not missing..
				//in the dataset, create these dummies, if the variable "varname" is equal to the corresponding value 1,2,3,4,...
				
        //------------------------------------------------------------------------      
        // Priors like in Santi's R's code: fill matrix of parameters 
        qui sum `count' if `varname'==`value'
        matrix params = params , (1/`k' + ((`k'-1)/2 - (`i'-1))/(`k'^2)   \ /*
                  */	   `r(sum)'/total0)
        //di "original parameters"
				//mat li params           
        
        //------------------------------------------------------------------------
          					
				matrix valuesDict`categ_count'[1,`i'] = `i'
				local valuename = strtoname("`value'", 0)
				
				local valuesnames "`valuesnames' `valuename'"
				local params_list "`params_list' cat_`categ_count'_`i'"
			}
      
      //------------------------------------------------------------------------      
      //Optional: correct non-decreasing MLR in initial priors (borrowed from Santi's code)
			   
			/*
			if "`mlr_correction_no'" != "mlr_correction_no" {
	      local mat_col_size `= colsof(params)'
	      
	      local second_param = `mat_col_size' - `k' + 2
	      scalar sum_matched = params[1,`mat_col_size']
	      
	      forvalues i = `mat_col_size' (-1) `second_param' {
	        if params[1,`i'-1]/params[1,`i'] < params[2,`i'-1]/params[2,`i'] {
	          di "Priors: non-montone LR"
	          matrix params[1,`i'-1] = (params[1,`i']*params[2,`i'-1])/params[2,`i']
	        }

	        scalar sum_matched = sum_matched + params[1,`i'-1]
	      }
	      
	      local first_param = `mat_col_size' - `k' + 1
	      
	      forvalues i = `mat_col_size' (-1) `first_param' {
		       matrix params[1,`i'] = params[1,`i']/sum_matched
	      }
		 }
		 */
              
      //------------------------------------------------------------------------

      
			matrix colnames valuesDict`categ_count' = `valuesnames'
			
			
			// keep a note of how many values there are to the `categ_count'th categorical variable
			local catcount_`categ_count' = `k'
			di as result `k' as text " parameters for `varname'"
			
			
			// increment counter
			local `++categ_count' //next categ_count dependiendo de cuantas variables categoricas haya
		}
		local `++distribs_count' //next distribution/variable
    
    
	}
  
	matrix params = params[.,2...]  // remove first col with empty values.
  
  
  
	if ("`initial'" != "") {
		matrix params = `initial' //use the matrix of initial parameters given by the user
	} 
  matrix list params

	if ("`verbose'" != "") {
		di as text "Initial distribution parameters: "
		matrix list params
		
		// If an output of iterations file specified, post each iteration's parameters to the file
		if ("`post2'" != "") {
			postfile params_post iteration mean_logl match mean_weight `params_list' using `post2', replace
		}
	}
	
	// 1.e. Rename pmatchguess to pmatch
	local pmatch = min(`pmatchguess', `maxpmatch')
	
	
	
	
	
	
	
	
	
	
	
********************************************************************************	
	//  2. Loop over:
	display "STEP 2 : LOOP - EM STEP"
  
	//  2.0. before that... initialize placeholder variables
	local tempvars "logPDistanceIfM logPDistanceIfU cumu_logPDistanceIfM cumu_logPDistanceIfU score"
	tempvar `tempvars'
	foreach var in `tempvars' {
		gen double ``var'' = .
	}
	
	forvalues iter = 1/`maxiter' {
		
		************************************************************************
		///////
		// 2.a. E-step (compute probabilities of a match/nonmatch given likelihood of given distance metrics)
		// 				(see equation 52 in the lecture notes, but computationally using logs of probabilities to avoid
		//				 being mislead by rounding errors)
		/////
		
		if ("`verbose'" != "")  {
			di as text "Iter `iter': Step E -- predicting true-match probabilities given distributional parameters"
		}
		//  2.a.1. We need eitehr Pr[distances|params] or f(distances|params) once for M (matches) and once for U (nonmatches),
		//         for the Bayes rule. We assume that distances are independent (for simplicity of calculation and definition of distributions)
		//         Therefore Pr[distances|params] = Pr[distance_1|params]*Pr[distance_2|params]*...*Pr[distance_K|params]
		//			To avoid errors caused by rounding of small numbers, we calculate the sum of logs of marginal probabilities
		//			and we will use the exp(log(Pr[distances|params])) before putting the weight there. As long as probabilities/densities are not 0
		//          we should be OK.
		//         Practically, we create new variables and set them to be 0 (pDistGivenM, pDistGivenU) = (0,0) and then add the current variable's log(Pr)
		qui replace `cumu_logPDistanceIfM' = 0
		qui replace `cumu_logPDistanceIfU' = 0
		
		local paramCounter = 1
		local categ_count  = 1
		forvalues k = 1/`: word count `varlist'' {
			local distanceVar : word `k' of `varlist'
			local type        : word `k' of `distribs'
			
			replace `logPDistanceIfM' = . if mi(`distanceVar')
			replace `logPDistanceIfU' = . if mi(`distanceVar')
			
			if ("`type'" == "binary") {
				qui replace `logPDistanceIfM' = (`distanceVar' == 0) * ln(params[1, `paramCounter']) /*       Agreement (distance == 0) with prob p_M
									*/		+	(`distanceVar' == 1) * ln(1 - params[1, `paramCounter'])  //  Disagreement (distance == 1) with (1-p_M)
				qui replace `logPDistanceIfU' = (`distanceVar' == 0) * ln(params[2, `paramCounter']) /*       Agreement (distance == 0) with prob p_U
									*/		+	(`distanceVar' == 1) * ln(1 - params[2, `paramCounter'])  //  Disagreement (distance == 1) with (1-p_U)
				
				local paramCounter = `paramCounter' + 1
			}
			else if ("`type'" == "categorical") {
											//  get the ln(p)  with the p estimated for the i'th value. The i'th value is found using the 
											//                                            valuesDict dictionary that looks like this:
											//                                           value: 0 1 4 9 10
											//                                           index: 1 2 3 4 5
											//                                    so strtoname(strofreal(`distanceVar'), 0)) maps the value of the distance var
											//                                    to an index of the parameter vector and then the parameter is taken from this index
				replace `logPDistanceIfM' = ln(params[1, `paramCounter' - 1 + valuesDict`categ_count'[1,colnumb(valuesDict`categ_count', strtoname(strofreal(`distanceVar'), 0))]])
				replace `logPDistanceIfU' = ln(params[2, `paramCounter' - 1 + valuesDict`categ_count'[1,colnumb(valuesDict`categ_count', strtoname(strofreal(`distanceVar'), 0))]])
				
				local paramCounter = `paramCounter' + `catcount_`categ_count'' // increment the parameter count (column number)
				
				local `++categ_count' // increment count of categorical variables (+1)
			}
			else if ("`type'" == "beta") {
				//parametros
				local alpha_M = params[1, `paramCounter'    ]
				local beta_M  = params[1, `paramCounter' + 1]
				local alpha_U = params[2, `paramCounter'    ]
				local beta_U  = params[2, `paramCounter' + 1]
				
				//og beta function
				local betafunc_M = lngamma(`alpha_M') + lngamma(`beta_M') - lngamma(`alpha_M' + `beta_M')
				local betafunc_U = lngamma(`alpha_U') + lngamma(`beta_U') - lngamma(`alpha_U' + `beta_U')
				
				//log probabilidades
				qui replace `logPDistanceIfM' = (`alpha_M' - 1)*ln(`distanceVar') + (`beta_M' - 1)*ln(1-`distanceVar') - `betafunc_M'
				qui replace `logPDistanceIfU' = (`alpha_U' - 1)*ln(`distanceVar') + (`beta_U' - 1)*ln(1-`distanceVar') - `betafunc_U'
				
				local paramCounter = `paramCounter' + 2
			}
			else if ("`type'" == "betau01") {
				//esta dist es mas larga... porque tienes masa en 0 y 1
				local alpha_M 	= params[1, `paramCounter'    ]
				local beta_M 	= params[1, `paramCounter' + 1]
				local alpha_U 	= params[2, `paramCounter'    ]
				local beta_U  	= params[2, `paramCounter' + 1]
				local p0_M 		= params[1, `paramCounter' + 2]
				local p1_M  	= params[1, `paramCounter' + 3]
				local p0_U		= params[2, `paramCounter' + 2]
				local p1_U  	= params[2, `paramCounter' + 3]				
				
				local betafunc_M = lngamma(`alpha_M') + lngamma(`beta_M') - lngamma(`alpha_M' + `beta_M')
				local betafunc_U = lngamma(`alpha_U') + lngamma(`beta_U') - lngamma(`alpha_U' + `beta_U')

				qui replace `logPDistanceIfM' = ln(1 - `p0_M' - `p1_M') ///
											  + (`alpha_M' - 1)*ln(`distanceVar') + (`beta_M' - 1)*ln(1-`distanceVar') /// 
											  - `betafunc_M' ///
									if (`distanceVar' > 0 & `distanceVar' < 1)
									
				qui replace `logPDistanceIfU' = ln(1 - `p0_M' - `p1_M') ///
											  + (`alpha_U' - 1)*ln(`distanceVar') + (`beta_U' - 1)*ln(1-`distanceVar') ///
											  - `betafunc_U' ///
									if (`distanceVar' > 0 & `distanceVar' < 1)
									
				qui replace `logPDistanceIfM' = ln(`p0_M') ///
									if (`distanceVar' == 0) 
									
				qui replace `logPDistanceIfU' = ln(`p0_U') ///
									if (`distanceVar' == 0) 

				qui replace `logPDistanceIfM' = ln(`p1_M') ///
									if (`distanceVar' == 1) 
									
				qui replace `logPDistanceIfU' = ln(`p1_U') ///
									if (`distanceVar' == 1) 
									
				local paramCounter = `paramCounter' + 4
			}
			
			// Check that there are no missing values of the probability when there are distance measures
			count if (mi(`logPDistanceIfM') | mi(`logPDistanceIfU')) & ~mi(`distanceVar')
			if (r(N) > 0) {
				di as text "Warning: marginal probability for the (nonmissing) distance measure " ///
						as result "`distanceVar'" as text " is missing for " as result `r(N)' as text " observations"
			}
			
			// sum all logF(g_k) to get logF(g)
			//distribucion acumulada...
			replace `cumu_logPDistanceIfM' = `cumu_logPDistanceIfM' + `logPDistanceIfM'
			replace `cumu_logPDistanceIfU' = `cumu_logPDistanceIfU' + `logPDistanceIfU'
			
		}
		
		
		
		// 2.a.2. Apply BAYES RULE. Now that we have log(Pr[distances|params]), combined with the parameter of unconditional prob to be a match Pr[M] 
		//        we can apply it. 
		//        w = Pr[M] * Pr[distances|params_M] / (Pr[M]*Pr[distances|params_M] + Pr[U]*Pr[distances|params_U])))
		display "STEP 3 - APPLY BAYES RULE"
    
    replace `weightvar' = `pmatch' * exp(`cumu_logPDistanceIfM') / (`pmatch' * exp(`cumu_logPDistanceIfM') + (1-`pmatch') * exp(`cumu_logPDistanceIfU'))
		
		//weightvar is w(i) in the paper
		
		// 2.a.3. Rescale probabilities if mean weight is bigger than UPPER BOUND  
		su `weightvar' `wexp', meanonly
		//el objetivo de esto es calcular la media de weightvar
		
		local new_pmatch = r(mean)
		if (`new_pmatch' > `maxpmatch') {		// this is the constant c from Winkler (1989, p. 7)
			replace `weightvar' = `weightvar' * (`maxpmatch' / `new_pmatch') //ajusta hacia abajo
			//ACA PUEDES VER PARA QUE SIRVE EL MAXPMATCH
			su `weightvar' `wexp', meanonly
			local new_pmatch = r(mean) // osea, maxpmatch
		}
		
		// double check for errors (no weightvar should be bigger than 1 unless something went wrong)
/*		qui count if `weightvar' > 1 & ~mi(`weightvar')
		if (r(N) > 0) {
			if ("`verbose'" != "") {
				di as error "Iter `iter': E step resulted in " as result "`r(N)'" as error " probabilities above 1. Truncating to 1"
				su `weightvar' `wexp', de
			}
			qui replace `weightvar' = 1 if `weightvar' > 1 & ~mi(`weightvar')
		}*/

		
		// Before going to the M-step, report results from the E-step.
		if ("`verbose'" != "") {
			di as text "Linkage probabilies estimates created. This is their distribution"
			su `weightvar' `wexp', de

			// Calculate logL / N
			qui replace `score' = 	`weightvar'  * (ln(  `pmatch') + `cumu_logPDistanceIfM') + ///
								 (1-`weightvar') * (ln(1-`pmatch') + `cumu_logPDistanceIfU')
			
			su `score' `wexp', meanonly
			di as text "Iter `iter': logL / N = " as result `r(mean)'

			if ("`post2'" != "") {
				forvalues row = 1/2 {
					local values ""
					forvalues col=1/`: word count `: colnames params'' {
						local value = params[`row',`col']
						local values "`values' (`value')"
					}
					
					if (`row' == 1) {
						local reported_weight = `new_pmatch'
					}
					else {
						local reported_weight = 1 - `new_pmatch'
					}
					post params_post (`iter') (`r(mean)') (2 - `row') (`reported_weight') `values'
				}
			}

		}

		
		
		
		
		
		************************************************************************		
		///////
		//  2.b. M-step (update distribution of distance metrics (conditional on match/nonmatch) given the match/nonmatch probabilities))
		//////
    display "STEP 4 - M-STEP"

		if ("`verbose'" != "")  {
			di as text "Iter `iter': Step M -- estimating distributional parameters given match probabilities (weights)"
		}

		matrix new_params = params    // Initialize by copying the old params matrix. Values will now be updated

		//  2.b.1. Estimate pmatch -- the unconditional probability to be a match. This is the average weight
		// was already done in the reporting stage after E-step... look for 
		// su `weightvar' `wexp', meanonly
		// new_pmatch = r(mean)
		if ("`verbose'" != "") {
			di as text "Iter `iter': M step yields " as result "p[match] = `new_pmatch'"
		}
		
		//  2.b.2. Estimate each of the other variables' parameters using ML:
		local paramCounter = 1
		local categ_count  = 1
		forvalues k = 1/`: word count `varlist'' {
			local distanceVar : word `k' of `varlist'
			local type        : word `k' of `distribs'

			// 2.b.2.a. Depending on the distribution of the distance variable
			if ("`type'" == "binary") {
				// To calculate Pr[distance=0] it's like a regular ML of a binary variable with Pr[X=1] with two changes:
				// (1) Instead of Pr[X=1] we are calculating Pr[X=0] so the usual p=avg(X) becomes 1-p=avg(X) or p = 1-avg(X)
				// (2) We have weights on which sample/class (match or nonmatch) an observation belongs to, so the average is
				//     actually \frac{ \sum (x_i*w_i) , \sum (w_i) }    -- you can see that a special case where classification is certain 
				//	   yields the regular average that is conditional on the sample you estimate p for.
				
				// Calculating p_M   (depends on w)
				replace `weightedScore' = `distanceVar'*`weightvar' //primera vez que se usa esta variable desde que se definio =.
				//distancevar es 0 o 1, multiplicado por el weight y sacando su media te va a dar (usando weights), el weighted average dentro de esa categoria (1 o 0)
				su `weightedScore' `wexp', meanonly
				
				matrix new_params[1, `paramCounter'] = 1 - (`r(mean)' / `new_pmatch')    // this is the 1 - avg(X)
				
				// Calculating p_U   (depends on (1-w))
				qui replace `weightedScore' = `distanceVar'*(1-`weightvar')
				su `weightedScore' `wexp', meanonly

				matrix new_params[2, `paramCounter'] = 1 - (`r(mean)' / (1 - `new_pmatch'))    // this is the 1 - avg(X)
				
				local paramCounter = `paramCounter' + 1
			}
			*******************************
			if ("`type'" == "categorical") {
				forvalues i = 1/`catcount_`categ_count'' {
					// Calculating p_i^M   (depends on w)
					replace `weightedScore' = (`cat_`categ_count'_`i'')*`weightvar' //notar q la primera es la dummy que creamos en un inicio
					su `weightedScore' `wexp', meanonly
					
					local p_i_m = r(mean) / `new_pmatch' //es la misma ecuacion que en el codigo en R
					
					// Calculating p_i^U   (depends on 1-w)
					replace `weightedScore' = (`cat_`categ_count'_`i'')*(1-`weightvar')
					su `weightedScore' `wexp', meanonly
					
					local p_i_u = r(mean) / (1-`new_pmatch')

					/*  ******* IF I DECIDE TO CONSTRAIN STUFF I NEED TO THINK HARDER ABOUT 
					            HOW TO ESTIMATE THIS WITH THE INEQUALITY CONSTRAINT *****/
					// make sure this likelihood ratio is lower than the previous one
					// (unless it's the first estimated parameter)
					
					//la comparacion es asi. ejemplo: tiens 1,2,3,4 como distancias. Entonces comparas las distancia de 2 con la de 1, la de 3 con la de 2, etc.
					//chequeas la ecuacion de ratios del paper, o simple: que si la distancia aumenta, el ratio de probabilides M sobre U debe disminuir.
					local paramCounter_m_1 = `paramCounter' - 1 //counter de la distancia anterior (o categoria)
					if (`i' > 1) {
						local prev_lr = new_params[1, `paramCounter_m_1'] / new_params[2, `paramCounter_m_1']
						if (`prev_lr' < (`p_i_m' / `p_i_u')) {
							di as error "Warning: LR is increasing in distance (should be nonincreasing): `i'th parameter of `k'th variable"
						}
					}
					
					matrix new_params[1, `paramCounter'] = `p_i_m'
					matrix new_params[2, `paramCounter'] = `p_i_u'

					local `++paramCounter' // increment the parameter count (column number)
				}
				
				local `++categ_count' // increment count of categorical variables
			}
			*******************************
			else if ("`type'" == "beta") {
			//tendria que calcular el estimador de ML para saber si esto esta bien
				// ...(1) Getting alpha_M and beta_M   (depend on w)
				
				// 	...(1).A Calculating \sum (w_i * ln(gamma_i))
				qui replace `weightedScore' = ln(`distanceVar') * `weightvar'
				
				su 		`weightedScore' `wexp', meanonly
				local 	weightedAvgOfLnGamma = `r(mean)'
				
				// 	...(1).B Calculating \sum (w_i * ln(1 - gamma_i))
				qui replace `weightedScore' = ln(1 - `distanceVar') * `weightvar'
				
				su 		`weightedScore' `wexp', meanonly
				local 	weightedAvgOfLn1_Gamma = `r(mean)'

				// 	...(1).C Find the solution to the two equation system coming out from the dlogL/dtheta = 0 condition
				//  ...(1).C.a get initial values for alpha and beta from previous guess
				local initial_alpha = new_params[1, `paramCounter'    ]
				local initial_beta  = new_params[1, `paramCounter' + 1]
				
				if ("`debug'" != "") {
					di as text "Trying to solve for the Beta distribution parameters with the following moments:"
					di "solve_beta_params_ml, 	weightedAvgOfLnGamma(`weightedAvgOfLnGamma') "
					di "                        weightedAvgOfLn1_Gamma(`weightedAvgOfLn1_Gamma')"
					di "                        avgOfWeights(`new_pmatch')"
					di "                        init_alpha(`initial_alpha')"
					di "                        init_beta( `initial_beta')"
				}

				solve_beta_params_ml, 	weightedAvgOfLnGamma(`weightedAvgOfLnGamma') ///
										weightedAvgOfLn1_Gamma(`weightedAvgOfLn1_Gamma') ///
										avgOfWeights(`new_pmatch') ///
										init_alpha(`initial_alpha')  ///
										init_beta( `initial_beta') 
				//aqui es donde llama a la otra funcion de Roy para resolver estos parametros
				
				// 	...(1).D Saving
				matrix new_params[1, `paramCounter'    ] = `r(alpha)'
				matrix new_params[1, `paramCounter' + 1] = `r(beta)'
				
				*****para los unmatched..
				// ...(2) Getting alpha_U and beta_U   (depend on (1-w))
				// temporarily replacing weight with 1-weight
				
				// 	...(2).A Calculating \sum ((1-w_i) * ln(gamma_i))
				qui replace `weightedScore' = ln(`distanceVar') * (1 - `weightvar')
				
				su 		`weightedScore' `wexp', meanonly
				local 	weightedAvgOfLnGamma = `r(mean)'
				
				// 	...(2).B Calculating \sum ((1-w_i) * ln(1 - gamma_i))
				qui replace `weightedScore' = ln(1 - `distanceVar') * (1 - `weightvar')
				
				su 		`weightedScore' `wexp', meanonly
				local 	weightedAvgOfLn1_Gamma = `r(mean)'

				// Average weight is now avg(1-w) = 1 - avg(w)
				local avg_1_weight = 1 - `new_pmatch'
				
				// 	...(2).C Find the solution to the two equation system coming out from the dlogL/dtheta = 0 condition
				//  ...(1).C.a get initial values for alpha and beta from previous guess
				local initial_alpha = new_params[2, `paramCounter'    ]
				local initial_beta  = new_params[2, `paramCounter' + 1]

				if ("`debug'" != "") {
					di as text "Trying to solve for the Beta distribution parameters with the following moments:"
					di "solve_beta_params_ml, 	weightedAvgOfLnGamma(`weightedAvgOfLnGamma') "
					di "                        weightedAvgOfLn1_Gamma(`weightedAvgOfLn1_Gamma')"
					di "                        avgOfWeights(`avg_1_weight')"
					di "                        init_alpha(`initial_alpha')"
					di "                        init_beta( `initial_beta')"
				}

				solve_beta_params_ml, 	weightedAvgOfLnGamma(`weightedAvgOfLnGamma') ///
										weightedAvgOfLn1_Gamma(`weightedAvgOfLn1_Gamma') ///
										avgOfWeights(`avg_1_weight') ///
										init_alpha(`initial_alpha')  ///
										init_beta( `initial_beta') 
				
				// 	...(2).D Saving
				matrix new_params[2, `paramCounter'    ] = `r(alpha)'
				matrix new_params[2, `paramCounter' + 1] = `r(beta)'

				local paramCounter = `paramCounter' + 2
			}
			*******************************
			else if "`type'" == "betau01" {
				// ...(1) Getting p0_M and p1_M (depend on w)
				// ...(1).a. Calculating p0_M
				qui replace `weightedScore' = (`distanceVar' == 0)*`weightvar'
				su `weightedScore' `wexp', meanonly
				
				matrix new_params[1, `paramCounter' + 2] = (`r(mean)' / `new_pmatch')

				// ...(1).b. Calculating p1_M
				qui replace `weightedScore' = (`distanceVar' == 1)*`weightvar'
				su `weightedScore' `wexp', meanonly
				
				matrix new_params[1, `paramCounter' + 3] = (`r(mean)' / `new_pmatch')

				// ...(2) Getting p0_U and p1_U (depend on (1-w))
				// ...(2).a. Calculating p0_U
				qui replace `weightedScore' = (`distanceVar' == 0)*(1 - `weightvar')
				su `weightedScore' `wexp', meanonly
				
				matrix new_params[2, `paramCounter' + 2] = (`r(mean)' / (1-`new_pmatch'))

				// ...(2).b. Calculating p1_U
				replace `weightedScore' = (`distanceVar' == 1)*(1 - `weightvar')
				su `weightedScore' `wexp', meanonly
				
				matrix new_params[2, `paramCounter' + 3] = (`r(mean)' / (1-`new_pmatch'))

				*******************************
				// ...(3) Getting alpha_M and beta_M   (depend on w)
				
				// 	...(3).A Calculating \sum (w_i * ln(gamma_i))
				qui replace `weightedScore' = ln(`distanceVar') * `weightvar' if `distanceVar' > 0 & `distanceVar' < 1
				
				su 		`weightedScore' if `distanceVar' > 0 & `distanceVar' < 1 `wexp', meanonly
				local 	weightedAvgOfLnGamma = `r(mean)'

				// 	...(3).B Calculating \sum (w_i * ln(1 - gamma_i))
				replace `weightedScore' = ln(1 - `distanceVar') * `weightvar' if `distanceVar' > 0 & `distanceVar' < 1
				
				su 		`weightedScore' if `distanceVar' > 0 & `distanceVar' < 1 `wexp', meanonly
				local 	weightedAvgOfLn1_Gamma = `r(mean)'

				// 	...(3).C Calculating \sum (w_i)   -- usually it's new_pmatch, but this is only for observations where distance \in (0,1)
				su `weightvar' if `distanceVar' > 0 & `distanceVar' < 1 `wexp', meanonly
				local avgWeightInternal = `r(mean)'
				
				// 	...(3).D Find the solution to the two equation system coming out from the dlogL/dtheta = 0 condition
				//  ...(3).D.a get initial values for alpha and beta from previous guess
				local initial_alpha = new_params[1, `paramCounter'    ]
				local initial_beta  = new_params[1, `paramCounter' + 1]
				
				if ("`debug'" != "") {
					di as text "Trying to solve for the Beta distribution parameters with the following moments:"
					di "solve_beta_params_ml, 	weightedAvgOfLnGamma(`weightedAvgOfLnGamma') "
					di "                        weightedAvgOfLn1_Gamma(`weightedAvgOfLn1_Gamma')"
					di "                        avgOfWeights(`avgWeightInternal')"
					di "                        init_alpha(`initial_alpha')"
					di "                        init_beta( `initial_beta')"
				}

				solve_beta_params_ml, 	weightedAvgOfLnGamma(`weightedAvgOfLnGamma') ///
										weightedAvgOfLn1_Gamma(`weightedAvgOfLn1_Gamma') ///
										avgOfWeights(`avgWeightInternal') ///
										init_alpha(`initial_alpha')  ///
										init_beta( `initial_beta') 
				
				// 	...(3).E Saving
				matrix new_params[1, `paramCounter'    ] = `r(alpha)'
				matrix new_params[1, `paramCounter' + 1] = `r(beta)'
				
				*******************************
				// ...(4) Getting alpha_U and beta_U   (depend on (1-w))
				
				// 	...(4).A Calculating \sum ((1-w_i) * ln(gamma_i))
				replace `weightedScore' = ln(`distanceVar') * (1 - `weightvar') if `distanceVar' > 0 & `distanceVar' < 1
				
				su 		`weightedScore' if `distanceVar' > 0 & `distanceVar' < 1 `wexp', meanonly
				local 	weightedAvgOfLnGamma = `r(mean)'
				
				// 	...(4).B Calculating \sum ((1-w_i) * ln(1 - gamma_i))
				replace `weightedScore' = ln(1 - `distanceVar') * (1 - `weightvar') if `distanceVar' > 0 & `distanceVar' < 1
				
				su 		`weightedScore' if `distanceVar' > 0 & `distanceVar' < 1 `wexp', meanonly
				local 	weightedAvgOfLn1_Gamma = `r(mean)'

				// 	...(4).C Calculating \sum (w_i)   -- usually it's new_pmatch, but this is only for observations where distance \in (0,1)
				local avgWeightInternal = 1 - `avgWeightInternal'
				
				// 	...(4).D Find the solution to the two equation system coming out from the dlogL/dtheta = 0 condition
				//  ...(4).D.a get initial values for alpha and beta from previous guess
				local initial_alpha = new_params[2, `paramCounter'    ]
				local initial_beta  = new_params[2, `paramCounter' + 1]
				
				if ("`debug'" != "") {
					di as text "Trying to solve for the Beta distribution parameters with the following moments:"
					di "solve_beta_params_ml, 	weightedAvgOfLnGamma(`weightedAvgOfLnGamma') "
					di "                        weightedAvgOfLn1_Gamma(`weightedAvgOfLn1_Gamma')"
					di "                        avgOfWeights(`avgWeightInternal')"
					di "                        init_alpha(`initial_alpha')"
					di "                        init_beta( `initial_beta')"
				}

				solve_beta_params_ml, 	weightedAvgOfLnGamma(`weightedAvgOfLnGamma') ///
										weightedAvgOfLn1_Gamma(`weightedAvgOfLn1_Gamma') ///
										avgOfWeights(`avgWeightInternal') ///
										init_alpha(`initial_alpha')  ///
										init_beta( `initial_beta') 
				
				// 	...(4).E Saving
				matrix new_params[2, `paramCounter'    ] = `r(alpha)'
				matrix new_params[2, `paramCounter' + 1] = `r(beta)'

				local paramCounter = `paramCounter' + 4

			}
			
		}
		
		if ("`verbose'" != "") {
			di "This iteration's parameters:"
			matrix list new_params
			
			di "Row 1 divided by row 2 (element-by-element):"
			local k =  colsof(new_params)
			matrix __c = J(1,`k',.)
			forvalues i = 1/`k' {
				matrix __c[1,`i'] =  new_params[1,`i'] / new_params[2,`i']
			}
			matrix list __c
		}


		
		
		
		
		
		
		
		
		************************************************************************
		//  2.c. Stop if parameters updated less than what the stopping rule prescribes
		//  2.c.1. Make a vector from the new_params and params matrices (as well as new_pmatch and pmatch) and subtract one from the other
		matrix theta = (new_params[1,....] , new_params[2,....], `new_pmatch') - (params[1,....] , params[2,....], `pmatch')
    mata: st_matrix("abs_theta",abs(st_matrix("theta")))
    mata: st_matrix("distance",max(st_matrix("abs_theta")))
		scalar distance_scl = distance[1,1]
		
		if ("`verbose'" != "") {
			di as text "Distance from last step: " as result scalar(distance_scl)
		}
		
		//  2.c.2. Calculate Eucledian distance between vectors
		if (scalar(distance_scl) < `stopat') {
			if ("`verbose'" != "") {
				di as text "CONVERGED!"
			}
      di as text "1. CONVERGED!"
      di as text "2. TOTAL NUMBER OF ITERATIONS : `iter' "
      matrix params_last = (new_params[1,....] , new_params[2,....], `new_pmatch')
      di "3. Last iteration parameters are: "
      mat list params_last

			continue, break
		}
    
    if `iter'==`maxiter' {
      di as text "1. NOT CONVERGED! JUST HIT THE MAX NUMBER OF ITERATIONS"
      di as text "2. TOTAL NUMBER OF ITERATIONS :  `iter'"  
      matrix params_last = (new_params[1,....] , new_params[2,....], `new_pmatch')
      di "3. Last iteration parameters are: "
      mat list params_last
      
    }
		// 2.d.3. Update parameters
		matrix params = new_params
		local  pmatch = `new_pmatch'
	}
	
	if ("`verbose'" != "" & "`post2'" != "") {
		postclose params_post
	}

	
	// copy the temp variable to the new variable name specified by the user
	gen `newvartype' `newvarname' = `weightvar'
	ereturn post params_last
	//di "p matchgues was: `pmatchguess'"

end
