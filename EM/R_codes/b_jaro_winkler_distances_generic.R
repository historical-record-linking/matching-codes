
rm(list=ls())
dropbox <- "C:/Users/acald/Desktop/test_em_data/"

# set directories
EMblocks<- paste(dropbox,"data/new_codes/em_santi_small2/EMblocks/",sep = "") 
EMdistances <- paste(dropbox,"data/new_codes/em_santi_small2/EMdistances/",sep = "") 

#install packages if you do not have them

#Load packages
library(stringdist)
library(doParallel)
library(foreign)
library(readstata13)
library(dplyr)
library(plyr)
library(foreach)
registerDoParallel(cores=2)

options(scipen=999)


## Categorization: Create categories of distances
dic_strdist<-function(x){
  ifelse(x<=0.067,1,0)+ifelse(x>0.067 & x<=0.12,2,0)+ifelse(x>0.12 & x<=0.25,3,0)+ifelse(x>0.25,4,0)
}

#Read Stata files into R (We will have two datasets A (source) and B (target), 
#we start from A and look for matches in B. For example A could be the 1910 census IPUMS sample and B the 1930 census )

#Get number of blocks
n_blocks<-read.dta(paste(EMblocks,"N_Blocks.dta", sep=""))

n_blocks<-max(n_blocks)

#Calculate distances

for (j in 1:n_blocks) {

  All_Data<-read.dta(paste(EMblocks,"Data_Block_",j,".dta", sep=""))
  
  A<-All_Data[which(All_Data$Data==0),]
  B<-All_Data[which(All_Data$Data==1),]

  rm(All_Data)

  #Count the number of observations in the source dataset
  n<-nrow(A)

  #Initialize empty lists
  strdist_FN<-list()
  strdist_LN<-list()
  agedist<-list()
  index<-list()
  n_obs<-list()

  #I now loop over each of the observations in the source dataset A. 
  # the line that starts with "index" identifies, for each observation in A, which observations in B belong to the same block
  # the lines that start with strdist_FN and strdist_LN compute the string distance of each observation in A with respect to each observation in B that belongs to its same block (this step is aimed at saving computational time)

  #Drop those that do not have a match within a five years window

  n_obs<-foreach(i=1:n) %dopar% length(which(abs(B$age_match-A[i,"age_match"])<=5))

  A<-A[which(unlist(n_obs)>0),]

  n_obs<-unlist(n_obs)[which(unlist(n_obs)>0)]
  index<-list()

  n<-length(n_obs)

  #index_B identifies the position or the observations in dataset B that I compare to each observation in dataset A
  index_B<-foreach(i=1:n) %dopar% which(abs(B$age_match-A[i,"age_match"])<=5)

  #Create distances in age, first and last names
  agedist<-foreach(i=1:n) %dopar% abs(c(A[i,"age_match"]-B[which(abs(B$age_match-A[i,"age_match"])<=5),"age_match"]))

  strdist_LN<-foreach(i=1:n, .export='stringdist') %dopar% c(stringdist(A[i,"l_name"],B[which(abs(B$age_match-A[i,"age_match"])<=5),"l_name"],method="jw",p=0.1))

  strdist_FN<-foreach(i=1:n, .export='stringdist') %dopar% c(stringdist(A[i,"f_name"],B[which(abs(B$age_match-A[i,"age_match"])<=5),"f_name"],method="jw",p=0.1))

  strdist_FN<-unlist(strdist_FN)
  strdist_LN<-unlist(strdist_LN)
  agedist<-unlist(agedist)

  ## Rounding: Apply some rounding to JW distances (this makes it more comparable to the Stata code)
  strdist_FN<-round(strdist_FN, 8)
  strdist_LN<-round(strdist_LN, 8)
  
  ## Categorization: Create categories of distances
  strdist_FN_index<-dic_strdist(strdist_FN)
  strdist_LN_index<-dic_strdist(strdist_LN)
  
  #
  index_A<-c()

  if (length(unlist(index_B))>0){

    for (i in 1:n){
      index_A<-append(index_A,rep(i,n_obs[i]))
    }

    #Export data on string distance to later read in Stata

    data<-cbind(A[index_A,"id"], B[unlist(index_B),"id"], agedist, strdist_FN_index, strdist_LN_index)

    colnames(data)<-c("id_A","id_B","Age_Dist","strdist_FN_index","strdist_LN_index")

    file<-paste(EMdistances,"distances_",j,".csv",sep="")

    write.table(data,file, row.names=F)
    
    #Store summarized information
    
    data <- data.frame(data)

print(strdist_FN)
#strdist_FN<-data$Dist_FN
print(strdist_FN)

#strdist_LN<-data$Dist_LN
#agedist<-data$Age_Dist

  #some observations were contaminated with non numeric characters (i.e. 1/ and 2/ instead of 1, 2).
  #this adjustment should fix this and other potential problems. first remove non-numeric characters, then transform agedist to numeric
  if(is.numeric(agedist)){

  } 
  else{
    agedist<-gsub("[^0-9]","",agedist)
    agedist<-as.numeric(as.character(agedist))
  }

#Convert string distance variables vector to vector with just the corresponding index
print(strdist_FN)
#strdist_FN<-as.numeric(levels(strdist_FN))[strdist_FN]
print(strdist_FN)

#strdist_LN<-as.numeric(levels(strdist_LN))[strdist_LN]

strdist_FN_index<-dic_strdist(strdist_FN) ##### corected!!
strdist_LN_index<-dic_strdist(strdist_LN)


dataagg<-cbind(c(1:length(agedist)),agedist,strdist_FN_index, strdist_LN_index)

#Count how many observations fall into each of the bins and store this information (this is all the info we need for the EM estimation)

dataagg<-aggregate(dataagg[,1], by=list(agedist,strdist_FN_index, strdist_LN_index), FUN=length)



dataA<-data.frame(expand.grid(c(0:5),c(1:4),c(1:4)))

total<-merge(dataA,dataagg, by.x=c("Var1","Var2","Var3"), by.y=c("Group.1","Group.2","Group.3"), all.x=TRUE)

total[is.na(total)]<-0

dataagg<-total

dataagg<-cbind(dataagg,n)

colnames(dataagg)<-c("Age_Dist","Dist_FN","Dist_LN","Count","N")

 file<-paste(EMdistances,"summary_",j,".csv",sep="")

    write.table(dataagg,file, row.names=F)
  
  }
  print(j)
}

rm(data)


####Append all data####

data<-data.frame(expand.grid(c(0:5),c(1:4),c(1:4)))

data<-cbind(data,0*c(1:nrow(data)),0*c(1:nrow(data)))

data<-data[order(data[,1],data[,2],data[,3]),]

colnames(data)<-c("Age_Dist","Dist_FN","Dist_LN","Count","N")

for (j in 1:n_blocks){
  
  if(file.exists(paste(EMdistances,"summary_",j,".csv",sep=""))==TRUE){
    
    new.block <- read.table(paste(EMdistances,"summary_",j,".csv",sep=""), stringsAsFactors = FALSE, header=TRUE)
   data<-cbind(data[,1:3],data$Count+new.block$Count,data$N+new.block$N)
colnames(data)<-c("Age_Dist","Dist_FN","Dist_LN","Count","N")
    print(j)
  }
}

file<-paste(EMdistances,"summary",sep="")
file2<-paste(EMdistances,"summary.csv",sep="")

write.table(data,file, row.names=F) 
write.table(data,file2, row.names=F) 














