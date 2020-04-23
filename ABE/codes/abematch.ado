/*******************************************************************************
abematch.ado
version 0.23 19oct2018

patch notes
-------------------
02:
	- make help file a bit clearer
	- make the default stub for unique "unique"
	- attempted to optimize timeband and uniqueband code
	- changed gen_timevar to gen_timediff
0.21 - save(string) not save(name)
0.22 - drop if id vars are missing
0.23 
	- rename unique unique_match
	- fixed bugs in unique_match
	- add unique_file
	- added if_A and if_B
	- added check to see >0 matches to provide warning instead of breaking

0.24 	
	- add strict
	
Matthew Curtis
mjdcurtis@ucdavis.edu

Katherine Eriksson
kaeriksson@ucdavis.edu

performs ABE record linkage
*******************************************************************************/
cap program drop abematch
program define abematch
	syntax namelist,  file_A(string) ///
		file_B(string) TIMEVar(name) ///
		[ if_A(passthru) if_B(passthru) TIMEDiff(integer 0) ///
		TIMEBand(integer 2) ///
		keep_A(namelist) keep_B(namelist) suffix_A(string) ///
		suffix_B(string) id_A(namelist) id_B(namelist) ///
		gen_id(namelist) gen_timediff(namelist) ///
		gen_i(namelist) gen_t(namelist) save(string) Replace Clear ///
		unique_file(passthru) unique_match(passthru) ///
		unique_f(passthru) unique_m(passthru) Strict] 
	


	qui {
	
	
	* clear
	
	if "`clear'"!=""{
		clear
	}
	
	if "`if_A'"!=""{
		local if_A = subinstr("`if_A'","if_A(","",.)
		local len = length("`if_A'")
		local len = `len'-1
		local if_A = substr("`if_A'",1,`len')
		noi di "`if_A'"
	}
	else {
		local if_A = "1"
	}
	
	
	if "`if_B'"!=""{
		local if_B = subinstr("`if_B'","if_B(","",.)
		local len = length("`if_B'")
		local len = `len'-1
		local if_B = substr("`if_B'",1,`len')
		noi di "`if_B'"
		
	}
	else {
		local if_B = "1"
	}
	

	* see if replace file
	local replace_save = "`replace'"
	
	
	* save existing data
	local preserved = 0
	if _N>0 {
		if "`save'"==""{
			noi di as error "please clear data or provide output file name"
			exit 1
		}
		
		* if I save the file I need to drop all tempvars
		* so check if user attempts to keep tempvars
		local error_flag = 0
		foreach var in `keep_A' `keep_B' `id_A' `id_B' `gen_id' `gen_timediff' ///
			`gen_i' `gen_t'  {
				local istemp = substr("`var'",1,2)
				if "`istemp'" == "__"{
					noi di as error "please don't use names starting in __ as they appear to be tempvars"
					local error_flag = 1
					continue, break
				}
		}
		if `error_flag' == 1{
			exit 1
		}

		
		local preserved = 1
		tempfile preserved_data
		save `preserved_data'
	}
	* I try to save files to make sure file names are ok
	* can't save empty files so make one var
	else{
		tempvar temp
		gen `temp' = 1
	
	}
	
	* check if I can save the output	
	if "`save'"!="" & "`replace_save'" == ""{
		save `save'
	}
	if "`save'"!="" & "`replace_save'" != ""{
		save `save',replace
	}
	
	cap drop `temp'
	
	/* awkward way to abbreviation  */
	if "`gen_i'"!=""{
		local gen_id = "`gen_i'"
	}
	if "`gen_t'"!=""{
		local gen_timediff = "`gen_t'"
	}

	if "`unique_f'"!=""{
		local unique_file "`unique_f'"
	}
	if "`unique_m'"!=""{
		local unique_match "`unique_m'"
	}

	
	/* set up unique match bands */

	* parse the unique_match command 
	if "`unique_m'"!=""{
		local unique_match = subinstr("`unique_match'","unique_m(","",.)
		local unique_match = subinstr("`unique_match'",")","",.)
	}
	else{
		local unique_match = subinstr("`unique_match'","unique_match(","",.)
		local unique_match = subinstr("`unique_match'",")","",.)
	}
	

	tokenize `unique_match'

	
	if "`3'"!=""{
		noi di as error "Please provide a name stub and an integer for unique"
		exit 1
	}
	
	
	local uniqueband_match = `timeband'
	* see if interger provided in part one or two
	* dumb way to see if interger provided
	
	cap di `1'/1
	
	* if you provide one thing it should be an integer
	if _rc == 0 & "`2'"==""{
		if `1'>0{	
			local uniqueband_match = `1'
		}
		local uniquestub_match = "unique_match"
	}

	* if you provide two, the first is a stub
	else {
		cap di `2'/1
		if _rc != 0 & "`1'"!=""{
			noi di as error "Please follow the name stub with an integer"
			exit 1
		}
		cap di `2'/1
		if _rc == 0 & "`1'"!=""{
			if `2'>0{	
				local uniqueband_match = `2'
			}
		}
		local uniquestub_match = "`1'"
	}
	
	* try to generate unique flags
	if "`1'"!=""{
		forval y = 1/`uniqueband_match'{
			gen `uniquestub_match'`y' = .
		}
	}
	
		
	/* set up unique file bands */

	* parse the unique_file command 
	if "`unique_f'"!=""{
		local unique_file = subinstr("`unique_file'","unique_f(","",.)
		local unique_file = subinstr("`unique_file'",")","",.)
	}
	else{
		local unique_file = subinstr("`unique_file'","unique_file(","",.)
		local unique_file = subinstr("`unique_file'",")","",.)
	}
	
	
	tokenize `unique_file'

	
	if "`3'"!=""{
		noi di as error "Please provide a name stub and an integer for unique"
		exit 1
	}
	
	
	local uniqueband_file = `timeband'
	* see if interger provided in part one or two
	* dumb way to see if interger provided
	
	cap di `1'/1
	
	* if you provide one thing it should be an integer
	if _rc == 0 & "`2'"==""{
		if `1'>0{	
			local uniqueband_file = `1'
		}
		local uniquestub_file = "unique_file"
	}

	* if you provide two, the first is a stub
	else {
		cap di `2'/1
		if _rc != 0 & "`1'"!=""{
			noi di as error "Please follow the name stub with an integer"
			exit 1
		}
		cap di `2'/1
		if _rc == 0 & "`1'"!=""{
			if `2'>0{	
				local uniqueband_file = `2'
			}
		}
		local uniquestub_file = "`1'"
	}
	
	* try to generate unique flags
	if "`1'"!=""{
		forval y = 1/`uniqueband_file'{
			gen `uniquestub_file'`y' = .
		}
	}
	
	* match vars
	
	
	
	local match_vars = "`namelist'"	
	if "`suffix_A'"==""{
		local suffix_A = "A"
	}
	if "`suffix_B'"==""{
		local suffix_B = "B"
	}

	
	/* make sure the right number of gen_id options */
	if "`gen_id'"!=""{
		local length: list sizeof gen_id
		if `length' != 2{
			noi di as error "please provide 2 names for gen_id"
			exit 1
		}
	}
	local file_n = 1
	foreach name in `gen_id' {
		if `file_n' == 1{
			local gen_id_A = "`name'"
		
		}
		else {
			local gen_id_B = "`name'"
		}
		local file_n = `file_n'+1	

	}
	if "`gen_timediff'"==""{
		local gen_timediff = "timediff_A timediff_B"
	}	
	local length: list sizeof gen_timediff
	if `length' != 2{
		noi di as error "please provide 2 names for gen_timediff"
		exit 1
	}
	local file_n = 1
	foreach name in `gen_timediff' {
		if `file_n' == 1{
			local gen_timediff_A = "`name'"
		
		}
		else {
			local gen_timediff_B = "`name'"
		}
		local file_n = `file_n'+1	
	}

	
		
	
	
	/* make sure there are no naming conflicts */
	local error_flag = 0
	foreach keep in `match_vars' `keep_A' `keep_B' `id_A' `id_B'{
		foreach replace in `gen_id' `gen_timediff' {
			if "`keep'"=="`replace'"{
				noi di as error "`keep' is a default output variable. Please use the gen options."
				local error_flag = 1
				continue, break
			}

		}
		if `error_flag'==1{
			continue, break
		}
	}
	if `error_flag'==1{
		exit 1
	}
	
	
	
	/* load file A */
	use "`file_A'", clear
	keep if `if_A'
	
	keep `match_vars' `timevar' `id_A' 

	tempvar File_A unique_all
	gen `File_A' = 1
	
	/* unique ordering */
	tempvar nA
	sort `match_vars' `timevar', stable
	gen `nA' = _n
	

	/* gen ID_A var */
	tempvar ID_A
	if "`id_A'"!=""{
		* drop missing ID vars
		foreach idvar in `id_A'{
			cap drop if `idvar' == .
			cap drop if `idvar' == ""
			cap drop if `idvar' == "."
		}
		if _N == 0 {
			noi di as error "File A has no non-missing ID vars."
			exit 1
		}
		egen double `ID_A' = group(`id_A')
		tempvar max_id
		duplicates tag `ID_A', gen(`max_id')
		sum `max_id'
		if r(max)>0{
			noi di as error "File A not uniquely identified by `id_A'."
			exit 1
		}
		
	}
	else {
		gen `ID_A' = `nA'
	}
	/* keep those unique in file A */
	bysort `match_vars' `timevar': egen `unique_all' = sum(`File_A')
	keep if `unique_all'==1
	drop `unique_all'
	
	/* save file A*/
	keep `match_vars' `timevar' `File_A' `ID_A' `nA' `ID_A'  `id_A' 
	tempfile tempA
	save `tempA',replace	
	
	/* add file B*/
	use "`file_B'"
	keep if `if_B'

	/* unique ordering */
	tempvar nB
	sort `match_vars' `timevar', stable
	gen `nB' = _n
	
	/* gen ID_B var */
	tempvar ID_B
	if "`id_B'"!=""{
		* drop missing ID vars
		foreach idvar in `id_B'{
			cap drop if `idvar' == .
			cap drop if `idvar' == ""
			cap drop if `idvar' == "."
		}
		if _N == 0 {
			noi di as error "File B has no non-missing ID vars."
			exit 1
		}
		egen double `ID_B' = group(`id_B') 
		tempvar max_id
		duplicates tag `ID_B', gen(`max_id')
		sum `max_id'
		if r(max)>0{
			noi di as error "File B not uniquely identified by `id_B'."
			exit 1
		}
	}
	else {
		gen `ID_B' = `nB'
	}

	/* append using file A */
	keep `match_vars' `timevar' `ID_B' `nB' `id_B'
	tempvar File_B
	append using `tempA'
	gen `File_B'=1 if `File_A'==.
	replace `File_B'=0 if `File_A'==1
	replace `File_A'=0 if `File_B'==1
	
	/* adjust time vars */
	replace `timevar' = `timevar' - `timediff' if `File_B'==1
	
	/* look for matches */
	tempvar matched_at_A
	gen `matched_at_A' = .
	
	tempvar exactmatch1 count_A count_B
	gen `exactmatch1'=0

	bysort `namelist' `timevar': egen `count_A' = sum(`File_A')
	bysort `namelist' `timevar': egen `count_B' = sum(`File_B')

	* unique file
	if "`uniquestub_file'"!=""{
		sort `File_A' `match_vars' `timevar' 
		forval x = 1/`uniqueband_file'{
			gen `uniquestub_file'`x' = 0
			bysort `File_A' `match_vars' (`timevar') : replace `uniquestub_file'`x'=1 if `timevar'-`x'<= `timevar'[_n-1] & _n>1
			bysort `File_A' `match_vars' (`timevar') : replace `uniquestub_file'`x'=1 if `timevar'+ `x' >= `timevar'[_n+1] & _n < _N
			replace `uniquestub_file'`x' = 1 - `uniquestub_file'`x'
		}
	}

	
	/* drop if more than one match */
	
	* e.g. 1 to 1
	replace `exactmatch1'=1 if `count_A'==1 & `count_B'==1
	
	* throw out 1 to 2+, but keep 2+ to 1+ in case they are an issue later
	drop if `count_B'>1  & `count_A'==1  & `File_A'==1
	drop `count_B' `count_A' 

	/* tag individuals with 1 match */
	replace `matched_at_A' = 0 if `exactmatch1' == 1 & `File_A' == 1

	if "`uniquestub_match'"!=""{
		bysort `match_vars' `timevar' : egen  `uniquestub_match'0 = sum(`File_B')
	}
	
	if `timeband'>0{
		tempvar already 
		gen `already' = `exactmatch1'
		forval x = 1/`timeband' {
		
			if "`strict'"!=""{
				replace `already' = 1
			}
			
			
			/* generate a variable for +x/-x for the timevar */
			tempvar timevar_m`x' timevar_p`x'
			gen `timevar_m`x'' =`timevar'-`x'
			gen `timevar_p`x'' = `timevar'+`x'
			replace `timevar_m`x'' = `timevar' if `File_B'==1
			replace `timevar_p`x'' = `timevar' if `File_B'==1
			
			tempvar unmatched_A
			gen `unmatched_A' = `File_A' == 1 & `already' == 0
			
			
			/* look for matches with -x */
			tempvar existing_matches mcount_A mcount_B exactmatch1_m`x' 
			bysort `match_vars' `timevar_m`x'': egen `mcount_A' = sum(`unmatched_A')
			bysort `match_vars' `timevar_m`x'': egen `mcount_B' = sum(`File_B')
			
			
			
			* if I have a match before, don't match me now!
			bysort `match_vars' `timevar_m`x'': egen `existing_matches' = sum(`already')
			
			/* if not already matched, throw out 1 to 2+ but keep 2+ to 1+*/
			gen `exactmatch1_m`x''=1 if `mcount_A'==1 & `mcount_B'==1 & `existing_matches'==0
			drop if `mcount_B'>1 & `mcount_A'==1  & `File_A'==1 & `existing_matches'==0
			drop `existing_matches'
			
			/* look for a match with +x */
			tempvar existing_matches pcount_A pcount_B exactmatch1_p`x'
			bysort `match_vars' `timevar_p`x'' : egen `pcount_A' = sum(`unmatched_A')
			bysort `match_vars' `timevar_p`x'' : egen `pcount_B' = sum(`File_B')
			bysort `match_vars' `timevar_p`x'' : egen `existing_matches' = sum(`already')

			/* if not already matched, throw out 1 to 2+ but keep 2+ to 1+*/
			gen `exactmatch1_p`x''=1 if `pcount_A'==1 & `pcount_B'==1 & `existing_matches'==0
			drop if `pcount_B'>1 & `pcount_A'==1  & `File_A'==1 & `existing_matches'==0
			drop `existing_matches'
			
			/* clean up */
			replace `exactmatch1_m`x'' = 0 if `exactmatch1_m`x''==.
			replace `exactmatch1_p`x'' = 0 if `exactmatch1_p`x''==.
			
			replace `matched_at_A' = `x' if `exactmatch1_p`x'' == 1 & ///
				`exactmatch1_m`x''==0 & `already'!=1 &`File_A' == 1
				
			replace `matched_at_A' = -`x' if `exactmatch1_m`x'' == 1 & ///
				`exactmatch1_p`x''==0 & `already'!=1 &`File_A' == 1
			
			replace `already'=1 if `exactmatch1_p`x''==1 & `exactmatch1_m`x''==0
			replace `already'=1 if `exactmatch1_p`x''==0 & `exactmatch1_m`x''==1
			
			* set up unique within exactly +/- x
			if "`uniquestub_match'"!=""{
				gen `uniquestub_match'`x' = `pcount_B' + `mcount_B'
				replace `uniquestub_match'`x' = . if `File_A' != 1
			}	
			drop `pcount_B' `pcount_A' `mcount_B' `mcount_A' `unmatched_A'
		}
	}
	/* keep matched */
	drop if `matched_at_A' ==. & `File_A' == 1

	* generate unique flags if uniqueband>timeband
	if "`uniquestub_match'"!=""&`uniqueband_match'>`timeband'{
		local start = `timeband'+1
		forval y = `start' / `uniqueband_match'{
			tempvar unique_p unique_m utimevar_m`y' utimevar_p`y'
			gen `utimevar_m`y'' =`timevar'-`y'
			gen `utimevar_p`y'' = `timevar'+`y'
			replace `utimevar_m`y'' = `timevar' if `File_B'==1
			replace `utimevar_p`y'' = `timevar' if `File_B'==1
			bysort `match_vars' `utimevar_p`y'' : egen `unique_p' = sum(`File_B')
			bysort `match_vars' `utimevar_m`y'' : egen `unique_m' = sum(`File_B')
			gen `uniquestub_match'`y' = `unique_m' + `unique_p'
			replace `uniquestub_match'`y' = . if `File_A' != 1
		}
	}

	* generate up unique within up to +/- x
	if "`uniquestub_match'"!=""{
		forval y = 1 / `uniqueband_match'{
			local z = `y'-1
			replace `uniquestub_match'`y' =  `uniquestub_match'`y'+`uniquestub_match'`z'
			
		}
		forval y = 1 / `uniqueband_match'{
			replace `uniquestub_match'`y' =  `uniquestub_match'`y'<=1 if `File_A' == 1
		}	
		drop `uniquestub_match'0
	}
	
	/* keep matched */
	drop if `matched_at_A' ==. & `File_A' == 1
	
	
	/* generate an adjusted timevar */
	tempvar timevar_keep1 matched
	gen `timevar_keep1' = `timevar' if `File_B'
	replace `timevar_keep1'=`timevar' +  `matched_at_A' if `File_A'==1 


	/* make sure there are only two individuals per matched pair */
	tempvar `count_A' `count_B'
	bysort `match_vars' `timevar_keep1': egen `count_A'=sum(`File_A')
	bysort `match_vars' `timevar_keep1': egen `count_B'=sum(`File_B')
	keep if `count_A'==1 & `count_B'==1
	drop  `count_A' `count_B'

	
	
	/* save forward direction */
	tempfile T1
	local N1 = _N
	save `T1', replace

	
/*******************************************************************************/
	/* GO THE OTHER WAY*/
	/* load file B */
	use "`file_B'", clear
	keep if `if_B'
	keep `match_vars' `timevar'  `id_B'

	tempvar unique_all
	gen `File_B' = 1

	/* unique ordering */
	sort `match_vars' `timevar', stable
	gen `nB' = _n
	
	/* gen ID_B var */
	/* nb.: at this point error would have happened if not unique! */
	if "`id_B'"!=""{
		* drop missing ID vars
		foreach idvar in `id_B'{
			cap drop if `idvar' == .
			cap drop if `idvar' == ""
			cap drop if `idvar' == "."
		}
		if _N == 0 {
			noi di as error "File B has no non-missing ID vars."
			exit 1
		}
		egen double `ID_B' = group(`id_B')
	}
	else {
		gen `ID_B' = `nB'
	}
	

	/* keep those unique in file B */
	bysort `match_vars' `timevar': egen `unique_all' = sum(`File_B')
	keep if `unique_all'==1
	drop `unique_all'
	
	/* save file B*/
	keep `match_vars' `timevar' `File_B' `ID_B' `nB' `ID_B'  `id_B' 
	tempfile tempB
	save `tempB',replace	
	
	/* add file A*/
	use "`file_A'"
	keep if `if_A'
	
	/* unique ordering */
	tempvar nA
	sort `match_vars' `timevar', stable
	gen `nA' = _n
	
	/* gen ID_A var */
	/* nb.: at this point error would have happened if not unique! */
	if "`id_A'"!=""{
		* drop missing ID vars
		foreach idvar in `id_A'{
			cap drop if `idvar' == .
			cap drop if `idvar' == ""
			cap drop if `idvar' == "."
		}
		if _N == 0 {
			noi di as error "File A has no non-missing ID vars."
			exit 1
		}
		egen double `ID_A' = group(`id_A')
	}
	else {
		gen `ID_A' = `nA'
	}

	/* append using file B */
	keep `match_vars' `timevar' `ID_A' `nA' `ID_A' `id_A'
	append using `tempB'

	gen `File_A'=1 if `File_B'==.
	replace `File_A'=0 if `File_B'==1
	replace `File_B'=0 if `File_A'==1

	/* adjust time vars */
	replace `timevar' = `timevar' - `timediff' if `File_B'==1

	/* look for matches */
	tempvar matched_at_B
	gen `matched_at_B' = .
	
	tempvar exactmatch2 count_A count_B
	gen `exactmatch2'=0

	bysort `namelist' `timevar': egen `count_A' = sum(`File_A')
	bysort `namelist' `timevar': egen `count_B' = sum(`File_B')

	* unique file
	if "`uniquestub_file'"!=""{
		sort `File_A' `match_vars' `timevar' 
		forval x = 1/`uniqueband_file'{
			gen `uniquestub_file'`x' = 0
			bysort `File_A' `match_vars' (`timevar') : replace `uniquestub_file'`x'=1 if `timevar'-`x'<= `timevar'[_n-1] & _n>1
			bysort `File_A' `match_vars' (`timevar') : replace `uniquestub_file'`x'=1 if `timevar'+ `x' >= `timevar'[_n+1] & _n < _N
			replace `uniquestub_file'`x' = 1 - `uniquestub_file'`x'
		}
	}

	
	/* drop if more than one match */
	
	* e.g. 1 to 1
	replace `exactmatch2'=1 if `count_A'==1 & `count_B'==1
	
	* throw out 1 to 2+, but keep 2+ to 1+ in case they are an issue later
	drop if `count_A'>1  & `count_B'==1  & `File_B'==1
	drop `count_B' `count_A' 

	/* tag individuals with 1 match */
	replace `matched_at_B' = 0 if `exactmatch2' == 1 & `File_B' == 1
	
	if "`uniquestub_match'"!=""{
		bysort `match_vars' `timevar' : egen  `uniquestub_match'0 = sum(`File_A')
	}
	if `timeband'>0{
		tempvar already
		gen `already' = `exactmatch2'
		forval x = 1/`timeband' {
		
			if "`strict'"!=""{
				replace `already' = 1
			}
			tempvar unmatched_B
			gen `unmatched_B' = `File_B' == 1 & `already' == 0

			/* generate a variable for +x/-x for the timevar */
			tempvar timevar_m`x' timevar_p`x'
			gen `timevar_m`x'' =`timevar'-`x'
			gen `timevar_p`x'' = `timevar'+`x'
			replace `timevar_m`x'' = `timevar' if `File_A'==1
			replace `timevar_p`x'' = `timevar' if `File_A'==1
			
			/* look for matches with -x */
			tempvar existing_matches mcount_A mcount_B exactmatch2_m`x'
			bysort `match_vars' `timevar_m`x'': egen `mcount_A' = sum(`File_A')
			bysort `match_vars' `timevar_m`x'': egen `mcount_B' = sum(`unmatched_B')
			* if I have a match before, don't match me now!
			bysort `match_vars' `timevar_m`x'': egen `existing_matches' = sum(`already')
			
			/* if not already matched, throw out 1 to 2+ but keep 2+ to 1+*/
			gen `exactmatch2_m`x''=1 if `mcount_A'==1 & `mcount_B'==1 & `existing_matches'==0
			drop if `mcount_A'>1 & `mcount_B'==1  & `File_B'==1 & `existing_matches'==0
			drop `existing_matches'
			
			/* look for a match with +x */
			tempvar existing_matches pcount_A pcount_B exactmatch2_p`x'
			bysort `match_vars' `timevar_p`x'' : egen `pcount_A' = sum(`File_A')
			bysort `match_vars' `timevar_p`x'' : egen `pcount_B' = sum(`unmatched_B')
			bysort `match_vars' `timevar_p`x'' : egen `existing_matches' = sum(`already')

			/* if not already matched, throw out 1 to 2+ but keep 2+ to 1+*/
			gen `exactmatch2_p`x''=1 if `pcount_A'==1 & `pcount_B'==1 & `existing_matches'==0
			drop if `pcount_A'>1 & `pcount_B'==1  & `File_B'==1 & `existing_matches'==0
			drop `existing_matches'
			
			/* clean up */
			replace `exactmatch2_m`x'' = 0 if `exactmatch2_m`x''==.
			replace `exactmatch2_p`x'' = 0 if `exactmatch2_p`x''==.
			
			replace `matched_at_B' = `x' if `exactmatch2_p`x'' == 1 & ///
				`exactmatch2_m`x''==0 & `already'!=1 &`File_B' == 1
				
			replace `matched_at_B' = -`x' if `exactmatch2_m`x'' == 1 & ///
				`exactmatch2_p`x''==0 & `already'!=1 &`File_B' == 1
				
			replace `already'=1 if `exactmatch2_p`x''==1 & `exactmatch2_m`x''==0
			replace `already'=1 if `exactmatch2_p`x''==0 & `exactmatch2_m`x''==1
		
			
			* set up unique within exactly +/- x
			
			if "`uniquestub_match'"!=""{
				gen `uniquestub_match'`x' = `pcount_A' + `mcount_A'
				replace `uniquestub_match'`x' = . if `File_B' != 1
			}	
			
			drop `pcount_B' `pcount_A' `mcount_B' `mcount_A' `unmatched_B'
		}
	}
	/* keep matched */
	drop if `matched_at_B' ==. & `File_B' == 1
	
	* generate unique flags if uniqueband>timeband
	if "`uniquestub_match'"!=""&`uniqueband_match'>`timeband'{
		local start = `timeband'+1
		forval y = `start' / `uniqueband_match'{
			tempvar unique_p unique_m utimevar_m`y' utimevar_p`y'
			gen `utimevar_m`y'' =`timevar'-`y'
			gen `utimevar_p`y'' = `timevar'+`y'
			replace `utimevar_m`y'' = `timevar' if `File_A'==1
			replace `utimevar_p`y'' = `timevar' if `File_A'==1
			bysort `match_vars' `utimevar_p`y'' : egen `unique_p' = sum(`File_A')
			bysort `match_vars' `utimevar_m`y'' : egen `unique_m' = sum(`File_A')
			gen `uniquestub_match'`y' = `unique_m' + `unique_p'
			replace `uniquestub_match'`y' = . if `File_B' != 1
		}		
	}
	
	* generate up unique within up to +/- x
	if "`uniquestub_match'"!=""{
		forval y = 1 / `uniqueband_match'{
			local z = `y'-1
			replace `uniquestub_match'`y' =  `uniquestub_match'`y'+`uniquestub_match'`z'
			
		}
		forval y = 1 / `uniqueband_match'{
			replace `uniquestub_match'`y' =  `uniquestub_match'`y'<=1 if `File_B' == 1
			
		}
		drop `uniquestub_match'0	
	}
	
	
	/* keep matched */
	drop if `matched_at_B' ==. & `File_B' == 1
	
	
	/* generate an adjusted timevar */
	tempvar timevar_keep2 matched
	gen `timevar_keep2' = `timevar' if `File_A'
	replace `timevar_keep2'=`timevar' +  `matched_at_B' if `File_B'==1 

	
	/* make sure there are only two individuals per matched pair */
	tempvar `count_A' `count_B'
	bysort `match_vars' `timevar_keep2': egen `count_A'=sum(`File_A')
	bysort `match_vars' `timevar_keep2': egen `count_B'=sum(`File_B')
	keep if `count_A'==1 & `count_B'==1
	drop  `count_A' `count_B'

	
	
	/* save forward direction */
	tempfile T2
	local N2 = _N
	save `T2', replace

    /***************************************************************************/
	/* Find intersection*/	
	
	
	if `N1' == 0 | `N2' == 0 {
		noi di as error "No successful matches!"
		noi di as result ""
	}
	else{
		
		/* fix IDs in T1*/
		use `T1'

		sort `match_vars' `timevar_keep1' `File_A'	
		replace `ID_A' = `ID_A'[_n+1] if `File_B'==1
		replace `ID_B' = `ID_B'[_n-1] if `File_A'==1
		
		if "`uniquestub_match'"!=""{
			forval y = 1 / `uniqueband_match'{
				tempvar min
				bysort `ID_A': egen `min' = max(`uniquestub_match'`y')
				*replace `uniquestub'`y' =  `min'
				tempvar `uniquestub_match'`y'A
				gen ``uniquestub_match'`y'A' =  `min'
				drop `uniquestub_match'`y'
			}
		}
		if "`uniquestub_file'"!=""{
			forval y = 1 / `uniqueband_file'{
				tempvar min
				bysort `ID_A': egen `min' = min(`uniquestub_file'`y')
				*replace `uniquestub'`y' =  `max'
				tempvar `uniquestub_file'`y'A
				gen ``uniquestub_file'`y'A' =  `min'
				drop `uniquestub_file'`y'
			}
		}


		tempfile temp
		save `temp', replace

		
		clear
		
		/* fix IDs in T2*/
		use `T2'
		sort `match_vars' `timevar_keep2' `File_A'	
		replace `ID_A' = `ID_A'[_n+1] if `File_B'==1
		replace `ID_B' = `ID_B'[_n-1] if `File_A'==1
		
		if "`uniquestub_match'"!=""{
			forval y = 1 / `uniqueband_match'{
				tempvar min
				bysort `ID_B': egen `min' = min(`uniquestub_match'`y')
				replace `uniquestub_match'`y' =  `min'
			}
		}
		if "`uniquestub_file'"!=""{
			forval y = 1 / `uniqueband_file'{
				tempvar min
				bysort `ID_B': egen `min' = min(`uniquestub_file'`y')
				replace `uniquestub_file'`y' =  `min'
			}
		}
		
		/* merge */
		tempvar merge
		merge 1:1 `ID_A' `ID_B' `File_A' using `temp',  gen(`merge')
		keep if `merge' == 3
		
		
		
		if _N == 0{
			noi di as error "No successful matches!"
			noi di as result ""
		}
		else {
			/* output files */
			preserve
			keep if `File_A' == 1
			gen `gen_timediff_A' = `matched_at_A'
			save `T1',replace
			restore
			preserve
			keep if `File_B' == 1
			gen `gen_timediff_B' = `matched_at_B'
			save `T2',replace
			restore

			/* merge in keep A vars */	
			use "`file_A'", clear
			keep if `if_A'
			keep `match_vars' `timevar' `keep_A' `id_A'
			sort `match_vars' `timevar', stable
			gen `nA' = _n
			if "`id_A'"!=""{
				foreach idvar in `id_A'{
					cap drop if `idvar' == .
					cap drop if `idvar' == ""
					cap drop if `idvar' == "."
				}
				egen double `ID_A' = group(`id_A') 
			}
			else {
				gen `ID_A' = `nA'
			}
			tempvar merge2
			merge 1:1 `ID_A' using `T1', keep(3) gen(`merge2')
			if "`keep_A'"!=""| "`id_A'"!=""{
				foreach var of varlist `keep_A'  `id_A'{
					ren `var' `var'_`suffix_A'
				}
			}
			
			save `temp',replace

			/* merge in keep B vars */	
			use "`file_B'", clear
			keep if `if_B'
			keep `match_vars' `timevar' `keep_B' `id_B'
			sort `match_vars' `timevar', stable
			gen `nB' = _n
			if "`id_B'"!=""{
				foreach idvar in `id_B'{
					cap drop if `idvar' == .
					cap drop if `idvar' == ""
					cap drop if `idvar' == "."
				}
				egen double `ID_B' = group(`id_B') 
			}
			else {
				gen `ID_B' = `nB'
			}
			tempvar merge3
			merge 1:1 `ID_B' using `T2', keep(3) gen(`merge3')
			if "`keep_B'"!="" | "`id_B'"!=""{
				foreach var of varlist `keep_B' `id_B'{
					ren `var' `var'_`suffix_B'
				}
			}
			
			drop `timevar'
			tempvar merge4
			merge 1:1 `ID_A' using `temp', keep(3) gen(`merge4')
			
			/* generate new vars */

			
			if "`gen_id'"!=""{
				gen `gen_id_A' = `ID_A'
				gen `gen_id_B' = `ID_B'
			}
			
			
			* fix the unique vars to be the minimum of the one from A and from B
			if "`uniquestub_match'"!=""{
				forval y = 1 / `uniqueband_match'{
					replace `uniquestub_match'`y' =  ``uniquestub_match'`y'A' if ``uniquestub_match'`y'A' <`uniquestub_match'`y' 
				}
			}
			if "`uniquestub_file'"!=""{
				forval y = 1 / `uniqueband_file'{
					replace `uniquestub_file'`y' =  ``uniquestub_file'`y'A' if ``uniquestub_file'`y'A' <`uniquestub_file'`y' 
				}
			}
		}
	}
	if "`save'"!="" & "`replace_save'" == ""{
		cap	drop __*
		save `save'
	}
	if "`save'"!="" & "`replace_save'" != ""{
		cap drop __*
		save `save',replace
	}
	if `preserved' == 1  {
		use `preserved_data',clear
	}

	

}
end

