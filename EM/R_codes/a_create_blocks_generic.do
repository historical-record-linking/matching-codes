* Save data from A and B in blocks based on blocking variables



/* Specify directory locations: */

local datadirA "C:\Users\acald\Desktop\test_em_data/data/input/1865_census" //location where the raw data for dataset A is held
local datadirB "C:\Users\acald\Desktop\test_em_data/data/input/1900_census" //location where the raw data for dataset B is held
local EMblocks "C:\Users\acald\Desktop\test_em_data\data\new_codes\em_santi_small2\EMblocks" //dirctory where you want to save the blocks

local fileA "1865_census_ready2link_subset.dta" // standardized data file A
local fileB "1900_census_ready2link_subset.dta" // standardized data file B

local blocking_vars = "initial_frst initial_last Place_of_Birth"

local timediff = (1900 - 1865) // number of years between reported age in data set A & B 

//******************************************************************************


* Delete existing blocks if they exists
local block_files: dir "`EMblocks'" files "Data_Block_*.dta", respectcase

if `"`block_files'"' != "" {
  foreach file of local block_files {
    rm "`EMblocks'/`file'"
  }
  rm "`EMblocks'/N_Blocks.dta"
  rm "`EMblocks'/Data_Blocks.dta"
}

* Open file A and append file B
use "`datadirA'/`fileA'", clear

gen Data=0
append using "`datadirB'/`fileB'"
replace Data=1 if Data==.

* Drop missing observations with missing values in blocking variables
drop if f_name=="" | l_name=="" | Place_of_Birth==.


* age_match = age in data set B 
gen age_match = age if Data == 1
replace age_match = age + `timediff' if Data == 0 

* check that there are no duplicates: 	
bysort id Data: egen count = count(id)
sum count 
if r(max) >1 {
  di "duplicate ids - check ids are unique"
  stop 
}
drop count


*generate blocks based on first letter of first and last names and place of birth
egen Data_Block=group(`blocking_vars')

gen Block_Size_ID=0

by Data_Block Data, sort: replace Block_Size_ID=1 if _n==1

egen Block_Size_Both=total(Block_Size_ID), by(Data_Block)

*Just keep those blocks which are present in both datasets A and B
keep if Block_Size_Both==2

*Save the data by block
egen Block=group(Data_Block)

sum Block
local n_blocks=r(max)

*Keep only the relevant variables
keep Data id f_name l_name age_match Block serial pernum

save "`EMblocks'/Data_Blocks.dta", replace

forvalues k=1(1)`n_blocks'{
  qui use "`EMblocks'/Data_Blocks.dta" if Block==`k', clear
  qui drop Block
  qui saveold "`EMblocks'/Data_Block_`k'.dta", version(12) replace 
}


* Store number of blocks (R will need this)
clear
set obs 1

gen n_blocks=`n_blocks'

saveold "`EMblocks'/N_Blocks", version(12) replace


