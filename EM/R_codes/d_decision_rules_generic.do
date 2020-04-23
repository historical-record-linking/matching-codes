



  /* Specify directory locations: */
  global EMmatches 		 "C:/Users/acald/Desktop/test_em_data/data/new_codes/em_santi_small2/EMmatches"			 				/*location to store matched data*/
  global EMdistances  	"C:/Users/acald/Desktop/test_em_data/data/new_codes/em_santi_small2/EMdistances"
  global EMblocks 		 "C:/Users/acald/Desktop/test_em_data/data/new_codes/em_santi_small2/EMblocks"			 				/*location to store matched data*/

  /* Set parameters for decision rules*/
  local p_underbar = 50 
  local l = 45


  ********************************************************************************
  * Open and save estimates of probabilities (we will merge this to the distances file)
  import delimited using "${EMmatches}/EM_Estimates_probabilities.csv", delimiter(" ") varnames(1) asdouble case(preserve) clear

  rename w_final w

  tempfile em_probabilities
  save `em_probabilities'

use "${EMblocks}/N_Blocks", clear

sum n_blocks

global n_blocks=r(mean)

* Open distances file and merge



forvalues k=1(1)$n_blocks{

  clear

  capture confirm file "${EMdistances}/distances_`k'.csv"

  if _rc==0{

    import delimited  "${EMdistances}/distances_`k'.csv", delimiter(space) case(preserve) encoding(ISO-8859-1) clear


    * Merge distances with probabilities (w) /*assert(3)*/
    merge m:1 Age_Dist strdist_FN_index strdist_LN_index using `em_probabilities', keepusing(w) keep(3) nogenerate
    
    //cap rename id_b id_B

    * Create ranks based on w
    egen rank_w_A = rank(w), by(id_A) field
    egen rank_w_B = rank(w), by(id_B) field

    //keep if rank_w_A<=2 | rank_w_B<=2 //I erase this to have the file as in Jacob's

    * Keep relevant variables
    keep id_A id_B w rank_w_A rank_w_B

    * Make sure there are not observations without ids
    drop if id_A=="" & id_B=="" //I added this

    ********************************************************************************

    * Keep only first and second (note I took this from above)

    keep if rank_w_A<=2 | rank_w_B<=2

    //------------------
    * *Decision Rules*
    //------------------

    *Identify potential matches for each pair of observations
    gen Potential_Match_A=0
    gen Potential_Match_B=0

    replace Potential_Match_A=1 if w>=`p_underbar'/100 & rank_w_A==1
    replace Potential_Match_A=1 if w>=`l'/100 & rank_w_A==2

    egen n_matches_A=total(Potential_Match_A), by(id_A)

    replace Potential_Match_B=1 if w>=`p_underbar'/100 & rank_w_B==1
    replace Potential_Match_B=1 if w>=`l'/100 & rank_w_B==2

    egen n_matches_B=total(Potential_Match_B), by(id_B)

    * Determine matches
    gen Match=0
    replace Match=1 if Potential_Match_A==1 & Potential_Match_B==1 & n_matches_A==1 & n_matches_B==1 & rank_w_A==1 & rank_w_B==1

    * Keep matched records
    keep if Match==1

    * Keep relevant variables
    keep id_A id_B w

    * Save matches
    save "${EMmatches}/matches_block_`k'_`p_underbar'_`l'", replace 
  }
}

*Append all blocks

clear

//set obs 1 

forvalues k=1(1)$n_blocks{
  capture confirm file "${EMmatches}/matches_block_`k'_`p_underbar'_`l'.dta"

  if _rc==0 {
    append using "${EMmatches}/matches_block_`k'_`p_underbar'_`l'"
  }
}

* Save matches

save "${EMmatches}/matches_`p_underbar'_`l'", replace 



/*test if match are the same (number is indeed the same)
use "C:\Users\acald\Desktop\test_em_data\data\new_codes\em_santi_small2\EMmatches/matches_50_45", clear

merge 1:1 id_A id_B using "C:\Users\acald\Desktop\test_em_data\data\new_codes\em_santi_small\EMmatches/matches_50_45",



