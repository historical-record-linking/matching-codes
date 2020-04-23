{smcl}
{* *! version 0.24 7nov2018}{...}
{viewerjumpto "Syntax" "abematch##syntax"}{...}
{viewerjumpto "Description" "abematch##description"}{...}
{viewerjumpto "Options" "abematch##options"}{...}
{viewerjumpto "Examples" "abematch##examples"}{...}
{viewerjumpto "Author" "abematch##authors"}{...}
{viewerjumpto "Acknowledgments" "abematch##acknowledgments"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{hi:abematch} {hline 2}}Abramitzky, Boustan, and Eriksson record linkage{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{opt abematch} {it:namelist}{cmd:,} {opt file_A}({it:filename}) {opt file_B}({it:filename}) {opt timev:ar}({it:name}) [{it:options}]


{pstd}
where {it:namelist} is a list of match variables; these variables must match exactly between files

{synoptset 30 tabbed}{...}
{synopthdr :options}
{synoptline}

{syntab:Input}
{synopt :{opt file_A}({it:string})}read input from dta file {it:string} as file A{p_end}
{synopt :{opt file_B}({it:string})}read input from dta file {it:string} as file B{p_end}
{synopt :{opt timev:ar}({it:name})}name of time variable in both file A and file B{p_end}
{synopt :{opt timed:iff}({it:integer})}offset in time between file A and file B (default is 0){p_end}
{synopt :{opt id_A}({it:namelist})}names of id variables in file A (default is {bf:_n}){p_end}
{synopt :{opt id_B}({it:namelist})}names of id variables in file B (default is {bf:_n}){p_end}
{synopt :{opt if_A}({it:exp})}keep data from file A if {it:exp} is true{p_end}
{synopt :{opt if_B}({it:exp})}keep data from file B if {it:exp} is true{p_end}

{syntab:Match criteria}
{synopt :{opt timeb:and}({it:integer})}iteratively match over age bands of up to +/- {it:integer} (default is 2){p_end}
{synopt :{opt unique_m:atch}({it:stub integer})}generate flags using {it:stub} ("unique_match" by default) indicating unique matches within intervals up to +/- {it:integer} {p_end}
{synopt :{opt unique_f:ile}({it:stub integer})}generate flags using {it:stub} ("unique_file" by default) indicating individuals unique in their file within intervals up to +/- {it:integer} {p_end}
{synopt :{opt s:trict}}disqualify matches if there is another potential candidate that was matched in a previous iteration {p_end}

{syntab:Output}
{synopt :{opt save}({it:string})}write output to dta file {it:string}{p_end}
{synopt :{opt r:eplace}}overwrite existing file{p_end}
{synopt :{opt c:lear}}clear existing data{p_end}
{synopt :{opt keep_A}({it:namelist})}list of auxiliary variables in file A to keep{p_end}
{synopt :{opt keep_B}({it:namelist})}list of auxiliary variables in file B to keep{p_end}
{synopt :{opt gen_i:d}({it:name})}name of new id variable to create; nothing by default {p_end}
{synopt :{opt gen_t:imediff}({it:namelist})}name of variables created equal to the time adjustment made; {it:timediff_A} and {it:timediff_B} by default {p_end}
{synopt :{opt suffix_A}({it:stub})}use {it:stub} as a suffix for all variables from file A (default is {it:A}){p_end}
{synopt :{opt suffix_B}({it:stub})}use {it:stub} as a suffix for all variables from file B (default is {it:B}){p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:abematch} is a fully automated method for linking datasets. Please read the below sources for a more detailed description of the algorithm. 

{pstd}
For every observation in file A, the algorithm searches for a unique match in file B in terms of the variables in {it:namelist} and {opt timevar}. 

{pstd}
If no match is found, the algorithm searches for a unique match in file B with {opt timevar} exactly 1 unit higher or lower. This process iterates until it reaches exactly {opt timeband} units higher or lower (default 2).

{pstd}
The algorithm then finds matches from file B in file A. The final set of matched data is the intersection of the sets of matches from A to B and from B to A. 


{marker options}{...}
{title:Options}

{dlgtab:Input}

{phang}
{opt file_A}({it:string}) is the name (including path) of the first of the two files you want matched. The order in which files are specified only matters for the {opt timediff} option

{phang}
{opt file_B}({it:string}) is the name (including path) of the second of the two files you want matched. The order in which files are specified only matters for the {opt timediff} option

{phang}
{opt timevar}({it:name}) is the name of a variable in both files that bands will be constructed around; the output will include the timevar from A

{phang}
{opt timediff} is an integer that will be subtracted from the time variable in file B to match file A; for example, if file A is the 1910 census and file B is the 1920 census, {opt timediff} should be set to 10

{phang}
{opt id_A}({it:namelist}) is a list of variables that together uniquely identify variables in file A; if unspecified, {cmd:abematch} will attempt to use {bf:_n} instead

{phang}
{opt id_B}({it:namelist}) is a list of variables that together uniquely identify variables in file B; if unspecified, {cmd:abematch} will attempt to use {bf:_n} instead


{phang}
{opt if_A}({it:exp) will keep data from file A if {it:exp} is true; e.g. {bf:if_A(age<30)} will keep all observations with age<30

{phang}
{opt if_B}({it:exp})  will keep data from file B if {it:exp} is true; e.g. {bf:if_B(age<30)} will keep all observations with age<30

{dlgtab:Match criteria}

{phang}
{opt timeband}({it:integer}) is the maximum number of units higher or lower in {opt timevar} the iterative matching procedure will consider for potential matches

{phang}
{opt unique_match}({it:stub integer}) will create flags for uniqueness of a match within +/- 1,2,...,{it:integer} of {opt timevar}; e.g. {bf: unique_m(flag 2)} will create {bf: flag1 flag2} and {bf: unique_m(1)} will create {bf: unique_match1}

{phang}
{opt unique_file}({it:stub integer}) will create flags for uniqueness of an individual in their file within +/- 1,2,...,{it:integer} of {opt timevar}; same syntax as {opt unique_match}

{phang}
{opt strict} disqualifies matches if there is another potential candidate that was matched in a previous iteration

{phang}
{opt save}({it:string}) is file name, including path, where you want the output saved 

{phang}
{opt replace} will allow {opt save}() to overwrite any existing file

{phang}
{opt clear} clears the current data; if {opt save}() isn't specified then the output remains in the active memory

{phang}
{opt keep_A}({it:namelist}) is a list of variables you wish to keep from file A in the final output that are otherwise not used

{phang}
{opt keep_B}({it:namelist}) is a list of variables you wish to keep from file B in the final output that are otherwise not used 

{phang}
{opt gen_id}({it:name}) creates a new variable to store a unique ID number based on the id_A and id_B

{phang}
{opt gen_timediff}({it:namelist}) creates new time variables equal to the adjustments done to {opt timevar} in the matching procedure (e.g. if the adjusted {opt timevar} is 40 in file A and 41 in file B, they are 1 and -1 respectively)

{phang}
{opt suffix_A}({it:stub}) specifies that all variables in the output file that come from file_A have the suffix {it: _stub}; {bf:_A} is used by default

{phang}
{opt suffix_B}({it:stub}) specifies that all variables in the output file that come from file_B have the suffix {it: _stub}; {bf:_B} is used by default

{marker examples}{...}
{title:Examples}


{pstd}Match all men from a 1900 census to a 1910 census iteratively over age bands of +/-2 years.{p_end}
{phang2}. abematch namefrst namelast, file_A("cens1900") file_B("cens1910") if_A(sex==1) if_B(sex==1) timevar(age) timediff(10) timeband(2) unique_m(unique 5) clear{p_end}

{pstd}Require all matches be unique within 5 years.{p_end}
{phang2}. keep if unique5==1{p_end}

{marker authors}{...}
{title:Authors}

{pstd}Matthew Curtis{p_end}
{pstd}mjdcurtis@ucdavis.edu{p_end}

{pstd}Katherine Eriksson{p_end}
{pstd}kaeriksson@ucdavis.edu {p_end}


{marker acknowledgments}{...}
{title:Acknowledgments}

{pstd} Ran Abramitzky's {browse "https://people.stanford.edu/ranabr/matching-codes":webpage} is an invaluable source of code for and background information on historical record linkage. 


{marker references}{...}
{title:References}

{marker ABE2012}{...}
{phang}
Abramitzky, Ran, Leah Platt Boustan, and Katherine Eriksson. 2012. "Europe's Tired, Poor, Huddled Masses: Self-Selection and Economic Outcomes in the Age of Mass Migration." {it:American Economic Review}, 102 (5): 1832-56.
{p_end}

{marker ABE2014}{...}
{phang}
Abramitzky, Ran, Leah Platt Boustan, and Katherine Eriksson. 2014. "A Nation of Immigrants: Assimilation and Economic Outcomes in the Age of Mass Migration." {it:Journal of Political Economy}, vol. 122, no. 3.
{p_end}

{marker ABE2017}{...}
{phang}
Abramitzky, Ran, Leah Platt Boustan, and Katherine Eriksson. 2017. "To the New World and Back Again: Return Migrants in the Age of Mass Migration." {it:Industrial and Labor Relations Review, Forthcoming}.
{p_end}
