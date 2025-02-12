** ===============================================
** Study 5
** ===============================================

** Cleanup
** -----------------------------------------------
// loading raw data
// note: below I pull data from GitHub, but you may wish to change the file path to load data from your local working directory
snapshot erase _all
version 18.5
import delimited "https://raw.githubusercontent.com/davetannenbaum/single-item-partitioning/refs/heads/master/Study5/data.csv", varnames(1) clear bindquote(strict)

// dropping extra rows of variable labels
drop in 1/2

// converting variables to numeric variables
quietly destring, replace

// remove unfinished responses and preview responses
drop if finished == 0
drop if status != 0

// drop duplicate IP address
sort startdate, stable
duplicates drop ipaddress, force

// renaming and cleaning
rename q61 gender
rename q62_1 age
replace gender = gender - 1
label define genderl 0 "Male" 1 "Female"
label val gender genderl
rename q9 choice1
rename q14 choice2
rename q19 choice3
rename q24 choice4

ds, has(type string) 
quietly foreach v of varlist choice1 choice2 choice3 choice4 {
	replace `v' = lower(`v') 
	replace `v' = rtrim(`v')
	replace `v' = itrim(`v')
	replace `v' = ltrim(`v')
}

// Cleaning up open responses
replace choice1 = "italy" if inlist(choice1,"european country, italy","italia","european country (italy)","italy!","itlay")
replace choice1 = "france" if inlist(choice1,"francce","france european country")
replace choice1 = "japan" if inlist(choice1,"asian country (japan)","okanwa japan")
replace choice1 = "" if ~inlist(choice1,"china","japan","vietnam","france","italy","germany")

replace choice2 = "mlb" if inlist(choice2,"mlb game","baseball game","mlb gamme","mlb)","sporting event (mlb)","yankees baseball game")
replace choice2 = "nfl" if inlist(choice2,"attend an nfl game.","college football","football game","lions game","nfl event","nfl football")
replace choice2 = "nfl" if inlist(choice2,"nfl football game","nfl game","nfl sporting event","nfl or mlb game","sporting event (nfl)","sporting event - nfl","sporting event, nfl","sporting event. nfl")
replace choice2 = "nba" if inlist(choice2,"basketball game","nba game","nba game.","sporting event nba game")
replace choice2 = "nhl" if inlist(choice2,"nhl game","nashville predators hockey game","sporting event, hockey","st louis blues","nil game")
replace choice2 = "musical" if inlist(choice2,"a musical at the local theatre","broadway production","cats","cultural event (musical)","cultural event - musical","cultural event musical","musical event")
replace choice2 = "theater" if inlist(choice2,"cultural event (theater)","cultural event theater","theater cultural event","theatre","theatre production","ugh. i guess theater")
replace choice2 = "" if ~inlist(choice2,"theater","opera","musical","nba","mlb","nfl")

replace choice3 = "boston" if inlist(choice3,"east coast city (boston)")
replace choice3 = "washington" if inlist(choice3,"washington, dc","washington, d.c.","washington dc","washington d.c","washington d c","washington d.c.","washington d. c.","d.c.","dc")
replace choice3 = "san francisco" if inlist(choice3,"francisco","san fancisco","san fran","san fransicso","san fransisco")
replace choice3 = "san francisco" if inlist(choice3,"sand francisco west coast city","sanfrancisco","west coast city (san francisco)","west coast city, san francisco","west coast, san francisco")
replace choice3 = "seattle" if inlist(choice3,"west coast seattle","west coast city seattle","west coast, seattle")
replace choice3 = "portland" if inlist(choice3,"portland.")
replace choice3 = "" if ~inlist(choice3,"boston","washington","philadelphia","san francisco","portland","seattle")

replace choice4 = "chocolate chip" if inlist(choice4,"chocolate","chocloate chip cookie","chocolate chip cookie","chocolate chip cookies","cookie (chocolate chip)","cookie chocolate chip")
replace choice4 = "chocolate chip" if inlist(choice4,"choc chip cookie","choco chip cookie","cookie - chocolate chip","cookie, chocolate chip")
replace choice4 = "oatmeal raisin" if inlist(choice4,"oatmeal raisin cookie","oatmeal cookie","cookie (oatmeal raisin)","cookie oatmeal raisin")
replace choice4 = "peanut butter" if inlist(choice4,"peanut butter cookie","cookie (peanut butter)","cookie-peanut butter")
replace choice4 = "mint chip ice cream" if inlist(choice4,"ice cream cone mint chip","ice cream cone mint chocolate chip","ice cream mint chip","mint","mint chip cone","mint chip ice cream cone","mint chip")
replace choice4 = "mint chip ice cream" if inlist(choice4,"ice cream cone (mint chip)","ice cream cone - mint chip","ice cream cone, mint chip","mint chi","mint chip non-dairy option","mint chocolate chip")
replace choice4 = "strawberry ice cream" if inlist(choice4,"strawberry ice cream cone","strawberry","ice cream cone strawberry","srawberry ice cream")
replace choice4 = "strawberry ice cream" if inlist(choice4,"ice cream cone: strawberry","strawberry ice creamcone","strawberry ice crem cone","strawberry ice-cream")
replace choice4 = "vanilla ice cream" if inlist(choice4,"vanilla","vanilla ice cream cone","ice cream cone - vanilla","ice cream cone vanilla","ice cream cone. vanilla flavor","vanilla cone","vanilla ice cream cone","vanillia")
replace choice4 = "vanilla ice cream" if inlist(choice4,"ice cream cone, vanilla","vanilla ice cream","vanilla ice cream cone.")
replace choice4 = "" if ~inlist(choice4,"chocolate chip","oatmeal raisin","peanut butter","mint chip ice cream","strawberry ice cream","vanilla ice cream")

