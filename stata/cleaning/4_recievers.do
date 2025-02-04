/*******************************************************************************
    Project: Skills inequality referrals
    Author: Reha Tuncer
    Date: 17.07.2024
    Description: This do-file creates long dataset
*******************************************************************************/


//# preamble
version 18
clear all
macro drop _all
set more off
set scheme s2color, permanently
set maxvar 32767

* Create a local macro to store all .do files beginning with 2_
local dofiles : dir "." files "3_*.do"

* First try both data file locations
capture noisily use "cleaning/cleaned_wide.dta"
if _rc != 0 {
    capture noisily use "cleaned_wide.dta"
    
    * If both fail, then execute the do files
    if _rc != 0 {
        foreach file of local dofiles {
            do "`file'"
        }
    }
}

* Step 1: Reshape the data to long format
reshape long ref_, i(net_id) j(ref_num)

* Step 2: Expand the dataset to create separate rows for each network type
gen network = 1 if ref_num <= 3
replace network = 2 if ref_num <= 6 & ref_num >= 4
replace network = 3 if ref_num <= 9 & ref_num >= 7

* Step 5: Label the network variable
label define network_label 1 "Cognitive" 2 "Social" 3 "SES Guess"
label values network network_label

* Step 6: Sort the data
sort net_id network ref_num

* Step 7: Rename variables to prepare for merge
rename net_id referrer_id
rename ref_ net_id

drop if net_id == . // drop those who did not make referrals

save "cleaned_long.dta", replace

// Load the wide dataset 
use "cleaned_wide.dta", clear

// Rename variables to add "_referral" suffix
foreach var of varlist * {
    rename `var' `var'_other
}

// Rename the key variable back to its original name for merging
rename net_id_other net_id

// Save the modified wide dataset
save "cleaned_wide_referral.dta", replace

// Load the long dataset
use "cleaned_long.dta", clear

// Merge with the modified wide dataset
merge m:1 net_id using "cleaned_wide_referral.dta", keepusing(*_other)

// drop individuals who never received a referral (19/849)
drop if _merge == 2

// Clean up
drop _merge

// Save the final merged dataset
save "cleaned_long.dta", replace
rm "cleaned_wide_referral.dta"

rename net_id net_id_other
rename referrer_id net_id

order net_id net_id_other network
sort net_id network

rename ref_num net_count

//# keep only useful _other variables
drop ref_* net_class_other finished_other difference*_other class_size_other observed_classmates_other fraction*_other treat_other duration_min duration_min_other above*_other

//# add labels loop
foreach var of varlist * {
    * Check if the variable doesn't end with _other
    if !regexm("`var'", "_other$") {
        * Check if there's an _other equivalent
        capture confirm variable `var'_other
        if !_rc {
            * Copy variable label
            local varlabel : variable label `var'
            if "`varlabel'" != "" {
                label variable `var'_other "`varlabel'"
            }
            
            * Copy value labels if they exist
            local vallabel : value label `var'
            if "`vallabel'" != "" {
                label values `var'_other `vallabel'
            }
        }
    }
}

* Add "Other" to the beginning of the label for _other variables
foreach var of varlist *_other {
    local current_label : variable label `var'
    label variable `var' "Other `current_label'"
}


//# network referral id
label variable net_count "Referral order"

rename net_count id_count
rename network task

//# Generate new variables to tag self-nominations 
gen self_referral = net_id == net_id_other
bysort net_id task: egen any_self_ref = sum(self_referral)


//# new vars from above results
gen same_semester = (semester == semester_other)
gen same_faculty = (faculty == faculty_other)
gen same_study = (study == study_other)


/*===========================================================================*/
//# Calculate ses guessing ability for referrers
/*===========================================================================*/

// Keep only guessing task observations, excluding self-referrals
keep if task == 3 & self_referral == 0

// Count valid guesses per person
bysort net_id: egen count_ = count(ses_other)

// Binary SES analysis
bysort net_id: egen ses_correct = sum(ses_other)
gen lses_fraction = ses_correct/count_
gen guess_ratio = lses_fraction - fraction_lses
gen hyper_prob = comb(count_low_ses,ses_correct)*comb(observed_classmates-count_low_ses,count_-ses_correct)/comb(observed_classmates,count_)
gen hyper_ratio = lses_fraction - hyper_prob
label variable guess_ratio "Guessing ability ratio"
drop ses_correct

// Generate standardized guess ratio
sum guess_ratio
global guess_ratio_mean = r(mean)
global guess_ratio_std = r(sd)
gen z_guess_ratio = (guess_ratio - $guess_ratio_mean)/$guess_ratio_std
macro drop guess_ratio_mean guess_ratio_std

// Strata-specific analysis
* Strata 1-2
gen ses12 = (strato_other <= 2)
replace ses12 = . if strato_other == .
bysort net_id: egen ses12_correct = sum(ses12)
gen ses12_pcent = ses12_correct/count_
gen guess_ratio12 = ses12_pcent - fraction_ses12
label variable guess_ratio12 "Guessing ability ratio for strato 1&2"
drop ses12_correct ses12

* Strata 3
gen ses3 = (strato_other == 3)
replace ses3 = . if strato_other == .
bysort net_id: egen ses3_correct = sum(ses3)
gen ses3_pcent = ses3_correct/count_
gen guess_ratio3 = ses3_pcent - fraction_ses3
drop ses3_correct ses3

* Strata 4
gen ses4 = (strato_other == 4)
replace ses4 = . if strato_other == .
bysort net_id: egen ses4_correct = sum(ses4)
gen ses4_pcent = ses4_correct/count_
gen guess_ratio4 = ses4_pcent - fraction_ses4
drop ses4_correct ses4

* Strata 5-6
gen ses56 = (strato_other > 4)
replace ses56 = . if strato_other == .
bysort net_id: egen ses56_correct = sum(ses56)
gen ses56_pcent = ses56_correct/count_
gen guess_ratio56 = ses56_pcent - fraction_ses56
drop ses56_correct count_ ses56

// Summarize all guess ratios
foreach var of varlist guess_ratio* {
    sum `var'
}

//# save cleaned data 
save "cleaned_long.dta", replace

//# 
keep z_guess_ratio guess_ratio net_id guess_ratio12 guess_ratio3 guess_ratio4 guess_ratio56 hyper_ratio
bysort net_id z_guess_ratio: keep if _n == 1
merge 1:1 net_id using "referrals_wide.dta"
drop _merge
save "referrals_wide.dta", replace


