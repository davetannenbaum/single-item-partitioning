## =======================================================================
## Clean up 
## =======================================================================
library(tidyverse)
library(forcats)

## calling data
## =======================================================================
setwd("~/Desktop")
df <- read_csv("Experiment1.csv") # import data

## cleaning up initial data set
## =======================================================================
df <- df[-c(1), ]                                 # remove first row
df <- filter(df, Include == "Yes")                # filtering subjects
df <- rename(df, cond = V5)                       # renaming
df$cond <- factor(df$cond)                        # converting to factor
id <- rownames(df)                                # generating id variable
df <- cbind(id=id, df)                            # adding id variable to dataframe

## renaming variables
## =======================================================================
names(df)[names(df) == 'dv(1)'] <-    'dv1'
names(df)[names(df) == 'dv(2)'] <-    'dv2'
names(df)[names(df) == 'dv(3)'] <-    'dv3'
names(df)[names(df) == 'dv(3)_1'] <-  'dv4'
names(df)[names(df) == 'dv(5)'] <-    'dv5'
names(df)[names(df) == 'dv(6)'] <-    'dv6'
names(df)[names(df) == 'dv(7)'] <-    'dv7'
names(df)[names(df) == 'dv(8)'] <-    'dv8'
names(df)[names(df) == 'dv(9)'] <-    'dv9'
names(df)[names(df) == 'dv(10)'] <-   'dv10'
names(df)[names(df) == 'dv(11)'] <-   'dv11'
names(df)[names(df) == 'dv(12)'] <-   'dv12'
names(df)[names(df) == 'dv(13)'] <-   'dv13'
names(df)[names(df) == 'dv(13)_1'] <- 'dv(14)'
names(df)[names(df) == 'dv(15)'] <-   'dv15'
names(df)[names(df) == 'dv(16)'] <-   'dv16'
names(df)[names(df) == 'dv(17)'] <-   'dv17'
names(df)[names(df) == 'dv(18)'] <-   'dv18'
names(df)[names(df) == 'dv(19)'] <-   'dv19'
names(df)[names(df) == 'dv(20)'] <-   'dv20'

## reshaping data
## =======================================================================
df <- gather(df, trial, response, dv1:dv20, factor_key=TRUE)
df <- select(df, id, cond, trial, response)
df <- arrange(df, id)
df <- transform(df, trial = as.numeric(trial))

## omitting "I don't understand" responses and recoding responses (0 = no, 1 = yes)
## =======================================================================
df <- filter(df, response != "3")
df <- transform(df, response = as.numeric(response))
df <- mutate(df, response = 1 - (response - 1))

## generating for incongruent dilemmas
## =======================================================================
df <- mutate(df, incongruent = mod(trial,2))


