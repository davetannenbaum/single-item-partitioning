** ===============================================
** Study 2
** ===============================================

** Cleanup
** -----------------------------------------------
// loading raw data
// note: Below I pull data from GitHub, but you may wish to change the file path to load data from your local working directory
snapshot erase _all
version 16.1
import delimited "https://shorturl.at/flqK3", varnames(1) clear

// dropping extra row of variable labels
drop in 1

// converting variables to numeric variables
quietly destring, replace

// remove unfinished responses and preview responses
drop if v10 == 0
drop if v7 != 0

// removing rows of observations with duplicate IP addresses
sort v8, stable
duplicates drop v6, force

// renaming and cleaning
// note: uses the "encoder" package, to install type: ssc install encoder
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
replace chores = "lawn mowing" if strpos(chores, "mowing")
replace chores = "weeding" if strpos(chores, "weeds")
replace chores = "vacuum" if strpos(chores, "vacuum")
encoder chores, replace

gen dv = 0 if inlist(chores,3,5)
replace dv = 1 if inlist(chores,1,2,4)
label define dvl 0 "outdoor chores" 1 "household chores"
label val dv dvl

// removing crud
keep cond chores dv position gender age
order cond chores dv position gender age

// saving snapshot of data
snapshot save

** Demographics
** -----------------------------------------------
snapshot restore 1
tab gender
sum age

** Main analysis
** -----------------------------------------------
snapshot restore 1
prtest dv, by(cond)

** Positioning effects
** -----------------------------------------------
snapshot restore 1
logit dv i.cond##i.position, robust // interaction between partition and listing position 
margins position, dydx(cond) // partitioning effects when grouped listing is top vs bottom
margins position, dydx(cond) pwcompare(effects) // difference in avg marginal effects

** Robustness Check: recode missing observations to go against hypothesis
** -----------------------------------------------
snapshot restore 1
replace dv = 0 if cond == 1 & dv == .
replace dv = 1 if cond == 0 & dv == .
prtest dv, by(cond)
logit dv i.cond##i.position, robust
margins position, dydx(cond)
margins position, dydx(cond) pwcompare(effects)