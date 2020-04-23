cap program drop _all
cap log close
clear all
macro drop _all


* Set directories and files
local MatchingDoFiles "C:\Users\acald\Dropbox\EHL\ran\test_EM_codes\EM_jacob" //set your directory where abeclean.ado is stored
local datadirA "C:\Users\acald\Dropbox\EM_testing/data/input/1865_census" //set your diretory name for dataset A
local datadirB "C:\Users\acald\Dropbox\EM_testing/data/input/1900_census" //set your diretory name for dataset B
local file_a_raw "1865_census_raw" //set your file name for dataset A
local file_b_raw "1900_census_raw"  //set your file name for dataset B

local datadirA_r2l "C:\Users\acald\Desktop\test_em_data/data/input/1865_census" //set your diretory name for the CLEAN dataset A (ready to link (r2l))
local datadirB_r2l "C:\Users\acald\Desktop\test_em_data/data/input/1900_census" //set your diretory name for the CLEAN dataset B (ready to link (r2l))

* Set variable names
local fist_name_variable "namefrst" //set your variable name for first names
local last_name_variable "namelast" //set your variable name for last names
local place_of_birth_variable "bplno" //set your variable name for place of birth
local age_variable "age" //set your variable name for age

/*******************************************************************************
*  Clean datasets
*******************************************************************************/
cd `MatchingDoFiles'

*File A
use "`datadirA'/`file_a_raw'", clear

rename `age_variable' age 						// call first name "f_name"
rename `fist_name_variable' f_name 						// call first name "f_name"
rename `last_name_variable' l_name 						// call last name "l_name"
rename `place_of_birth_variable' Place_of_Birth 				// optional, if matching on place of birth

keep if age >= 10 & age <= 20 & sex == 1 	// apply any restrictions 

* Create your own ids
tostring serial, replace
tostring pernum, replace
gen id = serial + "_" + pernum				// generate unique identifier, or rename existing identifier "id"

* clean first & last names 
abeclean f_name l_name, nicknames sex(sex) initial(middleinitial) nonysiis

*update names
drop f_name l_name
rename f_name_cleaned f_name
rename l_name_cleaned l_name

* find initals
gen initial_frst = strupper(substr(f_name,1,1))
gen initial_last = strupper(substr(l_name,1,1))

* Drop missing observations with missing values in blocking variables
drop if f_name=="" | l_name=="" | Place_of_Birth==.

*save
save "`datadirA_r2l'/`file_a_raw'_ready2link.dta", replace

//-----------------------------------------------------------------------------
*File B
use "`datadirB'/`file_b_raw'", clear

rename `age_variable' age 						// call first name "f_name"
rename `fist_name_variable' f_name 						// call first name "f_name"
rename `last_name_variable' l_name 						// call last name "l_name"
rename `place_of_birth_variable' Place_of_Birth 				// optional, if matching on place of birth

keep if age >= 45 & age <= 55 & sex == 1  	// apply any restrictions

* Create your own ids
tostring serial, replace
tostring pernum, replace
gen id = serial + "_" + pernum				// generate unique identifier, or rename existing identifier "id"

* clean first & last names 
abeclean f_name l_name, nicknames sex(sex) initial(middleinitial) nonysiis

*update names
drop f_name l_name
rename f_name_cleaned f_name
rename l_name_cleaned l_name

* find initals
gen initial_frst = strupper(substr(f_name,1,1))
gen initial_last = strupper(substr(l_name,1,1))

* Drop missing observations with missing values in blocking variables
drop if f_name=="" | l_name=="" | Place_of_Birth==.

*save
save "`datadirB_r2l'/`file_b_raw'_ready2link.dta", replace











