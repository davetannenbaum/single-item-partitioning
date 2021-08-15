** ===============================================
** Study 2
** ===============================================

** Cleanup
** -----------------------------------------------
// loading raw data
snapshot erase _all
version 16.1
import delimited "https://www.dropbox.com/s/3nfhciw5nf3n4h1/data.csv?dl=1", varnames(1) clear

// dropping extra row of variable labels
drop in 1

// converting variables to numeric variables
quietly destring, replace

// drop duplicate IP address
duplicates drop v6, force

// renaming and cleaning
rename q8 chores
rename q10 gender
replace gender = gender - 1
label define genderl 0 "Male" 1 "Female"
label val gender genderl
rename q11_1 age
encoder groupedcategory, replace setzero
rename groupedcategory position
replace position = 1 - position
label var position "menu partition position"
label define positionl 0 "packed category at top" 1 "packed category at bottom"
label val position positionl
encoder household, replace setzero
rename household cond
label define condl 0 "household packed" 1 "household unpacked"
label val cond condl

// converting response strings to lower case and removing dead spaces
replace chores = lower(chores) 
replace chores = rtrim(chores)
replace chores = itrim(chores)
replace chores = ltrim(chores)

// Household chores
replace chores = "" if strpos(chores,"your choice")
replace chores = "" if strpos(chores,"that is not a choice")
replace chores = "" if inlist(chores,"1","10000","40000","an indoor chore","an outdoor chore","indoor chore","outdoor chore","outdoor")
replace chores = "rain gutters" if strpos(chores,"rain")
replace chores = "laundry" if strpos(chores,"laundry")
replace chores = "kitchen cleaning" if strpos(chores, "kitchen")
replace chores = "lawn mowing" if strpos(chores, "lawn")
replace chores = "weeding" if strpos(chores, "weeds")
replace chores = "vacuum" if strpos(chores, "vacuum")
encoder chores, replace
gen indoor_chores = 0 if inlist(chores,3,4,6)
replace indoor_chores = 1 if inlist(chores,1,2,5)
rename indoor_chores dv
label define dvl 0 "outdoor chores" 1 "household chores"
label val dv dvl

// removing crud
keep cond chores dv position gender age
order cond chores dv position gender age
snapshot save

** Demographics
** -----------------------------------------------
snapshot restore 1
tab gender
sum age

** Analysis
** -----------------------------------------------
snapshot restore 1
prtest dv, by(cond)
logit dv i.cond##i.position
margins position, dydx(cond)

** Robustness Check: recode missing observations to go against hypothesis
** -----------------------------------------------
snapshot restore 1
replace dv = 0 if cond == 1 & dv == .
replace dv = 1 if cond == 0 & dv == .
prtest dv, by(cond)
logit dv i.cond##i.position

** Robustness Check: OLS regression
** -----------------------------------------------
snapshot restore 1
ttest dv, by(cond)
regress dv i.cond##i.position
margins position, dydx(cond)