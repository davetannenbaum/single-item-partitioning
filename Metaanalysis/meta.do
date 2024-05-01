** IMPORTANT: Need to set working directory to call on data files
** ---------------------------------------
snapshot erase _all
cd "~/Dropbox (Maestral)/Work/Partition Dependence/Studies/meta-analysis/"

** Combining data sets
** ---------------------------------------
use "study1A.dta", clear
gen study = 1
keep study id trial dv cond position
append using "study1B.dta", gen(study2)
replace study = 2 if study2 == 1
keep study id trial dv cond position
append using "study2.dta", gen(study3)
replace study = 3 if study3 == 1
keep study id trial dv cond position
append using "study3.dta", gen(study4)
replace study = 4 if study4 == 1
keep study id trial dv cond position
append using "study4.dta", gen(study5)
replace study = 5 if study5 == 1
keep study id trial dv cond position
append using "study5.dta", gen(study6)
replace study = 6 if study6 == 1
keep study id trial dv cond position
replace trial = 1 if trial == .
replace id = _n if study == 2
egen newid = group(id) if study == 2
replace id = newid if study == 2
drop newid
replace id = _n if study == 3
egen newid = group(id) if study == 3
replace id = newid if study == 3
drop newid
egen study_id = group(study id)
egen studytrial = group(study trial)

// labeling studies
gen studylbl = "Study 1A" if study == 1
replace studylbl = "Study 1B" if study == 2
replace studylbl = "Study 2" if study == 3
replace studylbl = "Study 3" if study == 4
replace studylbl = "Study 4" if study == 5
replace studylbl = "Study 5" if study == 6

// saving data
snapshot save

** Meta-analysis of basic effect
** ---------------------------------------
snapshot restore 1
gen double b0 = .
gen double se0 = .
gen double b1 = .
gen double se1 = .
gen double bdiff = .
gen double sediff = .
forvalues i = 1/6 {
	logit dv i.trial i.cond if study == `i', cluster(id)
	margins cond, post
	lincom _b[0.cond]
	replace b0 = r(estimate) if study == `i'
	replace se0 = r(se) if study == `i'
	lincom _b[1.cond]
	replace b1 = r(estimate) if study == `i'
	replace se1 = r(se) if study == `i'
	logit dv i.trial i.cond if study == `i', cluster(id)
	margins, dydx(cond) post
	lincom _b[1.cond]
	replace bdiff = r(estimate) if study == `i'
	replace sediff = r(se) if study == `i'
}
collapse b0 se0 b1 se1 bdiff sediff, by(study studylbl)
foreach var of varlist b0-sediff {
	replace `var' = `var' * 100
}

// meta analysis results
meta set bdiff sediff, studylabel(studylbl) eslabel(Avg Marginal Effect)
meta summarize, fixed
meta summarize, random

// Table of results
table studylbl, c(mean b1 mean se1 mean b0 mean se0) format(%9.1f)

// Calculating aggregated combined estimates (and standard errors) for unpacked and packed groupings (weighted by the inverse variance in the avg treatment effect)
gen fweight = 1/sediff^2
sum b1 [iweight = fweight]
quietly gen var1 = se1^2
local var1 = se1^2
sum var1 [iweight = fweight]
display "se = " sqrt(r(mean))
sum b0 [iweight = fweight]
gen var0 = se0^2
sum var0 [iweight = fweight]
display "se = " sqrt(r(mean))

** Meta-analysis of position effects
** ---------------------------------------
snapshot restore 1
gen double b0 = .
gen double se0 = .
gen double b1 = .
gen double se1 = .
forvalues i = 1/6 {
	logit dv i.trial i.cond##i.position if study == `i', cluster(id)
	margins position, dydx(cond) post
	lincom _b[1.cond:0bn.position]
	replace b0 = r(estimate) if study == `i'
	replace se0 = r(se) if study == `i'
	lincom _b[1.cond:1.position]
	replace b1 = r(estimate) if study == `i'
	replace se1 = r(se) if study == `i'
}
collapse b? se?, by(study studylbl)
reshape long b se, i(study) j(position)
label var position "menu partition position"
label define positionl1 0 "packed category at top" 1 "packed category at bottom"
label val position positionl1

meta set b se, studylabel(studylbl) eslabel(Avg Marginal Effect)
meta summarize, subgroup(position) fixed
meta summarize, subgroup(position) random

** Generating Table (Positioning Effects)
** ---------------------------------------
snapshot restore 1
gen double b0 = .
gen double se0 = .
gen double b1 = .
gen double se1 = .
gen double bdiff = .
gen double sediff = .
forvalues i = 1/6 {
	logit dv i.trial i.cond##i.position if study == `i', cluster(id)
	margins position, dydx(cond) post
	lincom _b[1.cond:0bn.position]
	replace b0 = r(estimate) if study == `i'
	replace se0 = r(se) if study == `i'
	lincom _b[1.cond:1.position]
	replace b1 = r(estimate) if study == `i'
	replace se1 = r(se) if study == `i'
	lincom _b[1.cond:1.position] - _b[1.cond:0bn.position]
	replace bdiff = r(estimate) if study == `i'
	replace sediff = r(se) if study == `i'
}
collapse b0 b1 bdiff se0 se1 sediff, by(study studylbl position)
table studylbl, c(mean b1 mean se1 mean b0 mean se0 mean bdiff) format(%9.3f)