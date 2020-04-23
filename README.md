![Image1](https://iowaculture.gov/sites/default/files/styles/general_content_feature_image/public/history-research-collections-census.jpg?itok=TfHQ0mxj&c=dc368fe2ea1c374e49ce98ecc80ac229)
# About
This repository provides codes and documentation required to implement historical linking methods. Details of methods can be found in the paper: [Abramizky, Boustan, Eriksson, Feigenbaum, and Pérez (2020). "Automated Linking of Historical Data".](https://ranabr.people.stanford.edu/sites/g/files/sbiybj5391/f/linking_may2019.pdf)

Please cite this paper if you use code from this folder.


# Notes on methods in repository

Currently, the repository provides codes for two such methods:

1. **The ABE fully automated approach:**
This approach is a fully automated method for linking historical datasets (e.g. complete-count Censuses) by first name, last name and age. The approach was first developed by Ferrie (1996) and adapted and scaled for the computer by Abramitzky, Boustan and Eriksson (2012, 2014, 2017). Because names are often misspelled or mistranscribed, our approach suggests testing robustness to alternative name matching (using raw names, NYSIIS standardization, and Jaro-Winkler distance).  To reduce the chances of false positives, our approach suggests testing robustness by requiring names to be unique within a five year window and/or requiring the match on age to be exact. 

2. **A fully automated probabilistic approach (EM):** 
This approach ([Abramitzky, Mill, and Perez 2019](https://ranabr.people.stanford.edu/sites/g/files/sbiybj5391/f/matching_historicalmethod_march27.pdf)) suggests a fully automated probabilistic method for linking historical datasets.  We combine distances in reported names and ages between each two potential records into a single score, roughly corresponding to the probability that both records belong to the same individual. We estimate these probabilities using the Expectation-Maximization (EM) algorithm, a standard technique in the statistical literature. We suggest a number of decision rules that use these estimated probabilities to determine which records to use in the analysis. 



# Contact Information
Contact Information: ranabr@stanford.edu (Ran Abramitzky),  lboustan@princeton.edu (Leah Boustan), kaeriksson@ucdavis.edu (Katherine Eriksson).


Last Updated: April 23, 2020


