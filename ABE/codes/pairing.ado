*! version 1.0.3  03mar2019  Jacob Conway, jcconway@stanford.edu

/*1.0.3:
	-Dropped observations with missing values in blocking variables
	-Added resume option
	-Fixed syntax issue whe load_vars() and restrictions() both unspecified
	-Changed existence check of existing block directory to also work on Windows*/
*1.0.2 Fixed issue related to spaces in filepath passed to block_dir
*1.0.1 Fixed issue related to spaces in working directory filepath


program define pairing, rclass 
	version 14
	syntax , ID_vars(string) BLocking_vars(string) 								///
		output(string) Distances(string) 										///
		[AFile(string)      ADirs(string)         APAtterns(string) 			///
		 BFile(string)      BDirs(string)         BPAtterns(string) 			///
		 ALoad_vars(string) ARestrictions(string) APReprocessing(string)  		///
		 BLoad_vars(string) BRestrictions(string) BPReprocessing(string) 		///
		 Load_vars(string)  Restrictions(string)  Preprocessing(string) 		///
		 Keep_vars(string)  ACleaned(string)      BCleaned(string)   			///
		 do_name(string)   CLEAN_pairs(string) 									///
		 CLUsters(integer 1) PROCessors(integer 0) parallel_passthru(string) 	///
		 save_blocks example_block block_dir(string) block_prefix(string) 		///
		 noAPPEND resume]
	
****************************Error Checking**************************************
*Error Checking of Common Options Provided
assert (`"`save_blocks'"'=="" & `"`example_block'"'=="") | `"`block_dir'"'!="" 	//If you want to save blocks, must provide directory in which to save
assert `"`restrictions'"'=="" | substr(`"`restrictions'"',1,3)=="if "			//Common restrictions when loading a file must either be empty or start with an if statement
if `"`append'"'=="noappend" assert `"`save_blocks'"'=="save_blocks" 			//Assert that blocks are being saved if user specifies not to append processed blocks together

*Cleanup optional filenames and use defaults if not specified
foreach src in "a" "b" {
	if regexm(`"``src'cleaned'"',"(^.*)(\.dta$)") local `src'cleaned = regexs(1) //Remove .dta from user provided cleaned source file name
	if `"``src'cleaned'"'=="" local `src'cleaned = "__`src'_cleaned"			//Default name for cleaned source file

}
if regexm(`"`do_name'"',"(^.*)(\.do$)") local `src'cleaned = regexs(1)			//Remove .do from user provided dofile name
if (`"`do_name'"'=="") local do_name = `"do_in_parallel"'						//Default .do file name (to create and pass to parallel instances)
if `"`block_prefix'"'=="" local block_prefix = "Block"							//Default block prefix is Block

*Check necessary files exist if resumes existing matching
if `"`resume'"'=="resume" {
	assert `"`save_blocks'"'=="save_blocks"
	foreach file in `"`block_dir'/`block_prefix'_key.dta"' `"`acleaned'.dta"' ///
		`"`bcleaned'.dta"' `"`do_name'.do"' {
			confirm file `"`file'"'
	}
}
local cwd = `"`c(pwd)'"'														//Current working directory


