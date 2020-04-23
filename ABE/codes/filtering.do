set obs `=_N+1'																	//Add observation at end, as jarowinkler fails if there are zero observations
gen age_diff = abs($timediff - abs((Bage - Aage)))									//Generate distance between expected age in data set B and A 
keep if age_diff <= $age_band | _n==_N											//We look for potential matches within +- 5 years of birth when searching across dataset, but within +-2 years when finding within data set distances. 
foreach name in "f_name_cleaned" "l_name_cleaned" {												//Loop through first and last name
	jarowinkler A`name' B`name', gen(jw_`name')									//Construct jarowinkler string similarity for name
	replace jw_`name' = 1-jw_`name'												//Flip jarowinkler direction so distance, 0 represents perfect fit and higher valeus are worse
	keep if jw_`name'<=0.1 | _n==_N												//Keep only potential pairs with sufficiently close names (<= 0.1)
}
drop if _n==_N																	//Drop the extra observation we added to the end
