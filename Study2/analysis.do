** ===============================================
** Study 2
** ===============================================

** Cleanup
** -----------------------------------------------
// loading raw data
snapshot erase _all
cd "~/GitHub/single-item-partitioning/Study2/"
import delimited data.csv, varnames(1) clear 

// dropping extra row of variable labels
drop in 1

// converting variables to numeric variables
quietly destring, replace

// removing rows of observations with duplicate IP addresses
// (IP addresses replaced with unique identifier to protect participant privacy)
sort v8
duplicates drop v6, force

// renaming variables
rename household cond
rename groupedcategory position
rename q8 chores
rename q10 gender
rename q11 age

// converting all response strings to lower case and removing dead spaces
ds, has(type string) 
quietly foreach v of varlist `r(varlist)' {
	replace `v' = lower(`v') 
	replace `v' = rtrim(`v')
	replace `v' = itrim(`v')
	replace `v' = ltrim(`v')
}

// choice of household chores
// recoding open responses to 0 = outdoor chores, 1 = indoor chores
replace chores = "" if strpos(chores, "indoor")
replace chores = "" if strpos(chores, "outdoor")
drop if inlist(chores, "1", "10000", "40000")
replace chores = "rain gutters" if strpos(chores,"rain")
replace chores = "laundry" if strpos(chores,"laundry")
replace chores = "kitchen cleaning" if strpos(chores, "kitchen")
replace chores = "lawn mowing" if strpos(chores, "mowing")
replace chores = "weeding" if strpos(chores, "weed")
replace chores = "vacuum" if strpos(chores, "vacuum")
rencode chores, replace
gen dv = 0 if inlist(chores,3,5)
replace dv = 1 if inlist(chores,1,2,4)

// subject ID variable
gen id = _n

// labeling variables and variable values
label var id "unique participant id"
rencode cond, replace
label var cond "menu partition manipulation"
replace cond = cond - 1
label define condl 0 "indoor packed" 1 "indoor unpacked"
label val cond condl
rencode position, replace
replace position = position - 1
label var position "menu partition position"
label define positionl 0 "packed category at bottom" 1 "packed category at top"
label val position positionl
label var dv "DV: choosing indoor/outdoor chore"
label define dvl 0 "outdoor chore" 1 "indoor chore"
label val dv dvl
replace gender = gender - 1
label var gender "participant gender"
label define genderl 0 "male" 1 "female"
label val gender genderl
label var age "participant age (in years)"

// removing crud
keep id cond position dv gender age
order id cond position dv gender age
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
logit dv i.position##i.cond
margins position, dydx(cond)

** Analysis - Robustness Check
** -----------------------------------------------
snapshot restore 1
replace dv = 0 if cond == 1 & dv == .
replace dv = 1 if cond == 0 & dv == .
prtest dv, by(cond)