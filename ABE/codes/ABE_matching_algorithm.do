/* This code gives an example of how the various versions of the ABE/Ferrie algorithm are run in Stata. 
In this example we give the code to link the 1865 Norwegian census to the 1900 Norwegian census. However the
majority of this code is generic, and will apply to any data set. In order use this code for your specific data, 
standardize the variable names given to match the names used in Section I. 

A note on linking large data sets: When linking large files (e.g. full-count census data), in order 
to make the matching more computationally feasible begin by saving your observations by place of birth 
(e.g. before matching all American-born men in the 1900 census to the 1910 census you should have 100 
individual data files, 50 place of birth files from each census year). The following linking steps will 
then be completed for each place of birth separately (e.g. link Alabama in 1900 to Alabama in 1910, then 
Arizona in 1900 to Arizona in 1910, ect…)  */
*-------------------------------------------------------------------------------------------------------*/


clear all
set more off

cap ssc install nysiis /* this package is required at some point */
cap ssc install jarowinkler /* this package is required at some point */
cap ssc install parallel /* this package is required at some point */

/* Specify directory locations: */
global MatchingDoFiles   "/Users/hkissel/Dropbox/Replications/ABE_algorithm_code/codes"  	    	/

*location where all ABE/Ferrie matching algorithm files (and .ado files) are stored */
global datadirA			 "/Users/hkissel/Dropbox/SEIPR/testing_code/input/1865_census"		  		/*location where the raw data for dataset A is held*/

global datadirB			 "/Users/hkissel/Dropbox/SEIPR/testing_code/input/1900_census"  			/*location where the raw data for dataset B is held*/

global outdir 			 "/Users/hkissel/Dropbox/SEIPR/testing_code/output" 						/*location to store cleaned data*/
global matchdir 		 "/Users/hkissel/Dropbox/SEIPR/testing_code/output"			 				/*location to store matched data*/


*******************************************************************************
/* SECTION 1. Standardize and Clean Data
*******************************************************************************/

/* 1.1 - Standardize data. This section of the code standardizes variable names, and will need to be changed to suit your data. 
		 Below we give an example using  1965 and 1900 Norwegian census data. */
use $datadirA//1865_census_raw.dta, clear

keep if age >= 10 & age <= 20 & sex == 1 	// apply any restrictions 

rename namefrst f_name 						// call first name "f_name"
rename namelast l_name 						// call last name "l_name"
rename bplno Place_of_Birth 				// optional, if matching on place of birth

tostring serial, replace
tostring pernum, replace
gen id = serial + "_" + pernum				// generate unique identifier, or rename existing identifier "id"

save $datadirA//1865_census_standardized.dta, replace

use $datadirB//1900_census_raw.dta, clear

keep if age >= 45 & age <= 55 & sex == 1  	// apply any restrictions

rename namefrst f_name 						// call first name "f_name"
rename namelast l_name 						// call last name "l_name"
rename bplno Place_of_Birth 				// optional, if matching on place of birth

tostring serial, replace
tostring pernum, replace
gen id = serial + "_" + pernum				// generate unique identifier, or rename existing identifier "id"

save $datadirB//1900_census_standardized.dta, replace

/* 1.2 - Clean names using abeclean.ado
		 Options: nicknames standardize common nicknames, the variable "sex" is required to specify male or female (sex = 1 if male, = 2 if female).
				  intial(middleinitial) creates a middle initial from the "f_name" string. */

cd $MatchingDoFiles // set current directory to location of abeclean.ado and abematch.ado
				  
use $datadirA//1865_census_standardized.dta, clear
abeclean f_name l_name, nicknames sex(sex) initial(middleinitial)
save $datadirA//1865_census_ready2link.dta, replace

use $datadirB//1900_census_standardized.dta, clear
abeclean f_name l_name, nicknames sex(sex) initial(middleinitial)
save $datadirB//1900_census_ready2link.dta, replace
clear

*******************************************************************************
/* SECTION 2. ABE/Ferrie matching algorithm
*******************************************************************************/



/* 2.1 Set up abe matching algorithm.  */
	global A $datadirA//1865_census_ready2link.dta 				// cleaned & standardized data file A
	global B $datadirB//1900_census_ready2link.dta 				// cleaned & standardized data file B
	global outputfile "${outdir}/ABE_matches_nysiis_no_middle"  // file name to save matched data 

	/* "match_vars" specifies which variables to link on. There are many options. Here we use NYSIIS standardized 
	names (f_name_nysiis l_name_nysiis), but you could instead use exact names (f_name_cleaned l_name_cleaned). In this 
	example we match on place of birth, other options include middle initial, race, or any other time-invariant characteristic. 
	*/
	global match_vars f_name_nysiis l_name_nysiis Place_of_Birth

	global timediff = (1900 - 1865) // number of years between the age reported in data set A and age reported in data set B. 

/* 2.2 Find ABE matches, standard version */
	clear
	abematch $match_vars,  file_A($A) file_B($B) timevar(age) timediff($timediff ) save($outputfile)  replace id_A(id) id_B(id) unique_m(2) unique_f(2) keep_A(l_name f_name) keep_B(l_name f_name) 
	
		* see abematch.sthlp for additional options 


