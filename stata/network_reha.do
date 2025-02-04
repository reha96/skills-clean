/*******************************************************************************
    Project: SIR - network data cleaned by Reha
    Author: Reha Tuncer
    Date: 25.07.2024
    Description: This do-file performs meain data analysis on SIR dataset
*******************************************************************************/


/*===========================================================================*/
//# PREAMBLE AND DATA IMPORT
/*===========================================================================*/


// Set up environment
version 18
clear all
macro drop _all
set more off
set scheme s2color, permanently
set maxvar 32767
set more off
set linesize 100
global graph_opts ///
    graphregion(fcolor(white) lcolor(white)) ///
    bgcolor(white) ///
    plotregion(lcolor(white))

// Import data
local root_dir "/Users/reha.tuncer/Library/CloudStorage/OneDrive-UniversityofLuxembourg/stata_reha/"
use "`root_dir'/cleaned.dta", clear
order net_id net_id_other



/*===========================================================================*/
//# DATA PREPARATION FOR DISCRETE CHOICE MODEL
/*===========================================================================*/


/***

/***
* Sort the data
sort net_id net_id_other

* Get unique values of net_id
levelsof net_id, local(id_list)

* Create variables for each unique net_id
foreach id of local id_list {
    gen net_rav_`id' = .
    gen net_eye_`id' = .
    gen net_guess_`id' = .
}

* Initialize variables to 0 only for rows in the same classroom, leave as missing otherwise
foreach id of local id_list {
    local class = `id' - mod(`id', 1000)  // Get the classroom number for this id
    replace net_rav_`id' = 0 if net_class == `class'
    replace net_eye_`id' = 0 if net_class == `class'
    replace net_guess_`id' = 0 if net_class == `class'
}

* Sort the data to ensure it's in the correct order
sort net_id net_id_other

* Get unique values of net_id
levelsof net_id, local(id_list)

* Update network variables based on actual nominations and potential choices
foreach id of local id_list {
    * For Ravens network (network == 1)
    replace net_rav_`id' = 1 if net_id_other == `id' & network == 1 & net_rav_`id' == 0
    * For Eye network (network == 2)
    replace net_eye_`id' = 1 if net_id_other == `id' & network == 2 & net_eye_`id' == 0
    * For Guess network (network == 3)
    replace net_guess_`id' = 1 if net_id_other == `id' & network == 3 & net_guess_`id' == 0
}

* Sort the data to ensure it's in the correct order
sort net_id net_id_other

* Get unique values of net_id
levelsof net_id, local(id_list)

foreach id of local id_list {
    * Inner loop: iterate over all net_id values again for variable names
    foreach var_id of local id_list {
        * Check Ravens network
        sum net_rav_`var_id' if net_id == `id', meanonly
        if r(max) == 1 {
            replace net_rav_`var_id' = 1 if net_id == `id' & net_rav_`var_id' == 0
        }
        
        * Check Eye network
        sum net_eye_`var_id' if net_id == `id', meanonly
        if r(max) == 1 {
            replace net_eye_`var_id' = 1 if net_id == `id' & net_eye_`var_id' == 0
        }
        
        * Check Guess network
        sum net_guess_`var_id' if net_id == `id', meanonly
        if r(max) == 1 {
            replace net_guess_`var_id' = 1 if net_id == `id' & net_guess_`var_id' == 0
        }
    }
}
***/

* Expand 16, generate(nv)
expand 15, generate(nv)
sort net_id nv

* Create a list of variables ending with _other
ds *_other
local other_vars `r(varlist)'

* Get unique net_id values
levelsof net_id, local(unique_net_ids)

* Create a temporary variable to store the order of sampling
tempvar sample_order
gen `sample_order' = .

* Loop through unique net_ids
local n_unique = 0
foreach id of local unique_net_ids {
    local ++n_unique
}

* Loop through observations
local sample_count = 0
forvalues i = 1/`c(N)' {
    * If nv == 1, replace with data from other net_ids
    if nv[`i'] == 1 {
        local current_net_id = net_id[`i']
        
        * Reset sample order if we've gone through all other net_ids
        if `sample_count' == `n_unique' - 1 {
            local sample_count = 0
        }
        
        * Select the next net_id in the sampling order
        local sample_count = `sample_count' + 1
        local sample_index = 1
        foreach id of local unique_net_ids {
            if `id' != `current_net_id' {
                if `sample_index' == `sample_count' {
                    local random_net_id = `id'
                    continue, break
                }
                local ++sample_index
            }
        }
        
        * Find a random row with the selected net_id
        summ net_id if net_id == `random_net_id', meanonly
        local random_row = `r(min)' + int(uniform() * `r(N)')
        
        * Replace all _other variables with data from the random row
        foreach var of local other_vars {
            replace `var' = `var'[`random_row'] in `i'
        }
        
        * Replace net_id_other with the random net_id
        replace net_id_other = `random_net_id' in `i'
        
        * Store the sampling order
        replace `sample_order' = `sample_count' in `i'
    }
}

* Order variables
order net_id_other nv net_id `sample_order'
sort net_id nv net_id_other

***/



/*===========================================================================*/
//# Summarize missing data
/*===========================================================================*/



// Generate new variables to tag self-nominations
gen rav_net_self = 0
label variable rav_net_self "self referral Ravens"
gen eye_net_self = 0
label variable eye_net_self "self referral Eye"
gen seb_net_self = 0
label variable seb_net_self "self referral SEB Guess"
replace rav_net_self = 1 if network == 1 & net_id == net_id_other
replace eye_net_self = 1 if network == 2 & net_id == net_id_other
replace seb_net_self = 1 if network == 3 & net_id == net_id_other
order rav_net_self eye_net_self seb_net_self

gen comp_nom = 1
label variable comp_nom "1 if 6/6 nominations 0 if not 99 if missing"
bysort net_id: egen any_self_ref = max(rav_net_self + eye_net_self + seb_net_self)
replace comp_nom = 0 if any_self_ref > 0
drop any_self_ref
order comp_nom, after(seb_net_self)
replace comp_nom = 99 if net_id_other == .
tab comp_nom

// 6/6 nominations for 382/863 obs total
tabstat comp_nom if comp_nom != 99, stat(mean n)
tab comp_nom finished 



/*===========================================================================*/
//# Data preparation: classroom variables & probability of low-SEB referral
/*===========================================================================*/



// class_size & class_size_other fix missing values
bysort net_class: egen max_class_size = max(class_size)
replace class_size = max_class_size
replace class_size_other = max_class_size
drop max_class_size

// Maximum possible nominations in class
order class_size
bysort net_class: egen max_nom = max(class_size - 1)
label variable max_nom "Maximum possible nominations in class"
order max_nom

// Maximum possible known low-SEB candidates in class
order net_class seb net_id
bysort net_class : egen count_low_SEB = sum(seb == 1)
replace count_low_SEB = count_low_SEB/9
order count_low_SEB
gen max_seb_nom = count_low_SEB
order max_seb_nom
replace max_seb_nom = max_seb_nom - 1 if seb == 1
label variable max_seb_nom "Maximum possible known low-SEB candidates in class"

// Create class size with seb known
bysort net_class: egen class_size_sebk = count(seb)
replace class_size_sebk = class_size_sebk/9
order net_class class_size class_size_sebk

// Create pr of making a random low-SEB ref
gen pr_seb = .
replace pr_seb = max_seb_nom/class_size_sebk
label variable pr_seb "Pr of picking a low-SEB at random if SEB is known"
corr class_size class_size_sebk
egen z_pr_seb = std(pr_seb) if id_count == 1
label variable pr_seb "z-score pr of picking a low-SEB at random"
sfrancia pr_seb if id_count == 1 
qnorm pr_seb if id_count == 1, grid $graph_opts

// Create lower bound for pr of making a random low-SEB ref
gen pr_seb_l = .
replace pr_seb_l = max_seb_nom/max_nom
label variable pr_seb_l "Pr of picking a low-SEB at random lower bound"
egen z_pr_seb_l = std(pr_seb_l) if id_count == 1
rename z_pr_seb_l z_share_low_seb
label variable z_share_low_seb "z-score pr of picking a low-SEB at random lower bound"
swilk z_share_low_seb if id_count == 1 & comp_nom == 1
qnorm z_share_low_seb if id_count == 1 & comp_nom == 1, grid $graph_opts

// Create classroom average scores
bysort net_class: egen class_avg_gpa = mean(gpa) 
egen __t = max(class_avg_gpa), by(net_class)
replace class_avg_gpa = __t if missing(class_avg_gpa)
drop __t
bysort net_class: egen class_avg_lowseb_gpa = mean(gpa) if seb == 1
egen __t = max(class_avg_lowseb_gpa), by(net_class)
replace class_avg_lowseb_gpa = __t if missing(class_avg_lowseb_gpa)
drop __t

// Loop through variables
foreach var in rav_pcent eye_pcent gpa test_score {
    // Generate overall average excluding self
    bysort net_class: egen total_`var' = sum(`var')
    bysort net_class: egen total_count = count(`var')
    gen choice_set_avg_`var' = (total_`var' - `var') / (total_count - 1)
    
	// gen temp
	bysort net_class: egen __t1 = mean(`var') if seb == 1
	egen __t2 = max(__t1), by(net_class)
	
    // Generate low-SEB average
    bysort net_class: egen total_lowseb_`var' = sum(`var') if seb == 1
    bysort net_class: egen total_lowseb_count = count(`var') if seb == 1
	gen choice_set_avg_lowseb_`var' = .
    replace choice_set_avg_lowseb_`var' = (total_lowseb_`var' - `var') / (total_lowseb_count - 1) if seb == 1
    replace choice_set_avg_lowseb_`var' = __t2 if missing(total_lowseb_`var')
    
    // Clean up temporary variables
    drop total_`var' total_count total_lowseb_`var' total_lowseb_count __t1 __t2
}

// Loop through variables to standardize
foreach var in rav_pcent eye_pcent gpa test_score {
    // Standardize choice set average
    gen z_cs_`var' = .
    summarize choice_set_avg_`var' if id_count == 1
    replace z_cs_`var' = (choice_set_avg_`var' - r(mean)) / r(sd) if id_count == 1
    bysort net_id (id_count): replace z_cs_`var' = z_cs_`var'[1] if missing(z_cs_`var')
    
    // Standardize low-SEB choice set average
    gen z_cs_lowseb_`var' = .
    summarize choice_set_avg_lowseb_`var' if id_count == 1
    replace z_cs_lowseb_`var' = (choice_set_avg_lowseb_`var' - r(mean)) / r(sd) if id_count == 1
    bysort net_id (id_count): replace z_cs_lowseb_`var' = z_cs_lowseb_`var'[1] if missing(z_cs_lowseb_`var')
}

