** ===============================================
** Tables 6 and 7
** ===============================================

** ---------------------------------------
// loading combined data
// note: below I pull data from GitHub, but you may wish to change the file path to load data from your local working directory
snapshot erase _all
version 18.5
import delimited "https://raw.githubusercontent.com/davetannenbaum/single-item-partitioning/refs/heads/master/Combined%20Results/combined_data.csv", clear

// labeling data
label var study "study number"
label var studylbl "Study label"
label var id "participant id"
label var trial "choice trial"
label var cond "menu partition manipulation"
label define condl 0 "category A packed" 1 "category A unpacked"
label val cond condl
label var position "menu partition position"
label define positionl 0 "packed category at top" 1 "packed category at bottom"
label val position positionl
label var dv "DV: choosing item from category A"
label define dvl 0 "Category B" 1 "Category A"
label val dv dvl

// saving snapshot of data
snapshot save

** Table 6
** ---------------------------------------
// first collapsing data for each study. We estimate the probability of choosing from the focal behavior in the unpacked condition (b1 and se1) and in the packed condition (b0 and se0), as well as the average marginal effect (bdiff and sediff).
snapshot restore 1
gen double b0 = .
gen double se0 = .
gen double b1 = .
gen double se1 = .
gen double bdiff = .
gen double sediff = .
forvalues i = 1/7 {
	logit dv i.trial i.cond if study == `i', cluster(id)
	margins cond, post
	lincom _b[0.cond]
	replace b0 = r(estimate) if study == `i'
	replace se0 = r(se) if study == `i'
	lincom _b[1.cond]
	replace b1 = r(estimate) if study == `i'
	replace se1 = r(se) if study == `i'
	lincom _b[1.cond] - _b[0.cond]
	replace bdiff = r(estimate) if study == `i'
	replace sediff = r(se) if study == `i'
}
collapse b0 se0 b1 se1 bdiff sediff, by(study studylbl)

// converting from [0,1] probabilities to percentages (0-100%)
foreach var of varlist b0-sediff {
	replace `var' = `var' * 100
}

// table of results
table studylbl, stat(mean b1 se1 b0 se0 bdiff sediff) nformat(%9.1f) nototals

// calculating combined estimates (and standard errors) for unpacked and packed conditions. We aggregate by weighting each estimate by the inverse variance in the avg treatment effect for that study.
quietly gen fweight = 1/sediff^2
quietly sum b1 [iweight = fweight]
display "combined b1 = " r(mean)
quietly gen var1 = se1^2
quietly sum var1 [iweight = fweight]
display "combined se1 = " sqrt(r(mean))
quietly sum b0 [iweight = fweight]
display "combined b0 = " r(mean)
quietly gen var0 = se0^2
quietly sum var0 [iweight = fweight]
display "combined se0 = " sqrt(r(mean))

// fixed-effect meta analysis
meta set bdiff sediff, studylabel(studylbl) eslabel(Avg Marginal Effect)
meta summarize, fixed
display "combined bdiff = " r(theta)
display "combined sediff = " r(se)

// checking results when using random-effects
meta summarize, random

** Meta-analysis of Positioning Effects (Table 7)
** ---------------------------------------
// first collapsing data for each study. We estimate the average marginal treatment effect when the packed category is the top listing (b0 and se0), the average marginal treatment effect when the packed category is the bottom listing (b1 and se1), and the difference between the two (bdiff and sediff).
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

// converting from [0,1] probabilities to percentages (0-100%)
foreach var of varlist b0-sediff {
	replace `var' = `var' * 100
}

// table of results
table studylbl, stat(mean b1 se1 b0 se0 bdiff sediff) nformat(%9.1f) nototals

// reshaping data
collapse b? se?, by(study studylbl)
reshape long b se, i(study) j(position)
label var position "menu partition position"
label define positionl1 0 "packed category at top" 1 "packed category at bottom"
label val position positionl1

// fixed-effect meta analysis
meta set b se, studylabel(studylbl) eslabel(Avg Marginal Effect)
meta summarize, subgroup(position) fixed
display "combined bdiff1 = " r(esgroup)[2,1]
display "combined sediff = " r(esgroup)[2,2]
display "combined bdiff0 = " r(esgroup)[1,1]
display "combined sedif0 = " r(esgroup)[1,2]
meta regress position, fixed

// checking results when using random-effects
meta summarize, subgroup(position) random
meta regress position, random