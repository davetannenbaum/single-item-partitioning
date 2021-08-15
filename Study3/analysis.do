** ===============================================
** Study 3
** ===============================================

** Cleanup
** -----------------------------------------------
// loading raw data
snapshot erase _all
version 16.1
import delimited "https://www.dropbox.com/s/cdgpgqee6ragepn/data.csv?dl=1", varnames(1) clear

// dropping extra row of variable labels
drop in 1

// converting variables to numeric variables
quietly destring, replace

// drop duplicate IP address
duplicates drop v6, force

// renaming and cleaning
drop in 1
quietly destring, replace
rename v6 ipaddress
rename v8 start
rename v9 end
rename v121 gender
rename q59_1 age
replace gender = gender - 1
label define genderl 0 "Male" 1 "Female"
label val gender genderl
rename q3 choice1
rename q12 choice2
rename q17 choice3
rename q22 choice4

ds, has(type string) 
quietly foreach v of varlist choice1 choice2 choice3 choice4 {
	replace `v' = lower(`v') 
	replace `v' = rtrim(`v')
	replace `v' = itrim(`v')
	replace `v' = ltrim(`v')
}

// Cleaning up open responses
replace choice2 = "mlb" if inlist(choice2,"mlb game")
replace choice2 = "nfl" if inlist(choice2,"nfl game")
replace choice2 = "nba" if inlist(choice2,"nba game")
replace choice2 = "musical" if inlist(choice2, "musical")
replace choice3 = "washington" if inlist(choice3,"washington d.c.")
replace choice4 = "chocolate chip" if inlist(choice4,"chocolate chip cookie")
replace choice4 = "chocolate ice cream" if inlist(choice4,"chocolate ice cream cone")
replace choice4 = "oatmeal raisin" if inlist(choice4,"oatmeal raisin cookie")
replace choice4 = "peanut butter" if inlist(choice4,"peanut butter cookie")
replace choice4 = "strawberry ice cream" if inlist(choice4, "strawberry ice cream cone","strawberry")
replace choice4 = "vanilla ice cream" if inlist(choice4,"vanilla","vanilla ice cream cone")

// generating new variables
forvalues i = 1/4 {
	gen countries`i' = q28_`i'  if q28_`i' != .
	replace countries`i' = q29_`i'  if q29_`i' != .
	replace countries`i' = q31_`i'  if q31_`i' != .
	replace countries`i' = q11_`i'  if q11_`i' != .
	gen entertainment`i' = q34_`i' if q34_`i' != .
	replace entertainment`i' = q35_`i' if q35_`i' != .
	replace entertainment`i' = q36_`i' if q36_`i' != .
	replace entertainment`i' = q37_`i' if q37_`i' != .
	gen city`i' = q43_`i'  if q43_`i' != .
	replace city`i' = q44_`i'  if q44_`i' != .
	replace city`i' = q45_`i'  if q45_`i' != .
	replace city`i' = q46_`i'  if q46_`i' != .
	gen dessert`i' = q50_`i'  if q50_`i' != .
	replace dessert`i' = q51_`i'  if q51_`i' != .
	replace dessert`i' = q52_`i'  if q52_`i' != .
	replace dessert`i' = q53_`i'  if q53_`i' != .
}

drop q*
order _all, alpha
encoder choice1, replace
encoder choice2, replace
encoder choice3, replace
encoder choice4, replace
encoder europe, replace
encoder sporting, replace
encoder westcoast, replace
encoder cookies, replace
encoder order, replace
encoder groupedcategory, replace


// creating dependent variables
recode choice1 (1 5 = 0 "asia") (2 3 4 = 1 "europe"), gen(dv1)
recode choice2 (2 5 6 = 0 "cultural event") (1 3 4 = 1 "sports"), gen(dv2)
recode choice3 (1 2 6 = 0 "east coast") (3 4 5 = 1 "west coast"), gen(dv3)
recode choice4 (2 5 6 = 0 "ice cream") (1 3 4 = 1 "cookie"), gen(dv4)

// creating treatment variables
rename europe cond1
rename sporting cond2
rename westcoast cond3
rename cookies cond4

