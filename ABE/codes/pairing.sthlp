{smcl}
{* *! version 1.0.3  02mar2019}{...}
{viewerjumpto "Syntax" "pairing##syntax"}{...}
{viewerjumpto "Description" "pairing##description"}{...}
{viewerjumpto "Options" "pairing##options"}{...}
{viewerjumpto "Examples" "pairing##examples"}{...}
{viewerjumpto "Author" "pairing##author"}{...}
{viewerjumpto "Acknowledgements" "pairing##acknowledgements"}{...}
{title:Title}

{phang}
{bf:pairing} {hline 2} Create a dataset of candidate matches between two data sources


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:pairing}
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opth id:_vars(varlist)}}list of variables which uniquely identify observations in each cleaned source file{p_end}
{synopt:{opth bl:ocking_vars(varlist)}}list of variables on which to block{p_end}
{synopt:{opth output(string)}}location at which to save our final dataset of pairs{p_end}
{synopt:{opth d:istances(varlist)}}list of distance variables to keep (along with ID variables) in output{p_end}

{syntab:Raw Data Sources}
{synopt:{opth af:ile(string)}}single file representing data source {it:A}{p_end}
{synopt:{opth ad:irs(string)}}list of directories representing data source {it:A} file locations{p_end}
{synopt:{opth ap:atterns(string)}}list of file name patterns representing data source {it:A}{p_end}
{phang}
{it:Each option is repeated for data source {it:B}, replacing prefix {it:a} with {it:b}.}

{syntab:Common Data Preprocessing}
{synopt:{opth l:oad_vars(varlist)}}subset of variables to load from both {it:A} and {it:B} raw file(s){p_end}
{synopt:{opth r:estrictions(string)}}subset (if statement restriction) to load from raw {it:A} and {it:B} files{p_end}
{synopt:{opth pr:eprocessing(string)}}list of do files/commands to apply to both {it:A} and {it:B} to clean, after source-specific preprocessing{p_end}
{synopt:{opth k:eep_vars(varlist)}}list of variables to save in cleaned dataset{p_end}

{syntab:Source-Specific Preprocessing}
{synopt:{opth al:oad_vars(varlist)}}subset of variables to load from the raw {it:A} file(s){p_end}
{synopt:{opth ar:estrictions(string)}}subset (if statement restriction) to load from raw {it:A} file(s){p_end}
{synopt:{opth apr:eprocessing(string)}}list of do files or commands to apply to {it:A} to clean{p_end}
{synopt:{opth ac:leaned(string)}}location to save cleaned {it:A} file, not kept by default{p_end}
{phang}
{it:Each option is repeated for data source {it:B}, replacing prefix {it:a} with {it:b}.}

{syntab:Block Creation and Processing}
{synopt:{opth clean:_pairs(string)}}list of do files/commands to apply to preliminary pairs on each block (in parallel){p_end}
{synopt:{opth do_name(string)}}location at which to save created .do file, not kept by default{p_end}
{synopt:{opt save_blocks}}option to save block specific processed pairs{p_end}
{synopt:{opt example_block}}option to save a single block's pairs, before and after running
	processing_pairs code{p_end}
{synopt:{opth block_dir(string)}}location at which to save blocks if specified; existing blocks will be deleted{p_end}
{synopt:{opth block_prefix(string)}}blocks will be saved as {it:string}#.dta if specified{p_end}
{synopt:{opt noappend}}option to not append together processed blocks{p_end}
{synopt:{opt resume}}option to resume a partially completed pairing process saving blocks{p_end}

