** ===============================================
** Study 1B: Chance Gambles
** ===============================================

** Cleanup
** -----------------------------------------------
// loading raw data
snapshot erase _all
cd "~/GitHub/single-item-partitioning/Study1B/"
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
rename q10 gender
rename q11 age
rename q12 comments

// generating choice variable
forvalues i = 1/6 {
	egen option`i' = rowfirst(q5_`i' q6_`i' q7_`i' q8_`i')
}
gen choice = .
forvalues i = 1/6 {
	replace choice = `i' if option`i' == 2
}

recode choice (1 = 1) (2 = 2) (3 = 3) (4 = 6) (5 = 5) (6 = 4) if riskyoptions == "unpacked" & groupedoption == "bottom", gen(choice1)
recode choice (1 = 6) (2 = 5) (3 = 4) (4 = 1) (5 = 2) (6 = 3) if riskyoptions == "packed" & groupedoption == "bottom", gen(choice2)
recode choice (1 = 6) (2 = 5) (3 = 4) (4 = 1) (5 = 2) (6 = 3) if riskyoptions == "unpacked" & groupedoption == "top", gen(choice3)
recode choice (1 = 1) (2 = 2) (3 = 3) (4 = 6) (5 = 5) (6 = 4) if riskyoptions == "packed" & groupedoption == "top", gen(choice4)
egen gamble_choice = rowfirst(choice1 choice2 choice3 choice4)
gen dv = inlist(gamble_choice,1,2,3)

// subject ID variable
gen id = _n

// labeling variables and variable values
label var id "unique participant id"
label var cond "menu partition manipulation"
label define condl 0 "risky packed" 1 "risky unpacked"
label val cond condl
label var position "menu partition position"
label define positionl 0 "packed category at top" 1 "packed category at bottom"
label val position positionl
label var gamble_choice "chance gamble selected by participant"
label define gamble_choicel 1 "13% chance $75" 2 "16% chance $65" 3 "19% chance $55" 4 "52% chance $25" 5 "65% chance $20" 6 "83% chance $15"
label val gamble_choice gamble_choicel
label var dv "DV: choosing indoor/outdoor chore"
label define dvl 0 "less risky gamble" 1 "more risky gamble"
label val dv dvl
replace gender = gender - 1
label var gender "participant gender"
label define genderl 0 "male" 1 "female"
label val gender genderl
label var age "participant age (in years)"

// removing crud
keep id cond position dv gamble_choice gender age
order id cond position dv gamble_choice gender age
snapshot save

** Demographics
** -----------------------------------------------
snapshot restore 1
tab gender
sum age

** Analysis
** -----------------------------------------------
snapshot restore 1
prtest dv, by(cond)
logit dv i.position##i.cond
margins position, dydx(cond)

** Pay out participants
** -----------------------------------------------
snapshot restore 1
set seed 987654321
gen random = runiform()
sort random
keep in 1/5
gen draw = int((100-0+1)*runiform())
gen payout = 0
replace payout = 1 if draw >= 48 & gamble_choice == 4
replace payout = 1 if draw >= 35 & gamble_choice == 5
replace payout = 1 if draw >= 17 & gamble_choice == 6