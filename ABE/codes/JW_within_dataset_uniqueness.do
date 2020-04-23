		

/*------------------------------------------------------------------------------------------------------------------------------------------------------------
This do-file identifies any matched pairs that are non-unique by JW string distances within their *own* data set. 
*------------------------------------------------------------------------------------------------------------------------------------------------------------*/

/* Compile list of all names we need to check for uniqueness (i.e. all people in least restrictive matched sample) */
use ${outputfile}_x0.dta, replace
keep Aid 
	* merge back in names
	rename Aid id
	merge 1:1 id using $A, keep(1 3)
		* double check all names merge 
		count if _merge == 1 
		if r(N) > 0 {
		di "id variables from matched data do not match id variables in ready2link data, check format"
		error 
		}
drop _merge
keep $loadvars
save $outdir/check_names_A, replace

use ${outputfile}_x0.dta, replace
keep Bid 
	* merge back in names
	rename Bid id
	merge 1:1 id using $B, keep(1 3) 
	
		* double check all names merge 
		count if _merge == 1 
		if r(N) > 0 {
		di "id variables from matched data do not match id variables in ready2link data, check format"
		error 
		}
drop _merge
keep $loadvars
save $outdir/check_names_B, replace

/*  Within dataset distances*/
	global timediff = 0													// Same data set 
	global age_band = 2 												// Find distances only within a +- 2 year band
		
	** AtoA distances		
	cap mkdir $outdir/BlocksAtoA
	pairing, afile(`"$outdir/check_names_A"') bfile(`"$A"')					///	
		load_vars($loadvars) restrictions() 				///			// Variables to load and restrictions to use when loading raw data (e.g. age restriction, set restriction)
		preprocessing($main/gen_initials.do) 				///			// Preprocessing code to find first initials (can also add in any additional cleaning of names to the "gen_initals.do" file
		id(id) 												/// 		// Unique identifier variables
		keep($loadvars initial_frst initial_last)			///			// Add other variables to keep in cleaned data sources
		blocking($blockingvars )							///			// Only consider candidates which match exactly on blocking variables
		clusters(4) 										///			// # of clusters to use when running in parallel,
		clean_pairs($main/filtering.do) 					///			// filtering.do contains instructions about which pairs to consider as potential matches.  
		distances(age_diff jw_f_name jw_l_name)  			///			// Distance variables after running clean_pairs
		output("$outdir/matches") save_blocks block_dir("$outdir/BlocksAtoA") noappend				


		** BtoB distances	
		cap mkdir $outdir/BlocksBtoB

		pairing, afile(`"$outdir/check_names_B"') bfile(`"$B"')				///	
		load_vars($loadvars) restrictions() 				///			// Variables to load and restrictions to use when loading raw data (e.g. age restriction, set restriction)
		preprocessing($main/gen_initials.do) 				///			// Preprocessing code to find first initials (can also add in any additional cleaning of names to the "gen_initals.do" file
		id(id) 									/// 		// Unique identifier variables
		keep($loadvars initial_frst initial_last)			///			// Add other variables to keep in cleaned data sources
		blocking($blockingvars )							///			// Only consider candidates which match exactly on blocking variables
		clusters(4) 										///			// # of clusters to use when running in parallel,
		clean_pairs($main/filtering.do) 					///			// filtering.do contains instructions about which pairs to consider as potential matches.  
		distances(age_diff jw_f_name jw_l_name)  			///			// Distance variables after running clean_pairs
		output("$outdir/BlocksBtoB/matches") save_blocks block_dir("$outdir/BlocksBtoB") noappend				

		
		
		
/*  Find pairs within the same data set that are non-unique by JW string distance */ 
	global yr_band = "0 2" 	// Specify which age band(s) to check uniqueness in. We typically check for uniqueness by exact age (yr_band = 0) and within +- 2 years (yr_band = 2)
	global ID_AA "Aid" 		// unique identifer in data set A
	global ID_BB "Bid" 		// unique identifer in data set A
	global BlocksAA "$outdir/BlocksAtoA"	// location of AtoA distances
	global BlocksBB "$outdir/BlocksBtoB"	// location of BtoB distances
	
	
	
	
	
foreach v in AA BB {
	di "-------- Finding non-unique names in data set `v'  --------- "
	qui {
		use ${Blocks`v'}/Block_key, clear
		qui sum block_number
		global n_blocks = r(max)

		forvalues k=1(1)$n_blocks {
			di "Block `k'" 				

			clear
			capture confirm file "${Blocks`v'}/Block`k'.dta"
			

			if _rc==0 {
				use  "${Blocks`v'}/Block`k'"

				count
				if `r(N)'==0 {
					display "empty"
				}
				else {
					tab age_diff
					*Identify other name within +- 0.1 string distance within specified age bands: 
					foreach x in $yr_band {
					di " ********** yr band = `x' *************"
						gen Potential_Match =0
						replace Potential_Match =1 if jw_f_name<=0.1& jw_l_name<=0.1 & age_diff<= `x'
						egen n_matches_A=total(Potential_Match), by(Aid)
						gen unique_within_`x'_yr_band =(n_matches_A==1)
						tab unique_within_`x'_yr_band
						drop Potential_Match n_matches_A
					}
					
					by Aid, sort: drop if _n>1
				
					keep Aid unique*
					if "`v'" == "BB"{
					rename Aid Bid
					}

					tempfile JW_Unique_`k'_`v'
					save `JW_Unique_`k'_`v''
				}
			}
		}
	}
	}



di "-------- Appending uniqueness indicators --------- "
qui{
foreach v in AA BB{
	use ${Blocks`v'}/Block_key, clear
	sum block_number
	global n_blocks = r(max)
	clear

	forvalues k=1(1)$n_blocks {
		 capture append using `JW_Unique_`k'_`v'', force
		count
	}
	

	save ${outdir}/Uniqueness_indicators_`v', replace
}
}