// Create delta variables
foreach var in rav_pcent eye_pcent gpa test_score {
    // Create raw delta
    gen delta_`var' = choice_set_avg_lowseb_`var' - choice_set_avg_`var'
    label variable delta_`var' "Difference between overall and low-SEB average `var'"
    
    // Create standardized delta
    gen z_delta_`var' = .
    summarize delta_`var' if id_count == 1
    replace z_delta_`var' = (delta_`var' - r(mean)) / r(sd) if id_count == 1
    
    // Propagate standardized values to other instances of the same net_id
    bysort net_id (id_count): replace z_delta_`var' = z_delta_`var'[1] if missing(z_delta_`var')
    
    label variable z_delta_`var' "Standardized difference between overall and low-SEB average `var'"
}



/*===========================================================================*/
//# Data preparation: actualized referrals and low-SEB share
/*===========================================================================*/



// Share of actualized low-SEB nominations Cognitive
gen act_seb_r = .
replace act_seb_r = 1 if seb_other == 1 & network ==1
replace act_seb_r = 0 if seb_other == 0 & network ==1
order act_seb_r
label variable act_seb_r "Actual low-SEB nominations per referrer Cognitive"
bysort net_id: egen sum_seb_r = sum(act_seb_r)
replace sum_seb_r = . if net_id_other == .
order sum_seb_r
label variable sum_seb_r "Total actualized low-SEB nominations per referrer Cognitive"
drop act_seb_r
gen s_seb_r = .
replace s_seb_r = sum_seb_r/min(3, max_seb_nom)
order s_seb_r
label variable s_seb_r "Share of actualized low-SEB nominations Cognitive"

// Share of actualized low-SEB nominations Social
gen act_seb_e = .
replace act_seb_e = 1 if seb_other == 1 & network ==2
replace act_seb_e = 0 if seb_other == 0 & network ==2
order act_seb_e
label variable act_seb_e "Actual low-SEB nominations per referrer Social"
bysort net_id: egen sum_seb_e = sum(act_seb_e)
replace sum_seb_e = . 	if net_id_other == .
order sum_seb_e
label variable sum_seb_e "Total actualized low-SEB nominations per referrer Social"
drop act_seb_e
gen s_seb_e = .
replace s_seb_e = sum_seb_e/min(3, max_seb_nom)
order s_seb_e
label variable s_seb_e "Share of actualized low-SEB nominations Social"

// Create a combined share (sum of low-SEB referrals across both tasks)
gen c_s_seb_ref = (s_seb_e + s_seb_r) / 2
label variable c_s_seb_ref "Combined Low-SEB referral share"
order c_s_seb_ref
swilk c_s_seb_ref if id_count == 1 & comp_nom 
qnorm c_s_seb_ref if id_count == 1 & comp_nom, grid $graph_opts
tab c_s_seb_ref if id_count == 1 & comp_nom 

* Descriptive statistics
summarize s_seb_r s_seb_e c_s_seb_ref, detail

* Correlation between individual shares and combined share
corr s_seb_r s_seb_e c_s_seb_ref


/*===========================================================================*/
//# Data preparation: randomization check table & data standardization
/*===========================================================================*/


// Analyze completed responses
bysort finished : sum net_id if id_count == 1

//# Randomization table
preserve 
keep if id_count == 1 & finished == 1
tabstat seb first_gen gender gpa, by(treat) stat(mean sd n)  format(%9.2f)
// Statistical tests
prtest seb , by(treat)
prtest first_gen, by(treat)
prtest gender , by(treat)
ttest  gpa , by(treat) unpaired unequal
restore

// Data preparation finished == complete referrer data (but not necessarily referral)
keep if finished == 1
order net_id treat seb
sort net_id 

// Standardize variables
egen z_gpa = std(gpa)
label variable z_gpa "z-score GPA"
egen z_gpa_other = std(gpa_other)
label variable z_gpa_other "Other z-score GPA"

// Fix math and test scores
replace math = 100 if math==364
replace math_other = 100 if math_other == 364
replace test_score = . if inlist(test_score, 136, 136.5, 100)
replace test_score_other = . if inlist(test_score_other, 136, 136.5, 100)

// Create z-scores for entry exam
egen z_test = std(test_score)
label variable z_test "entry exam z-score"
egen z_test_other = std(test_score_other)
label variable z_test_other "Other entry exam z-score"

// Create referral quartiles
foreach var in rav eye {
    xtile rank_`var'_xtile = rank_`var'_class, nq(4)
    xtile rank_`var'_other_xtile = rank_`var'_class_other, nq(4)
}

// Create SEB by classroom quartiles
egen seb_class = mean(seb), by(net_class)
order seb_class pr_seb
xtile seb_class_xtile = seb_class, nq(4)

// standardized low-seb share in class
egen z_seb_class = std(seb_class)

// standardized class size
egen z_class_size = std(class_size)

// Calculate SEB guessing ability
bysort net_id: gen seb_ability = 1 if (seb_other == 1 & network == 3 & seb_net_self == 0)
order network net_id_other seb_other seb_ability
replace seb_ability = 0 if (seb_other == 0 & network == 3)
replace seb_ability = . if (seb_net_self == 1 & network == 3)
egen seb_correct = sum(seb_ability), by(net_id)
order seb_correct seb_ability
bysort net_id: egen count_seb = count(seb_ability)
order count_seb seb_correct seb_ability 
gen seb_pcent = seb_correct/count_seb
order seb_pcent
egen z_seb_pcent = std(seb_pcent)
label variable z_seb_pcent "Detection ability z-score"
qnorm z_seb_pcent if id_count == 1, grid $graph_opts
rename z_seb_pcent z_ability

order seb_pcent count_seb seb_correct seb_ability, last



/*===========================================================================*/
//# REGRESSION FROM REFERRER POV: Share of low-SEB actually referred
/*===========================================================================*/



preserve
keep if id_count == 1 & comp_nom == 1
reg c_s_seb_ref i.seb, robust
estimates store m1
reg c_s_seb_ref i.seb i.treat, robust
estimates store m2
reg c_s_seb_ref i.treat i.seb i.first_gen, robust
estimates store m3
reg c_s_seb_ref i.treat i.seb##i.first_gen i.seb##c.z_ability, robust
estimates store m4
reg c_s_seb_ref i.treat i.seb##i.first_gen c.z_ability  i.seb##c.z_share_low_seb , robust
estimates store m5
reg c_s_seb_ref i.treat i.seb##i.first_gen c.z_ability  i.seb##c.z_share_low_seb c.z_rav c.z_eye c.z_test c.z_gpa, robust
estimates store m6
reg c_s_seb_ref i.treat i.seb##i.first_gen c.z_ability  i.seb##c.z_share_low_seb c.z_rav c.z_eye c.z_test c.z_gpa c.z_cs_lowseb_gpa c.z_cs_lowseb_test_score c.z_cs_lowseb_rav_pcent c.z_cs_lowseb_eye_pcent, robust
estimates store m7
reg c_s_seb_ref i.treat i.seb##i.first_gen c.z_ability  i.seb##c.z_share_low_seb c.z_rav c.z_eye c.z_test c.z_gpa c.z_cs_lowseb_gpa c.z_cs_lowseb_test_score c.z_cs_lowseb_rav_pcent c.z_cs_lowseb_eye_pcent c.z_cs_gpa c.z_cs_test_score c.z_cs_rav_pcent c.z_cs_eye_pcent, robust
estimates store m8
reg c_s_seb_ref i.treat i.seb##i.first_gen c.z_ability  i.seb##c.z_share_low_seb c.z_rav c.z_eye c.z_test c.z_gpa c.z_delta_rav_pcent c.z_delta_eye_pcent c.z_delta_gpa c.z_delta_test_score c.z_cs_lowseb_gpa c.z_cs_lowseb_test_score c.z_cs_lowseb_rav_pcent c.z_cs_lowseb_eye_pcent c.z_cs_gpa c.z_cs_test_score c.z_cs_rav_pcent c.z_cs_eye_pcent, robust
estimates store m9
predict residuals, residuals
* Create a Q-Q plot to check normality of residuals
qnorm residuals, name(qqr, replace)
restore
estimates table m6 m7 m8 m9, star(.1 .05 .01) stats(r2 N)



coefplot m9, xline(0) sort ///
    coeflabels(                        ///
		1.i.seb#i.seb_other = "Low-SEB referrer*Low-SEB" ///
		2.treat = "Referrer is in Quota condition" ///
		1.seb = "Referrer is Low-SEB"    ///
		2.network = "Eye network" ///
        1.seb_other = "Low-SEB"    ///
		1.first_gen_other = "First Gen"    ///
        z_rav_other = "Cognitive z-score"     ///
		z_eye_other = "Social z-score"     ///
		z_rav = "Cognitive z-score"     ///
		z_eye = "Social z-score"     ///
		classroom_zeye = "Average Eye score in class" ///
		classroom_zrav = "Average Ravens score in class" ///
		int_rav_seb = "Ravens score*Low-SEB" ///
		int_gpa_seb = "GPA*Low-SEB" ///
		int_test_seb = "National Exam Score*Low-SEB" ///
        z_test_other = "Entry Exam z-score"      ///
		z_test = "Entry Exam z-score"      ///
		int_seb_class_seb = "Low-SEB share in class*Low-SEB" ///
		z_class_size = "Classroom size" ///
		z_seb_class = "Low-SEB share in class" ///
        z_gpa_other = "GPA z-score"        ///
		z_gpa = "GPA z-score"        ///
        1.gender_other = "Female"  ///
		z_pr_seb_l = "z-score Pr: Random pick is low-SEB" ///
		z_seb_pcent = "z-score Referrer low-SEB guess acc. " ///
    , labsize(vsmall))                                  ///
    title("Probability of making a low-SEB referral") ///
    xtitle("Coefficient estimate")     ///
    ytitle("")                         ///
    name(model1, replace) $graph_opts






