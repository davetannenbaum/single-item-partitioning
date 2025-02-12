** ===============================================
** Study 4
** ===============================================

** Cleanup
** -----------------------------------------------
// loading raw data
// note: below I pull data from GitHub, but you may wish to change the file path to load data from your local working directory
snapshot erase _all
version 18.5
import delimited "https://raw.githubusercontent.com/davetannenbaum/single-item-partitioning/refs/heads/master/Study4/data.csv", varnames(1) clear

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
rename q57 gender
replace gender = gender - 1
label define genderl 0 "Male" 1 "Female"
label val gender genderl
rename q59_1 age
rename v58 comments
rename sporting cond1
rename cookies cond2
rename westcoast cond3
rename europe cond4
rename q83_1 infer1
rename q84_1 infer2
rename q85_1 infer3
rename q86_1 infer4
rename q12 choice1
rename q22 choice2
rename q17 choice3
rename q3 choice4

// converting response strings to lower case and removing dead spaces
ds, has(type string) 
quietly foreach v of varlist choice1 choice2 choice3 choice4 {
	replace `v' = lower(`v') 
	replace `v' = rtrim(`v')
	replace `v' = itrim(`v')
	replace `v' = ltrim(`v')
}

// Cleaning up open responses
replace choice1 = "mlb" if inlist(choice1,"mlb game")
replace choice1 = "nfl" if inlist(choice1,"nfl game")
replace choice1 = "nba" if inlist(choice1,"nba game")
replace choice2 = "chocolate chip" if inlist(choice2,"chocolate chip cookie")
replace choice2 = "chocolate ice cream" if inlist(choice2,"chocolate ice cream cone")
replace choice2 = "oatmeal raisin" if inlist(choice2,"oatmeal raisin cookie")
replace choice2 = "peanut butter" if inlist(choice2,"peanut butter cookie")
replace choice2 = "strawberry ice cream" if inlist(choice2, "strawberry ice cream cone","strawberry")
replace choice2 = "vanilla ice cream" if inlist(choice2,"vanilla","vanilla ice cream cone")

// creating dependent variables
// note: uses the "encoder" package, to install type: ssc install encoder
encoder choice1, replace
encoder choice2, replace
encoder choice3, replace
encoder choice4, replace
recode choice1 (2 5 6 = 0 "cultural event") (1 3 4 = 1 "sports"), gen(dv1)
recode choice2 (2 5 6 = 0 "ice cream") (1 3 4 = 1 "cookie"), gen(dv2)
recode choice3 (1 2 6 = 0 "east coast") (3 4 5 = 1 "west coast"), gen(dv3)
recode choice4 (1 5 6 = 0 "asia") (2 3 4 = 1 "europe"), gen(dv4)

// reshaping data
gen id = _n
reshape long dv cond infer, i(id) j(trial)

// coding and labeling variables
encoder cond, replace
replace cond = cond - 1
label define condl 0 "packed" 1 "unpacked", replace
label val cond condl
encoder estimation, replace
replace estimation = estimation - 1
label define estimationl 0 "after" 1 "before", replace
label val estimation estimationl
encoder groupedcategory, replace
rename groupedcategory position
replace position = (position == 1)
label var position "menu partition position"
label define positionl 0 "packed category at top" 1 "packed category at bottom"
label val position positionl

// labeling trials
recode trial (4 = 1 "Vacations") (1 = 2 "Entertainment") (3 = 3 "Weekend trip") (2 = 4 "Deserts"), gen(trial2)
drop trial
rename trial2 trial

// pruning data set
keep id trial cond position estimation dv infer gender age comments filter
order id trial cond position estimation dv infer gender age comments filter

// saving snapshot of data
snapshot save

** Demographics
** -----------------------------------------------
snapshot restore 1
collapse age, by(id gender)
tab gender
sum age if age != 520

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

** Positioning effects - Preferences
** -----------------------------------------------
snapshot restore 1

// interaction between partition and listing position
logit dv i.trial i.cond##i.position, cluster(id)

// partitioning effects when grouped listing is top vs bottom
margins position, dydx(cond)

// difference in avg marginal effects
margins position, dydx(cond) pwcompare(effects)

** Interaction between timing of inferences and choice
** -----------------------------------------------
snapshot restore 1

// interaction between timing and choice
logit dv i.trial i.estimation##i.cond, cluster(id)

// partitioning effects when inferences are elicited before vs after exposure to partition
margins estimation, dydx(cond)

// difference in avg marginal effects
margins estimation, dydx(cond) pwcompare(effects)

// results for each domain
forvalues i = 1/4 {
	quietly logit dv i.cond if trial == `i' & estimation == 0, robust
	margins, dydx(cond)
}
forvalues i = 1/4 {
	quietly logit dv i.cond if trial == `i' & estimation == 1, robust
	margins, dydx(cond)
}

** Interaction between timing of inferences and judgments
** -----------------------------------------------
snapshot restore 1

// interaction between timing and inferences
regress infer i.trial i.estimation##i.cond, cluster(id)

// inferences before vs after exposure to partition
margins estimation, dydx(cond)

