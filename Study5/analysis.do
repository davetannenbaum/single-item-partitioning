** ===============================================
** Study 5
** ===============================================

** Cleanup
** -----------------------------------------------
// loading raw data
snapshot erase _all
version 16.1
import delimited "https://git.io/JRjsC", varnames(1) clear bindquote(strict)

// dropping extra rows of variable labels
drop in 1/2

// converting variables to numeric variables
quietly destring, replace

// remove unfinished responses and preview responses
drop if finished == 0
drop if status != 0

// drop duplicate IP address
sort v8, stable
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

// recoding and labeling variables
rename groupedcategory position
replace position = (position == 1)
label define positionl 0 "packed category at top" 1 "packed category at bottom"
label val position positionl
label define triall 1 "Vacations" 2 "Entertainment" 3 "Weekend trip" 4 "Deserts"
label val trial triall
replace order = order - 1
label define orderl 0 "choice block first" 1 "inference block first"
label val order orderl
label define condl 0 "category A packed" 1 "category A unpacked"
label val cond condl
label define dvl 0 "Category B" 1 "Category A"
label val dv dvl
label var id "unique participant id"
label var trial "choice trial"
label var dv "DV: choosing item from category A vs B"
label var cond "menu partition manipulation"
label var infer "predicted choice share for category A/B items"
label var order "order of choice/inference blocks"
label var position "menu partition position"
label var gender "participant gender"
label var age "participant age (in years)"
label var nsi "susceptibility to normative social influence score"
label var isi "susceptibility to informational social influence score"

// pruning data set 
keep id trial dv cond infer order position gender age nsi isi
order id trial dv cond infer order position gender age nsi isi
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

** Analysis - Inferences
** -----------------------------------------------
snapshot restore 1
table trial cond, c(mean infer) format(%9.3f)
regress infer i.trial i.cond, cluster(id)
forvalues i = 1/4 {
	quietly regress infer i.cond if trial == `i', cluster(id)
	margins, dydx(*)
}

** Position effects
** -----------------------------------------------
snapshot restore 1
logit dv i.trial i.cond##i.position, cluster(id)
margins position, dydx(cond)
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

// Average across-subject, within-items correlation
snapshot restore 1
statsby corr=r(rho), by(trial) clear nodots: corr dv infer
sum corr

** Does block order moderate results?
** -----------------------------------------------
snapshot restore 1
logit dv i.trial i.cond##i.order, cluster(id)
margins order, dydx(cond)
regress infer i.trial i.cond##i.order, cluster(id)
margins order, dydx(cond)

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
table trial cond, c(mean infer) format(%9.1f)
regress infer i.trial i.cond, cluster(id)
forvalues i = 1/4 {
	quietly regress infer i.cond if trial == `i', cluster(id)
	margins, dydx(*)
}
regress infer i.trial i.cond##i.position, cluster(id)
margins position, dydx(cond)

** Mediation (KHB method)
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
snapshot restore 1
khb logit dv cond || c.infer if order == 1, summary vce(cluster id) concomitant(i.trial)
khb logit dv cond || c.infer if order == 2, summary vce(cluster id) concomitant(i.trial)

** Mediation (potential outcomes method)
** -----------------------------------------------
snapshot restore 1
set seed 987654321
tab trial, gen(t)
medeff (regress infer t2 t3 t4 cond) (probit dv t2 t3 t4 infer cond), mediate(infer) treat(cond) vce(cluster id) sims(10000)

** Sensitivity analysis (potential outcomes method)
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

** Moderation/Subgroup Analysis
** -----------------------------------------------
snapshot restore 1
replace infer = infer * .01

regress dv i.trial i.cond##c.nsi, cluster(id)
regress dv i.trial i.cond##c.isi, cluster(id)
regress infer i.trial i.cond##c.nsi, cluster(id)
regress infer i.trial i.cond##c.isi, cluster(id)
regress dv i.trial i.cond c.infer##c.nsi, cluster(id)
regress dv i.trial i.cond c.infer##c.isi, cluster(id)

