
/* remove any spaces from begining of name */
replace  f_name_cleaned = subinstr(f_name_cleaned," ","",.)
replace  l_name_cleaned = subinstr(l_name_cleaned," ","",.)

gen initial_frst = substr(f_name_cleaned,1,1)											//Create initial of first name
gen initial_last = substr(l_name_cleaned,1,1)											//Create initial of last name