// generating new inference variables
// note: uses the "encoder" package, to install type: ssc install encoder
forvalues i = 1/4 {
	generate countries`i' = q27_`i'  if q27_`i' != .
	replace countries`i' = q29_`i'  if q29_`i' != .
	replace countries`i' = q31_`i'  if q31_`i' != .
	replace countries`i' = q33_`i'  if q33_`i' != .
	generate entertainment`i' = q35_`i' if q35_`i' != .
	replace entertainment`i' = q37_`i' if q37_`i' != .
	replace entertainment`i' = q39_`i' if q39_`i' != .
	replace entertainment`i' = q41_`i' if q41_`i' != .
	generate city`i' = q43_`i'  if q43_`i' != .
	replace city`i' = q45_`i'  if q45_`i' != .
	replace city`i' = q47_`i'  if q47_`i' != .
	replace city`i' = q49_`i'  if q49_`i' != .
	generate dessert`i' = q51_`i'  if q51_`i' != .
	replace dessert`i' = q53_`i'  if q53_`i' != .
	replace dessert`i' = q55_`i'  if q55_`i' != .
	replace dessert`i' = q57_`i'  if q57_`i' != .
}

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
recode choice1 (1 5 6 = 0 "asia") (2 3 4 = 1 "europe"), gen(dv1)
recode choice2 (2 5 6 = 0 "cultural event") (1 3 4 = 1 "sports"), gen(dv2)
recode choice3 (1 2 6 = 0 "east coast") (3 4 5 = 1 "west coast"), gen(dv3)
recode choice4 (2 5 6 = 0 "ice cream") (1 3 4 = 1 "cookie"), gen(dv4)

// creating treatment variables
rename europe cond1
rename sporting cond2
rename westcoast cond3
rename cookies cond4

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

// susceptibility to interpersonal influence
alpha q58_1 q58_2 q58_3 q58_4, item gen(nsi)
alpha q59_1 q59_2 q59_3 q59_4, item gen(isi)
replace nsi = nsi - 4
replace isi = isi - 4
pwcorr nsi isi

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
keep id trial dv cond infer order position gender age nsi isi
order id trial dv cond infer order position gender age nsi isi

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

** Analysis - Inferences
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

** Correlation between inferences and choices
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
khb logit dv cond || c.infer, summary vce(cluster id) concomitant(i.trial) verbose

** Bootstrapped mediation (KHB method)
** -----------------------------------------------
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

** Bootstrapped mediation by block ordering
** -----------------------------------------------
// choices first
snapshot restore 1
set seed 987654321
keep if order == 1
capture program drop bootm
program bootm, rclass
  khb logit dv cond || c.infer, concomitant(i.trial)
  return scalar total = el(e(b),1,1)
  return scalar direct = el(e(b),1,2)
  return scalar indirect = el(e(b),1,3)
end
bootstrap r(total) r(direct) r(indirect), cluster(id) reps(10000) nodots: bootm
estat boot, bc percentile

// judgments first
snapshot restore 1
set seed 987654321
keep if order == 2
capture program drop bootm
program bootm, rclass
  khb logit dv cond || c.infer, concomitant(i.trial)
  return scalar total = el(e(b),1,1)
  return scalar direct = el(e(b),1,2)
  return scalar indirect = el(e(b),1,3)
end
bootstrap r(total) r(direct) r(indirect), cluster(id) reps(10000) nodots: bootm
estat boot, bc percentile

** Moderation/Subgroup Analysis
** -----------------------------------------------
snapshot restore 1

// recoding inferences to fall between [0,1], so that inference and choice are on similar scales
replace infer = infer * .01

// model 1
regress dv i.trial i.cond##c.nsi, cluster(id)

// model 2
regress dv i.trial i.cond##c.isi, cluster(id)

// model 3
regress infer i.trial i.cond##c.nsi, cluster(id)

// model 4
regress infer i.trial i.cond##c.isi, cluster(id)

// model 5
regress dv i.trial i.cond c.infer##c.nsi, cluster(id)

// model 6
regress dv i.trial i.cond c.infer##c.isi, cluster(id)

// same thing, but examining p-values when using logit models for models 1, 2, 5, and 6
logit dv i.trial i.cond##c.nsi, cluster(id)
logit dv i.trial i.cond##c.isi, cluster(id)
regress infer i.trial i.cond##c.nsi, cluster(id)
regress infer i.trial i.cond##c.isi, cluster(id)
logit dv i.trial i.cond c.infer##c.nsi, cluster(id)
logit dv i.trial i.cond c.infer##c.isi, cluster(id)

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
	scatteri -.25 0 .88 0, recast(line) lcolor(black) lwidth(medthin) || ///
	scatteri 0 -1 0 1, recast(line) lcolor(black) lwidth(medthin) || ///
	scatteri .11778991 -1 .11778991 1, recast(line) lcolor(black) lwidth(medthin) lpattern(dash) ///
	ytitle("Average Mediation Effect") ///
	xtitle("Sensitivity parameter: {&rho}") ///
	xlabel(-1(.5)1, nogrid) ///
	plotr(m(zero)) ///
	scheme(s1mono) ///
	legend(off)
graph twoway rarea _med_updelta0 _med_lodelta0 _med_rho, bcolor(gs14) || line _med_delta0 _med_rho, lcolor(black) ytitle("ACME") title("ACME({&rho})") xtitle("Sensitivity parameter: {&rho}") legend(off) scheme(sj)