
set obs `=_N+1'																	//Add observation at end, as jarowinkler fails if there are zero observations
gen age_diff = abs($timediff - abs((Bage - Aage)))												//Generate distance between expected age 
keep if age_diff <=5 | _n==_N													//Require age difference to be no more than 3 years
foreach suff in "f_name" "l_name" {											//Loop through first and last name
	jarowinkler A`suff' B`suff', gen(jw_`suff')									//Construct jarowinkler string similarity for name
	replace jw_`suff' = 1-jw_`suff'												//Flip jarowinkler direction so distance, 0 represents perfect fit and higher valeus are worse
	
	* Rounding to 8 decimals
	replace jw_`suff' = round(jw_`suff', 0.00000001)
	
	* Categories
	gen jw_`suff'_cat = .
	replace jw_`suff'_cat = 1*(jw_`suff'<=0.067)+2*(jw_`suff'>0.067 & jw_`suff'<=0.12)+3*(jw_`suff'>0.12 & jw_`suff'<=0.25)+4*(jw_`suff'>0.25)
	
}

drop if _n==_N																	//Drop the extra observation we added to the end
