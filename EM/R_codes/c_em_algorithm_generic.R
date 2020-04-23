
rm(list=ls())
dropbox <- "C:/Users/acald/Desktop/test_em_data/"

# set directories
EMdistances <- paste(dropbox,"data/new_codes/em_santi_small2/EMdistances/",sep = "") 
EMmatches <-  paste(dropbox,"data/new_codes/em_santi_small2/EMmatches/",sep = "") 

# Select threshold for Algorithm and maximum number of iterations
stop_at_param<-0.00001
iter<-3000

#Load packages
library(stringdist)
library(doParallel)
library(foreign)
library(readstata13)
library(dplyr)
library(doParallel)
library(plyr)
library(doParallel)
library(foreach)
registerDoParallel(cores=2)

options(scipen=999)


#Import appended data on summary of distances (created by jaro_winkler_names.R) 

data<-vector()
data <- read.table(paste(EMdistances,"summary.csv",sep=""), header = T)
data <- data.frame(data)


Dist_FN<-data$Dist_FN
Dist_LN<-data$Dist_LN
Age_Dist<-data$Age_Dist

# *EM Algorithm*

## PRIOR Distributions: Initial value for proportion of matches

n_obs<-sum(data$Count)

p_M_0<-data$N[1]/n_obs

p_U_0<-1-p_M_0


###String distribution: multinomial 

###Set number of categorical variables (k) for names and ages
#### 4 groups defined below by the dic_strdist functions

k_N<-4
k_A<-6
i_N<-1:k_N
i_A<-1:k_A

#Priors are set equal to 1/k for the unmatched and to 1/k + [(k-1)/2 - (i-1)]/(k^2) for the matched

###First name priors (on the unmatched assume no further information provided by knowing that unmatched. for the matched impose a decreasing LR): 

theta_strdist_FN_U_0<-(aggregate(data$Count, by=list(Dist_FN=data$Dist_FN), FUN=sum)/n_obs)[,2]
theta_strdist_FN_M_0<-(1/k_N+((k_N-1)/2-(i_N-1))/k_N^2)

for (i in c(k_N:2)){
	
  if (theta_strdist_FN_M_0[i-1]/theta_strdist_FN_M_0[i]<theta_strdist_FN_U_0[i-1]/theta_strdist_FN_U_0[i]){
  	theta_strdist_FN_M_0[i-1]<-theta_strdist_FN_M_0[i]*theta_strdist_FN_U_0[i-1]/theta_strdist_FN_U_0[i]
  }	  
  }	

theta_strdist_FN_M_0<-theta_strdist_FN_M_0/sum(theta_strdist_FN_M_0)

###Last name priors (my prior is that the Pr(Distance/U) is approx the empirical frequencies of each distance)

theta_strdist_LN_U_0<-(aggregate(data$Count, by=list(Dist_LN=data$Dist_LN), FUN=sum)/n_obs)[,2]
theta_strdist_LN_M_0<-(1/k_N+((k_N-1)/2-(i_N-1))/k_N^2)

for (i in c(k_N:2)){
	
  if (theta_strdist_LN_M_0[i-1]/theta_strdist_LN_M_0[i]<theta_strdist_LN_U_0[i-1]/theta_strdist_LN_U_0[i]){
  	theta_strdist_LN_M_0[i-1]<-theta_strdist_LN_M_0[i]*theta_strdist_LN_U_0[i-1]/theta_strdist_LN_U_0[i]
  }	  
  }	

theta_strdist_LN_M_0<-theta_strdist_LN_M_0/sum(theta_strdist_LN_M_0)
	

###Age distribution: multinomial over 0,1,2,3,4,5 absolute age difference

theta_agedist_U_0<-(aggregate(data$Count, by=list(Age_Dist=data$Age_Dist), FUN=sum)/n_obs)[,2]
theta_agedist_M_0<-(1/k_A+((k_A-1)/2-(i_A-1))/k_A^2)

for (i in c(k_A:2)){
	
  if (theta_agedist_M_0[i-1]/theta_agedist_M_0[i]<theta_agedist_U_0[i-1]/theta_agedist_U_0[i]){
  	
  	theta_agedist_M_0[i-1]<-theta_agedist_M_0[i]*theta_agedist_U_0[i-1]/theta_agedist_U_0[i]
  }	
  
  }	
  
theta_agedist_M_0<-theta_agedist_M_0/sum(theta_agedist_M_0)
	
print(theta_agedist_M_0/theta_agedist_U_0)
print(theta_strdist_FN_M_0/theta_strdist_FN_U_0)
print(theta_strdist_LN_M_0/theta_strdist_LN_U_0)

#Match enriched sample

p_age_M<-theta_agedist_M_0[data[,1]+1]
  p_age_U<-theta_agedist_U_0[data[,1]+1]
  
  p_str_FN_M<-theta_strdist_FN_M_0[data[,2]]
  p_str_FN_U<-theta_strdist_FN_U_0[data[,2]]

  p_str_LN_M<-theta_strdist_LN_M_0[data[,3]]
  p_str_LN_U<-theta_strdist_LN_U_0[data[,3]]
  
  m<-(p_str_FN_M*p_str_LN_M*p_age_M*p_M_0)/(p_M_0)
  u<-(p_str_FN_U*p_str_LN_U*p_age_U*p_U_0)/(p_U_0)
  
