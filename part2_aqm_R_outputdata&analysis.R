## Title: Coding Coursework Project___Part2 R Codes
## Course: Advanced Quantitative Methods
## Author: Whitney Hung
## Study Program: PANC
## Date: 29/04/2019
## Program language: R version 3.5.1

######### NOTES

## This code takes in csv file named: "outputData.csv" which was generated from the python codes.
## This generates the final csv file named: "33585886_outputdata.csv"

## This code has 4 parts
## part 1. Data wrangling, creates all needed variable
## part 2. FnoA score calculation
## part 3. Merging with demographic data named:
##         "sub_demographic_data.csv" & File output
## part 4. Data analysis part



#____________________Code starts here, Part 1, data wrangling


install.packages('data.table') #Only needs to install once
## Set path
setwd(".")
library(data.table)

# Import data
data = read.csv("outputData.csv")
data = as.data.table(data)

# correction "resp_rew" : 
# note: in python created as resp_corr but should be named resp_rew.
colnames(data)[12] = 'resp_rew'


# All missing values as NA 
data[resp_rew=='NaN', resp_rew:= NA ,]
data[response=='NaN', response:= NA ,]


# create "phase" variable : test/training, 1~56: train, 57~: test
data[, phase := ifelse(data[, trialnum<57,], 'train', 'test'),]

# create "FnoAorder" variable : based on cbcond
  # cbcond = 1->2, 2->1, 3->2, 4->1
data[, FnoAorder:= ifelse(data[,cbcond==1|cbcond==3,],2,1),]

# create "FnoAformat" variable : based on format
data[, FnoAformat:= ifelse(data[,format=='weather',],'Fbk=W','Fbk=D'),]

# correction "outcome" variable : if test phase, then na, if 0 then 2
data[, outcome:= ifelse(data[,phase=='test',],'',ifelse(data[,outcome==0,],2,1)),]

# class(data$outcome) is character
data$outcome = as.numeric(data$outcome) #change to numeric

# create "response" variable : 
data[,
     response := ifelse ( data[,is.na(response) == FALSE,],data$response,
                          ifelse ( data[,resp_rew==1 & outcome==1,],1,
                                 ifelse ( data[,resp_rew==1 & outcome==2,],2,
                                          ifelse ( data[,resp_rew==0 & outcome==2,],1,
                                                   ifelse ( data[,resp_rew==0 & outcome==1,],2,NA))))),]


# create "prob_out1" : based on cues
data[,prob_out1:=0.5,]
data[,prob_out1:=ifelse(data[,cue1==1,],prob_out1+0.25,prob_out1+0),]
data[,prob_out1:=ifelse(data[,cue2==1,],prob_out1+0.25,prob_out1+0),]
data[,prob_out1:=ifelse(data[,cue3==1,],prob_out1-0.25,prob_out1+0),]
data[,prob_out1:=ifelse(data[,cue4==1,],prob_out1-0.25,prob_out1+0),]

# "resp_corr" variable :  if prob = 0.5, then na, (CORRECT ONE)
### Note: test phase has no outcome
data[,resp_corr:=ifelse(data[,prob_out1==0.5,],'',ifelse(data[,(prob_out1>0.5 & response==1)|(prob_out1<0.5 & response==2),],1,0)),]
# reformat missing values
data[resp_corr=='', resp_corr:= NA ,]
# correction: class(data$resp_corr) # character
data$resp_corr = as.numeric(data$resp_corr) #change to numeric

# create "include" variable:include the trial for this participant (1=yes; 0=no) [0 for trials where there was a bug in recording trial outcome for some Ss)
# update 29/04/2019:() FnoAorder = 2,phase= 'training', trialnum= 53-56 )-> include==0
data[,
     include:=
       ifelse(data[,(phase =='train' & 
                       (is.na(resp_rew)==TRUE|resp_rew==2))|
                     (FnoAorder == 2 & (trialnum>=53 & trialnum<=56)),],0,1),]

### sanity check: if test phase starts from 57
# min(data[phase=='test',trialnum])

data = data[,c(1:2,5:20)]


#____________________End of data formatting


#____________________FnoAcorr calculation_______Part 2


# Nitems_FnoA: Number of valid test phase response for the FnoA condition - for each sub
Nitems_FnoA = data[(phase=='test' & include==1 & RT > 0.1 & prob_out1!=0.5), .N , by='subno'] # to be divided by 10
Corritems_FnoA = data[(phase=='test'& RT > 0.1 & is.na(resp_corr)==FALSE), sum(resp_corr), by='subno'] 

# FnoAcorr: Proportion correct in test phase of the FnoA condition - for each sub
corrpercent = merge(Nitems_FnoA, Corritems_FnoA, by='subno') #column N is Nitems_FnoA, column V1 is Corritems_FnoA
corrpercent[,FnoAcorr:=V1/N,]
corrpercent = corrpercent[,c(1,2,4)] # Only need subno & FnoAcorr
colnames(corrpercent)[2] = 'Nitems_FnoA'



#____________________Data merging (Demographic & FnoAcorr) & File output_______Part 3

# Import csv data
demo = read.csv("sub_demographic_data.csv")
demo = as.data.table(demo)

# merge tables
data = merge(data, demo, by='subno')

# merge FnoAcorr data
data = merge(data, corrpercent, by='subno')

# Data export
write.csv(data, file = "33585886_outputdata.csv")

#____________________Data analysis_______Part 4

# Get data ready for analysis, exclude experimental columns.
dat = data[,c(1,12:30)]

# import packages
install.packages("Hmisc")
library(Hmisc)

# ---Correlation

#include test phase only
datcorr = dat[ include==1 & phase=='test',]
# check data type & remove non numeric data
sapply(datcorr, class)
# subno          RT       phase   FnoAorder  FnoAformat   prob_out1   resp_corr     include 
# "factor"   "numeric" "character"   "numeric" "character"   "numeric"   "numeric"   "numeric" 
# age          ue          cd         ian         inc        epqe        epqp      bastot 
# "integer"   "integer"   "integer"   "integer"   "integer"   "integer"   "integer"   "integer" 
# nstot     harmtot    FnoAcorr 
# "integer"   "integer"   "numeric" 
datcorr = datcorr[,c(2,4,6:19)]

print(rcorr(as.matrix(datcorr)))

# ----Descriptive stats

# Mean test score & age
datanal = dat[, list(mean_FnoAcorr = mean(FnoAcorr),
                     std_FnoAcorr = sd(FnoAcorr),
                     mean_age = mean(age),
                     std_age = sd(age)),]
print(datanal) 