{syntab:Parallelization Options, see -parallel- for more detail}
{synopt:{opth clu:sters(#)}}number of clusters to use when running in parallel, default is 1{p_end}
{synopt:{opth proc:essors(#)}}number of processors to use per cluster when running in parallel, default is 0{p_end}
{synopt:{opth parallel_passthru(string)}}other options to pass through to the {cmd:parallel} command verbatim{p_end}

{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:pairing} reads in two data sources, {it:A} and {it:B}. If specified, multiple files are combined to form a given data source and preprocessing optionally specified by the user may be applied, after which a cleaned dataset is saved for each. 

{pstd}
For each combination of blocking variables found in the cleaned versions of both {it:A} and {it:B}, all possible pairwise combinations between our cleaned {it:A} and {it:B} are formed for this subset, after which additional processing specified by the user is applied to this block of candidate matches. This step is done in parallel for each block across multiple clusters using {cmd:parallel}. The resulting files are then combined across blocks to form our final dataset of all possible pairs. Note that observations with missing values in at least one blocking variable are dropped.

{pstd}
This program is designed to flexibly allow the user to form a dataset of potential pairs between two data sources, while loading data and processing blocks in parallel as efficiently as possible.

{pstd}
An example use case for this program would be to facilitate matching individuals in US Census files across years, in which the pairing program could be used to generate a set of possible matches.

{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opth id_vars(varlist)} requires the user to specify a list of variables which will uniquely identify observations in the cleaned versions of {it:A} and {it:B}. The validity of these ID variables are checked using {cmd:isid}. {varlist} occurs in 
the final output with A and B prefixes to indicate the source.

{phang}
{opth blocking_vars(varlist)} allows the user to specify a list of variables on which pairs between {it:A} and {it:B} must match exactly (on all) to be considered candidate matches.

{phang}
{opth output(string)} allows the user to specify the filepath {it:string} at which the final set of candidate pairs between {it:A} and {it:B} will be saved. This may be either a relative or absolute filepath.

{phang} 
{opth distances(varlist)} specifies a {varlist} to be kept, along with ID variables, in the final output dataset. This will often be a list of distance variables.

{dlgtab:Raw Data Sources}

{phang}
{opth afile(string)} specifies a single file representing the raw data for source {it:A}. This may be either a relative or absolute path.

{phang}
{opth adirs(string)} specifies a list of directories holding the raw data for source {it:A}. This may be either a relative or absolute path.

{phang}
{opth apatterns(string)} specifies a list of file patterns holding the raw data for source {it:A}. The lists for {cmd:adirs} and {cmd:apatterns} must be of equal length. 

{phang}
{it:The user must specify either {cmd:afile} or {cmd:adirs}+{cmd:apatterns}. Each option is repeated for data source {it:B}, replacing prefix {it:a} with {it:b}.}

{dlgtab:Common Data Preprocessing}

{phang}
{opth load_vars(varlist)} specifies a {varlist} to load from both the {it:A} and {it:B} raw data source files.

{phang}
{opth restrictions(string)} specifies "if" restrictions to use when loading observations for the {it:A} and {it:B} raw data source files. For example, {cmd:restrictions("if sex==1")} might load the subset of men for some raw data source files.

{phang}
{opth preprocessing(string)} specifies a list of .do files or commands to apply to both {it:A} and {it:B} in order to clean these raw data files. This common preprocessing occurs after source-specific preprocessing 
specified by {cmd: apreprocessing} or {cmd: bpreprocessing}.

{phang}
{opth keep_vars(varlist)} specifies a {varlist} to keep (in addition to the ID variables) in cleaned versions of datasources {it:A} and {it:B} after running preprocessing.

{dlgtab:Source-Specific Preprocessing}

{phang}
{opth aload_vars(varlist)} specifies a {varlist} to load, in addition to the common list specified by {cmd:load_vars}, from the {it:A} raw data source file(s). This option may be useful in loading variables which are needed only 
for preprocessing specific to {it:A} and not needed for {it:B}.

{phang}
{opth arestrictions(string)} specifies "if" restrictions to use when loading observations for the {it:A} raw data source files. These restrictions will be combined (via &) with any common restrictions given in {cmd:restrictions}.

{phang}
{opth apreprocessing(string)} specifies a list of .do files or commands to apply to the raw {it:A} file(s) before running common preprocessing.

{phang}
{opth acleaned(string)} specifies a filepath at which to save the cleaned {it:A} dataset, after preprocessing. 
Subsets will be loaded from this cleaned dataset by blocking variable combination in order to form all {it:A} X {it:B} combinations within this subset.
The default is to save this file at "__a_cleaned.dta" and to remove this file at the end of the program. 
If a different filepath is specified by the user, the user-specified cleaned {it:A} dataset will not be removed.

{phang}
{it:Each option is repeated for data source {it:B}, replacing prefix {it:a} with {it:b}.}

{dlgtab:Block Creation and Processing}

{phang}
{opth clean_pairs(string)} specifies a list of .do files or commands to apply to each block's {it:A} X {it:B} preliminary pairs in order to process these pairs. This is done in parallel using the {cmd:parallel} package. 
Users may wish to specify the creation of different distance variables and apply several filters in a do file to pass to each block.

{phang}
{opth do_name(string)} specifies a name for the .do file that is created to pass to each cluster through the {cmd:parallel} command. This .do file includes code to: 
loop through the subset of blocks assigned to this cluster; 
load the relevant subsets from the cleaned {it:A} and {it:B} datasets; 
form {it:A}X{it:B} combinations; apply any processing specified by {cmd:clean_pairs}; 
optionally save the processed block; 
finally append together all process blocks. 
By default this .do file is created at "do_in_parallel.do" and is removed at the end of the program. 
If the user wishes to view this created .do file, they can specify a different filepath, in which case this user-specified file will not be removed.

{phang}
{opt save_blocks} specifies that the program should save blocks of processed {it:A} X {it:B} pairs (after running {cmd:clean_pairs} code) for later use by the user. 
By default, all blocks are saved as temporary files and removed at the end of the program. Note that even with the {cmd:save_blocks} option, blocks for which there are zero remaining observations after processing will not be saved. 

{phang}
{opt example_block} specifies that the program should save a single example block (the first) before and after running the processing code specified by {cmd:clean_pairs}. 
This may be useful for users seeking to debug the code they wish to pass to each block.

{phang}
{opth block_dir(string)} specifies a folder location in which to save blocks. This option must be specified if either the {cmd:save_blocks} or {cmd:example_block} options are specified. 
If there are any existing block files (matching file pattern "<block_prefix>*.dta") in this location, these will be deleted.

{phang}
{opth block_prefix(string)} specifies a prefix for any saved block files, which will be saved as "<block_dir>/<block_prefix><#>.dta". The default is equivalent to {cmd:block_prefix(Block)}.

{phang}
{opt noappend} specifies that the processed blocks should not be appended together.
This will suppress the saving of a final output dataset.
If this option is specified, {cmd:save_blocks} must also be specified.

{phang}
{opt resume} specifies that a partially completed pairing process should be resumed.
This will skip blocks that have already been created in <block_dir>.
If this option is specified, {cmd:save_blocks} must also be specified.
An existing dofile to run in parallel, a block key, and cleaned source files must already exist.

{dlgtab:Parallelization Options}

{phang}
{opth clusters(#)} specifies the number of clusters (new Stata instances) to use when running the block creation and blocking in parallel. The default is 1, see the {cmd:parallel} program for more detail.

{phang}
{opth processors(#)} specifies the number of processors to use per cluster when running the block creation and blocking in parallel. The default is 0, see the {cmd:parallel} program for more detail.

{pstd}
{opth parallel_passthru(string)} specifies other options to be passed through to the {cmd:parallel} command verbatim.


{marker examples}{...}
{title:Examples}

{phang} 
pairing, afile("Data/A.dta") bdirs("Data_B") bpatterns("File_number*.dta") load_vars(myid name age state) 
restrictions(if sex==1) preprocessing(Code/my_preprocessing.do) 
id(myid) keep(age name state) blocking(state) clusters(4) 
clean_pairs(Code_Folder2/run_on_blocks.do) distances(age_diff name_distance) output("Data/Pairs")


{marker author}{...}
{title:Author}
{phang}
Jacob Conway

{phang}
jcconway@stanford.edu


{marker acknowledgements}{...}
{title:Acknowledgements}
{phang}
This program calls on George Vega Yon and Brian Quistorff's {cmd:parallel} package.