if "`resume'"=="" {
foreach src in "a" "b" {
*Error Checking of Source-Specific Options
	assert (`"``src'file'"'!="" & `"``src'dirs'"'=="" &`"``src'patterns'"'=="") ///
		| (`"``src'file'"'=="" & `"``src'dirs'"'!="" &`"``src'patterns'"'!="")	//For each source, must specify either single file or directories and patterns but not both
	assert `: list sizeof `src'dirs'==`: list sizeof `src'patterns'				//Assert number of directories matches number of patterns
	assert inlist(substr(`"``src'restrictions'"',1,2),"","if","& ")				//Source specific restrictions must be missing, start with an if, or an and

**************************Create Useful Locals**********************************

*Add common preprocessing, load_vars, and restrictions to source-specific versions
local `src'load_vars: list `src'load_vars | load_vars
local `src'preprocessing = `"``src'preprocessing' `preprocessing'"'
local `src'restrictions = `"`restrictions' ``src'restrictions'"'
}

*Specify variables to keep in block files and in cleaned source files
if `"`keep_vars'"'!="" {														//If user provided list of variables to keep in block datasets
	local keep_vars: list keep_vars | id_vars 									//Add ID variables to list of variables to keep if not already specified
	local vars_in_cleaned: list keep_vars | blocking_vars						//In cleaned version of dataset, keep ultimate variables to keep (with added IDs) and blocking variables
}
else {																			//If user did not provide list of variables to keep, keep all variables in cleaned source dataset and in block datasets
	local keep_vars = "_all"													
	local vars_in_cleaned = "_all"
}

*Create version of source variables with source (A and B) prefixes
local id_w_src
foreach id of local id_vars {
	local to_add = "A`id' B`id'"
	local id_w_src: list id_w_src | to_add
}

**************************Block Saving Preparation******************************
if `"`save_blocks'"'!="" | `"`example_block'"'!="" {
	*Remove any existing block directory and its contents	
	mata: st_local("exists", strofreal(direxists(`"`block_dir'"'))) 			//Check if block directory already exists
	if `exists' {																//If so, remove files matching our block prefix
		local to_remove: dir `"`block_dir'"' files `"`block_prefix'*.dta"'
		foreach file of local to_remove {
			rm `"`block_dir'/`file'"'
		}
	}
	else mkdir `"`block_dir'"'													//Otherwise create a new block directory
	qui cd `"`cwd'"'
}

foreach src in "a" "b" {														//For each data source A and B
*********************************Load Data Sources******************************
if `"``src'file'"'!="" {
	local using = cond(`"``src'load_vars' ``src'restrictions'"'!="","using","")
	use ``src'load_vars' ``src'restrictions' `using' `"``src'file'"', clear		//Load data if it is a single file, with only desired variables and with given restrictions
}
else {																			//If multiple files, load each with only desired variables and restriction, save, and append
	local `src'files
	local `src'files_cleaned
	while `"``src'patterns'"'!="" {
		gettoken `src'current_dir `src'dirs: `src'dirs							//Get current directory holding source files
		gettoken `src'current_pat `src'patterns: `src'patterns					//Get current pattern source files
		local `src'files_to_add: dir `"``src'current_dir'"' ///
			files `"``src'current_pat'"'										//Store list of files matching current pattern in current directory
		local `src'files = `"``src'files' ``src'files_to_add'"'					//Add these files to list so far
	}
	local `src'file_count = 1
	foreach `src'file of local `src'files {										//Loop through stored list of source files
		use ``src'load_vars' ``src'restrictions' ///
			using `"``src'current_dir'/``src'file'"', clear						//Load source file (with given observation and variable subsets)
		tempfile File``src'file_count'
		qui save  `File``src'file_count''										//Save subset source file
		local `src'files_cleaned = `"``src'files_cleaned' `File``src'file_count''"' //Add subset source file to list of files to append
		local ``src'file_count++'												//Increment source file counter
	}
	clear
	qui append using ``src'files_cleaned'										//Append together stored subset source files
}
****************************Run Preprocessing Code******************************
while `"``src'preprocessing'"'!="" {											//While there is still preprocessing to be done for this source
	gettoken `src'current_command `src'preprocessing: `src'preprocessing		//Get next preprocessing command
	if regexm(`"``src'current_command'"',"\.do$")==1 qui do ``src'current_command' //If command is a do-file, run it
	else ``src'current_command'													//Otherwise just pass command through verbatim
}

****************************Save Cleaned Source File****************************
keep `vars_in_cleaned'															//Keep only specified variables,
isid `id_vars'																	//Assert that ID variables uniquely identify observations in cleaned dataset
tempvar blocking_miss
egen `blocking_miss' = rowmiss(`blocking_vars')
qui count if `blocking_miss'!=0
if `r(N)'!=0 {
	qui drop if `blocking_miss'!=0
	di in red "Dropping `r(N)' observations from source `src' with missing values in at least one blocking variable"
}
drop `blocking_miss'
sort `blocking_vars'
qui compress
qui save `"``src'cleaned'"', replace

***********************Get Unique Blocking Variable Combinations****************							
keep `blocking_vars'															//Keep only our blocking variables
tempvar n
gen `n' = _n
qui by `blocking_vars': gen `src'_start = `n'[1]								//Store where this block starts in our cleaned source file, for later "in"
qui by `blocking_vars': gen `src'_end = `n'[_N]									//Store where block ends
qui by `blocking_vars': keep if _n==1											//Keep only unique blocking variable combinations
drop `n'

if "`src'"=="a" {																										
	tempfile ablocks
	qui save `ablocks'															//If source is A (first time through), save combinations for later
}
else {																			
	assert `"`src'"'=="b"
	qui merge 1:1 `blocking_vars' using `ablocks', nogen keep(3)				//If source is B, merge on blocks in common with A
	rm `ablocks'
}
}

gen block_number = _n															//Number our blocking variable combinations
local N_blocks = _N																//# of unique blocking variable combinations in A that is also in B
di as text `"Number of blocks is: "' as text `N_blocks'
if `"`save_blocks'"'!="" {
	order block_number															
	qui save "`block_dir'/`block_prefix'_key", replace							//If saving blocks, save a block numbering key
}

