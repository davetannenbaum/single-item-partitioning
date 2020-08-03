** ===============================================
** Study 4
** ===============================================

** Cleanup
** -----------------------------------------------
// loading raw data
snapshot erase _all
cd "~/GitHub/single-item-partitioning/Study4/"
import delimited data.csv, varnames(1) clear

// dropping extra row of variable labels
drop in 1

// converting variables to numeric variables
quietly destring, replace

// removing rows of observations with duplicate IP addresses
// (IP addresses replaced with unique identifier to protect participant privacy)
sort v8
duplicates drop v6, force

// renaming condition variables
rename europe cond1
rename sporting cond2
rename westcoast cond3
rename cookies cond4

// renaming choice variables
rename q3 choice1
rename q12 choice2
rename q17 choice3
rename q22 choice4

// rename inference variables
rename q86_1 infer1
rename q83_1 infer2
rename q85_1 infer3
rename q84_1 infer4

// renaming age and gender
rename q57 gender
rename q59 age

// converting response strings to lower case and removing dead spaces
ds, has(type string) 
quietly foreach v of varlist `r(varlist)' {
	replace `v' = lower(`v') 
	replace `v' = rtrim(`v')
	replace `v' = itrim(`v')
	replace `v' = ltrim(`v')
}

// choice 1: vacations
// recoding responses to 0 = asian countries, 1 = european countries
// note: requires 'encoder' program from SSC
encoder choice1, replace
recode choice1 (1 5 6 = 0 "asia") (2 3 4 = 1 "europe"), gen(dv1)

// choice 2: entertainment options
// recodings responses to 0 = cultural event, 1 = sporting event
replace choice2 = "mlb" if inlist(choice2, "mlb game")
replace choice2 = "nfl" if inlist(choice2, "nfl game")
replace choice2 = "nba" if inlist(choice2, "nba game")
encoder choice2, replace
recode choice2 (2 5 6 = 0 "cultural event") (1 3 4 = 1 "sports"), gen(dv2)

// choice 3: weekend city
// recodings responses to 0 = east coast city, 1 = west coast city
encoder choice3, replace
recode choice3 (1 2 6 = 0 "east coast") (3 4 5 = 1 "west coast"), gen(dv3)

// choice 4: desert
// recodings responses to 0 = ice cream, 1 = cookie
replace choice4 = "chocolate chip" if inlist(choice4, "chocolate chip cookie")
replace choice4 = "chocolate ice cream" if inlist(choice4, "chocolate ice cream cone", "chocolate ice cream")
replace choice4 = "oatmeal raisin" if inlist(choice4, "oatmeal raisin cookie")
replace choice4 = "peanut butter" if inlist(choice4, "peanut butter cookie")
replace choice4 = "strawberry ice cream" if inlist(choice4, "strawberry", "strawberry ice cream cone")
replace choice4 = "vanilla ice cream" if inlist(choice4, "vanilla", "vanilla ice cream cone")
encoder choice4, replace
recode choice4 (2 5 6 = 0 "ice cream") (1 3 4 = 1 "cookie"), gen(dv4)

// reshaping data
gen id = _n
reshape long dv cond infer, i(id) j(trial)

// labeling variables and variable values
label var id "unique participant id"
label var trial "choice trial"
label define triall 1 "vacations" 2 "entertainment options" 3 "weekend cities" 4 "desert options"
label val trial triall
label var cond "menu partition manipulation"
encoder cond, replace
replace cond = cond - 1
label define condl 0 "category A packed" 1 "category A unpacked"
label val cond condl
label var estimation "estimating popularity before/after viewing menu partition"
encoder estimation, replace
replace estimation = estimation - 1
label define estimationl 0 "after" 1 "before", replace
label val estimation estimationl
rename grouped position
encoder position, replace
replace position = position - 1
label var position "menu partition position"
label define positionl 0 "packed category at bottom" 1 "packed category at top"
label val position positionl
label var dv "DV: choosing item from category A vs B"
label define dvl 0 "Category B" 1 "Category A"
label val dv dvl
label var infer "predicted choice share for category A/B items"
replace gender = gender - 1
label var gender "participant gender"
label define genderl 0 "male" 1 "female"
label val gender genderl
label var age "participant age (in years)"

// pruning data set
keep id trial cond estimation position dv infer gender age
order id trial cond estimation position dv infer gender age
snapshot save

** Demographics
** -----------------------------------------------
snapshot restore 1
collapse age, by(id gender)
tab gender
sum age

** Analysis
** -----------------------------------------------
// Preferences
snapshot restore 1
logit dv i.trial i.cond, cluster(id) nolog
margins, dydx(cond)
logit dv i.trial i.estimation##i.cond, cluster(id) nolog
margins estimation, dydx(cond)
margins estimation, dydx(cond) pwcompare

// Inferences
snapshot restore 1
regress infer i.trial i.cond, cluster(id)
margins, dydx(cond)
regress infer i.trial i.estimation##i.cond, cluster(id)
margins estimation, dydx(cond) 
margins estimation, dydx(cond) pwcompare

// Mediation: khb method bootstrapped
snapshot restore 1
separate dv, by(estimation)
separate infer, by(estimation)
set seed 987654321
bootstrap _b[Diff], reps(10000) nodots: khb logit dv0 cond || infer, vce(cluster id)
estat boot, bc percentile
bootstrap _b[Diff], reps(10000) nodots: khb logit dv1 cond || infer, vce(cluster id)
estat boot, bc percentile

// Moderated Mediation (Hayes, 2013 Model 8)
snapshot restore 1
gen intx = cond * estimation
tab trial, gen(trial)
gsem (infer <- trial2-trial4 cond estimation intx) (dv <- trial2-trial4 cond estimation intx infer, family(binomial) link(logit)), vce(cluster id)
nlcom (_b[infer:cond]+0*_b[infer:intx]) * _b[dv:infer]
nlcom (_b[infer:cond]+1*_b[infer:intx]) * _b[dv:infer]
nlcom _b[infer:intx] * _b[dv:infer]

// Bootstrapped Moderated Mediation (Hayes, 2013 Model 8)
snapshot restore 1
gen intx = cond * estimation
tab trial, gen(trial)
capture program drop _all
program modmed, rclass
  gsem (infer <- trial2-trial4 cond estimation intx) (dv <- trial2-trial4 cond estimation intx , family(binomial) link(logit)), vce(cluster id)
  return scalar indirect = _b[infer:intx] * _b[dv:infer]
end
set seed 987654321
bootstrap r(indirect), reps(10000) nodots: modmed
estat boot, bc percentile