/* 2.3 More conservative matching, restrict sample to those unique within +-2 years of age. */
	keep if unique_file2 == 1  // keep only names unique within +- 2 years in own data sets
	keep if unique_match2 == 1 // drop people that have another potential match within +-2 years of birth

	save ${outputfile}_5yr_band, replace
		
		


*******************************************************************************
/* SECTION 3. ABE/Ferrie matching Jaro-Winkler adjustment */
*******************************************************************************
/* This version of the ABE/Ferrie algorithm is analogous to the process used in Section 2, 
but rather than finding pairs that match on exact or standardized name, this version uses 
the Jaro-Winkler string distances between each potential pair of names to determine which 
records match. */

global A "$datadirA/1865_census_ready2link_subset.dta" // cleaned & standardized data file A
global B "$datadirB/1900_census_ready2link_subset.dta" // cleaned & standardized data file B
//cap mkdir $outdir/BlocksAtoB 				   // location to save distance files 

/* 3.1 Define what to consider as a potential match */
global blockingvars = "initial_frst initial_last Place_of_Birth"		// Variables to block on (here we are blocking on first & last inital and place of birth, could also add race, middle initial ect... 
global age_band = 5 													// We typically define potential matches to be observations within +-5 years of birth 

/* 3.2 Find string distances between potential matches in data set A and data set B. */ 
global main = "$MatchingDoFiles"
cap program drop _all
adopath+"global" 
global loadvars = "id age f_name_cleaned l_name_cleaned Place_of_Birth"	//Variables to load from both A and B
global timediff = (1900 - 1865)									    	// number of years between the age reported in data set A and age reported in data set B. 

pairing, afile(`"$A"') bfile(`"$B"')					///	
	load_vars($loadvars) restrictions() 				///			// Variables to load and restrictions to use when loading raw data (e.g. age restriction, set restriction)
	preprocessing($main/gen_initials.do) 				///			// Preprocessing code to find first initials (can also add in any additional cleaning of names to the "gen_initals.do" file
	id(id) 												/// 		// Unique identifier variables
	keep($loadvars initial_frst initial_last)			///			// Add other variables to keep in cleaned data sources
	blocking($blockingvars )							///			// Only consider candidates which match exactly on blocking variables
	clusters(4) 										///			// # of clusters to use when running in parallel,
	clean_pairs($main/filtering.do) 					///			// filtering.do contains instructions about which pairs to consider as potential matches.  
	distances(age_diff jw_f_name jw_l_name)  			///			// Distance variables after running clean_pairs
	output("$outdir/matches") save_blocks block_dir("$outdir/BlocksAtoB") noappend				


/* 3.3 Apply ABE-JW decision rules */

/* Specify which value(s) of x to use. We typically use x = 0 as our "less conservative" option, and x = 2 as our "more conservative" option. 
When x = 0 we keep the closest match in terms of age difference, so long as the match is unique. When x = 2 we drop any observations with more
than one potential match within +- 2 years. */
global rules "0 2"  

global max_age_diff = 2 	  			 // number of years reported age can differ between matched pairs (we typically restrict to +- 2) 
global outputfile "${outdir}/JW_matches" // name of matched file (note: this name will be appended with your choice of "x" and any uniqueness requirements)

/* Apply decision rules using JW_decision_rules.do*/
do "$MatchingDoFiles/JW_decision_rules.do "



/* 3.4 Apply *within dataset* uniqueness requirements (optional). Since JW string distances in not transitive, in some cases records will successfully match by JW 
string distance, even though there is another name within his/her own data set within 0.1 JW string distance in name. To drop these cases, we need to find string distances 
between the names of each person within his/her own data set. */

/* 3.4.1 - Identify the within-dataset uniqueness of matched individual*/
do $MatchingDoFiles/JW_within_dataset_uniqueness.do 


/* 3.4.2 -  Drop non-unique matched pairs. Typically we require names to be unique by JW string distance & exact age when x = 0, and 
require names to be unique within +- 2 years age when x = 2 (as shown). However any other uniquness requirements can be specified */ 

** Example: x = 0, requiring uniqueness by exact age 
	use ${outdir}/JW_matches_x0, clear
	
	merge 1:1 $ID_AA using ${outdir}/Uniqueness_indicators_AA
	keep if unique_within_0_yr_band == 1 & _merge == 3 
	drop _merge 
	
	merge 1:1 $ID_BB using ${outdir}/Uniqueness_indicators_BB 
	keep if unique_within_0_yr_band == 1 & _merge == 3 
	drop _merge 
	
	save ${outdir}/JW_matches_x0_unique, replace

** Example: x = 2, requiring uniqueness within +- 2 years age
use ${outdir}/JW_matches_x2, clear

merge 1:1 $ID_AA using ${outdir}/Uniqueness_indicators_AA,
keep if unique_within_2_yr_band == 1 & _merge == 3 
drop _merge 

merge 1:1 $ID_BB using ${outdir}/Uniqueness_indicators_BB 
keep if unique_within_2_yr_band == 1 & _merge == 3 
drop _merge 

save ${outdir}/JW_matches_x2_unique, replace



** last updated: April 3, 2019 
** please contact ranabr@stanford.edu (Ran Abramitzky), lboustan@princeton.edu (Leah Boustan), and/or kaeriksson@ucdavis.edu (Katherine Eriksson) 
** with any questions or feedback about this code. 


