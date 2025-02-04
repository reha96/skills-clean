/*******************************************************************************
    Project: SIR - cmc analysis
    Author: Reha Tuncer
    Date: 25.07.2024
    Description: Discrete Choice model
*******************************************************************************/

//# preamble
version 18
clear all
macro drop _all
set more off
set scheme s2color, permanently
set maxvar 32767

// create dataset 1
capture noisily use "cleaning/cleaned_wide.dta"
if _rc != 0 {
    use "cleaned_wide.dta"
}

expand class_size

bysort net_id: gen first_occ = _n
gen index = _n
save "class_size_expand.dta", replace

// create dataset 2
capture noisily use "cleaning/cleaned_wide.dta"
if _rc != 0 {
    use "cleaned_wide.dta"
}

sort net_id
bysort net_class: gen first_occ = _n
expand class_size

drop fraction* difference* above* ref* pc* 

// Rename variables to add "_referral" suffix
foreach var of varlist * {
    rename `var' `var'_referral
}
rename first_occ_referral first_occ
sort net_class_referral net_id_referral
bysort net_class first_occ: gen ordering = _n
drop first_occ
rename ordering first_occ
sort net_class first_occ net_id
gen index = _n
save "class_size_referral.dta", replace

use "class_size_expand.dta"
merge 1:1 index using "class_size_referral.dta"
save "class_size_expand.dta", replace

clear all
use "class_size_expand.dta"

forvalues t = 1/9 {
    replace ref_`t' = ref_`t' - net_class
}

gen rav1 = (ref_1 == first_occ)
gen rav2 = (ref_2 == first_occ)
gen rav3 = (ref_3 == first_occ)
gen rav = rav1 + rav2 + rav3
drop rav1 rav2 rav3 

gen eye1 = (ref_4 == first_occ)
gen eye2 = (ref_5 == first_occ)
gen eye3 = (ref_6 == first_occ)
gen eye = eye1 + eye2 + eye3
drop eye1 eye2 eye3 

gen ses1 = (ref_7 == first_occ)
gen ses2 = (ref_8 == first_occ)
gen ses3 = (ref_9 == first_occ)
gen ses_guess = ses1 + ses2 + ses3
drop ses1 ses2 ses3 

drop ref_*
order net_id net_id_referral rav eye ses_guess

cmset net_id net_id_referral,force
cmsample, generate(flag)

// 1. Base model with referral characteristics
keep if net_id != net_id_referral
clogit rav c.z_gpa_referral c.z_rav_referral c.z_eye_referral i.ses_referral, group(net_id)

// 2. Add homophily measures
gen same_gender = (gender == gender_referral)
gen same_ses = (ses == ses_referral)
gen both_lses = (ses == ses_referral) & ses == 1
gen both_hses = (ses == ses_referral) & ses == 2
gen same_faculty = (faculty == faculty_referral)
gen gpa_diff = abs(z_gpa - z_gpa_referral)
gen test_diff = abs(z_test - z_test_referral)

clogit rav c.z_gpa_referral i.ses_referral  c.gpa_diff, group(net_id)
margins, at(z_gpa_referral=(-2(1)2) ses_referral= (0 1))  
marginsplot
