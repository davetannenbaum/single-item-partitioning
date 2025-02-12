** ===============================================
** Study 3
** ===============================================

** Cleanup
** -----------------------------------------------
// loading raw data
// note: below I pull data from GitHub, but you may wish to change the file path to load data from your local working directory
snapshot erase _all
version 18.5
import delimited "https://raw.githubusercontent.com/davetannenbaum/single-item-partitioning/refs/heads/master/Study3/data.csv", varnames(1) clear

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

// cleaning up open responses
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
// note: uses the "encoder" package, to install type: ssc install encoder
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

// saving snapshot of data
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

// table of results
table trial cond, stat(mean dv) nformat(%9.3f) nototals

// logit and avg marginal effect
logit dv i.trial i.cond, cluster(id)
margins, dydx(cond)

// results for each domain
forvalues i = 1/4 {
	quietly logit dv i.cond if trial == `i', robust
	margins, dydx(cond)
}

** Analysis - Judgments
** -----------------------------------------------
snapshot restore 1

// table of results
table trial cond, stat(mean infer) nformat(%9.1f) nototals

// regression and avg marginal effect
regress infer i.trial i.cond, cluster(id)
margins, dydx(cond)

// results for each domain
forvalues i = 1/4 {
	quietly regress infer i.cond if trial == `i', robust
	margins, dydx(cond)
}

** Positioning effects
** -----------------------------------------------
snapshot restore 1

// interaction between partition and listing position
logit dv i.trial i.cond##i.position, cluster(id)

// partitioning effects when grouped listing is top vs bottom
margins position, dydx(cond)

// difference in avg marginal effects
margins position, dydx(cond) pwcompare(effects)

// interaction between partition and listing position
regress infer i.trial i.cond##i.position, cluster(id)

// partitioning effects when grouped listing is top vs bottom
margins position, dydx(cond)

** Correlation between judgments and choices
** -----------------------------------------------
// grand correlation
snapshot restore 1
pwcorr dv infer, sig

// avg correlation across items, within participants
snapshot restore 1
statsby corr=r(rho), by(id) clear nodots: corr dv infer
sum corr

// avg correlation within items, across participants
snapshot restore 1
statsby corr=r(rho), by(trial) clear nodots: corr dv infer
sum corr

** Block order effects
** -----------------------------------------------
snapshot restore 1
logit dv i.trial i.cond##i.order, cluster(id)
margins order, dydx(cond)
margins order, dydx(cond) pwcompare(effects)
regress infer i.trial i.cond##i.order, cluster(id)
margins order, dydx(cond)

** Restricting analysis to first block (choices)
** -----------------------------------------------
snapshot restore 1
keep if order == 1
table trial cond, stat(mean dv) nformat(%9.3f) nototals
logit dv i.trial i.cond, cluster(id)
margins, dydx(cond)
forvalues i = 1/4 {
	quietly logit dv i.cond if trial == `i', robust
	margins, dydx(cond)
}
logit dv i.trial i.cond##i.position, cluster(id)
margins position, dydx(cond)
margins position, dydx(cond) pwcompare(effects)

** Restricting analysis to first block (judgments)
** -----------------------------------------------
snapshot restore 1
keep if order == 2
table trial cond, stat(mean infer) nformat(%9.1f) nototals
regress infer i.trial i.cond, cluster(id)
margins, dydx(cond)
forvalues i = 1/4 {
	quietly regress infer i.cond if trial == `i', robust
	margins, dydx(cond)
}
regress infer i.trial i.cond##i.position, cluster(id)
margins position, dydx(cond)

** Mediation (KHB method)
** note: uses the "khb" package, to install type: ssc install khb
** -----------------------------------------------
snapshot restore 1
khb logit dv cond || infer, cluster(id) concomitant(i.trial)

** Bootstrapped mediation (KHB method)
** -----------------------------------------------
snapshot restore 1
set seed 987654321
capture program drop bootm
program bootm, rclass
  logit dv i.trial c.infer i.cond
  predict xb, xb
  regress xb i.trial i.cond
  local total = _b[1.cond]
  regress xb i.trial c.infer i.cond
  local direct = _b[1.cond]
  return scalar total = `total'
  return scalar direct = `direct'
  return scalar indirect = `total' - `direct'
  drop xb
