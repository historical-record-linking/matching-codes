
/* This code gives an example of to use the EM stata command. In this example we give the code to 
link the 1865 Norwegian census to the 1900 Norwegian census. However the majority of this code is generic, 
and will apply to any data set. 
* Some important comments:
- Standardize names of variables as in the "create_data.do". Important for "loadvars" and "blocking_vars"
- Set correctly directory and file names (for dta and do files).
- Set parameters for decision rule.
- Set difference in years between files.
- You can change paremeter for the EM algorithm (tolerance and max number of iterations) below. You can also use the default values.
- You can set initial guess for the matching probability in the EM algorithm. You can also use the default prior (the number of observations of the smaller dataset divided by the total number of candidates from pairing.ado).
- You can use the main ado file (matching_em.ado) in 2 ways: calculating EM probabilities, or just applying decision rules. In the latter case, you should have saved the probabilities calculated before (see example below).

*-------------------------------------------------------------------------------------------------------*/

/* Specify directory locations: */
cap program drop _all
clear all
set more off

	
* Set directories

local MatchingDoFiles   "C:\Users\acald\Dropbox\EHL\ran\test_EM_codes\NEW_codes\EM_jacob" /*location where all matching algorithm files (and .ado files) are stored */
local datadirA			 "C:\Users\acald\Desktop\test_em_data\data\input\1865_census"	/*location where the raw data for dataset A is held*/
local datadirB			 "C:\Users\acald\Desktop\test_em_data\data\input\1900_census" /*location where the raw data for dataset B is held*/
local outdir 			 "C:\Users\acald\Desktop\test_em_data\data\new_codes\em_jacob_small" /*location to store cleaned data*/
local matchdir 		 "C:\Users\acald\Desktop\test_em_data\data\new_codes\em_jacob_small\em_matches" /*location to store matched data*/
local block_dir "C:\Users\acald\Desktop\test_em_data\data\new_codes\em_jacob_small/JWdistance_Blocks"

* Set file names
local Afile "`datadirA'/1865_census_ready2link.dta" // standardized data file A
local Bfile "`datadirB'/1900_census_ready2link.dta" // standardized data file B

* Set parameters for decision rules
local p1 = .50
local l1 = .45

// other parameters (to show how to use the command without creating pairs and using the EM again)
local p2 = .6
local l2 = .3

* Set difference in age between files
global timediff = (1900 - 1865) // number of years between reported age in data set A & B 

* Set variables to load and blocking variables
local loadvars = "id age f_name l_name Place_of_Birth initial_frst initial_last"	//Variables to load from both A and B
local blocking_vars = "initial_frst initial_last Place_of_Birth" // Variables to block on. In this example we are blocking on initals and place of birth, could also use race, sex, etc... 

*Add do file path to adopath
adopath++"`MatchingDoFiles'"


*******************************************************************************
/* Section 1: create pairs using pairing.ado
*******************************************************************************/