******************Parse List of Commands to Run on Block Pairs******************
local parsed_commands															//String of parsed commands, to pass to a later file write in creating a .do file
while `"`clean_pairs'"'!="" {
	gettoken command clean_pairs: clean_pairs
	if regexm(`"`command'"',"\.do$") {
		local parsed_commands = `"`parsed_commands' `"qui do `command'"' _n"'	//Do if a .do file

	}
	else {
		local parsed_commands = `"`parsed_commands' `"qui `command'"' _n"'		//Otherwise pass command through verbatim
	}
}

******************Write .do File to Run in Parallel on Each Block***************
cap file close parallel_do														//Close connection to file we want to write if it's open
file open parallel_do using `"`do_name'.do"', write text replace				//Open do file to write to
file write parallel_do 															///
`"qui local matsize = 11000"'												_n	///	//Set matsize as large as possible, 11000 for MP/SE and 800 for IC
`"qui cap set matsize \`matsize'"'											_n	///
`"if _rc {"'																_n	///
`"local matsize = 800"'														_n	///
`"qui set matsize \`matsize'"'												_n	///
`"}"'																		_n	///
`"local N_blocks = _N"'														_n	/// //# of blocks
`"local length = \`matsize'/5"'												_n	/// //Maximum length of matrix with 5 columns
`"forval m=1/\`=ceil(\`N_blocks'/\`length')' {"'							_n	/// //Loop through matrices we need to create, storing block number and start and stop indices
`"local first = (\`m'-1)*\`length'+1"'										_n	/// //Matrix will start at this data entry
`"local last = min(\`m'*\`length',\`N_blocks')"'							_n	/// //Matrix will end at this data entry
`"qui cap drop __0*"'														_n	/// //mkmat sometimes tries to write over these temp variables, so delete them
`"mkmat block_number a_start a_end b_start b_end in \`first'/\`last', matrix(Cutoffs\`m')"' _n	/// //Save block number and index cutoffs
`"}"'																		_n	///
`"local pairs_list"'														_n	///	//List of saved pairs files, to fill
`"forval i=1/\`N_blocks' {"'												_n	/// //Loop through subset of blocking combinations given
`"parallel break"'															_n	/// //Check whether user has pressed break
`"local m = ceil(\`i'/\`length')"'											_n	/// //Get corresponding matrix number
`"qui matrix slice = Cutoffs\`m'[mod(\`i'-1,\`length')+1,1..5]"'			_n	///	//Get block row from matrix
`"local block = slice[1,1]"'												_n	/// //First entry is block number
`"qui use `keep_vars' `block_vars' using `bcleaned' in \`=slice[1,4]'/\`=slice[1,5]', clear"'	_n	/// //Open desired variables and block observations from cleaned B
`"qui keep `keep_vars'"'													_n	/// //Keep only desired variables
`"qui ren * B*"'															_n	/// //Rename variables to start with B to identify source
`"qui tempfile B_obs\`block'"'												_n	///
`"qui save \`B_obs\`block''"'												_n	/// //Save B block observations
`"qui use `keep_vars' `block_vars' using `acleaned' in \`=slice[1,2]'/\`=slice[1,3]', clear"' _n	/// //Open A block observations
`"qui keep `keep_vars' "'													_n	/// //Keep only desired variables (dropping some blocking variables)
`"qui ren * A*"'															_n	/// //Rename to indicate source
`"qui cross using \`B_obs\`block''"'										_n	/// //Form all pairwise combinations with B observations
`"qui rm \`B_obs\`block''"'													_n	/// //Remove tempfiles, these can cause file permissions issues when parallel cleans up on servers
`"if "`example_block'"=="example_block" & \`block'==1 {"'					_n	///
`"qui save `"`block_dir'/`block_prefix'\`block'_precommands"', replace"'	_n	/// //If specified, save the first block prior to running specified commands
`"}"'																		_n	///
`parsed_commands'															_n	/// //Run parsed commands
`"qui keep `id_w_src' `distances'"'											_n	/// //Keep only IDs and distances
`"if "`save_blocks'"!="save_blocks" {"'										_n	///
`"if _N>0 {"'																_n	/// //If not saving blocks, don't create tempfiles with zero observations
`"qui tempfile Pairs\`block'"' 												_n	///
`"qui save `"\`Pairs\`block''"'"'											_n	/// //Save cleaned pairs as tempfile unless told to save blocks
`"}"'																		_n	///
`"if "`example_block'"=="example_block" & \`block'==1 {"'					_n	///
`"qui save `"`block_dir'/`block_prefix'\`block'"'"'							_n	/// //If not saving all blocks and told to save an example after running commands, do so
`"}"'																		_n	///
`"}"'																		_n	///
`"else {"'																	_n	///
`"if _N==0 drop _all"'														_n	/// //If we're saving a block with no observations (helpful for resume option), don't save variables
`"qui save `"`block_dir'/`block_prefix'\`block'"', emptyok"' 				_n	/// //If told to save blocks, save cleaned pairs as real datasets rather than tempfiles
`"local Pairs\`block' = `"`block_dir'/`block_prefix'\`block'"'"' 			_n	/// //Save local with same handle as possible tempfile, pointing to save cleaned pairs
`"}"'																		_n	///
`"if `"`append'"'!="noappend" & _N>0 {"'									_n	///
`"qui cap local pairs_list = `"\`pairs_list' `"\`Pairs\`block''"'"'"'		_n	/// //Try to add saved pairs to list of saved pairs, may fail if list is too long
`"local rc = _rc"'															_n	/// //Save return code from attempt
`"qui assert(inlist(\`rc',0,920))"'											_n	/// //Check that attempt either suceeded or failed because list was too long
`"if \`rc'==920 {"'															_n	/// //If list was too long...
`"qui clear"'																_n	/// //Clear data
`"qui append using \`pairs_list' \`Pairs\`block''"'							_n	/// //Append files in pairs list
`"foreach file of local pairs_list {"'										_n	///
`"qui rm \`file'"'															_n	///	//Remove appended tempfiles, these can cause file permissions issues when parallel cleans up on servers
`"}"'																		_n	///
`"qui tempfile combined_at\`block'"'										_n	/// 
`"qui save \`combined_at\`block''"'											_n	/// //Save under a single file
`"local pairs_list = `"\`combined_at\`block''"'"' 							_n	/// //Start a new pairs list with just this combined file
`"}"'																		_n	///
`"}"'																		_n	///
`"}"'																		_n	/// //This finishes looping through files
`"qui clear"'																_n	///
`"if `"`append'"'!="noappend" {"'											_n	///
`"if `"\`pairs_list'"'!="" {"'												_n	/// 
`"qui append using \`pairs_list'"'											_n	/// //Append saved pairs together
`"if "`save_blocks'"!="save_blocks" {"'										_n	///
`"foreach file of local pairs_list {"'										_n	///
`"rm \`file'"'																_n	/// //Remove tempfiles, these can cause file permissions issues when parallel cleans up on servers
`"}"'																		_n	///	
`"}"'																		_n	///
`"}"'																		_n	///
`"}"'																		_n	///
`"if _N==0 {"'																_n	///			
`"set obs 1"'																_n	///
`"gen var_to_drop_later=1"'													_n	///
`"keep var_to_drop_later"'													_n	///
`"}"'
file close parallel_do															//Close our connection to the .do file we've written

