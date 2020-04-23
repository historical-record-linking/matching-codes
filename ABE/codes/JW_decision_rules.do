
/*------------------------------------------------------------------------------------------------------------------------------------------------------------
This do-file uses the string distances generated with the pairing.ado command to create a matched sample using the jaro-winkler algorithm. 
*------------------------------------------------------------------------------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------------------------------------------------------
Find the potential matches in each block of data. 
------------------------------------------------------------------------------------------------------------------------------------*/
/* find number of blocks*/
use $outdir/BlocksAtoB/Block_key.dta,  clear
qui sum block_number
local max_blocks = r(max)

forval k = 1(1)`max_blocks'{
	di "block `k'"

	clear	 
	*confirm that this block exists
	capture confirm file   "${outdir}/BlocksAtoB/Block`k'.dta" 

	if _rc==0{

		use  "${outdir}/BlocksAtoB/Block`k'"
		
		count
		if `r(N)'==0 {
			display "empty"
		}
		else {
			egen n_A=group(Aid)
			sum n_A
			local max=r(Bid)
			gen obs=`max'

			egen n_B=group(Bid)

			
			foreach x in $rules {
				preserve

				*Identify best match among those in terms of age distance
				gen Potential_Match=1

				egen min_Age_Dist_A=min(age_diff), by(Aid)
				egen min_Age_Dist_B=min(age_diff), by(Bid)

				gen diff_Age_A=age_diff-min_Age_Dist_A
				gen diff_Age_B=age_diff-min_Age_Dist_B

				*Apply decision rule 
				replace Potential_Match=0 if (diff_Age_A>`x' & diff_Age_A~=.) | (diff_Age_B>`x' & diff_Age_B~=. ) 

				*Keep only pairs with ony one remaining potential match in each data set
				egen n_matches_A=total(Potential_Match), by(n_A)
				egen n_matches_B=total(Potential_Match), by(n_B)

				keep if Potential_Match==1 & n_matches_A==1 & n_matches_B==1 & age_diff<= $max_age_diff
				
				* At this point there may not be any remaining successful matches: 
				count
					* Check that there are not 2 duplicates matches
					if r(N) > 0 {
						bysort Aid: egen count = count(Aid)
						sum count
						if r(max) > 1 {
							di "Duplicate match found - check matching process for error" 
							gen 1 = 0 
						}
					}

					
				/* These can be saved as real files instead of temp if needed */
				tempfile matches`k'_x`x'   
				save `matches`k'_x`x''
				restore
		}
		}	
	}	
}



* Append all matches togegher 
foreach x in $rules {
	clear
	forval k = 1(1)`max_blocks'{
		capture append using `matches`k'_x`x'', force
		//count
	}
	save ${outputfile}_x`x'.dta, replace
}

















