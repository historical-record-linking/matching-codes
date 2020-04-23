

program define matching_em, rclass 
	version 14
	syntax , ///
		 ///
		 ///
		pairs_dta(string) ///
		matches_dta(string) ///
		probabilities_dta(string) probabilities_path(string) ///
		ID_vars(string) 								///
 		distances(string) 	  distributions(string) 		///
		[AFile(string)      ADirs(string)         APAtterns(string) 			///
		 BFile(string)      BDirs(string)         BPAtterns(string) 			///
		 ALoad_vars(string) ARestrictions(string) APReprocessing(string)  		///
		 BLoad_vars(string) BRestrictions(string) BPReprocessing(string) 		///
		 Load_vars(string)  Restrictions(string)  Preprocessing(string) 		///
		 Keep_vars(string)  ACleaned(string)      BCleaned(string)   			///
		 do_name(string)    CLEAN_pairs(string) 								///
		 CLUsters(integer 1) PROCessors(integer 0) parallel_passthru(string)	///
		 save_blocks example_block block_dir(string) block_prefix(string)		///
		 min_score(real 0.6) max_second(real 0.3)  maxpmatch(real 0.99)			///
		 link_score_passthru(string) thicken noPRERULE_save ///
		 pairs_not_loaded only_decision_rule stop_at(real 0.0005) MAXIter(integer 500) ///
		 save_counts match_enriched_sample save_coefficients default_priors ///
		 user_pmatchguess(real 0.15)]

*****1. Set up************


local cwd = `"`c(pwd)'"'	

foreach src in "a" "b" {
	local `src'_ids
	foreach var of local id_vars {
		local `src'_ids = `"``src'_ids' `=upper("`src'")'`var'"' //Make id_variable list with source prefix (A or B)
	}
}

/*
*****. Pairing ************
if `"``create_pairs''"'=="create_pairs" {
	
	pairing, id_vars(`id_vars') blocking_vars(`blocking_vars') output(`"`output'"') ///
		distances(`distances') afile(`"`afile'"') adirs(`"`adirs'"') 				///
		apatterns(`"`apatterns'"') bfile(`"`bfile'"') bdirs(`"`bdirs'"') 			///
		bpatterns(`"`bpatterns'"') aload_vars(`aload_vars') 						///
		arestrictions(`"`arestrictions'"') apreprocessing(`"`apreprocessing'"')		///
		bload_vars(`bload_vars') brestrictions(`"`brestrictions'"') 				///
		bpreprocessing(`"`bpreprocessing'"') load_vars(`load_vars') 				///
		restrictions(`"`restrictions'"') preprocessing(`"`preprocessing'"') 		///
		keep_vars(`keep_vars') acleaned(`"`acleaned'"') bcleaned(`"`bcleaned'"')	///
		do_name(`"`do_name'"') clean_pairs(`"`clean_pairs'"') clusters(`clusters')	///
		processors(`processors') parallel_passthru(`parallel_passthru') `save_blocks' `example_block'	///
		block_dir(`"`block_dir'"') block_prefix(`"`block_prefix'"') 				
}
*/

*****2. Set priors for pmatchguess and choose how to open files************

