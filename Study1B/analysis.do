** ===============================================
** Study 1B
** ===============================================

** Cleanup
** -----------------------------------------------
// loading raw data
snapshot erase _all
version 16.1
import delimited "https://www.dropbox.com/s/rhd3qjxi6msyu7k/data.csv?dl=1", varnames(1) clear 

// dropping extra row of variable labels
drop in 1

// converting variables to numeric variables
quietly destring, replace

// drop duplicate IP address
duplicates drop v6, force

// renaming variables
rename q10 gender
rename q11 age
rename q12 comments

// generating choice variable
forvalues i = 1/6 {
	egen option`i' = rowfirst(q5_`i' q6_`i' q7_`i' q8_`i')
}
gen choice = .
forvalues i = 1/6 {
	replace choice = `i' if option`i' == 2
}
gen dv = .
replace dv = 0 if inlist(choice,4,5,6) & riskyoptions == "unpacked" & groupedoption == "bottom"
replace dv = 1 if inlist(choice,1,2,3) & riskyoptions == "unpacked" & groupedoption == "bottom"
replace dv = 0 if inlist(choice,1,2,3) & riskyoptions == "packed" & groupedoption == "bottom"
replace dv = 1 if inlist(choice,4,5,6) & riskyoptions == "packed" & groupedoption == "bottom"
replace dv = 0 if inlist(choice,1,2,3) & riskyoptions == "unpacked" & groupedoption == "top"
replace dv = 1 if inlist(choice,4,5,6) & riskyoptions == "unpacked" & groupedoption == "top"
replace dv = 0 if inlist(choice,4,5,6) & riskyoptions == "packed" & groupedoption == "top"
replace dv = 1 if inlist(choice,1,2,3) & riskyoptions == "packed" & groupedoption == "top"

// subject ID variable
gen id = _n

// labeling variables and variable values
label var id "unique participant id"
label var cond "menu partition manipulation"
label define condl 0 "risky packed" 1 "risky unpacked"
label val cond condl
label var position "menu partition position"
label define positionl 0 "packed category at top" 1 "packed category at bottom"
label val position positionl
label var dv "DV: choosing indoor/outdoor chore"
label define dvl 0 "less risky gamble" 1 "more risky gamble"
label val dv dvl
replace gender = gender - 1
label var gender "participant gender"
label define genderl 0 "male" 1 "female"
label val gender genderl
label var age "participant age (in years)"

// removing crud
keep id cond position dv gender age comments
order id cond position dv gender age comments
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

** Robustness Check: OLS regression
** -----------------------------------------------
snapshot restore 1
ttest dv, by(cond)
regress dv i.position##i.cond

** Payoffs
** -----------------------------------------------
snapshot restore 1
set seed 987654321
gen random = runiform()
sort random
keep in 1/5
gen draw = int((100-0+1)*runiform())