end
bootstrap r(total) r(direct) r(indirect), cluster(id) reps(10000) nodots: bootm
estat boot

** Bootstrapped mediation by block ordering
** -----------------------------------------------
snapshot restore 1
keep if order == 1
set seed 987654321
capture program drop bootm
program bootm, rclass
  logit dv i.trial c.infer i.cond
  predict xb, xb
  regress xb i.trial i.cond
  local total = _b[1.cond]
  regress xb i.trial c.infer i.cond
  local direct = _b[1.cond]
  return scalar total = `total'
  return scalar direct = `direct'
  return scalar indirect = `total' - `direct'
  drop xb
end
bootstrap r(total) r(direct) r(indirect), cluster(id) reps(10000) nodots: bootm
estat boot

snapshot restore 1
keep if order == 2
set seed 987654321
capture program drop bootm
program bootm, rclass
  logit dv i.trial c.infer i.cond
  predict xb, xb
  regress xb i.trial i.cond
  local total = _b[1.cond]
  regress xb i.trial c.infer i.cond
  local direct = _b[1.cond]
  return scalar total = `total'
  return scalar direct = `direct'
  return scalar indirect = `total' - `direct'
  drop xb
end
bootstrap r(total) r(direct) r(indirect), cluster(id) reps(10000) nodots: bootm
estat boot

** Mediation (potential outcomes method)
** note: uses the "mediation" package, to install type: ssc install mediation
** -----------------------------------------------
snapshot restore 1
set seed 987654321
tab trial, gen(t)
medeff (regress infer t2 t3 t4 cond) (probit dv t2 t3 t4 infer cond), mediate(infer) treat(cond) vce(cluster id) sims(10000)

** Sensitivity analysis (potential outcomes method)
** note: the command 'mendsens' is installed as part of the "mediation" package, 
** but also requires the "moremata" package, to install type: ssc install moremata
** -----------------------------------------------
snapshot restore 1
set seed 987654321
tab trial, gen(t)
medsens (regress infer t2 t3 t4 cond) (probit dv t2 t3 t4 infer cond), mediate(infer) treat(cond) sims(10000)
twoway ///
	rarea _med_updelta0 _med_lodelta0 _med_rho, color(gs12) lwidth(none) || ///
	line _med_delta0 _med_rho, lcolor(black) lwidth(medthin) || ///
	scatteri -.25 0 .85 0, recast(line) lcolor(black) lwidth(medthin) || ///
	scatteri 0 -1 0 1, recast(line) lcolor(black) lwidth(medthin) || ///
	scatteri .10515728 -1 .10515728 1, recast(line) lcolor(black) lwidth(medthin) lpattern(dash) ///
	ytitle("Average Mediation Effect") ///
	xtitle("Sensitivity parameter: {&rho}") ///
	xlabel(-1(.5)1, nogrid) ///
	plotr(m(zero)) ///
	scheme(s1mono) ///
	legend(off)

** Robustness check: removing participants who had difficulty registering a preference
** note: uses the "xtab" package, to install type: ssc install xtab
** -----------------------------------------------
snapshot restore 1
xtab id if filter == 1, i(id)
replace dv = 0 if cond == 1 & filter == 1
replace dv = 1 if cond == 0 & filter == 1

table trial cond, stat(mean dv) nformat(%9.3f) nototals
logit dv i.trial i.cond, cluster(id)
margins, dydx(cond)
forvalues i = 1/4 {
	quietly logit dv i.cond if trial == `i', robust
	margins, dydx(cond)
}

set seed 987654321
capture program drop bootm
program bootm, rclass
  logit dv i.trial c.infer i.cond
  predict xb, xb
  regress xb i.trial i.cond
  local total = _b[1.cond]
  regress xb i.trial c.infer i.cond
  local direct = _b[1.cond]
  return scalar total = `total'
  return scalar direct = `direct'
  return scalar indirect = `total' - `direct'
  drop xb
end
bootstrap r(total) r(direct) r(indirect), cluster(id) reps(10000) nodots: bootm
estat boot