if `"`only_decision_rule'"'=="" {
	if `"`pairs_not_loaded'"'!="" {
		di "Pairs dataset is not loaded, then, open it. (this can take a long time if datafile is large)"
		if `"`default_priors'"'=="default_priors" {
			use `distances' `a_ids' `b_ids' using "`pairs_dta'", clear

			*Prior for match probability, like Santi
			tempvar id_a id_b
			egen `id_a' = group(`a_ids')
			egen `id_b' = group(`b_ids')
			sum `id_a'
			local id_a_max =  `r(max)'
			sum `id_b'
			local id_b_max =  `r(max)'
			drop `id_a' `id_b'
			local p_match_guess = min(`id_a_max', `id_b_max')/_N //like Santi: number of A units over number of potential matches
			
			di "Prior for matching probability is: `p_match_guess'"
			
			if `p_match_guess'<0.005 {
				"Warning: your guess for the match probability is very low (less than 0.5%)."
			}
		}
		else {
			use `distances' `a_ids' `b_ids' using "`pairs_dta'", clear
			
			*Default prior for match probability (set by user)
			if `"`user_pmatchguess'"'=="" {
				di "Error: if you don't use default initial guesses, you must specify your own guess for the matching probability using user_pmatchguess()"
				error 197
			}
			local p_match_guess = `user_pmatchguess'
			di "Prior for matching probability is (user's choice): `user_pmatchguess'"
		}
	}
	
	else {
		display "You stated that pairs datafile is loaded. Then, directly calculate priors."
		if `"`default_priors'"'=="default_priors" {
			di "For this to work, you need to have the id vars loaded."

			*Prior for match probability
			tempvar id_a id_b
			egen `id_a' = group(`a_ids')
			egen `id_b' = group(`b_ids')
			sum `id_a'
			local id_a_max =  `r(max)'
			sum `id_b'
			local id_b_max =  `r(max)'
			drop `id_a' `id_b'
			local p_match_guess = min(`id_a_max', `id_b_max')/_N //like Santi: number of A units over number of potential matches
			
			di "Prior for matching probability based on your data is: `p_match_guess'"
		}
		else {		
			*Default prior for match probability (set by user)	
			if `"`user_pmatchguess'"'=="" {
				di "Error: if you don't use default initial guesses, you must specify your own guess for the matching probability using user_pmatchguess()"
				error 197
			}
			local p_match_guess = `user_pmatchguess'
			di "Prior for matching probability is (user's choice): `user_pmatchguess'"
		}
	}
	

	********3. Convert Distances to Match Probabilities using EM Algorithm*************
	tempvar weights
	gen `weights' = 1
	collapse (sum) `weights', by(`distances')

	*Save counts
	if "`save_counts'"=="save_counts"{
		di "Option: saving counts..."
		di regexm("`probabilities_dta'", "([A-Za-z0-9_]+).dta")
		local probabilities = regexs(1)
		save "`probabilities_path'/counts_`probabilities'.dta", replace
	}

	
	*Link Score
	//display "TIME TO USE LINK_SCORE"
	
	qui egen match_probability = link_score(`distances'), distribs(`distributions')		///
		maxp(`maxpmatch') `link_score_passthru' wexp("[aw=`weights']") stopat(`stop_at') ///
		maxiter(`maxiter') pmatchguess(`p_match_guess') count(`weights')
	drop `weights'
	
	* Rounding to 8 decimals
	replace match_probability = round(match_probability, 0.00000001)
	
	if "`save_coefficients'"=="save_coefficients"{
		display "Option: exporting coefficients..."
		preserve
		clear
		mat b = e(b)
		svmat b, names(coef_)
		di regexm("`probabilities_dta'", "([A-Za-z0-9_]+).dta")
		local probabilities = regexs(1) //name without ".dta"
		export delimited using "`probabilities_path'/coef_`probabilities'.csv", replace
		restore
	}
	

	********4. Merge Match Probabilities back onto Candidate Pairs*********************
	//display "TIME TO MERGE BACK TO THE ORIGINAL DATASET"
	
	merge 1:m `distances' using "`pairs_dta'", nogen assert(3)
	
		
	if `"`prerule_save'"'!="noprerule_save" {
		di "Option: save candidates with their probabilities"
		save "`probabilities_path'/`probabilities_dta'", replace
	}
		
		
}
else {
	display "Option: only apply decision rules."
	use "`probabilities_path'/`probabilities_dta'", clear
}

********5. Apply DECISION RULES of which Candidates to Keep as Matches*************
//display "TIME TO APPLY DECISION RULES..."

assert !missing(match_probability)

tempvar to_drop
gen `to_drop' = 0
di _N
foreach src in "a" "b" {
	bys ``src'_ids' (match_probability): replace `to_drop' = 1 if (_n<_N) 	///	//Flag to drop if better match exists
		| match_probability<`min_score' 										/// //Or if not above minimum cutoffs
		| (match_probability[_N-1]>`max_second' & _N>1) 							//Or if second-best match probability is above maximum cutoff
}

drop if `to_drop'==1														//Drop matches not satisfying gap or minimum cutoff
di _N
drop `to_drop'



******************************7. Save Results**************************************
return clear
return scalar N_matches	= _N													//Return number of matches

compress
save "`matches_dta'", replace //Save final dataset of matches according to EM and specified decision rule

********************************8. Cleanup*****************************************

end