estimates store model1
preserve
keep if id_count == 1 & comp_3 == 1 & comp_nom == 1
reg share_low_seb_referrals i.seb c.z_rav c.z_eye c.pr_seb i.treat , robust
estimates store model1
estimates table model1, star(.05 .01 .001)
restore
estimates store model1
coefplot model1, xline(0) drop(_cons) sort ///
    coeflabels(                        ///
		1.i.seb#i.seb_other = "Low-SEB referrer*Low-SEB" ///
		1.seb = "Low-SEB"    ///
		2.network = "Eye network" ///
        1.seb_other = "Low-SEB"    ///
		1.first_gen_other = "First Gen"    ///
        z_rav_other = "Cognitive z-score"     ///
		z_eye_other = "Social z-score"     ///
		z_rav = "Cognitive z-score"     ///
		z_eye = "Social z-score"     ///
		classroom_zeye = "Average Eye score in class" ///
		classroom_zrav = "Average Ravens score in class" ///
		int_rav_seb = "Ravens score*Low-SEB" ///
		int_gpa_seb = "GPA*Low-SEB" ///
		int_test_seb = "National Exam Score*Low-SEB" ///
        z_test_other = "Entry Exam z-score"      ///
		z_test = "Entry Exam z-score"      ///
		int_seb_class_seb = "Low-SEB share in class*Low-SEB" ///
		z_class_size = "Classroom size" ///
		z_seb_class = "Low-SEB share in class" ///
        z_gpa_other = "GPA z-score"        ///
		z_gpa = "GPA z-score"        ///
        1.gender_other = "Female"  ///
    , labsize(vsmall))                                  ///
    title("Who gets a referral?") ///
    xtitle("Coefficient estimate")     ///
    ytitle("")                         ///
    name(model1, replace) $graph_opts

	
	
/*===========================================================================*/
//# Data preparation: POV of referrals
/*===========================================================================*/



// Number of referrals per net_id_other
egen rav_count = count(net_id_other) if network == 1 & net_id_other != ., by(net_id_other)
label variable rav_count "# referrals received by net_id_other (Ravens)"
order rav_count net_id_other network, first
sort network net_id_other

egen eye_count = count(net_id_other) if network == 2 & net_id_other != ., by(net_id_other)
label variable eye_count "# referrals received by net_id_other (Eye)"

gen total_ref = .
replace total_ref = rav_count if !missing(rav_count)
replace total_ref = eye_count if !missing(eye_count)

order total_ref rav_count eye_count


// Referral yes/no per per net_id
gen rav_ref = 1 if network == 1 
label variable rav_ref "Received a Ravens referral by net_id"
order rav_ref net_id network id_count, first
sort net_id rav_ref

by net_id: gen ___t = rav_ref == 1 & _n == 1
order ___t
replace rav_ref = . if ___t != 1
drop ___t


preserve
keep if network == 1
levelsof net_id, local(all_net_ids)
levelsof net_id_other, local(ref_net_ids)
local not_in_others : list all_net_ids - ref_net_ids
restore

foreach id of local not_in_others {
    replace rav_ref = 0 if net_id == `id' & network == 1
}

by net_id: gen ___t = rav_ref == 0 & _n == 1
order ___t
replace rav_ref = . if ___t != 1 & rav_ref == 0
drop __*

**

gen eye_ref = 1 if network == 2
label variable eye_ref "Received an Eye referral by net_id"
sort net_id eye_ref
order eye_ref

by net_id: gen ___t = eye_ref == 1 & _n == 1
order ___t
replace eye_ref = . if ___t != 1
drop ___t


preserve
keep if network == 2
levelsof net_id, local(all_net_ids)
levelsof net_id_other, local(all_net_id_others)
local not_in_others : list all_net_ids - all_net_id_others
restore

foreach id of local not_in_others {
    replace eye_ref = 0 if net_id == `id' & network == 2
}

by net_id: gen ___t = eye_ref == 0 & _n == 1
order ___t
replace eye_ref = . if ___t != 1 & eye_ref == 0
drop __*

bysort net_id: egen sum_eye_ref = sum(eye_ref)
bysort net_id: egen sum_rav_ref = sum(rav_ref)
gen ref0 = sum_eye_ref + sum_rav_ref
order ref0
drop sum_eye_ref sum_rav_ref

by net_id: gen ___t = ref0 == 0 & _n == 1
order ___t
replace ref0 = . if ___t != 1 & ref0 == 0
drop __*

by net_id: gen ___t = ref0 == 1 & _n == 1
order ___t
replace ref0 = . if ___t != 1 & ref0 == 1
drop __*

by net_id: gen ___t = ref0 == 2 & _n == 1
order ___t
replace ref0 = . if ___t != 1 & ref0 == 2
drop __*

gen ref_logit = ref0 
replace ref_logit = 1 if ref0 == 2

order ref0 eye_ref rav_ref total_ref rav_count eye_count, last

sort net_id network







/*===========================================================================*/
//# REGRESSIONS FOR NOT RECEIVING A REFERRAL
/*===========================================================================*/


tabstat ref_logit if network != 3, by(ref_logit) stat(n)

preserve 
keep if network != 3
xtset seb_class_xtile
logit ref_logit i.seb i.gender c.z_rav c.z_eye i.seb_class_xtile c.z_gpa c.z_test
restore
xtlogit rav_ref i.seb i.gender c.z_rav c.z_eye i.treat c.z_gpa c.z_test, fe
estimates store model1
restore


estimates store model1
coefplot model1, xline(0) drop(_cons) sort ///
    coeflabels(                        ///
		1.i.seb#i.seb_other = "Low-SEB referrer*Low-SEB" ///
		1.seb = "Low-SEB"    ///
		2.network = "Eye network" ///
        1.seb_other = "Low-SEB"    ///
		1.first_gen_other = "First Gen"    ///
        z_rav_other = "Cognitive z-score"     ///
		z_eye_other = "Social z-score"     ///
		z_rav = "Cognitive z-score"     ///
		z_eye = "Social z-score"     ///
		classroom_zeye = "Average Eye score in class" ///
		classroom_zrav = "Average Ravens score in class" ///
		int_rav_seb = "Ravens score*Low-SEB" ///
		int_gpa_seb = "GPA*Low-SEB" ///
		int_test_seb = "National Exam Score*Low-SEB" ///
        z_test_other = "Entry Exam z-score"      ///
		z_test = "Entry Exam z-score"      ///
		int_seb_class_seb = "Low-SEB share in class*Low-SEB" ///
		z_class_size = "Classroom size" ///
		z_seb_class = "Low-SEB share in class" ///
        z_gpa_other = "GPA z-score"        ///
		z_gpa = "GPA z-score"        ///
        1.gender_other = "Female"  ///
    , labsize(vsmall))                                  ///
    title("Who gets a referral?") ///
    xtitle("Coefficient estimate")     ///
	xla(-2(1)2) ///
    ytitle("")                         ///
    name(model1, replace) $graph_opts

	

/*===========================================================================*/
//# REGRESSION ON THE NUMBER OF REFERRALS RECEIVED
/*===========================================================================*/

order net_id_other network total_ref rav_count eye_count
sort net_id_other network


preserve
keep if treat == 1
xtset net_class
xtreg total_ref i.seb_other c.z_rav_other c.z_gpa_other c.z_test_other, fe
restore




/*===========================================================================*/
//#	PERFORMANCE IN SKILL TESTS BY SEB VS ADMIN DATA
/*===========================================================================*/



//# VIOLINPLOT SAMPLE SKILL TEST PERFORMANCE BY SEB
/*===========================================================================*/