logit dv i.trial i.cond##c.nsi, cluster(id)
logit dv i.trial i.cond##c.isi, cluster(id)
regress infer i.trial i.cond##c.nsi, cluster(id)
regress infer i.trial i.cond##c.isi, cluster(id)
logit dv i.trial i.cond c.infer##c.nsi, cluster(id)
logit dv i.trial i.cond c.infer##c.isi, cluster(id)


** Robustness check: removing participants who had difficulty registering a preference
** -----------------------------------------------
snapshot restore 1
replace dv = 0 if cond == 1 & dv == .
replace dv = 1 if cond == 0 & dv == .

table trial cond, c(mean dv) format(%9.3f)
logit dv i.trial i.cond, cluster(id)
margins, dydx(cond)
forvalues i = 1/4 {
	quietly logit dv i.cond if trial == `i', cluster(id)
	margins, dydx(*)
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

replace infer = infer * .01
regress dv i.trial i.cond##c.nsi, cluster(id)
regress dv i.trial i.cond##c.isi, cluster(id)
regress infer i.trial i.cond##c.nsi, cluster(id)
regress infer i.trial i.cond##c.isi, cluster(id)
regress dv i.trial i.cond c.infer##c.nsi, cluster(id)
regress dv i.trial i.cond c.infer##c.isi, cluster(id)

logit dv i.trial i.cond##c.nsi, cluster(id)
logit dv i.trial i.cond##c.isi, cluster(id)
regress infer i.trial i.cond##c.nsi, cluster(id)
regress infer i.trial i.cond##c.isi, cluster(id)
logit dv i.trial i.cond c.infer##c.nsi, cluster(id)
logit dv i.trial i.cond c.infer##c.isi, cluster(id)





*** Leftovers ***

** Moderation/Subgroup Analysis
** -----------------------------------------------
snapshot restore 1
label var cond "Partition"
label var nsi "NSI"
label var isi "ISI"
label var infer "Item Popularity"
label var dv "Choice"

eststo m1: logit dv i.trial i.cond##c.nsi, cluster(id)
eststo m2: logit dv i.trial i.cond##c.isi, cluster(id)
eststo m3: regress infer i.trial i.cond##c.nsi, cluster(id)
eststo m4: regress infer i.trial i.cond##c.isi, cluster(id)
eststo m5: logit dv i.trial i.cond c.infer##c.nsi, cluster(id)
eststo m6: logit dv i.trial i.cond c.infer##c.isi, cluster(id)

replace infer = infer * .01
eststo n1: regress dv i.trial i.cond##c.nsi, cluster(id)
eststo n2: regress dv i.trial i.cond##c.isi, cluster(id)
eststo n3: regress infer i.trial i.cond##c.nsi, cluster(id)
eststo n4: regress infer i.trial i.cond##c.isi, cluster(id)
eststo n5: regress dv i.trial i.cond c.infer##c.nsi, cluster(id)
eststo n6: regress dv i.trial i.cond c.infer##c.isi, cluster(id)

esttab n1 n2 n3 n4 n5 n6 using table6.tex, /// 
	b(%9.3f) ///
	se(%9.3f) ///
	r2 ///
	label ///
	align(S) ///
	star(+ 0.10 * 0.05 ** 0.0101 *** 0.001) ///
	keep(1.cond nsi isi infer 1.cond#c.nsi 1.cond#c.isi c.infer#c.nsi c.infer#c.isi _cons) ///
	coeflabels(1.cond "Partition" 1.cond#c.nsi "Partition # NSI" 1.cond#c.isi "Partition # ISI")

** Moderated Mediation
** -----------------------------------------------
// Test: NSI moderates partition -> inference pathway
snapshot restore 1
quietly summarize snsi
replace snsi = snsi - r(mean)
regress infer i.trial i.cond##c.snsi
estimates store m1
logit dv i.trial c.infer i.cond##c.snsi
estimates store m2
suest m1 m2, vce(cluster id)
nlcom _b[m1_mean:1.cond#c.snsi] * _b[m2_dv:infer]

// Test: ISI moderates partition -> inference pathway
snapshot restore 1
regress infer i.trial i.cond##c.sisi
estimates store m1
logit dv i.trial c.infer i.cond##c.sisi
estimates store m2
suest m1 m2, vce(cluster id)
nlcom _b[m1_mean:1.cond#c.sisi] * _b[m2_dv:infer]

// Test: NSI moderates inference -> dv pathway
snapshot restore 1
regress infer i.trial i.cond
estimates store m1
logit dv i.trial i.cond c.infer##c.snsi
estimates store m2
suest m1 m2, vce(cluster id)
nlcom _b[m1_mean:1.cond] * _b[m2_dv:c.infer#c.snsi]

// Test: ISI moderates inference -> dv pathway
snapshot restore 1
regress infer i.trial i.cond
estimates store m1
logit dv i.trial i.cond c.infer##c.sisi
estimates store m2
suest m1 m2, vce(cluster id)
nlcom _b[m1_mean:1.cond] * _b[m2_dv:c.infer#c.sisi]

// Combined Test:
// NSI moderates partition -> inference pathway
// ISI moderates inference -> dv pathway
snapshot restore 1
regress infer i.trial i.cond##c.snsi
estimates store m1
logit dv i.cond##c.snsi c.infer##c.sisi
estimates store m2
suest m1 m2, vce(cluster id)
nlcom (_b[m1_mean:1.cond#c.snsi])* (_b[m2_dv:c.infer] + _b[m2_dv:c.infer#c.sisi]) // not sure if this is right

gsem (infer <- trial2-trial4 cond estimation intx) (dv <- trial2-trial4 cond estimation intx infer, family(binomial) link(logit)), vce(cluster id)
nlcom (_b[infer:cond]+0*_b[infer:intx]) * _b[dv:infer]
nlcom (_b[infer:cond]+1*_b[infer:intx]) * _b[dv:infer]
nlcom _b[infer:intx] * _b[dv:infer]

snapshot restore 1
sum snsi
replace snsi = snsi - r(mean)
sum sisi
replace sisi = sisi - r(mean)
gen intx1 = cond * snsi
gen intx2 = infer * snsi
gen intx3 = cond * sisi
gen intx4 = infer * sisi
tab trial, gen(trial)

// NSI influences decision weights
quietly gsem (infer <- trial2-trial4 cond) (dv <- trial2-trial4 cond infer snsi intx2, family(binomial) link(logit)), vce(cluster id)
estat ic

// NSI influences beliefs
quietly gsem (infer <- trial2-trial4 cond snsi intx1) (dv <- trial2-trial4 cond infer, family(binomial) link(logit)), vce(cluster id)
estat ic

// NSI influences both
quietly gsem (infer <- trial2-trial4 cond sisi intx3) (dv <- trial2-trial4 cond infer sisi intx4, family(binomial) link(logit)), vce(cluster id)
estat ic

// ISI influences decision weights
quietly gsem (infer <- trial2-trial4 cond) (dv <- trial2-trial4 cond infer sisi intx4, family(binomial) link(logit)), vce(cluster id)
estat ic

// ISI influences beliefs
quietly gsem (infer <- trial2-trial4 cond sisi intx3) (dv <- trial2-trial4 cond infer, family(binomial) link(logit)), vce(cluster id)
estat ic

// ISI influences both
quietly gsem (infer <- trial2-trial4 cond sisi intx3) (dv <- trial2-trial4 cond infer sisi intx4, family(binomial) link(logit)), vce(cluster id)
estat ic

// Combined version: NSI influences beliefs, ISI influences decision weights
gsem (infer <- trial2-trial4 cond snsi intx1) (dv <- trial2-trial4 cond snsi intx1 infer sisi intx4, family(binomial) link(logit)), vce(cluster id)
estat ic

// Less complicated combined version
gsem (infer <- trial2-trial4 cond snsi intx1) (dv <- trial2-trial4 infer cond sisi intx4, family(binomial) link(logit)), vce(cluster id)
estat ic