foreach var of varlist countries* entertainment* dessert* city* {
	replace `var' = . if `var' == -99
}

// generating inference items
gen infer1 = countries1 + countries2 + countries3 if grouped == 1 & cond1 == 2
replace infer1 = countries2 + countries3 + countries4 if grouped == 2 & cond1 == 2
replace infer1 = countries4 if grouped == 1 & cond1 == 1
replace infer1 = countries1 if grouped == 2 & cond1 == 1
gen infer2 = entertainment1 + entertainment2 + entertainment3 if grouped == 1 & cond2 == 2
replace infer2 = entertainment2 + entertainment3 + entertainment4 if grouped == 2 & cond2 == 2
replace infer2 = entertainment4 if grouped == 1 & cond2 == 1
replace infer2 = entertainment1 if grouped == 2 & cond2 == 1
gen infer3 = city1 + city2 + city3 if grouped == 1 & cond3 == 2
replace infer3 = city2 + city3 + city4 if grouped == 2 & cond3 == 2
replace infer3 = city4 if grouped == 1 & cond3 == 1
replace infer3 = city1 if grouped == 2 & cond3 == 1
gen infer4 = dessert1 + dessert2 + dessert3 if grouped == 1 & cond4 == 2
replace infer4 = dessert2 + dessert3 + dessert4 if grouped == 2 & cond4 == 2
replace infer4 = dessert4 if grouped == 1 & cond4 == 1
replace infer4 = dessert1 if grouped == 2 & cond4 == 1

// reshaping data
gen id = _n
reshape long dv cond infer, i(id) j(trial)
label drop cookies
label drop dv4
replace cond = (cond == 2)

// recoding and labeling group position variable
rename groupedcategory position
replace position = (position == 1)
label var position "menu partition position"
label define positionl 0 "packed category at top" 1 "packed category at bottom"
label val position positionl

// labeling trials
label define triall 1 "Vacations" 2 "Entertainment" 3 "Weekend trip" 4 "Deserts"
label val trial triall

// pruning data set 
keep id trial dv cond infer order position gender age filter
order id trial dv cond infer order position gender age filter
snapshot save

** Demographics
** -----------------------------------------------
snapshot restore 1
collapse age, by(id gender)
tab gender
sum age

** Analysis - Preferences
** -----------------------------------------------
snapshot restore 1
table trial cond, c(mean dv) format(%9.3f)
logit dv i.trial i.cond, cluster(id)
margins, dydx(cond)
forvalues i = 1/4 {
	quietly logit dv i.cond if trial == `i', cluster(id)
	margins, dydx(*)
}
logit dv i.trial i.cond##i.position, cluster(id)
margins position, dydx(cond)

** Analysis - Inferences
** -----------------------------------------------
snapshot restore 1
table trial cond, c(mean infer) format(%9.3f)
regress infer i.trial i.cond, cluster(id)
margins, dydx(cond)
forvalues i = 1/4 {
	quietly regress infer i.cond if trial == `i', cluster(id)
	margins, dydx(*)
}
regress infer i.trial i.cond##i.position, cluster(id)
margins position, dydx(cond)

** Restricting analysis to first block
** -----------------------------------------------
snapshot restore 1
keep if order == 1
table trial cond, c(mean dv) format(%9.3f)
logit dv i.trial i.cond, cluster(id)
margins, dydx(cond)
forvalues i = 1/4 {
	quietly logit dv i.cond if trial == `i', cluster(id)
	margins, dydx(*)
}
logit dv i.trial i.cond##i.position, cluster(id)
margins position, dydx(cond)

snapshot restore 1
keep if order == 2
table trial cond, c(mean infer) format(%9.3f)
regress infer i.trial i.cond, cluster(id)
margins, dydx(cond)
forvalues i = 1/4 {
	quietly regress infer i.cond if trial == `i', cluster(id)
	margins, dydx(*)
}
regress infer i.trial i.cond##i.position, cluster(id)
margins position, dydx(cond)

** Correlation between inferences and choices
** -----------------------------------------------
// Grand Correlation
snapshot restore 1
pwcorr dv infer, sig

