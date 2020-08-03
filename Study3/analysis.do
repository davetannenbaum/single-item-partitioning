** ===============================================
** Study 3
** ===============================================
** Note: csv file has a coded variable ("filter") for dropping subjects
** who reported difficulty  with task (choices might not be genuine)
** drop if filter == 1

** Cleanup
** -----------------------------------------------
// loading raw data
snapshot erase _all
cd "~/GitHub/single-item-partitioning/Study3/"
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
rename v121 gender
rename q59_1 age
rename q3 choice1
rename q12 choice2
rename q17 choice3
rename q22 choice4
rename europe cond1
rename sporting cond2
rename westcoast cond3
rename cookies cond4

// converting variables to numeric
// note: requires 'encoder' program from SSC
encoder grouped, replace setzero
encoder order, replace setzero
encoder cond1, replace setzero
encoder cond2, replace setzero
encoder cond3, replace setzero
encoder cond4, replace setzero

// converting all response strings to lower case and removing dead spaces
ds, has(type string) 
quietly foreach v of varlist `r(varlist)' {
	replace `v' = lower(`v') 
	replace `v' = rtrim(`v')
	replace `v' = itrim(`v')
	replace `v' = ltrim(`v')
}

// choice 1: vacations
// recoding responses to 0 = asian countries, 1 = european countries
encoder choice1, replace
recode choice1 (1 5 = 0 "asia") (2 3 4 = 1 "europe"), gen(dv1)

// choice 2: entertainment options
// recodings responses to 0 = cultural event, 1 = sporting event
replace choice2 = "mlb" if inlist(choice2, "mlb game")
replace choice2 = "nfl" if inlist(choice2, "nfl game")
replace choice2 = "nba" if inlist(choice2, "nba game")
encoder choice2, replace
recode choice2 (2 5 6 = 0 "cultural event") (1 3 4 = 1 "sports"), gen(dv2)

// choice 3: weekend city
// recodings responses to 0 = east coast city, 1 = west coast city
replace choice3 = "washington" if inlist(choice3, "washington d.c.")
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

// generating inference items
forvalues i = 1/4 {
	egen countries`i' = rowfirst(q28_`i' q29_`i' q31_`i' q11_`i')
	egen entertainment`i' = rowfirst(q34_`i' q35_`i' q36_`i' q37_`i')
	egen city`i' = rowfirst(q43_`i' q44_`i' q45_`i' q46_`i')
	egen dessert`i' = rowfirst(q50_`i' q51_`i' q52_`i' q53_`i')
}
foreach var of varlist countries* entertainment* dessert* city* {
	replace `var' = . if `var' == -99
}
gen infer1 = countries1 + countries2 + countries3 if grouped == 0 & cond1 == 1
replace infer1 = countries2 + countries3 + countries4 if grouped == 1 & cond1 == 1
replace infer1 = countries4 if grouped == 0 & cond1 == 0
replace infer1 = countries1 if grouped == 1 & cond1 == 0
gen infer2 = entertainment1 + entertainment2 + entertainment3 if grouped == 0 & cond2 == 1
replace infer2 = entertainment2 + entertainment3 + entertainment4 if grouped == 1 & cond2 == 1
replace infer2 = entertainment4 if grouped == 0 & cond2 == 0
replace infer2 = entertainment1 if grouped == 1 & cond2 == 0
gen infer3 = city1 + city2 + city3 if grouped == 0 & cond3 == 1
replace infer3 = city2 + city3 + city4 if grouped == 1 & cond3 == 1
replace infer3 = city4 if grouped == 0 & cond3 == 0
replace infer3 = city1 if grouped == 1 & cond3 == 0
gen infer4 = dessert1 + dessert2 + dessert3 if grouped == 0 & cond4 == 1
replace infer4 = dessert2 + dessert3 + dessert4 if grouped == 1 & cond4 == 1
replace infer4 = dessert4 if grouped == 0 & cond4 == 0
replace infer4 = dessert1 if grouped == 1 & cond4 == 0

// reshaping data
gen id = _n
reshape long dv cond infer, i(id) j(trial)

// labeling variables and variable values
label var id "unique participant id"
label var trial "choice trial"
label define triall 1 "vacations" 2 "entertainment options" 3 "weekend cities" 4 "desert options"
label val trial triall
label var cond "menu partition manipulation"
label define condl 0 "category A packed" 1 "category A unpacked"
label val cond condl
rename grouped position
label var position "menu partition position"
label define positionl 0 "packed category at bottom" 1 "packed category at top"
label val position positionl
label var order "order of choice/inference blocks"
label define orderl 0 "choice block first" 1 "inference block first"
label val order orderl
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
keep id trial position order cond dv infer gender age
order id trial position order cond dv infer gender age
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
logit dv i.trial i.cond, cluster(id)
margins, dydx(cond)
quietly logit dv i.trial##i.cond, cluster(id)
margins trial, dydx(cond)

// Inferences
snapshot restore 1
regress infer i.trial i.cond, cluster(id)
margins, dydx(cond)
quietly regress infer i.trial##i.cond, cluster(id)
margins trial, dydx(cond)

// Do preferences/inferences differ depending on what is elicited first?
snapshot restore 1
logit dv i.trial i.order##i.cond, cluster(id)
regress infer i.trial i.order##i.cond, cluster(id)

// Restricting analysis to first block
snapshot restore 1
logit dv i.trial i.cond if order == 0, cluster(id)
margins, dydx(cond)
regress infer i.trial i.cond if order == 1, cluster(id)
margins, dydx(cond)

// Grand Correlation
snapshot restore 1
pwcorr dv infer, sig

// Average across-items, within-subjects correlation
snapshot restore 1
statsby corr=r(rho), by(id) clear nodots: corr dv infer
sum corr

// Average across-subject, within-items correlation
snapshot restore 1
statsby corr=r(rho), by(trial) clear nodots: corr dv infer
sum corr

// Correlation using only data from first block
snapshot restore 1
replace infer = . if order == 1
replace infer = infer * .01
replace dv = . if order == 0
collapse dv infer, by(trial cond)
pwcorr dv infer, sig

// Mediation: khb method bootstrapped
// note: requires 'khb' program from SSC
snapshot restore 1
set seed 987654321
bootstrap _b[Diff], reps(10000) cluster(id) nodots: khb logit dv cond || c.infer //bootstrapped model
estat boot, bc percentile

// Mediation: alternative model
snapshot restore 1
khb regress infer cond || i.dv, summary vce(cluster id) // alternative model

// Mediation: Looking at whether inferences were measured first or second
khb logit dv cond || c.infer if order == 0, summary vce(cluster id) 
khb logit dv cond || c.infer if order == 1, summary vce(cluster id)