pairing, ///
afile(`"`Afile'"') /// 
bfile(`"`Bfile'"') ///	
load_vars(`loadvars') ///
restrictions() ///			// Variables to load and restrictions to use when loading raw data (e.g. age restriction, set restriction)
id(id) /// 		// Unique identifier variables
blocking(`blocking_vars') ///			// Only consider candidates which match exactly on blocking variables
clusters(4) ///			// # of clusters to use when running in parallel,
clean_pairs("`MatchingDoFiles'/em_filter.do") ///
distances(age_diff jw_f_name jw_l_name jw_f_name_cat jw_l_name_cat) ///
output("`block_dir'/all_blocks.dta") ///
save_blocks ///
block_dir("`block_dir'")


*******************************************************************************
/* Section 2: EM matching algorithm (EMA) and decision rules
*******************************************************************************/

local p_val1 = `p1' * 100
local l_val1 = `l1' * 100


matching_em, ///
pairs_not_loaded /// //dta is not open, then the command will open it (useful when dealing with big files)
id_vars(id) /// //specify id
distances(age_diff jw_f_name_cat jw_l_name_cat) /// //specify distance variables
distributions(categorical categorical categorical) /// //specify distributions
min_score(`p1') /// //specify parameter for decision rules: min prob for best match
max_second(`l1')  /// //specify parameter for decision rules: max prob for second best match
pairs_dta("`block_dir'/all_blocks") /// //file with all blocks
matches_dta("`matchdir'/em_matches_`p_val1'_`l_val1'.dta") /// //file to store matches
default_priors /// // the guess for the probability of a match is set as the size of the smaller dataset dividid by the total number of candidates. If you don't specify this, you must specify your own guess using user_pmatchguess()
/// //Optional:
save_coefficients /// //optional: save coefficients from EMA. They are saved as "coef_`probabilities_dta'".
save_counts /// //optional: save counts before they are used in EMA. They are saved as "counts_`probabilities_dta'".
probabilities_path(`matchdir') /// //optional: directory where to store probabilities (use noprerule_save to avoid this; though you will need it if you want to save counts and coefficients)
probabilities_dta("em_probabilities.dta") /// //optional: file name to store probabilities (use noprerule_save to avoid this)
stop_at(0.000001) /// //optional: set tolerance to stop EMA (default=0.0005)
maxiter(3000) /// //optional: set max number of iteracions for the EMA (default=500)



*******************************************************************************
/* Section 3: ONLY decision rules 
- using the output from section 1 and 2
- You must have saved candidates with probabilities from EMA using probabilities_path() and probabilities_dta()
*******************************************************************************/

local p_val2 = `p2' * 100
local l_val2 = `l2' * 100

	  	 
matching_em, ///
only_decision_rule /// //only apply decision rules on a previously created file with probabilities from EMA
probabilities_path(`matchdir') /// //directory where you saved probabilities
probabilities_dta("em_probabilities.dta") /// //file where you saved probabilities (use noprerule_save to avoid this)
min_score(`p2') /// //specify parameter for decision rules: min prob for best match
max_second(`l2')  /// //specify parameter for decision rules: max prob for second best match
matches_dta("`matchdir'/em_matches_`p_val2'_`l_val2'.dta") /// //file to store matches
///
id_vars(*) /// //specify id (not neeeded)
distances(*) /// //specify distance variables (not neeeded)
distributions(*) /// //specify distributions (not neeeded)
pairs_dta(*) //file with all blocks (not neeeded)


*******************************************************************************
/* Section 4: Specify your own initial guess for the matching probability using user_pmatchguess()
- "default_priors" is replaced by "user_pmatchguess(0.08)"
*******************************************************************************/

matching_em, ///
pairs_not_loaded /// //dta is not open, then the command will open it (useful when dealing with big files)
id_vars(id) /// //specify id
distances(age_diff jw_f_name_cat jw_l_name_cat) /// //specify distance variables
distributions(categorical categorical categorical) /// //specify distributions
min_score(`p1') /// //specify parameter for decision rules: min prob for best match
max_second(`l1')  /// //specify parameter for decision rules: max prob for second best match
pairs_dta("`block_dir'/all_blocks") /// //file with all blocks
matches_dta("`matchdir'/em_matches_`p_val1'_`l_val1'.dta") /// //file to store matches
user_pmatchguess(0.08) /// // the guess for the probability of a match is set as the size of the smaller dataset dividid by the total number of candidates. If you don't specify this, you must specify your own guess using user_pmatchguess()
/// //Optional:
save_coefficients /// //optional: save coefficients from EMA. They are saved as "coef_`probabilities_dta'".
save_counts /// //optional: save counts before they are used in EMA. They are saved as "counts_`probabilities_dta'".
probabilities_path(`matchdir') /// //optional: directory where to store probabilities (use noprerule_save to avoid this; though you will need it if you want to save counts and coefficients)
probabilities_dta("em_probabilities.dta") /// //optional: file name to store probabilities (use noprerule_save to avoid this)
stop_at(0.000001) /// //optional: set tolerance to stop EMA (default=0.0005)
maxiter(3000) /// //optional: set max number of iteracions for the EMA (default=500)