// Average across-items, within-subjects correlation
snapshot restore 1
statsby corr=r(rho), by(id) clear nodots: corr dv infer
sum corr
signtest corr = 0

// Average across-subject, within-items correlation
snapshot restore 1
statsby corr=r(rho), by(trial) clear nodots: corr dv infer
sum corr
signtest corr = 0

// Group-level correlation using only data from first block
snapshot restore 1
replace infer = . if order == 1
replace infer = infer * .01
replace dv = . if order == 2
collapse dv infer, by(trial cond)
pwcorr dv infer, sig

** Mediation
** -----------------------------------------------
// khb method
snapshot restore 1
khb logit dv cond || c.infer, summary vce(cluster id) concomitant(i.trial) verbose

// khb method - bootstrapped
snapshot restore 1
set seed 987654321
capture program drop bootm
program bootm, rclass
  khb logit dv cond || c.infer, concomitant(i.trial)
  return scalar total = el(e(b),1,1)
  return scalar direct = el(e(b),1,2)
  return scalar indirect = el(e(b),1,3)
end
bootstrap r(total) r(direct) r(indirect), cluster(id) reps(10000) nodots: bootm
estat boot, bc percentile

// Looking at whether inferences were measured first or second
snapshot restore 1
keep if order == 1
set seed 987654321
capture program drop bootm
program bootm, rclass
  khb logit dv cond || c.infer, concomitant(i.trial)
  return scalar total = el(e(b),1,1)
  return scalar direct = el(e(b),1,2)
  return scalar indirect = el(e(b),1,3)
end
bootstrap r(total) r(direct) r(indirect), cluster(id) reps(10000) nodots: bootm
estat boot, bc percentile

snapshot restore 1
keep if order == 2
set seed 987654321
capture program drop bootm
program bootm, rclass
  khb logit dv cond || c.infer, concomitant(i.trial)
  return scalar total = el(e(b),1,1)
  return scalar direct = el(e(b),1,2)
  return scalar indirect = el(e(b),1,3)
end
bootstrap r(total) r(direct) r(indirect), cluster(id) reps(10000) nodots: bootm
estat boot, bc percentile

// Mediation: potential outcomes approach
snapshot restore 1
set seed 987654321
tab trial, gen(t)
medeff (regress infer t2 t3 t4 cond) (probit dv t2 t3 t4 infer cond), mediate(infer) treat(cond) vce(cluster id) sims(10000)
medsens (regress infer t2 t3 t4 cond) (probit dv t2 t3 t4 infer cond), mediate(infer) treat(cond) sims(1000) graph
graph twoway rarea _med_updelta0 _med_lodelta0 _med_rho, bcolor(gs14) || line _med_delta0 _med_rho, lcolor(black) ytitle("ACME") title("ACME({&rho})") xtitle("Sensitivity parameter: {&rho}") legend(off) scheme(sj)


** Robustness Check: removing participants who had difficulty registered a preference
** -----------------------------------------------
snapshot restore 1
xtab id if filter == 1, i(id)
replace dv = 0 if cond == 1 & filter == 1
replace dv = 1 if cond == 0 & filter == 1

table trial cond, c(mean dv mean infer) format(%9.3f)
logit dv i.trial i.cond, cluster(id)
margins, dydx(*)
forvalues i = 1/4 {
	quietly logit dv i.cond if trial == `i', cluster(id)
	margins, dydx(*)
}
regress infer i.trial i.cond##i.position, cluster(id)
margins position, dydx(cond)

set seed 987654321
capture program drop bootm
program bootm, rclass
  khb logit dv cond || c.infer, concomitant(i.trial)
  return scalar total = el(e(b),1,1)
  return scalar direct = el(e(b),1,2)
  return scalar indirect = el(e(b),1,3)
end
bootstrap r(total) r(direct) r(indirect), cluster(id) reps(10000) nodots: bootm
estat boot, bc percentile

set seed 987654321
tab trial, gen(t)
medeff (regress infer t2 t3 t4 cond) (logit dv t2 t3 t4 infer cond), mediate(infer) treat(cond) vce(cluster id) sims(10000)