** Mediation (KHB method)
** note: uses the "khb" package, to install type: ssc install khb
** -----------------------------------------------
snapshot restore 1
separate dv, by(estimation)
separate infer, by(estimation)
khb logit dv0 cond || infer0, cluster(id) concomitant(i.trial)
khb logit dv1 cond || infer1, cluster(id) concomitant(i.trial)

** Bootstrapped mediation (KHB method)
** -----------------------------------------------
snapshot restore 1
separate dv, by(estimation)
separate infer, by(estimation)
set seed 987654321
capture program drop bootm
program bootm, rclass
  logit dv0 i.trial c.infer0 i.cond
  predict xb, xb
  regress xb i.trial i.cond
  local total0 = _b[1.cond]
  regress xb i.trial c.infer0 i.cond
  local direct0 = _b[1.cond]
  return scalar total0 = `total0'
  return scalar direct0 = `direct0'
  return scalar indirect0 = `total0' - `direct0'
  drop xb
end
bootstrap r(total0) r(direct0) r(indirect0), cluster(id) reps(10000) nodots: bootm
estat boot

snapshot restore 1
separate dv, by(estimation)
separate infer, by(estimation)
set seed 987654321
capture program drop bootm
program bootm, rclass
  logit dv1 i.trial c.infer1 i.cond
  predict xb, xb
  regress xb i.trial i.cond
  local total1 = _b[1.cond]
  regress xb i.trial c.infer1 i.cond
  local direct1 = _b[1.cond]
  return scalar total1 = `total1'
  return scalar direct1 = `direct1'
  return scalar indirect1 = `total1' - `direct1'
  drop xb
end
bootstrap r(total1) r(direct1) r(indirect1), cluster(id) reps(10000) nodots: bootm
estat boot
 
** Mediation (potential outcomes method)
** note: uses the "mediation" package, to install type: ssc install mediation
** -----------------------------------------------
snapshot restore 1
set seed 987654321
tab trial, gen(t)
separate dv, by(estimation)
separate infer, by(estimation)
medeff (regress infer0 t2 t3 t4 cond) (probit dv0 t2 t3 t4 infer0 cond), mediate(infer0) treat(cond) vce(cluster id) sims(10000)
medeff (regress infer1 t2 t3 t4 cond) (probit dv1 t2 t3 t4 infer1 cond), mediate(infer1) treat(cond) sims(10000)

** Sensitivity analysis (potential outcomes method)
** note: the command 'mendsens' is installed as part of the "mediation" package, 
** but also requires the "moremata" package, to install type: ssc install moremata
** -----------------------------------------------
snapshot restore 1
set seed 987654321
tab trial, gen(t)
separate dv, by(estimation)
separate infer, by(estimation)
set seed 1234
medsens (regress infer0 t2 t3 t4 cond) (probit dv0 t2 t3 t4 infer0 cond), mediate(infer0) treat(cond) sims(10000)
twoway ///
	rarea _med_updelta0 _med_lodelta0 _med_rho, color(gs12) lwidth(none) || ///
	line _med_delta0 _med_rho, lcolor(black) lwidth(medthin) || ///
	scatteri -.2 0 .3 0, recast(line) lcolor(black) lwidth(medthin) || ///
	scatteri 0 -1 0 1, recast(line) lcolor(black) lwidth(medthin) || ///
	scatteri .01320377 -1 .01320377 1, recast(line) lcolor(black) lwidth(medthin) lpattern(dash) ///
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

logit dv i.trial i.estimation##i.cond, cluster(id)
margins estimation, dydx(cond)
margins estimation, dydx(cond) pwcompare(effects)
forvalues i = 1/4 {
	quietly logit dv i.cond if trial == `i' & estimation == 0, robust
	margins, dydx(cond)
}
forvalues i = 1/4 {
	quietly logit dv i.cond if trial == `i' & estimation == 1, robust
	margins, dydx(cond)
}

snapshot restore 1
replace dv = 0 if cond == 1 & filter == 1
replace dv = 1 if cond == 0 & filter == 1
separate dv, by(estimation)
separate infer, by(estimation)
set seed 987654321
capture program drop bootm
program bootm, rclass
  logit dv0 i.trial c.infer0 i.cond
  predict xb, xb
  regress xb i.trial i.cond
  local total0 = _b[1.cond]
  regress xb i.trial c.infer0 i.cond
  local direct0 = _b[1.cond]
  return scalar total0 = `total0'
  return scalar direct0 = `direct0'
  return scalar indirect0 = `total0' - `direct0'
  drop xb
end
bootstrap r(total0) r(direct0) r(indirect0), cluster(id) reps(10000) nodots: bootm
estat boot

snapshot restore 1
replace dv = 0 if cond == 1 & filter == 1
replace dv = 1 if cond == 0 & filter == 1
separate dv, by(estimation)
separate infer, by(estimation)
set seed 987654321
capture program drop bootm
program bootm, rclass
  logit dv1 i.trial c.infer1 i.cond
  predict xb, xb
  regress xb i.trial i.cond
  local total1 = _b[1.cond]
  regress xb i.trial c.infer1 i.cond
  local direct1 = _b[1.cond]
  return scalar total1 = `total1'
  return scalar direct1 = `direct1'
  return scalar indirect1 = `total1' - `direct1'
  drop xb
end
bootstrap r(total1) r(direct1) r(indirect1), cluster(id) reps(10000) nodots: bootm
estat boot