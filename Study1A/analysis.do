** ===============================================
** Study 1A
** ===============================================

** Cleanup
** -----------------------------------------------
// loading raw data
// note: below I pull data from GitHub, but you may wish to change the file path to load data from your local working directory
snapshot erase _all
version 18.5
import delimited "https://raw.githubusercontent.com/davetannenbaum/single-item-partitioning/refs/heads/master/Study1A/data.csv", varnames(1) clear

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

// naming variables
rename groupedcategory position
rename animalcharities cond1
rename scifimovies cond2
rename lifescience cond3
rename worldnews cond4
rename q9 choice1
rename q14 choice2
rename q19 choice3
rename q24 choice4
rename q26 gender
rename q27 age
rename q29 comments

// converting all response strings to lower case and removing dead spaces
ds, has(type string) 
quietly foreach v of varlist `r(varlist)' {
	replace `v' = lower(`v') 
	replace `v' = rtrim(`v')
	replace `v' = itrim(`v')
	replace `v' = ltrim(`v')
}

// choice 1: animal vs environmental charities
// recoding open responses to 0 = environmental charity, 1 = animal charity
// note: uses the "encoder" package, to install type: ssc install encoder
replace choice1 = "" if strpos(choice1, "based")
replace choice1 = "" if inlist(choice1, "none")
replace choice1 = "SPCA" if strpos(choice1, "prevention")
replace choice1 = "SPCA" if strpos(choice1, "spca")
replace choice1 = "Animal Legal Defense Fund" if strpos(choice1, "legal")
replace choice1 = "Humane Society" if strpos(choice1, "human")
replace choice1 = "NRDC" if strpos(choice1, "natural")
replace choice1 = "NRDC" if strpos(choice1, "nrdc")
replace choice1 = "Env Defense Fund" if inlist(choice1, "environmental defense fund")
replace choice1 = "Sierra Club" if inlist(choice1, "sierra club")
encoder choice1, replace
recode choice1 (1 3 5 = 1 "animal based") (2 4 6 = 0 "environmental"), gen(dv1)

// choice 2: sci-fi vs romantic comedy movies
// recoding open responses to 0 = romantic comeday, 1 = sci-fi movie
replace choice2 = "" if strpos(choice2, "science fiction")
replace choice2 = "" if strpos(choice2, "romantic comedies")
replace choice2 = "" if inlist(choice2, "they all suck")
replace choice2 = "When Harry Met Sally" if strpos(choice2, "sally")
replace choice2 = "You've Got Mail" if strpos(choice2, "mail")
replace choice2 = "Sleepless in Seattle" if strpos(choice2, "sleepless")
replace choice2 = "2001" if strpos(choice2, "2001")
replace choice2 = "2001" if strpos(choice2, "a space odyssey")
replace choice2 = "ET" if strpos(choice2, "e.t")
replace choice2 = "ET" if inlist(choice2, "et: the extra terrestrial", "et")
replace choice2 = "Star Wars" if strpos(choice2, "star")
encoder choice2, replace
recode choice2 (1 2 4 = 1 "science fiction") (3 5 6 = 0 "rom com"), gen(dv2)

// choice 3: life science vs social science books
// recoding open responses to 0 = social science book, 1 = life science book
replace choice3 = "" if strpos(choice3, "life science")
replace choice3 = "" if strpos(choice3, "social science")
replace choice3 = "" if inlist(choice3, "none", "wired")
replace choice3 = "A Short History" if strpos(choice3, "history")
replace choice3 = "Gun Germs Steel" if strpos(choice3, "germs")
replace choice3 = "Outliers" if strpos(choice3, "outlier")
replace choice3 = "Outliers" if inlist(choice3, "ouliers")
replace choice3 = "Wisdom of Crowds" if strpos(choice3, "crowds")
replace choice3 = "Selfish Gene" if strpos(choice3, "selfish")
replace choice3 = "Superfreakonomics" if strpos(choice3, "freak")
encoder choice3, replace
recode choice3 (1 2 4 = 1 "life science") (3 5 6 = 0 "social science"), gen(dv3)

// choice 4: world news vs popular science magazine subscriptions
// recoding open responses to 0 = popular science magazine, 1 = world news magazine
replace choice4 = "" if strpos(choice4, "your choice")
replace choice4 = "" if inlist(choice4, "popular science", "popular sience", "popular science magazine")
replace choice4 = "" if inlist(choice4, "world news magazine")
replace choice4 = "The Atlantic" if strpos(choice4, "atlantic")
replace choice4 = "Discover" if strpos(choice4, "discover")
replace choice4 = "Time" if strpos(choice4, "time")
replace choice4 = "Newsweek" if strpos(choice4, "newsweek")
replace choice4 = "New Scientist" if strpos(choice4, "scientist")
replace choice4 = "Sci American" if strpos(choice4, "scientific")
encoder choice4, replace
recode choice4 (3 5 6 = 1 "World News") (1 2 4 = 0 "Popular Science"), gen(dv4)

// reshaping data from wide to long format
gen id = _n
reshape long dv cond, i(id) j(trial)

// labeling variables and variable values
label var id "unique participant id"
label var trial "choice trial"
label define triall 1 "charities" 2 "movies" 3 "books" 4 "magazine subscriptions"
label val trial triall
label var cond "menu partition manipulation"
encoder cond, replace
replace cond = cond - 1
label define condl 0 "category A packed" 1 "category A unpacked"
label val cond condl
encoder position, replace setzero
replace position = 1 - position
label var position "menu partition position"
label define positionl 0 "packed category at top" 1 "packed category at bottom"
label val position positionl
label var dv "DV: choosing item from category A vs B"
label define dvl 0 "Category B" 1 "Category A"
label val dv dvl
replace gender = gender - 1
label var gender "participant gender"
label define genderl 0 "male" 1 "female"
label val gender genderl
label var age "participant age (in years)"

// removing crud
keep id trial cond position dv gender age
order id trial cond position dv gender age

// saving snapshot of data
snapshot save

** Demographics
** -----------------------------------------------
snapshot restore 1
collapse age, by(id gender)
tab gender
sum age

** Main analysis
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

** Positioning effects
** -----------------------------------------------
snapshot restore 1

// interaction between partition and listing position
logit dv i.trial i.cond##i.position, cluster(id) 

// partitioning effects when grouped listing is top vs bottom
margins position, dydx(cond) 

// difference in avg marginal effects
margins position, dydx(cond) pwcompare(effects) 

** Robustness Check: recode missing observations to go against hypothesis
** -----------------------------------------------
snapshot restore 1
replace dv = 0 if cond == 1 & dv == .
replace dv = 1 if cond == 0 & dv == .
table trial cond, stat(mean dv) nformat(%9.3f) nototals
logit dv i.trial i.cond, cluster(id)
margins, dydx(cond)
forvalues i = 1/4 {
	quietly logit dv i.cond if trial == `i', robust
	margins, dydx(cond)
}