data<-data[order(-log(m/u)),]
weight<-log(m/u)

weight<-weight[order(-weight)]

data<-cbind(data,c(1:length(data$Count)))

data$Count<-data$Count/(data[,6])

n_obs<-sum(data$Count)

p_M_0<-data$N[1]/n_obs

p_U_0<-1-p_M_0

## Start loop

t<-1
error<-10
error_v<-vector()

while(error>stop_at_param & t<iter){
  
  #Pr(distance/parameters)
  
  p_age_M<-theta_agedist_M_0[data[,1]+1]
  p_age_U<-theta_agedist_U_0[data[,1]+1]
  
  p_str_FN_M<-theta_strdist_FN_M_0[data[,2]]
  p_str_FN_U<-theta_strdist_FN_U_0[data[,2]]

  p_str_LN_M<-theta_strdist_LN_M_0[data[,3]]
  p_str_LN_U<-theta_strdist_LN_U_0[data[,3]]
  
  w<-(p_str_FN_M*p_str_LN_M*p_age_M*p_M_0)/((p_str_FN_M*p_str_LN_M*p_age_M*p_M_0)+(p_str_FN_U*p_str_LN_U*p_age_U*p_U_0))
  

  p_M_1<-weighted.mean(w,data[,4])
  p_U_1<-1-p_M_1
  
  theta_agedist_M_1<-vector()
  theta_agedist_U_1<-vector()
  
  theta_strdist_FN_M_1<-vector()
  theta_strdist_FN_U_1<-vector()
  
  theta_strdist_LN_M_1<-vector()
  theta_strdist_LN_U_1<-vector()
  
  #Updated values of the parameters
  
  for (i in 1:k_A){
    theta_agedist_M_1[i]<-(w[which(data[,1]==i-1)]%*%data[which(data[,1]==i-1),4])/(w%*%data[,4])
     
    theta_agedist_U_1[i]<-((1-w[which(data[,1]==i-1)])%*%data[which(data[,1]==i-1),4])/((1-w)%*%data[,4])
  }
  
  for (i in 1:k_N){
    	
    theta_strdist_FN_M_1[i]<-(w[which(data[,2]==i)]%*%data[which(data[,2]==i),4])/(w%*%data[,4])
    theta_strdist_FN_U_1[i]<-((1-w[which(data[,2]==i)])%*%data[which(data[,2]==i),4])/((1-w)%*%data[,4])
    
    theta_strdist_LN_M_1[i]<-(w[which(data[,3]==i)]%*%data[which(data[,3]==i),4])/(w%*%data[,4])
    theta_strdist_LN_U_1[i]<-((1-w[which(data[,3]==i)])%*%data[which(data[,3]==i),4])/((1-w)%*%data[,4])

  }
  
       #Check difference in absolute value
  
  t<-t+1
  
  error1<-max(abs(rbind(theta_agedist_M_1,theta_agedist_U_1)-rbind(theta_agedist_M_0,theta_agedist_U_0)))
  error2<-max(abs(rbind(theta_strdist_FN_M_1,theta_strdist_FN_U_1,theta_strdist_LN_M_1,theta_strdist_LN_U_1)-rbind(theta_strdist_FN_M_0,theta_strdist_FN_U_0,theta_strdist_LN_M_0,theta_strdist_LN_U_0)))
  error3<-abs(p_M_1-p_M_0)
  error<-max(error1,error2,error3)
  error_v[t]<-error
  
   #Update values

  theta_agedist_M_0<-theta_agedist_M_1
  theta_agedist_U_0<-theta_agedist_U_1
  
  theta_strdist_FN_M_0<-theta_strdist_FN_M_1
  theta_strdist_FN_U_0<-theta_strdist_FN_U_1
  
  theta_strdist_LN_M_0<-theta_strdist_LN_M_1
  theta_strdist_LN_U_0<-theta_strdist_LN_U_1
  
  p_M_0<-p_M_1
  p_U_0<-p_U_1
  
  print(t)
}

#Create final w:

w_final<-(p_str_FN_M*p_str_LN_M*p_age_M*p_M_0)/((p_str_FN_M*p_str_LN_M*p_age_M*p_M_0)+(p_str_FN_U*p_str_LN_U*p_age_U*p_U_0))

w_final<-round(w_final, 8)

#Save parameters
parameters<-c(theta_agedist_M_0,theta_agedist_U_0,theta_strdist_FN_M_0,theta_strdist_FN_U_0,theta_strdist_LN_M_0,theta_strdist_LN_U_0,p_M_0)
names<-c("AM0","AM1","AM2","AM3","AM4","AM5","AU0","AU1","AU2","AU3","AU4","AU5","FM0","FM1","FM2","FM3","FU0","FU1","FU2","FU3","LM0","LM1","LM2","LM3","LU0","LU1","LU2","LU3","P")

parameters<-cbind(names, parameters)

file1<-paste(EMmatches,"EM_Estimates_parameters.csv",sep="")

write.table(parameters,file1, row.names=F)

#Save estimates of probabilities (w)

probs_export<-cbind(data, w_final)

colnames(probs_export) <- c("Age_Dist", "strdist_FN_index", "strdist_LN_index", "counts", "N", "w_final")

file2<-paste(EMmatches,"EM_Estimates_probabilities.csv",sep="")

write.table(probs_export,file2, row.names=F)





















