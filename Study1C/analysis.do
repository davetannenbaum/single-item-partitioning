** ===============================================
** Study 1C
** ===============================================

** Cleanup
** -----------------------------------------------
// loading raw data
// note: below I pull data from GitHub, but you may wish to change the file path to load data from your local working directory
snapshot erase _all
version 18.5
import delimited "https://raw.githubusercontent.com/davetannenbaum/single-item-partitioning/refs/heads/master/Study1C/data.csv", varnames(1) clear bindquote(strict)  maxquotedrows(unlimited)

// dropping extra row of variable labels
drop in 1

// converting variables to numeric variables
quietly destring, replace

// remove unfinished responses and preview responses
drop if finished == 0

// removing rows of observations with duplicate IP addresses
sort startdate, stable
duplicates drop ipaddress, force

// generating choice variable (0 = less than $2, 1 = $2 or more}
egen response = rowfirst(q3 q4)
gen choice = .
replace choice = 0 if cond == 0 & inrange(response,1,4)
replace choice = 1 if cond == 0 & response == 5
replace choice = 0 if cond == 1 & response == 1
replace choice = 1 if cond == 1 & inrange(response,2,5)

// generating transfer amount
egen amount = rowfirst(q5-q14)

// renaming demographic variables
rename q16 gender
rename q17 age

// remove one participant who gave a transfer amount of $121
replace amount = . if amount > 10

// labeling variables and variable values
label var cond "menu partition manipulation"
label define condl 0 "low transfer unpacked" 1 "high transfer unpacked"
label val cond condl
label var choice "transfer $2 or more?"
label define choicel 0 "no" 1 "yes"
label val choice choicel
label var amount "dollar amount transferred to recipient"
replace gender = gender - 1
label var gender "participant gender"
label define genderl 0 "male" 1 "female"
label val gender genderl
label var age "participant age (in years)"

// removing crud
keep cond choice amount gender age
keep cond choice amount gender age

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

// percent choosing to transfer ≥ $2 as a function of menu partition
prtest choice, by(cond)

// amount transferred to recipient as a function of menu partition
ttest amount, by(cond)
esize twosample amount, by(cond)

** Restricting analysis to ``non-heuristic'' responses
** -----------------------------------------------
snapshot restore 1

// coding for heuristic responding
gen half = (amount == 5)
prtest half, by(cond)
gen zero = (amount == 0)
prtest zero, by(cond)
gen heuristic = (half == 1 | zero == 1)

// frequency of heuristic responding
tab heuristic
prtest heuristic, by(cond)

// percent choosing to transfer ≥ $2 as a function of menu partition
prtest choice if heuristic == 0, by(cond)

// amount transferred to recipient as a function of menu partition
ttest amount if heuristic == 0, by(cond)
esize twosample amount if heuristic == 0, by(cond)

// graphs indicating that effect of menu partition happens primarily in the interior between giving nothing and giving half
graph twoway kdensity amount if cond == 0, gaus || kdensity amount if cond == 1, gaus legend(off) xtitle("transfer amount")
cdfplot amount, by(cond) legend(off)