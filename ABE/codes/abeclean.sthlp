{smcl}
{* *! version 0.23  11nov2018}{...}
{viewerjumpto "Syntax" "abeclean##syntax"}{...}
{viewerjumpto "Description" "abeclean##description"}{...}
{viewerjumpto "Options" "abeclean##options"}{...}
{viewerjumpto "Examples" "abeclean##examples"}{...}
{viewerjumpto "Author" "abeclean##authors"}{...}
{viewerjumpto "Acknowledgments" "abeclean##acknowledgments"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{hi:abeclean} {hline 2}}Data cleaning for Abramitzky, Boustan, and Eriksson record linkage{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{opt abeclean} {it:varlist} [{cmd:,} {it:options}]

{pstd}
where {it:varlist} is one or two string variables
{p_end}

{synoptset 25 tabbed}{...}
{synopthdr :options}
{synoptline}

{syntab:Standardization}
{synopt :{opt no:nysiis}}do not apply NYSIIS{p_end}
{synopt :{opt nick:names}}standardize common nicknames for the first variable in {it:varlist}; requires the option {opt sex}{p_end} 
{synopt :{opt sex}({it:name})}name of a numeric variable coded 1 for male and 2 for female{p_end}
{synopt :{opt oldnick:names}}older nickname crosswalk for males only; rarely used{p_end}

{syntab:Output}
{synopt :{opt gen:erate}({it:namelist})}list of names for new variables{p_end}
{synopt :{opt ini:tial}({it:name})}create a variable for a middle initial{p_end}
{synopt :{opt mid:dle}}keep middle name{p_end}
{synopt :{opt r:eplace}}replace existing {it:varlist} {p_end}


{marker description}{...}
{title:Description}

{pstd}
Recommended name cleaning procedure to be used before {cmd:abematch}. {cmd:nysiis} is a dependency ({bf:ssc install nysiis}).

{pstd}
{cmd:abeclean} prepares one or two string variables, canonically names, to be used to link records. These strings are stripped of special characters, occupational titles, and initials. 

{pstd}
The NYSIIS phonetic algorithm is applied by default; see references or {bf:help nysiis} for a discussion of the algorithm.

{pstd}
If two string variables are provided, the first is interpreted as a first name for nickname cleaning or the creation of middle names / initials. 

{pstd}
If you have both first and last name in one string, put the last word into the last name variable and all others into the first name variable.  

{marker options}{...}
{title:Options}

{dlgtab:Input}

{phang}
{opt nonysis} prevents the names being transformed into NYSIIS phonetic codes

{phang}
{opt nicknames} replaces nicknames in the first string variable provided using a built in dictionary; as the nicknames are sex-specific the sex option must be specified

{phang}
{opt sex}({it:name}) specifies the name of a variable coding an individual's sex; it must be numeric with 1 for male and 2 for female

{phang}
{opt oldnicknames} was a check used by the authors of this package to match old results 

{dlgtab:Output}

{phang}
{opt generate}({it:namelist}) a list of names for new variables created with the cleaned variable(s) (in order) and then the NYSIIS encoded variable(s) (in order); by default the suffix {it:_cleaned} and {it:_nysiis} are added to the variable(s)

{phang}
{opt middle} keeps middle names; generate option be adjusted accordingly; middle names will be generated only from the first string variable provided


{phang}
{opt initial}({it:name}) a name for a new variable created for a middle initial; middle initials will be generated only from the first string variable provided

{marker examples}{...}
{title:Examples}


{pstd}Clean first and last names from a 1900 census using the nickname crosswalk and applying NYSIIS.{p_end}
{phang2}. abeclean namefrst namelast,  generate(first last first_n last_n) nicknames sex(sex)

{pstd}Clean first, middle, and last names from a 1900 census without using the nickname crosswalk or applying NYSIIS.{p_end}
{phang2}. abeclean namefrst namelast, generate(first middle last) no {p_end}

{marker authors}{...}
{title:Authors}

{pstd}Matthew Curtis{p_end}
{pstd}mjdcurtis@ucdavis.edu{p_end}

{pstd}Katherine Eriksson{p_end}
{pstd}kaeriksson@ucdavis.edu {p_end}


{marker acknowledgments}{...}
{title:Acknowledgments}

Thanks to Adrian Sayers at the University of Bristol (adrian.sayers@bristol.ac.uk) for providing the command {cmd:nysiis} to SSC.

Thanks to Tom Zohar and Jaime Arellano-Bover for creating an earlier cleaning program for the Comparing Linking Algorithms project.

Thanks to Jacob Conway for finding an error in the way the program checks for correct coding of sex variables.

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

{marker ABE2017}{...}
{phang}
Herzog T.N., Scheuren F.J., and Winkler W.E. 2007.  "Data Quality and Record Linkage Techniques." pg 119-121.
{p_end}

{marker ABE2017}{...}
{phang}
Taft, RL. 1970. "Name Search Techniques", New York State Identification and Intelligence System, Special Report No. 1, Albany, New York.
{p_end}