* t-test and text 1
ttest z_rav if id_count == 1, by(seb)
local pval = r(p)
local pval_rounded_t = round(`pval', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text "t-test {it:p} < 0.001"
} 
else {
    local text "t-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}
* t-test and text 2
ttest z_eye if id_count == 1, by(seb)
local pval = r(p)
local pval_rounded_t = round(`pval', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text2 "t-test {it:p} < 0.001"
} 
else {
    local text2 "t-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}
* t-test and text 3
ttest z_gpa if id_count == 1, by(seb)
local pval = r(p)
local pval_rounded_t = round(`pval', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text3 "t-test {it:p} < 0.001"
} 
else {
    local text3 "t-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}
* t-test and text 4
ttest z_test if id_count == 1, by(seb)
local pval = r(p)
local pval_rounded_t = round(`pval', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text4 "t-test {it:p} < 0.001"
} 
else {
    local text4 "t-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}

violinplot z_rav z_eye z_gpa z_test if id_count == 1, split(seb) name(violin_performance_by_seb, replace) subtitle("") note("") color(orange*0.8 blue*0.8) graphregion(fcolor(white) lcolor(white)) xlabel(0 "Cognitive" 1 "Social" 2 "GPA" 3 "Entry Exam" , labsize(medsmall) tlength(zero) labgap(tiny)) legend(order(1 "High-SEB" 2 "Low-SEB") pos(6) col(1) ring(0) size(small) region(lcolor(none) fcolor(none))) ytitle("Score (standardized)") ///
text(3.6 0 `"`text'"',  placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
text(3.6 1 `"`text2'"',  placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
text(3.6 2 `"`text3'"',  placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
text(3.6 3 `"`text4'"',  placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
mean(msymbol(0) msize(small)) $graph_opts


//# BARPLOT SAMPLE SKILL TEST PERFORMANCE BY SEB
/*===========================================================================*/

* Generate new variables for bar positions
gen new_var1 = 0
gen new_var2 = 0.5
gen new_var3 = 1.5
gen new_var4 = 2

* Calculate means and confidence intervals
ci means rav_pcent if seb == 1 
gen m1 = r(mean)/100
gen lb1 = r(lb)/100
gen ub1 = r(ub)/100

ci means rav_pcent if seb == 0 
gen m1b = r(mean)/100
gen lb1b = r(lb)/100
gen ub1b = r(ub)/100

ci means eye_pcent if seb == 1 
gen m2 = r(mean)/100
gen lb2 = r(lb)/100
gen ub2 = r(ub)/100

ci means eye_pcent if seb == 0 
gen m2b = r(mean)/100
gen lb2b = r(lb)/100
gen ub2b = r(ub)/100

* T-tests and text
ttest rav_pcent if id_count == 1, by(seb)
local pval = r(p)
local pval_rounded_t = round(`pval', 0.0001)	 
local text = cond(`pval_rounded_t' < 0.001, "t-test {it:p} < 0.001", "t-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'")

ttest eye_pcent if id_count == 1, by(seb)
local pval = r(p)
local pval_rounded_t = round(`pval', 0.0001)	 
local text2 = cond(`pval_rounded_t' < 0.001, "t-test {it:p} < 0.001", "t-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'")

* Create the graph
twoway (bar m1b new_var1, sort color(orange*0.8) barwidth(0.4)) ///
       (bar m1 new_var2, sort color(blue*0.5) barwidth(0.4)) ///
       (bar m2b new_var3, sort color(orange*0.8) barwidth(0.4)) ///
       (bar m2 new_var4, sort color(blue*0.5) barwidth(0.4)) ///
       (rcap lb1b ub1b new_var1, sort color(black) lwidth(thin)) ///
       (rcap lb1 ub1 new_var2, sort color(black) lwidth(thin)) ///
       (rcap lb2b ub2b new_var3, sort color(black) lwidth(thin)) ///
       (rcap lb2 ub2 new_var4, sort color(black) lwidth(thin)) ///
       (scatteri .634 0 .634 .5, msize(*0.7) msymbol(pipe) mc(black)) ///
       (scatteri .638 0 .638 .5, recast(line) lw(vthin) lc(black) lp(solid)) ///
	   (scatteri .634 1.5 .634 2, msize(*0.7) msymbol(pipe) mc(black)) ///
       (scatteri .638 1.5 .638 2, recast(line) lw(vthin) lc(black) lp(solid)), ///
       legend(order(1 "High-SEB" 2 "Low-SEB") pos(12) ring(0) cols(1) region(lcolor(white))) ///
	   subtitle("") note("") ylabel(, angle(horizontal)) yla(0(.2)1) ///
       plotregion(margin(0) style(none)) ///
       text(.675 .25 `"`text'"', placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
	   text(.675 1.75 `"`text2'"', placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
	    text(.15 0 "`=string(m1b, "%9.2f")'", placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
       text(.15 1.5 "`=string(m1, "%9.2f")'", placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
       text(.15 0.5 "`=string(m2b, "%9.2f")'", placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
       text(.15 2 "`=string(m2, "%9.2f")'", placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
       xlabel(-.25 " " 0.25 "Cognitive" 1.75 "Social" 2.25 " ", labsize(medsmall) tlength(zero) labgap(tiny)) ///
       xtitle("") ytitle("Test score proportion") name(bar_perf, replace) ///
       graphregion(fcolor(white) lcolor(white)) xsize(4) ysize(3) $graph_opts

drop new_var* m1* m2* lb* ub*	   


//# BARPLOT REFERAL BY SEB
/*===========================================================================*/


* Generate new variables for bar positions
gen new_var1 = 0
gen new_var2 = 0.5
gen new_var3 = 1.5
gen new_var4 = 2

* Calculate means and confidence intervals
ci means seb_other if network == 1 & seb == 0 & rav_net_self == 0
gen m1 = r(mean)
gen lb1 = r(lb)
gen ub1 = r(ub)

ci means seb_other if network == 1 & seb == 1 & rav_net_self == 0
gen m1b = r(mean)
gen lb1b = r(lb)
gen ub1b = r(ub)

ci means seb_other if network == 2 & seb == 0 & eye_net_self == 0
gen m2 = r(mean)
gen lb2 = r(lb)
gen ub2 = r(ub)

ci means seb_other if network == 2 & seb == 1 & eye_net_self == 0
gen m2b = r(mean)
gen lb2b = r(lb)
gen ub2b = r(ub)

ci means seb  if id_count == 1
gen m3 = r(mean)

* T-tests and text
prtest seb_other if network == 1, by(seb)
local pval = r(p)
local pval_rounded_t = round(`pval', 0.0001)	 
local text = cond(`pval_rounded_t' < 0.001, "pr-test {it:p} < 0.001", "t-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'")

prtest seb_other if network == 2, by(seb)
local pval = r(p)
local pval_rounded_t = round(`pval', 0.0001)	 
local text2 = cond(`pval_rounded_t' < 0.001, "pr-test {it:p} < 0.001", "t-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'")

* Create the graph
twoway (bar m1 new_var1, sort color(orange*0.8) barwidth(0.4)) ///
       (bar m1b new_var2, sort color(blue*0.5) barwidth(0.4)) ///
       (bar m2 new_var3, sort color(orange*0.8) barwidth(0.4)) ///
       (bar m2b new_var4, sort color(blue*0.5) barwidth(0.4)) ///
       (rcap lb1 ub1 new_var1, sort color(black) lwidth(thin)) ///
       (rcap lb1b ub1b new_var2, sort color(black) lwidth(thin)) ///
       (rcap lb2 ub2 new_var3, sort color(black) lwidth(thin)) ///
       (rcap lb2b ub2b new_var4, sort color(black) lwidth(thin)) ///
	   (function y = m3, range(-0.25 2.25) lcolor(black) lpattern(dash)) ///
       (scatteri .634 0 .634 .5, msize(*0.7) msymbol(pipe) mc(black)) ///
       (scatteri .638 0 .638 .5, recast(line) lw(vthin) lc(black) lp(solid)) ///
	   (scatteri .634 1.5 .634 2, msize(*0.7) msymbol(pipe) mc(black)) ///
       (scatteri .638 1.5 .638 2, recast(line) lw(vthin) lc(black) lp(solid)), ///
       legend(order(1 "High-SEB" 2 "Low-SEB") pos(12) ring(0) cols(1) region(lcolor(white))) ///
	   subtitle("") note("") ylabel(, angle(horizontal)) yla(0(.2)1) ///
       plotregion(margin(0) style(none)) ///
       text(.675 .25 `"`text'"', placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
	   text(.675 1.75 `"`text2'"', placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
	   text(.15 0 "`=string(m1, "%9.2f")'", placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
       text(.15 .5 "`=string(m1b, "%9.2f")'", placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
       text(.15 1.5 "`=string(m2, "%9.2f")'", placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
       text(.15 2 "`=string(m2b, "%9.2f")'", placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
       xlabel(-.25 " " 0.25 "Cognitive" 1.75 "Social" 2.25 " ", labsize(medsmall) tlength(zero) labgap(tiny)) ///
       xtitle("") ytitle("Low-SEB referral share") name(bar_perf, replace) ///
       graphregion(fcolor(white) lcolor(white)) xsize(4) ysize(3) $graph_opts

drop new_var* m1* m2* lb* ub* m3

	   
//# CORRELATION PLOTS 
/*===========================================================================*/

* rav and entry exam

// Calculate slopes and intercepts for each group
foreach seb in 0 1 {
    // Calculate the correlation coefficient for this group
    correlate z_test z_rav if id_count == 1 & seb == `seb'
    local corr_`seb' = r(rho)

    // Calculate the slope and intercept for the correlation line
    summarize z_test if id_count == 1 & seb == `seb'
    local sd_y_`seb' = r(sd)
    local mean_y_`seb' = r(mean)
    summarize z_rav if id_count == 1 & seb == `seb'
    local sd_x_`seb' = r(sd)
    local mean_x_`seb' = r(mean)
    local slope_`seb' = `corr_`seb'' * (`sd_y_`seb'' / `sd_x_`seb'')
    local intercept_`seb' = `mean_y_`seb'' - `slope_`seb'' * `mean_x_`seb''
    
    // Format slope for label
    local slope_label_`seb' = string(`slope_`seb'', "%9.3f")
}

twoway (scatter z_test z_rav if id_count == 1 & seb == 0, jitter(5) mcolor(blue*.5)) ///
       (scatter z_test z_rav if id_count == 1 & seb == 1, jitter(5) mcolor(pink*.5)) ///
       (function y = `slope_0'*x + `intercept_0', range(z_rav) lcolor(blue*.7) lwidth(thick)) ///
       (function y = `slope_1'*x + `intercept_1', range(z_rav) lcolor(pink*.7) lwidth(thick)), ///
       legend(order(3 "High-SEB (slope = `slope_label_0')" 4 "Low-SEB (slope = `slope_label_1')") pos(11) col(1) ring(0) size(small) region(lcolor(none) fcolor(none))) ///
       name(corr_rav_test, replace) ///
       graphregion(fcolor(white) lcolor(white)) ///
       ytitle("Entry Exam") ///
       xtitle("Cognitive") ///
       ylabel(, angle(horizontal)) yla(-4(2)4)

* eye and entry exam

// Calculate slopes and intercepts for each group
foreach seb in 0 1 {
    // Calculate the correlation coefficient for this group
    correlate z_test z_eye if id_count == 1 & seb == `seb'
    local corr_`seb' = r(rho)

    // Calculate the slope and intercept for the correlation line
    summarize z_test if id_count == 1 & seb == `seb'
    local sd_y_`seb' = r(sd)
    local mean_y_`seb' = r(mean)
    summarize z_eye if id_count == 1 & seb == `seb'
    local sd_x_`seb' = r(sd)
    local mean_x_`seb' = r(mean)
    local slope_`seb' = `corr_`seb'' * (`sd_y_`seb'' / `sd_x_`seb'')
    local intercept_`seb' = `mean_y_`seb'' - `slope_`seb'' * `mean_x_`seb''
    
    // Format slope for label
    local slope_label_`seb' = string(`slope_`seb'', "%9.3f")
}

twoway (scatter z_test z_eye if id_count == 1 & seb == 0, jitter(5) mcolor(blue*.5)) ///
       (scatter z_test z_eye if id_count == 1 & seb == 1, jitter(5) mcolor(pink*.5)) ///
       (function y = `slope_0'*x + `intercept_0', range(z_rav) lcolor(blue*.7) lwidth(thick)) ///
       (function y = `slope_1'*x + `intercept_1', range(z_rav) lcolor(pink*.7) lwidth(thick)), ///
       legend(order(3 "High-SEB (slope = `slope_label_0')" 4 "Low-SEB (slope = `slope_label_1')") pos(11) col(1) ring(0) size(small) region(lcolor(none) fcolor(none))) ///
       name(corr_eye_test, replace) ///
       graphregion(fcolor(white) lcolor(white)) ///
       ytitle("Entry Exam") ///
       xtitle("Social") ///
       ylabel(, angle(horizontal)) yla(-4(2)4)

* rav and gpa

// Calculate slopes and intercepts for each group
foreach seb in 0 1 {
    // Calculate the correlation coefficient for this group
    correlate z_gpa z_rav if id_count == 1 & seb == `seb'
    local corr_`seb' = r(rho)

    // Calculate the slope and intercept for the correlation line
    summarize z_gpa if id_count == 1 & seb == `seb'
    local sd_y_`seb' = r(sd)
    local mean_y_`seb' = r(mean)
    summarize z_rav if id_count == 1 & seb == `seb'
    local sd_x_`seb' = r(sd)
    local mean_x_`seb' = r(mean)
    local slope_`seb' = `corr_`seb'' * (`sd_y_`seb'' / `sd_x_`seb'')
    local intercept_`seb' = `mean_y_`seb'' - `slope_`seb'' * `mean_x_`seb''
    
    // Format slope for label
    local slope_label_`seb' = string(`slope_`seb'', "%9.3f")
}

twoway (scatter z_gpa z_rav if id_count == 1 & seb == 0, jitter(5) mcolor(blue*.5)) ///
       (scatter z_gpa z_rav if id_count == 1 & seb == 1, jitter(5) mcolor(pink*.5)) ///
       (function y = `slope_0'*x + `intercept_0', range(z_rav) lcolor(blue*.7) lwidth(thick)) ///
       (function y = `slope_1'*x + `intercept_1', range(z_rav) lcolor(pink*.7) lwidth(thick)), ///
       legend(order(3 "High-SEB (slope = `slope_label_0')" 4 "Low-SEB (slope = `slope_label_1')") pos(11) col(1) ring(0) size(small) region(lcolor(none) fcolor(none))) ///
       name(corr_gpa_rav, replace) ///
       graphregion(fcolor(white) lcolor(white)) ///
       ytitle("GPA") ///
       xtitle("Cognitive") ///
       ylabel(, angle(horizontal)) yla(-4(2)4)	   


* eye and gpa

// Calculate slopes and intercepts for each group
foreach seb in 0 1 {
    // Calculate the correlation coefficient for this group
    correlate z_gpa z_eye if id_count == 1 & seb == `seb'
    local corr_`seb' = r(rho)

    // Calculate the slope and intercept for the correlation line
    summarize z_gpa if id_count == 1 & seb == `seb'
    local sd_y_`seb' = r(sd)
    local mean_y_`seb' = r(mean)
    summarize z_eye if id_count == 1 & seb == `seb'
    local sd_x_`seb' = r(sd)
    local mean_x_`seb' = r(mean)
    local slope_`seb' = `corr_`seb'' * (`sd_y_`seb'' / `sd_x_`seb'')
    local intercept_`seb' = `mean_y_`seb'' - `slope_`seb'' * `mean_x_`seb''
    
    // Format slope for label
    local slope_label_`seb' = string(`slope_`seb'', "%9.3f")
}

twoway (scatter z_gpa z_eye if id_count == 1 & seb == 0, jitter(5) mcolor(blue*.5)) ///
       (scatter z_gpa z_eye if id_count == 1 & seb == 1, jitter(5) mcolor(pink*.5)) ///
       (function y = `slope_0'*x + `intercept_0', range(z_rav) lcolor(blue*.7) lwidth(thick)) ///
       (function y = `slope_1'*x + `intercept_1', range(z_rav) lcolor(pink*.7) lwidth(thick)), ///
       legend(order(3 "High-SEB (slope = `slope_label_0')" 4 "Low-SEB (slope = `slope_label_1')") pos(11) col(1) ring(0) size(small) region(lcolor(none) fcolor(none))) ///
       name(corr_gpa_eye, replace) ///
       graphregion(fcolor(white) lcolor(white)) ///
       ytitle("GPA") ///
       xtitle("Social") ///
       ylabel(, angle(horizontal)) yla(-4(2)4)


	   
* rav and rav_other

egen ___rav_avg = mean(z_rav_other) if network == 1, by(net_id)
bysort net_id (___rav_avg): egen to_fill = max(___rav_avg)
replace ___rav_avg = to_fill if missing(___rav_avg)
egen __z_rav_age = std(___rav_avg)
drop to_fill
tabstat __z_rav_age z_rav  if id_count == 1 , stat(n mean sd)

correlate __z_rav_age z_rav if id_count == 1 
local pval = r(rho)
if `pval' < 0.001 {
    local pval_rounded = "< 0.001"
} 
else {
    local pval_rounded = "= " + string(round(`pval', 0.001))
}	 
local text = " r `pval_rounded'" 
twoway (scatter __z_rav_age z_rav if id_count == 1 , jitter(5)), text(2 -2.5 `"`text'"',  placement(c) justification(left) size(small) fcolor(none) margin(small)) name(corr_ravref, replace)

egen ___eye_avg = mean(z_eye_other) if network == 2, by(net_id)
bysort net_id (___eye_avg): egen to_fill = max(___eye_avg)
replace ___eye_avg = to_fill if missing(___eye_avg)
egen __z_eye_age = std(___eye_avg)
drop to_fill

	   
/*===========================================================================*/
//#	 LOW SEB SHARE IN SAMPLE VS REFERRALS (POOLED RAVENS AND EYE)
/*===========================================================================*/



//# TABLE 
/*===========================================================================*/

* share of low-SEB among sample and referrals without performance
tabstat seb if id_count == 1, by(seb) stat(mean sd n)
tabstat seb_other if network != 3, by(seb_other)  stat(mean sd n)

//# BAR PLOT
/*===========================================================================*/

preserve
keep if treat == 1
quietly summarize
local n = r(N)
local remainder = mod(`n', 2)
if `remainder' > 0 {
    expand 2 in 1
}
generate new_var = mod(_n-1, 2)
tabulate new_var

ci means seb if id_count == 1
gen m1 = r(mean)
gen lb1 = r(lb)
gen ub1 = r(ub)

ci means seb_other if network != 3
gen m2 = r(mean)
gen lb2 = r(lb)
gen ub2 = r(ub)

gen temp1 = seb if id_count == 1
gen temp2 = seb_other if network != 3
prtest temp1 = temp2 // 2 sample group test (between sample)
local pval = r(p)
local mu1 = round(r(P1), 0.01)
display "`mu1'"
local mu2 = round(r(P2), 0.01)
display "`mu2'"
local pval_rounded_t = round(`pval', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text "pr-test {it:p} < 0.001"
} 
else {
    local text "pr-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}
display "`text'"
twoway (bar m1 new_var if new_var == 0, sort color(pink*0.5) barwidth(0.5)) ///
       (bar m2 new_var if new_var == 1, sort color(blue*0.5) barwidth(0.5)) ///
       (rcap lb1 ub1 new_var if new_var == 0, sort color(black) lwidth(thin)) ///
       (rcap lb2 ub2 new_var if new_var == 1, sort color(black) lwidth(thin)) ///
       (scatteri .734 0 .734 1, msize(*0.7) msymbol(pipe) mc(black)) ///
       (scatteri .738 0 .738 1, recast(line) lw(vthin) lc(black) lp(solid)), ///
       legend(off) subtitle("") note("") ylabel(, angle(horizontal)) yla(0(.2)1) plotregion(margin(0) style(none)) ///
       text(.77 .5 `"`text'"',  placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
       text(.15 0 "`=string(`mu1', "%9.2f")'",  placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
       text(.15 1 "`=string(`mu2', "%9.2f")'",  placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
       xlabel(-0.5 " " 0 "Sample" 1 "Referrals only" 1.5 " ", labsize(medsmall) tlength(zero) labgap(tiny)) ///
       xtitle("") ytitle("Low-SEB share") name(bar_share_ref_low, replace)  graphregion(fcolor(white)) xsize(3) ysize(3) ///
	   graphregion(fcolor(white) lcolor(white))

drop m1 lb1 ub1 m2 lb2 ub2 new_var temp1 temp2
restore


//# LOW SEB SHARE IN SAMPLE VS REFERRALS BY SEB XTILE
/*===========================================================================*/

tabstat seb if id_count == 1, by(seb_class_xtile) stat(mean sd n)
tabstat seb_other if network != 3, by(seb_class_xtile)  stat(mean sd n)

gen __temp1 = seb if id_count == 1 & seb_class_xtile < 3
gen __temp2 = seb_other if network != 3 & seb_class_xtile < 3
prtest __temp1 = __temp2
drop __*

gen __temp1 = seb if id_count == 1 & seb_class_xtile > 2
gen __temp2 = seb_other if network != 3 & seb_class_xtile > 2
prtest __temp1 = __temp2
drop __*



/*===========================================================================*/
//# BASELINE VS QUOTA: LOW-SEB SHARE IN REFERRALS
/*===========================================================================*/


//# BAR GRAPH
tabstat seb_other treat if network != 3, by(seb_other) stat(n mean sd)
tab seb_other treat if network != 3

* create new variable for a bar chart with 2 columns!!
gen new_var1 = 0
gen new_var2 = 0.5
gen new_var3 = 1.5
gen new_var4 = 2
    
ci means seb_other if treat==1 & network == 1
gen m1 = r(mean)
gen lb1 = r(lb)
gen ub1 = r(ub)
ci means seb_other if treat==1 & network == 2
gen m1bbis = r(mean)
gen lb1bbis = r(lb)
gen ub1bbis = r(ub)
ci means seb if treat == 1
gen m1bis = r(mean)

ci means seb if treat == 2
gen m2bis = r(mean)
ci means seb_other if treat==2 & network == 1
gen m2 = r(mean)
gen lb2 = r(lb)
gen ub2 = r(ub)
ci means seb_other if treat==2 & network == 2
gen m2bbis = r(mean)
gen lb2bbis = r(lb)
gen ub2bbis = r(ub)
ci means seb if id_count == 1
gen m3 = r(mean)

prtest seb_other if network != 3, by(treat)
local pval = r(p)
local mu1 = round(r(P1), 0.01)
local mu2 = round(r(P2), 0.01)
local pval_rounded_t = round(`pval', 0.0001)     
if `pval_rounded_t' < 0.001 {
    local text "pr-test {it:p} < 0.001"
} 
else {
    local text "pr-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}
display "`text'"
twoway (bar m1 new_var1, sort color(orange*0.8) barwidth(0.5)) ///
       (bar m1bbis new_var2, sort color(blue*0.5) barwidth(0.5)) ///
	   (bar m2 new_var3, sort color(orange*0.8) barwidth(0.5)) ///
       (bar m2bbis new_var4, sort color(blue*0.5) barwidth(0.5)) ///
       (rcap lb1 ub1  new_var1, sort color(black) lwidth(thin)) ///
       (rcap lb1bbis ub1bbis  new_var2, sort color(black) lwidth(thin)) ///
	   (rcap lb2 ub2  new_var3, sort color(black) lwidth(thin)) ///
	   (rcap lb2bbis ub2bbis new_var4, sort color(black) lwidth(thin)) ///
       (scatteri .734 0 .734 1, msize(*0.7) msymbol(pipe) mc(black)) ///
       (scatteri .738 0 .738 1, recast(line) lw(vthin) lc(black) lp(solid)) ///
       (scatter m1bis new_var1, msymbol(diamond) mcolor(red) msize(medium)) ///
       (scatter m2bis new_var3, msymbol(diamond) mcolor(red) msize(medium)), ///
       legend(off) subtitle("") note("") ylabel(, angle(horizontal)) yla(0(.2)1) plotregion(margin(0) style(none)) ///
       text(.77 .5 `"`text'"',  placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
       text(.15 0 "`=string(`mu1', "%9.2f")'",  placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
	   text(.15 0.5 "`=string(`mu1b', "%9.2f")'",  placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
       text(.15 1.5 "`=string(`mu2', "%9.2f")'",  placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
	   text(.15 1.5 "`=string(`mu2b', "%9.2f")'",  placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
       xlabel(-0.5 " " 0.5 "Baseline" 1.5 "Quota" 2.5 " ", labsize(medsmall) tlength(zero) labgap(tiny)) ///
       xtitle("") ytitle("Low-SEB referral share") name(bar_low_treat, replace)  graphregion(fcolor(white))  xsize(3) ysize(3) $graph_opts
* Safely drop variables if they exist
drop m1* lb* ub* m2* new_var*  m3*

/*===========================================================================*/
//# TOP REFERRALS FOR RAV AND EYE 
/*===========================================================================*/


//# BAR GRAPH

* create new variable for a bar chart with 2 columns!!
quietly summarize
local n = r(N)
local remainder = mod(`n', 2)
if `remainder' > 0 {
    expand 2 in 1
}
generate new_var = mod(_n-1, 2)
tabulate new_var
	
ci means any_top_ref_r 
gen m1 = r(mean)
gen lb1 = r(lb)
gen ub1 = r(ub)

ci means any_top_ref_e 
gen m2 = r(mean)
gen lb2 = r(lb)
gen ub2 = r(ub)


prtest any_top_ref_r = any_top_ref_e 
local pval = r(p)
local mu1 = round(r(P1), 0.01)
local mu2 = round(r(P2), 0.01)
local pval_rounded_t = round(`pval', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text "pr-test {it:p} < 0.001"
} 
else {
    local text "pr-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}
display "`text'"
twoway (bar m1 new_var if new_var == 0, sort color(orange*0.8) barwidth(0.5)) ///
       (bar m2 new_var if new_var == 1, sort color(blue*0.8) barwidth(0.5)) ///
       (rcap lb1 ub1 new_var if new_var == 0, sort color(black) lwidth(thin)) ///
       (rcap lb2 ub2 new_var if new_var == 1, sort color(black) lwidth(thin)) ///
       (scatteri .734 0 .734 1, msize(*0.7) msymbol(pipe) mc(black)) ///
       (scatteri .738 0 .738 1, recast(line) lw(vthin) lc(black) lp(solid)), ///
       legend(off) subtitle("") note("") ylabel(, angle(horizontal)) yla(0(.2)1) plotregion(margin(0) style(none)) ///
       text(.77 .5 `"`text'"',  placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
       text(.465 0 "`=string(`mu1', "%9.2f")'",  placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
       text(.465 1 "`=string(`mu2', "%9.2f")'",  placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
       xlabel(-0.5 " " 0 "Cognitive" 1 "Social" 1.5 " ", labsize(medsmall) tlength(zero) labgap(tiny)) ///
       xtitle("") ytitle("Q1 referral share") name(bar_low_quota_rav_CI, replace)  graphregion(fcolor(white))  xsize(3) ysize(3) $graph_opts

* Safely drop variables if they exist
foreach var in m1 lb1 ub1 m2 lb2 ub2 m3 new_var {
    capture confirm variable `var'
    if !_rc {
        drop `var'
    }
}

/*===========================================================================*/
//#	LOW SEB SHARE IN TOP REFERRALS (POOLED RAVENS AND EYE)
/*===========================================================================*/



//#  TOP3
/*===========================================================================*/

* start with ravens
tabstat z_rav if id_count == 1 & rank_eye_class<=3, by(seb) stat(mean sd n) save
local h1 = r(Stat1)[3,1]
local l1 = r(Stat2)[3,1]
local t1 = `h1' + `l1'
local r1 = `l1'/`t1'
display "Low-SEB share in top 3 Ravens: `r1'"

* table for top 3 ravens referrals
tabstat z_rav_other if network == 1 & rank_rav_class_other<=3, by(seb_other) stat(mean sd n) save

* proportion test
prtest seb_other == `r1' if network == 1 & rank_rav_class_other<=3

* barplot combine raven and eye
quietly summarize
local n = r(N)
local remainder = mod(`n', 2)
if `remainder' > 0 {
    expand 2 in 1
}
generate new_var = mod(_n-1, 2)
tabulate new_var

ci means seb if id_count == 1 & (rank_eye_class<=3 | rank_rav_class<=3)
local mu = r(mean)
gen m1 = r(mean)
gen lb1 = r(lb)
gen ub1 = r(ub)

ci means seb_other if (rank_rav_class_other<=3 & network==1) | (rank_eye_class_other<=3 & network==2)
gen m2 = r(mean)
gen lb2 = r(lb)
gen ub2 = r(ub)

prtest seb_other == `mu' if (rank_rav_class_other<=3 & network==1) | (rank_eye_class_other<=3 & network==2)
local pval = r(p)
local mu1 = round(`r(P1)', 0.01)
local mu2 = round(`r(P2)', 0.01)
local pval_rounded_t = round(`pval', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text "pr-test {it:p} < 0.001"
} 
else {
    local text "pr-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}
twoway (bar m1 new_var if new_var == 0, sort color(pink*0.5) barwidth(0.5)) ///
       (bar m2 new_var if new_var == 1, sort color(blue*0.5) barwidth(0.5)) ///
       (rcap lb1 ub1 new_var if new_var == 0, sort color(black) lwidth(thin)) ///
       (rcap lb2 ub2 new_var if new_var == 1, sort color(black) lwidth(thin)) ///
       (scatteri .634 0 .634 1, msize(*0.7) msymbol(pipe) mc(black)) ///
       (scatteri .638 0 .638 1, recast(line) lw(vthin) lc(black) lp(solid)), ///
	   legend(off) subtitle("") note("") ylabel(, angle(horizontal)) yla(0(.2)1) plotregion(margin(0) style(none)) ///
	   text(.675 .5 `"`text'"',  placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
	   text(.15 0 "`=string(m1, "%9.2f")'",  placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
	   text(.15 1 "`=string(m2, "%9.2f")'",  placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
	   xlabel(-0.5 " " 0 "Sample" 1 "Referrals only" 1.5 " ", labsize(medsmall) tlength(zero) labgap(tiny)) ///
	   xtitle("") ytitle("Top 3 share of low-SEB") name(bar_ref_top3, replace)  graphregion(fcolor(white)) xsize(3) ysize(3) ///
	   graphregion(fcolor(white) lcolor(white))
	   
drop m1 lb1 ub1 m2 lb2 ub2 new_var


//#  Q1 bar plot
/*===========================================================================*/

* start with ravens
preserve
keep if treat == 1 
tabstat z_rav if id_count == 1 & rank_rav_xtile==1, by(seb) stat(mean sd n) save
local h1 = r(Stat1)[3,1]
local l1 = r(Stat2)[3,1]
local t1 = `h1' + `l1'
local r1 = `l1'/`t1'
display "Low-SEB share in top 3 Ravens: `r1'"

* table for top ravens referrals
tabstat z_rav_other if network == 1 & rank_rav_other_xtile==1, by(seb_other) stat(mean sd n) save

* proportion test
prtest seb_other == `r1' if (network == 1 & rank_rav_other_xtile==1)

* barplot combine raven and eye
quietly summarize
local n = r(N)
local remainder = mod(`n', 2)
if `remainder' > 0 {
    expand 2 in 1
}
generate new_var = mod(_n-1, 2)
tabulate new_var

ci means seb if id_count == 1 & (rank_eye_xtile==1 | rank_rav_xtile==1)
local mu = r(mean)
gen m1 = r(mean)
gen lb1 = r(lb)
gen ub1 = r(ub)

ci means seb_other if (rank_rav_other_xtile==1 & network==1) | (rank_eye_other_xtile==1 & network==2)
gen m2 = r(mean)
gen lb2 = r(lb)
gen ub2 = r(ub)

prtest seb_other == `mu' if (rank_rav_other_xtile==1 & network==1) | (rank_eye_other_xtile==1 & network==2)
local pval = r(p)
local mu1 = round(`r(P1)', 0.01)
local mu2 = round(`r(P2)', 0.01)
local pval_rounded_t = round(`pval', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text "pr-test {it:p} < 0.001"
} 
else {
    local text "pr-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}
twoway (bar m1 new_var if new_var == 0, sort color(pink*0.5) barwidth(0.5)) ///
       (bar m2 new_var if new_var == 1, sort color(blue*0.5) barwidth(0.5)) ///
       (rcap lb1 ub1 new_var if new_var == 0, sort color(black) lwidth(thin)) ///
       (rcap lb2 ub2 new_var if new_var == 1, sort color(black) lwidth(thin)) ///
       (scatteri .634 0 .634 1, msize(*0.7) msymbol(pipe) mc(black)) ///
       (scatteri .638 0 .638 1, recast(line) lw(vthin) lc(black) lp(solid)), ///
	   legend(off) subtitle("") note("") ylabel(, angle(horizontal)) yla(0(.2)1) plotregion(margin(0) style(none)) ///
	   text(.675 .5 `"`text'"',  placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
	   text(.15 0 "`=string(m1, "%9.2f")'",  placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
	   text(.15 1 "`=string(m2, "%9.2f")'",  placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
	   xlabel(-0.5 " " 0 "Sample" 1 "Referrals only" 1.5 " ", labsize(medsmall) tlength(zero) labgap(tiny)) ///
	   xtitle("") ytitle("Q1 share of low-SEB") name(bar_ref_q1, replace)  graphregion(fcolor(white)) xsize(3) ysize(3) ///
	   graphregion(fcolor(white) lcolor(white))
	   
drop m1 lb1 ub1 m2 lb2 ub2 new_var
restore

//# VIOLINPLOT Q1 PERFORMANCE BY SEB
/*===========================================================================*/

* t-test and text 1
ttest z_rav if (id_count==1), by(seb)
local pval = r(p)
local pval_rounded_t = round(`pval', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text1 "t-test {it:p} < 0.001"
} 
else {
    local text1 "t-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}

* t-test and text 2
ttest z_rav if (rank_rav_xtile==1 & id_count==1), by(seb)
local pval = r(p)
local pval_rounded_t = round(`pval', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text2 "t-test {it:p} < 0.001"
} 
else {
    local text2 "t-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}

* t-test and text 3
ttest z_eye if (id_count==1), by(seb)
local pval = r(p)
local pval_rounded_t = round(`pval', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text3 "t-test {it:p} < 0.001"
} 
else {
    local text3 "t-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}

* t-test and text 4
ttest z_eye if (rank_eye_xtile==1 & id_count==1), by(seb)
local pval = r(p)
local pval_rounded_t = round(`pval', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text4 "t-test {it:p} < 0.001"
} 
else {
    local text4 "t-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}

gen r0 = z_rav if id_count == 1
gen r1 = z_rav if id_count == 1 & rank_rav_class <= 3
gen ey0 = z_eye if id_count == 1
gen ey1 = z_eye if id_count == 1 & rank_eye_class <= 3

violinplot r0 r1 ey0 ey1, split(seb) ///
    name(violin_top_performance_by_seb, replace) ///
    subtitle("") note("") ///
    color(blue*.5 pink*.5) ///
    graphregion(fcolor(white) lcolor(white)) ///
    xlabel(-.5 " " 0 "Cognitive" 1 "Q1 Cognitive" 2 "Social" 3 "Q1 Social", labsize(medsmall) tlength(zero) labgap(tiny)) ///
    legend(order(1 "High-SEB" 2 "Low-SEB") pos(5) cols(1) ring(0) size(small) region(lcolor(none) fcolor(none))) ///
    ytitle("Standardized test score") ///
    text(3 0 `"`text1'"', placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
    text(3 1 `"`text2'"', placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
	text(3 2 `"`text3'"', placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
    text(3 3 `"`text4'"', placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
    mean(msymbol(O) msize(small)) yla(-4(2)4) tight
drop r0 r1 ey0 ey1

//# VIOLINPLOT REFERRAL VS Q1 REFERRAL PERFORMANCE BY SEB
/*===========================================================================*/

* t-test and text 1
ttest z_rav_other if (network==1), by(seb_other)
local pval = r(p)
local pval_rounded_t = round(`pval', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text1 "t-test {it:p} < 0.001"
} 
else {
    local text1 "t-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}

* t-test and text 2
ttest z_rav_other if (rank_rav_class_other_xtile==1 & network==1), by(seb_other)
local pval = r(p)
local pval_rounded_t = round(`pval', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text2 "t-test {it:p} < 0.001"
} 
else {
    local text2 "t-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}

* t-test and text 3
ttest z_eye_other if (network==2), by(seb_other)
local pval = r(p)
local pval_rounded_t = round(`pval', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text3 "t-test {it:p} < 0.001"
} 
else {
    local text3 "t-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}

* t-test and text 4
ttest z_eye_other if (rank_eye_class_other_xtile==1 & network==2), by(seb_other)
local pval = r(p)
local pval_rounded_t = round(`pval', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text4 "t-test {it:p} < 0.001"
} 
else {
    local text4 "t-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}

gen r0 = z_rav_other if network == 1
gen r1 = z_rav_other if network == 1 & rank_rav_class_other_xtile == 1
gen ey0 = z_eye_other if network == 2
gen ey1 = z_eye_other if network == 2 & rank_eye_class_other_xtile == 1

violinplot r0 r1 ey0 ey1, split(seb_other) ///
    name(violin_topref_performance_by_seb, replace) ///
    subtitle("") note("") ///
    color(blue*.5 pink*.5) ///
    graphregion(fcolor(white) lcolor(white)) ///
    xlabel(-.5 " " 0 "Cognitive" 1 "Q1 Cognitive" 2 "Social" 3 "Q1 Social", labsize(medsmall) tlength(zero) labgap(tiny)) ///
    legend(order(1 "High-SEB" 2 "Low-SEB") pos(5) cols(1) ring(0) size(small) region(lcolor(none) fcolor(none))) ///
    ytitle("Standardized test score") ///
    text(3 0 `"`text1'"', placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
    text(3 1 `"`text2'"', placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
	text(3 2 `"`text3'"', placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
    text(3 3 `"`text4'"', placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
    mean(msymbol(O) msize(small)) yla(-4(2)4)
drop r0 r1 ey0 ey1


* check for top 3 availability by seb origin
tabstat seb if ((rank_rav_class<=3 & network==1) | (rank_eye_class<=3 & network==2)), by(net_class) stat(mean sd n) save
tabstat z_rav_other if network == 1 & rank_rav_class_other<=3, by(seb_other) stat(mean sd n) save

* top 3 referrals by seb origin
tab seb seb_other if ((rank_rav_class_other<=3 & network==1) | (rank_eye_class_other<=3 & network==2)), row



/*===========================================================================*/		
//#  GUESSING ABILITY SEB
/*===========================================================================*/



//# bar plot SEB guessing ability by SEB guesser
/*===========================================================================*/


preserve
keep if network == 3 & seb_net_self == 0

tab seb_pcent seb_class_xtile // correct guesses are driven by availability!
tab seb_pcent seb 

* plot
quietly summarize
local n = r(N)
local remainder = mod(`n', 2)
if `remainder' > 0 {
    expand 2 in 1
}
generate new_var = mod(_n-1, 2)
tabulate new_var

ci means guess_ratio if seb == 0 & net_count == 1
local mu = r(mean)
gen m1 = r(mean)
gen lb1 = r(lb)
gen ub1 = r(ub)

ci means guess_ratio if seb == 1 &  net_count == 1
gen m2 = r(mean)
gen lb2 = r(lb)
gen ub2 = r(ub)

ci means seb if net_count == 1
gen m3 = r(mean)

ttest guess_ratio if net_count == 1, by(seb) unequal unpaired // correct guesses are driven by own SEB!
local pval = r(p)
local mu1 = round(`r(P1)', 0.01)
local mu2 = round(`r(P2)', 0.01)
local pval_rounded_t = round(`pval', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text "t-test {it:p} < 0.001"
} 
else {
    local text "t-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}
twoway (bar m1 new_var if new_var == 0, sort color(orange*0.8) barwidth(0.5)) ///
       (bar m2 new_var if new_var == 1, sort color(blue*0.5) barwidth(0.5)) ///
	   (function y = 1, range(-0.5 1.5) lcolor(black) lpattern(dash)) ///
       (rcap lb1 ub1 new_var if new_var == 0, sort color(black) lwidth(thin)) ///
       (rcap lb2 ub2 new_var if new_var == 1, sort color(black) lwidth(thin)) ///
       (scatteri 1.504 0 1.504 1, msize(*0.7) msymbol(pipe) mc(black)) ///
       (scatteri 1.508 0 1.508 1, recast(line) lw(vthin) lc(black) lp(solid)), ///
	   legend(off) subtitle("") note("") ylabel(, angle(horizontal)) yla(0(.2)2) plotregion(margin(0) style(none)) ///
	   text(1.562 .5 `"`text'"',  placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
	   text(.15 0 "`=string(m1, "%9.2f")'",  placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
	   text(.15 1 "`=string(m2, "%9.2f")'",  placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
	   xlabel(-0.5 " " 0 "High-SEB" 1 "Low-SEB" 1.5 " ", labsize(medsmall) tlength(zero) labgap(tiny)) ///
	   xtitle("") ytitle("Correct guesses / Low-SEB share ") name(bar_guess, replace)  graphregion(fcolor(white)) xsize(3) ysize(3) ///
	   graphregion(fcolor(white) lcolor(white)) $graph_opts
	   
drop m1 lb1 m3 ub1 m2 lb2 ub2 new_var
restore



* plot by seb_class_xtile

* Calculate share of low SES referrals in each classroom by conditions
preserve
keep if network == 3 & net_count == 1
tabstat seb_pcent seb, by(seb_class_xtile) stat(mean)


gen __l = seb_pcent if seb == 1
replace __l = . if seb != 1
bysort seb_class_xtile: egen __sl = mean(__l)

gen __h = seb_pcent if seb == 0
replace __h = . if seb != 0
bysort seb_class_xtile: egen __sh = mean(__h)


* Calculate average seb for each seb_class_xtile group
bysort seb_class_xtile: egen avg_seb = mean(seb)

* Graph
twoway (area avg_seb seb_class_xtile, color(orange*0.2)) ///
	   (connected __sl seb_class_xtile, lcolor(blue*.5) mcolor(blue*.5) msymbol(O) lwidth(medthick) lpattern(dash))  ///
	   (connected __sh seb_class_xtile, lcolor(pink*.5) mcolor(pink*.5) msymbol(O) lwidth(medthick) lpattern(dash)) , ///
       ylabel(0(0.2)1, angle(0)) ///
       xlabel(1(1)4, labsize(medsmall) tlength(zero) labgap(tiny)) ///
       xtitle("Low-SEB share by quartile") ///
       ytitle("Percentage share") ///
       legend(order(1 "Average Low-SEB share in quartile" ///
                    2 "Low-SEB accuracy" ///
                    3 "High-SEB accuracy" ///
                       ) ///
              pos(11) col(1) ring(0) size(small) region(lcolor(none) fcolor(none)) rows(4)) ///
       title("Guessing ability by Low-SEB share") ///
       graphregion(color(white)) plotregion(margin(0) style(none)) ///
       name(pooledseb_byclass_xtile_area, replace) $graph_opts

restore






/*===========================================================================*/
//# LOW-SEB REFERRALS ACROSS CLASSES
/*===========================================================================*/


//# area plot
* Calculate share of low SES referrals in each classroom by conditions
preserve

gen __counter = seb_class_xtile
order __counter seb_class_xtile
sort __counter

keep if treat == 1 & network != 3


* Calculate share of low SES referrals in each classroom by conditions
gen __reftolow = 1 if seb_other == 1 & net_id_other != .
replace __reftolow = 0 if seb_other == 0 & net_id_other != .
bysort __counter: egen __share_reftolow = mean(__reftolow)

gen __refl2l = 1 if seb_other == 1 & seb == 1 & net_id_other != .
replace __refl2l = 0 if seb_other == 0 & seb == 1 & net_id_other != .
bysort __counter: egen __share_refl2l = mean(__refl2l)

gen __refh2l = 1 if seb_other == 1 & seb == 0 & net_id_other != .
replace __refh2l = 0 if seb_other == 0 & seb == 0 & net_id_other != .
bysort __counter: egen __share_refh2l = mean(__refh2l)

gen __reftohigh = 1 if seb_other == 0 & net_id_other != .
replace __reftohigh = 0 if seb_other == 1 & net_id_other != .
bysort __counter: egen __share_reftohigh = mean(__reftohigh)

* Calculate average seb for each seb_class_xtile group
bysort __counter: egen avg_seb = mean(seb) if id_count == 1

* Graph
twoway (area avg_seb __counter if id_count == 1, color(orange*0.2)) ///
       (connected __share_reftolow __counter, lcolor(black) mcolor(black) msymbol(O) lwidth(medthick) lpattern(dash)) ///
       (connected __share_refl2l __counter, lcolor(blue*0.5) mcolor(blue*0.5) msymbol(D) lwidth(medthick) lpattern(dash)) ///
       (connected __share_refh2l __counter, lcolor(pink*0.5) mcolor(pink*0.5) msymbol(S) lwidth(medthick) lpattern(dash)), ///
       ylabel(0(0.2)1, angle(0)) ///
       xlabel(1(1)4, labsize(medsmall) tlength(zero) labgap(tiny)) ///
       xtitle("SEB Class Quartile") ///
       ytitle("Percentage share") ///
       legend(order(1 "Low-SEB share in class" ///
                    2 "Ref. to Low-SEB" ///
                    3 "Ref. Low-SEB to Low-SEB" ///
                    4 "Ref. High-SEB to Low-SEB") ///
              pos(11) col(1) ring(0) size(small) region(lcolor(none) fcolor(none)) rows(4)) ///
       title("Referrals by Low-SEB share in Baseline ") ///
       graphregion(color(white)) plotregion(margin(0) style(none)) ///
       name(pooled_byclass_xtile_area, replace)

restore


//# bar plot 
preserve
keep if treat == 1 & network != 3
tabstat seb_other seb, by(seb) stat(mean)
tab seb_other seb

* g1
quietly summarize
local n = r(N)
local remainder = mod(`n', 2)
if `remainder' > 0 {
    expand 2 in 1
}
generate new_var = mod(_n-1, 2)
tabulate new_var

ci means seb_other if network != 3 & seb == 0
gen m1 = r(mean)
gen lb1 = r(lb)
gen ub1 = r(ub)

ci means seb_other if network != 3 & seb == 1
gen m2 = r(mean)
gen lb2 = r(lb)
gen ub2 = r(ub)

ci means seb if id_count == 1
gen m3 = r(mean)
local text_ "`=string(m3, "%9.3f")'"

prtest seb_other if network != 3, by(seb) // tab seb_other seb if treat == 1 & network != 3 --> to verify
local pval = r(p)
local mu1 = round(r(P1), 0.01)
local mu2 = round(r(P2), 0.01)
local pval_rounded_t = round(`pval', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text "pr-test {it:p} < 0.001"
} 
else {
    local text "pr-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}
display "`text'"
twoway (bar m1 new_var if new_var == 0, sort color(pink*0.5) barwidth(0.5)) ///
       (bar m2 new_var if new_var == 1, sort color(blue*0.5) barwidth(0.5)) ///
       (rcap lb1 ub1 new_var if new_var == 0, sort color(black) lwidth(thin)) ///
       (rcap lb2 ub2 new_var if new_var == 1, sort color(black) lwidth(thin)) ///
	   (function y = m3, range(-0.5 1.5) lcolor(black) lpattern(dash)) ///
       (scatteri .734 0 .734 1, msize(*0.7) msymbol(pipe) mc(black)) ///
       (scatteri .738 0 .738 1, recast(line) lw(vthin) lc(black) lp(solid)), ///
       legend(off) subtitle("") note("") ylabel(, angle(horizontal)) yla(0(.2)1) plotregion(margin(0)) ///
       text(.77 .5 `"`text'"',  placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
       text(.415 0 "`=string(`mu1', "%9.2f")'",  placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
       text(.415 1 "`=string(`mu2', "%9.2f")'",  placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
	   text(.6 1.35 `"`text_'"',  placement(c) justification(left) size(vsmall) fcolor(none) margin(small)) ///
       xlabel(-0.5 " " 0 "High" 1 "Low" 1.5 " ", labsize(medsmall) tlength(zero) labgap(tiny)) ///
       xtitle("SEB Referrer") ytitle("Low-SEB share") name(bar_byses, replace)  graphregion(fcolor(white) lcolor(white)) xsize(3) ysize(3)

foreach var in m1 lb1 ub1 m2 lb2 ub2 m3 new_var {
    capture confirm variable `var'
    if !_rc {
        drop `var'
    }
}
restore

//# combined plot by quartile

forvalues i = 1/4 {
    preserve
	keep if seb_class_xtile == `i'
    keep if treat == 1 & network != 3
    tabstat seb_other seb, by(seb) stat(mean)
    tab seb_other seb
    * g`i'
    quietly summarize
    local n = r(N)
    local remainder = mod(`n', 2)
    if `remainder' > 0 {
        expand 2 in 1
    }
    generate new_var = mod(_n-1, 2)
    tabulate new_var
    ci means seb_other if network != 3 & seb == 0
    gen m1 = r(mean)
    gen lb1 = r(lb)
    gen ub1 = r(ub)
    ci means seb_other if network != 3 & seb == 1
    gen m2 = r(mean)
    gen lb2 = r(lb)
    gen ub2 = r(ub)
    ci means seb if id_count == 1
    gen m3 = r(mean)
    local text_ "`=string(m3, "%9.3f")'"
    prtest seb_other if network != 3, by(seb)
    local pval = r(p)
    local mu1 = round(r(P1), 0.01)
    local mu2 = round(r(P2), 0.01)
    local pval_rounded_t = round(`pval', 0.0001)	 
    if `pval_rounded_t' < 0.001 {
        local text "pr-test {it:p} < 0.001"
    } 
    else {
        local text "pr-test {it:p} = `=string(`pval_rounded_t', "%9.3f")'"
    }
    display "`text'"
    twoway (bar m1 new_var if new_var == 0, sort color(pink*0.5) barwidth(0.5)) ///
           (bar m2 new_var if new_var == 1, sort color(blue*0.5) barwidth(0.5)) ///
           (rcap lb1 ub1 new_var if new_var == 0, sort color(black) lwidth(thin)) ///
           (rcap lb2 ub2 new_var if new_var == 1, sort color(black) lwidth(thin)) ///
    	   (function y = m3, range(-0.5 1.5) lcolor(black) lpattern(dash)) ///
           (scatteri .734 0 .734 1, msize(*0.7) msymbol(pipe) mc(black)) ///
           (scatteri .738 0 .738 1, recast(line) lw(vthin) lc(black) lp(solid)), ///
           legend(off) subtitle("") note("") ylabel(, angle(horizontal)) yla(0(.2)1) plotregion(margin(0)) ///
           text(.77 .5 `"`text'"',  placement(c) justification(left) size(small) fcolor(none) margin(small)) ///
           text(.15 0 "`=string(`mu1', "%9.2f")'",  placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
           text(.15 1 "`=string(`mu2', "%9.2f")'",  placement(c) justification(left) size(medium) fcolor(none) margin(small)) ///
    	   text(.585 1.35 `"`text_'"',  placement(c) justification(left) size(vsmall) fcolor(none) margin(small)) ///
           xlabel(-0.5 " " 0 "High" 1 "Low" 1.5 " ", labsize(medsmall) tlength(zero) labgap(tiny)) ///
           xtitle("SEB Referrer") ytitle("Low-SEB share") ///
           title("Quartile `i'", size(medium)) ///
           name(bar_byses_`i', replace) graphregion(fcolor(white) lcolor(white)) xsize(3) ysize(3) nodraw
    foreach var in m1 lb1 ub1 m2 lb2 ub2 m3 new_var {
        capture confirm variable `var'
        if !_rc {
            drop `var'
        }
    }
    restore
}

graph combine bar_byses_1 bar_byses_2 bar_byses_3 bar_byses_4, ///
    rows(2) cols(2) imargin(tiny) title("Referrals by Low-SEB share") ///
    name(combined_bar_plots, replace) graphregion(fcolor(white) lcolor(white))


/*===========================================================================*/
//# REFERRALS VS SAMPLE PERFORMANCE
/*===========================================================================*/


//#* TABLE
tabstat z_gpa if id_count == 1 ,  stat(mean sd n q)
tabstat z_gpa_other if network != 3 , stat(mean sd n q)

tabstat z_test if id_count == 1 ,  stat(mean sd n q)
tabstat z_test_other if network != 3 , stat(mean sd n q)


//# PERFORMANCE REFERRALS VS SAMPLE 
/*===========================================================================*/


gen __t1 = .
replace __t1 = z_gpa if id_count == 1 
gen __t2 = .
replace __t2 = z_gpa_other if network != 3
gen __t3 = .
replace __t3 = z_test if id_count == 1 
gen __t4 = .
replace __t4 = z_test_other if network != 3
gen __t5 = .
replace __t5 = z_rav if id_count == 1
gen __t6 = .
replace __t6 = z_rav_other if network == 1
gen __t7 = .
replace __t7 = z_eye if id_count == 1
gen __t8 = .
replace __t8 = z_eye_other if network == 2

// Perform t-tests manually for each pair

// GPA
ttest __t1 == __t2, unpaired
local gpa_p = r(p)
local pval_rounded_t = round(`gpa_p', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text1 "{it:p} < 0.001"
} 
else {
    local text1 "{it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}

// Test Score
ttest __t3 == __t4, unpaired
local test_p = r(p)
local pval_rounded_t = round(`test_p', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text2 "{it:p} < 0.001"
} 
else {
    local text2 "{it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}

// Cognitive (RAV)
ttest __t5 == __t6, unpaired
local rav_p = r(p)
local pval_rounded_t = round(`rav_p', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text3 "{it:p} < 0.001"
} 
else {
    local text3 "{it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}


// Social
ttest __t7 == __t8, unpaired
local eye_p = r(p)
local pval_rounded_t = round(`eye_p', 0.0001)	 
if `pval_rounded_t' < 0.001 {
    local text4 "{it:p} < 0.001"
} 
else {
    local text4 "{it:p} = `=string(`pval_rounded_t', "%9.3f")'"
}

violinplot __t1 __t2 __t3 __t4 __t5 __t6 __t7 __t8, left ///
	name(violin_refperformance, replace) ///
    subtitle("") note("") ///
    color(green*.8 green*.5 orange*.8 orange*.5 blue*.8 blue*.5 pink*.8 pink*.5) ///
    graphregion(fcolor(white) lcolor(white)) ///
    ylabel(0 " " -0.5 "GPA" -2.5 "Entry Exam" -4.5 "Cognitive" -6.5 "Social" -7 " " , labsize(medsmall) tlength(zero) labgap(tiny)) ///
    legend(order(1 "High-SEB" 2 "Low-SEB") pos(5) cols(1) ring(0) size(small) region(lcolor(none) fcolor(none))) ///
    xtitle("Scores (standardized)") ///
    text(-.35 0 `"`text1'"', placement(c) justification(left) size(vsmall) fcolor(none) margin(small)) ///
    text(-2.35 0 `"`text2'"', placement(c) justification(left) size(vsmall) fcolor(none) margin(small)) ///
	text(-4.35 0 `"`text3'"', placement(c) justification(left) size(vsmall) fcolor(none) margin(small)) ///
    text(-6.35 0 `"`text4'"', placement(c) justification(left) size(vsmall) fcolor(none) margin(small)) ///
	title("Sample vs Referral Performance") ///
    mean(msymbol(O) msize(small)) tight
	
drop __*




//# Referral performance (n=382)
/*===========================================================================*/


preserve
keep if comp_nom == 1 & treat == 1 & network != 3
ttest z_rav = z_rav_other
ttest z_gpa = z_gpa_other
ttest z_test = z_test_other
restore