******************Alternative if We Resume an Existing Pairing******************
}
else {	
	use `"`block_dir'/`block_prefix'_key.dta"', clear
	local existing_blocks: dir `"`block_dir'"' files `"`block_prefix'*.dta"'
	local block_key = `"`block_prefix'_key.dta"'
	local block_precommands = `"`block_prefix'1_precommands.dta"'
	local existing_blocks: list existing_blocks - block_key						
	local existing_blocks: list existing_blocks - block_precommands				//We append these existing blocks on later
	foreach file of local existing_blocks { //Remove blocks that we've already created from our "To-Do" block_key held in memory
		assert regexm("`file'","(^`block_prefix')([0-9]+)(.dta$)")
		qui drop if block_number==`=regexs(2)'
	}
}

******************Run .do File in Parallel on Each Block************************
/*Splits our data (block numbers and restrictions) among clusters, runs the
	.do file we've written on each block, and then combines the results*/
qui cd `"`cwd'"'
if _N!=0 {
parallel setclusters `clusters'													//Number of clusters to use
parallel do `do_name'.do,  processors(`processors') `parallel_passthru'			//Splits our data (block numbers and restrictions) among cluster
cap confirm variable var_to_drop_later											//If one of our clusters ended with zero observations, we created a dummy observation to avoid an error and now remove this observation
if !_rc {
	qui drop if var_to_drop_later==1
	drop var_to_drop_later
}
}
else clear


qui cd `"`block_dir'"'
if "`resume'"=="resume" qui append using `existing_blocks'										

******************************Save Results**************************************
if "`resume'"!="resume" return scalar N_blocks 	= `N_blocks'			//Return number of blocks
return scalar N_pairs	= _N													//Return number of pairs

qui cd `"`cwd'"'																//Return to initial working directory if we moved
if `"`append'"'!="noappend" {													
qui compress
qui save `"`output'"', replace
}
else clear

********************************Cleanup*****************************************
foreach src in "a" "b" {
	if `"``src'cleaned'"'=="__`src'_cleaned" rm `"``src'cleaned'.dta"'			//If cleaned source was not specified, delete the version we created
}

if `"`do_name'"'=="do_in_parallel" rm `"`do_name'.do"'							//If the .do file created was not named by the user, remove it

end

