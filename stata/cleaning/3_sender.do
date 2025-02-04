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

// load dataset
* Create a local macro to store all .do files beginning with 2_
local dofiles : dir "." files "2_*.do"

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


//# reshape long
reshape long ref_, i(net_id) j(ref_num)

//# cut non valid refs
gen self_ref = net_id == ref_
keep if  ref_num <=6
keep if  !self_ref
keep if  ref_ !=.

// Save temporary dataset
save "temp.dta", replace

//# TWICE REFERRED BY SAME REFERRER
keep if treat == 1

bysort ref_ net_id: gen count_ref = _N
sort ref_

gen twice_ref_t1 = (count_ref >= 2 & treat == 1)
bysort ref_ : gen count_twice_t1 = sum(twice_ref_t1)
bysort ref_: egen __t = max(count_twice_t1)
replace  count_twice_t1 = __t
drop __t

gen twice_ref_t1_lses = (count_ref >= 2 & treat == 1 &ses==1)
bysort ref_ : gen count_twice_t1_lses = sum(twice_ref_t1_lses)
bysort ref_: egen __t = max( count_twice_t1_lses)
replace   count_twice_t1_lses = __t
drop __t

gen twice_ref_t1_hses = (count_ref >= 2 & treat == 1 &ses==0)
bysort ref_ : gen count_twice_t1_hses = sum(twice_ref_t1_hses)
bysort ref_: egen __t = max( count_twice_t1_hses)
replace   count_twice_t1_hses = __t
drop __t

gen single_ref_t1 = (!twice_ref_t1)
gen single_rav_t1 = (single_ref_t1 & ref_num<=3)
gen single_eye_t1 = (single_ref_t1 & ref_num>3)
bysort ref_ : gen count_single_t1 = sum(single_ref_t1)
bysort ref_ : gen count_singler_t1 = sum(single_rav_t1)
bysort ref_ : gen count_singlee_t1 = sum(single_eye_t1)
bysort ref_: egen __t = max(count_single_t1)

replace count_single_t1 = __t
drop __t
bysort ref_: egen __t = max(count_singler_t1)
replace count_singler_t1 = __t
drop __t
replace count_singler_t1 = 0 if count_singler_t1 == .

bysort ref_: egen __t = max(count_singlee_t1)
replace count_singlee_t1 = __t
drop __t
replace count_singlee_t1 = 0 if count_singlee_t1 == .

gen single_rav_t1_lses = (single_ref_t1 & ref_num<=3  & ses==1)
gen single_rav_t1_hses = (single_ref_t1 & ref_num<=3  & ses==0)
bysort ref_ : gen count_singler_t1_lses = sum(single_rav_t1_lses)
bysort ref_ : gen count_singler_t1_hses = sum(single_rav_t1_hses)

drop twice_ref_t1 single_ref_t1 single_rav_t1 single_eye_t1 count_ref


keep count* ref_
drop count_low_ses
collapse (mean) count*, by(ref_)
merge 1:m ref_ using "temp.dta"
drop _merge

replace count_twice_t1 = 0 if count_twice_t1 == .
replace count_single_t1 = 0 if count_single_t1 == .
replace count_singler_t1 = 0 if count_singler_t1 == .
replace count_singlee_t1 = 0 if count_singlee_t1 == .

replace count_singler_t1_lses = 0 if count_singler_t1_lses == .
replace count_singler_t1_hses = 0 if count_singler_t1_hses == .
replace count_twice_t1_lses = 0 if count_twice_t1_lses == .
replace count_twice_t1_hses = 0 if count_twice_t1_hses == .

save "temp.dta", replace

//

keep if treat == 2

bysort ref_ net_id: gen count_ref = _N
sort ref_

gen twice_ref_t2 = (count_ref >= 2 & treat == 2)
bysort ref_ : gen count_twice_t2 = sum(twice_ref_t2)
bysort ref_: egen __t = max(count_twice_t2)
replace count_twice_t2 = __t
drop __t

gen twice_ref_t2_lses = (count_ref >= 2 & treat == 2 & ses ==1)
bysort ref_ : gen count_twice_t2_lses = sum(twice_ref_t2_lses)
bysort ref_: egen __t = max(count_twice_t2_lses)
replace count_twice_t2_lses = __t
drop __t

gen twice_ref_t2_hses = (count_ref >= 2 & treat == 2 & ses ==0)
bysort ref_ : gen count_twice_t2_hses = sum(twice_ref_t2_hses)
bysort ref_: egen __t = max(twice_ref_t2_hses)
replace twice_ref_t2_hses = __t
drop __t

gen single_ref_t2 = (!twice_ref_t2)
gen single_rav_t2 = (single_ref_t2 & ref_num<=3)
gen single_eye_t2 = (single_ref_t2 & ref_num>3)
bysort ref_ : gen count_single_t2 = sum(single_ref_t2)
bysort ref_ : gen count_singler_t2 = sum(single_rav_t2)
bysort ref_ : gen count_singlee_t2 = sum(single_eye_t2)

bysort ref_: egen __t = max(count_single_t2)
replace count_single_t2 = __t
drop __t

bysort ref_: egen __t = max(count_singler_t2)
replace count_singler_t2 = __t
drop __t
replace count_singler_t2 = 0 if count_singler_t2 == .

bysort ref_: egen __t = max(count_singlee_t2)
replace count_singlee_t2 = __t
drop __t
replace count_singlee_t2 = 0 if count_singlee_t2 == .

gen single_rav_t2_lses = (single_ref_t2 & ref_num<=3  & ses==1)
gen single_rav_t2_hses = (single_ref_t2 & ref_num<=3  & ses==0)
bysort ref_ : gen count_singler_t2_lses = sum(single_rav_t2_lses)
bysort ref_ : gen count_singler_t2_hses = sum(single_rav_t2_hses)

drop twice_ref_t2 single_ref_t2 single_rav_t2 single_eye_t2 count_ref

keep count* ref_
drop count_low_ses
collapse (mean) count*, by(ref_)
merge 1:m ref_ using "temp.dta"
drop _merge

replace count_twice_t2 = 0 if count_twice_t2 == .
replace count_single_t2 = 0 if count_single_t2 == .
replace count_singler_t2 = 0 if count_singler_t2 == .
replace count_singlee_t2 = 0 if count_singlee_t2 == .

replace count_singler_t2_lses = 0 if count_singler_t2_lses == .
replace count_singler_t2_hses = 0 if count_singler_t2_hses == .
replace count_twice_t2_lses = 0 if count_twice_t2_lses == .
replace count_twice_t2_hses = 0 if count_twice_t2_hses == .

save "temp.dta", replace

gen count_single = count_single_t1 + count_single_t2
gen count_singler = count_singler_t1 + count_singler_t2
gen count_singlee = count_singlee_t1 + count_singlee_t2






//# NUMBER OF REFERRALS RECEIVED FOR EACH SKILL
bysort net_class ref_: gen count_rav = sum(finished) if ref_num <= 3 
egen __t = max(count_rav), by(ref_) 
replace count_rav = __t
drop __t  
replace count_rav = 0 if count_rav == . 

bysort net_class ref_: gen count_eye = sum(finished) if ref_num > 3
egen __t = max(count_eye), by(ref_) 
replace count_eye = __t
drop __t  
replace count_eye = 0 if count_eye == . 

gen count_total = count_eye + count_rav

//# NUMBER OF REFERRALS RECEIVED FOR EACH SKILL BY REFERRER SES
bysort net_class ref_: gen count_rav_lses = sum(finished) if ref_num <= 3 & ses == 1
egen __t = max(count_rav_lses), by(ref_) 
replace count_rav_lses = __t
drop __t  
replace count_rav_lses = 0 if count_rav_lses == . 
//
bysort net_class ref_: gen count_rav_hses = sum(finished) if ref_num <= 3 & ses == 0
egen __t = max(count_rav_hses), by(ref_) 
replace count_rav_hses = __t
drop __t  
replace count_rav_hses = 0 if count_rav_hses == . 
//
bysort net_class ref_: gen count_eye_lses = sum(finished) if ref_num > 3  & ses == 1
egen __t = max(count_eye_lses), by(ref_) 
replace count_eye_lses = __t
drop __t  
replace count_eye_lses = 0 if count_eye_lses == . 
//
bysort net_class ref_: gen count_eye_hses = sum(finished) if ref_num > 3 & ses == 0
egen __t = max(count_eye_hses), by(ref_) 
replace count_eye_hses = __t
drop __t  
replace count_eye_hses = 0 if count_eye_hses == . 
//
gen count_total_lses = count_eye_lses + count_rav_lses
gen count_total_hses = count_eye_hses + count_rav_hses

//# NUMBER OF REFERRALS RECEIVED FOR EACH SKILL BY REFERRER TREATMENT
bysort net_class ref_: gen count_rav_t1 = sum(finished) if ref_num <= 3 & treat == 1
egen __t = max(count_rav_t1), by(ref_) 
replace count_rav_t1 = __t
drop __t  
replace count_rav_t1 = 0 if count_rav_t1 == . 

bysort net_class ref_: gen count_rav_t2 = sum(finished) if ref_num <= 3 & treat == 2
egen __t = max(count_rav_t2), by(ref_) 
replace count_rav_t2 = __t
drop __t  
replace count_rav_t2 = 0 if count_rav_t2 == . 

bysort net_class ref_: gen count_eye_t1 = sum(finished) if ref_num > 3 & treat == 1
egen __t = max(count_eye_t1), by(ref_) 
replace count_eye_t1 = __t
drop __t  
replace count_eye_t1 = 0 if count_eye_t1 == . 

bysort net_class ref_: gen count_eye_t2 = sum(finished) if ref_num > 3 & treat == 2
egen __t = max(count_eye_t2), by(ref_) 
replace count_eye_t2 = __t
drop __t  
replace count_eye_t2 = 0 if count_eye_t2 == . 

gen count_total_t1 = count_eye_t1 + count_rav_t1
gen count_total_t2 = count_eye_t2 + count_rav_t2

//# NUMBER OF REFERRALS RECEIVED FOR EACH SKILL BY REFERRER TREATMENT AND BY SES
bysort net_class ref_: gen count_rav_t1lses = sum(finished) if ref_num <= 3 & treat == 1 & ses == 1
egen __t = max(count_rav_t1lses), by(ref_) 
replace count_rav_t1lses = __t
drop __t  
replace count_rav_t1lses = 0 if count_rav_t1lses == . 

bysort net_class ref_: gen count_rav_t2lses = sum(finished) if ref_num <= 3 & treat == 2 & ses == 1
egen __t = max(count_rav_t2lses), by(ref_) 
replace count_rav_t2lses = __t
drop __t  
replace count_rav_t2lses = 0 if count_rav_t2lses == . 

bysort net_class ref_: gen count_rav_t1hses = sum(finished) if ref_num <= 3 & treat == 1 & ses == 0
egen __t = max(count_rav_t1hses), by(ref_) 
replace count_rav_t1hses = __t
drop __t  
replace count_rav_t1hses = 0 if count_rav_t1hses == . 

bysort net_class ref_: gen count_rav_t2hses = sum(finished) if ref_num <= 3 & treat == 2 & ses == 0
egen __t = max(count_rav_t2hses), by(ref_) 
replace count_rav_t2hses = __t
drop __t  
replace count_rav_t2hses = 0 if count_rav_t2hses == . 

//

bysort net_class ref_: gen count_eye_t1lses = sum(finished) if ref_num > 3 & treat == 1 & ses == 1
egen __t = max(count_eye_t1lses), by(ref_) 
replace count_eye_t1lses = __t
drop __t  
replace count_eye_t1lses = 0 if count_eye_t1lses == . 

bysort net_class ref_: gen count_eye_t2lses = sum(finished) if ref_num > 3 & treat == 2 & ses == 1
egen __t = max(count_eye_t2lses), by(ref_) 
replace count_eye_t2lses = __t
drop __t  
replace count_eye_t2lses = 0 if count_eye_t2lses == .

bysort net_class ref_: gen count_eye_t1hses = sum(finished) if ref_num > 3 & treat == 1 & ses == 0
egen __t = max(count_eye_t1hses), by(ref_) 
replace count_eye_t1hses = __t
drop __t  
replace count_eye_t1hses = 0 if count_eye_t1hses == .

bysort net_class ref_: gen count_eye_t2hses = sum(finished) if ref_num > 3 & treat == 2 & ses == 0
egen __t = max(count_eye_t2hses), by(ref_) 
replace count_eye_t2hses = __t
drop __t  
replace count_eye_t2hses = 0 if count_eye_t2hses == .

// 
gen count_total_t1lses = count_eye_t1lses + count_rav_t1lses
gen count_total_t2lses = count_eye_t2lses + count_rav_t2lses
gen count_total_t1hses = count_eye_t1hses + count_rav_t1hses
gen count_total_t2hses = count_eye_t2hses + count_rav_t2hses


//# REFERRALS FROM ABOVE MEDIAN PERFORMERS BY TREATMENT
sum z_rav, det
global rav_med_guess = r(p50)
sum z_eye, det
global eye_med_guess = r(p50)

bysort net_class ref_: gen count_rav_t1_top = sum(finished) if ref_num <= 3 & z_rav > $rav_med_guess & treat == 1
egen __t = max(count_rav_t1_top), by(ref_) 
replace count_rav_t1_top = __t
drop __t  
replace count_rav_t1_top = 0 if count_rav_t1_top == . 

bysort net_class ref_: gen count_rav_t1_low = sum(finished) if ref_num <= 3 & z_rav <= $rav_med_guess & treat == 1
egen __t = max(count_rav_t1_low), by(ref_) 
replace count_rav_t1_low = __t
drop __t  
replace count_rav_t1_low = 0 if count_rav_t1_low == . 

bysort net_class ref_: gen count_eye_t1_top = sum(finished) if ref_num > 3 & z_eye > $eye_med_guess & treat == 1
egen __t = max(count_eye_t1_top), by(ref_) 
replace count_eye_t1_top = __t
drop __t  
replace count_eye_t1_top = 0 if count_eye_t1_top == . 

bysort net_class ref_: gen count_eye_t1_low = sum(finished) if ref_num > 3 & z_eye <= $eye_med_guess & treat == 1
egen __t = max(count_eye_t1_low), by(ref_) 
replace count_eye_t1_low = __t
drop __t  
replace count_eye_t1_low = 0 if count_eye_t1_low == .

//
bysort net_class ref_: gen count_rav_t2_top = sum(finished) if ref_num <= 3 & z_rav > $rav_med_guess & treat == 2
egen __t = max(count_rav_t2_top), by(ref_) 
replace count_rav_t2_top = __t
drop __t  
replace count_rav_t2_top = 0 if count_rav_t2_top == . 

bysort net_class ref_: gen count_rav_t2_low = sum(finished) if ref_num <= 3 & z_rav <= $rav_med_guess & treat == 2
egen __t = max(count_rav_t2_low), by(ref_) 
replace count_rav_t2_low = __t
drop __t  
replace count_rav_t2_low = 0 if count_rav_t2_low == . 

bysort net_class ref_: gen count_eye_t2_top = sum(finished) if ref_num > 3 & z_eye > $eye_med_guess & treat == 2
egen __t = max(count_eye_t2_top), by(ref_) 
replace count_eye_t2_top = __t
drop __t  
replace count_eye_t2_top = 0 if count_eye_t2_top == . 

bysort net_class ref_: gen count_eye_t2_low = sum(finished) if ref_num > 3 & z_eye <= $eye_med_guess & treat == 2
egen __t = max(count_eye_t2_low), by(ref_) 
replace count_eye_t2_low = __t
drop __t  
replace count_eye_t2_low = 0 if count_eye_t2_low == .

gen count_rav_top = count_rav_t1_top + count_rav_t2_top
gen count_rav_low = count_rav_t1_low + count_rav_t2_low
gen count_eye_top = count_eye_t1_top + count_eye_t2_top
gen count_eye_low = count_eye_t1_low + count_eye_t2_low

//# MERGE

keep ref_ count*
drop count_low_ses
collapse (mean) count*, by(ref_)
rename ref_ net_id 
drop if net_id == .
merge 1:1 net_id using "cleaned_wide.dta"

// Replace missing values with 0 for all count variables 
ds count*, has(type numeric)  
foreach x in `r(varlist)' {
    if "`x'" != "count_low_ses" {
        replace `x' = 0 if `x' == .
    }
} // 86 students never received a referral 

drop ref_* _merge
gen missing = (ses == .)

/*===========================================================================*/
//# CALCULATE RATIOS / PERCENTAGES
/*===========================================================================*/

//# ratio refferal by observed_classmates
gen pcent_count_rav = (count_rav/(observed_classmates))*100
replace pcent_count_rav = (count_rav/(observed_classmates-1))*100 if ses !=.

gen pcent_count_eye = (count_eye/(observed_classmates-1))*100
replace pcent_count_eye = (count_eye/(observed_classmates-1))*100 if ses !=.

gen pcent_count_total = ((count_rav + count_eye)/(observed_classmates*2))*100
replace pcent_count_total = ((count_rav + count_eye)/((observed_classmates-1)*2))*100 if ses !=.

//# ratio lses refferal by observed_classmates
egen __t = max(count_low_ses), by(net_class) 
replace count_low_ses = __t
drop __t 

gen pcent_count_rav_lses = (count_rav_lses/(count_low_ses))*100
replace pcent_count_rav_lses = (count_rav_lses/(count_low_ses-1))*100 if ses == 1

gen pcent_count_eye_lses = (count_eye_lses/(count_low_ses))*100
replace pcent_count_eye_lses = (count_eye_lses/(count_low_ses-1))*100 if ses == 1

gen pcent_count_total_lses = ((count_rav_lses + count_eye_lses)/(count_low_ses*2))*100
replace pcent_count_total_lses = ((count_rav_lses + count_eye_lses)/((count_low_ses-1)*2))*100 if ses == 1

//# ratio hses refferal by observed_classmates
gen n_hses = observed_classmates - count_low_ses

gen pcent_count_rav_hses = (count_rav_hses/(n_hses))*100
replace pcent_count_rav_hses = (count_rav_hses/(n_hses-1))*100 if ses == 0

gen pcent_count_eye_hses = (count_eye_hses/(n_hses))*100
replace pcent_count_eye_hses = (count_eye_hses/(n_hses-1))*100 if ses == 0

gen pcent_count_total_hses = ((count_rav_hses + count_eye_hses)/(n_hses*2))*100
replace pcent_count_total_hses = ((count_rav_hses + count_eye_hses)/((n_hses-1)*2))*100 if ses == 0

//# ratio t1 refferal by observed_classmates
bysort net_class: egen n_t1 = count(finished) if treat == 1
egen __t = max(n_t1), by(net_class) 
replace n_t1 = __t
drop __t 
 
gen pcent_count_rav_t1 = (count_rav_t1/(n_t1))*100
replace pcent_count_rav_t1 = (count_rav_t1/(n_t1 - 1))*100 if treat == 1

gen pcent_count_eye_t1 = (count_eye_t1/(n_t1))*100
replace pcent_count_eye_t1 = (count_eye_t1/(n_t1-1))*100 if treat == 1

gen pcent_count_total_t1 = ((count_rav_t1 + count_eye_t1)/(n_t1*2))*100
replace pcent_count_total_t1 = ((count_rav_t1 + count_eye_t1)/((n_t1-1)*2))*100 if treat == 1

//# ratio t2 refferal by observed_classmates
bysort net_class: egen n_t2 = count(finished) if treat == 2
egen __t = max(n_t2), by(net_class) 
replace n_t2 = __t
drop __t 

gen pcent_count_rav_t2 = (count_rav_t2/(n_t2))*100 
replace pcent_count_rav_t2 = (count_rav_t2/(n_t2-1))*100 if treat == 2

gen pcent_count_eye_t2 = (count_eye_t2/(n_t2))*100
replace pcent_count_eye_t2 = (count_eye_t2/(n_t2-1))*100 if treat == 2

gen pcent_count_total_t2 = ((count_rav_t2 + count_eye_t2)/(n_t2*2))*100
replace pcent_count_total_t2 = ((count_rav_t2 + count_eye_t2)/((n_t2-1)*2))*100 if treat == 2

//# ratio lses t1 refferal by observed_classmates
bysort net_class: egen n_t1lses = count(finished) if treat == 1 & ses == 1
egen __t = max(n_t1lses), by(net_class) 
replace n_t1lses = __t
drop __t 

gen pcent_count_rav_t1lses = (count_rav_t1lses/(n_t1lses))*100
replace pcent_count_rav_t1lses = (count_rav_t1lses/(n_t1lses-1))*100 if treat == 1 & ses == 1

gen pcent_count_eye_t1lses = (count_eye_t1lses/(n_t1lses))*100
replace pcent_count_eye_t1lses = (count_eye_t1lses/(n_t1lses-1))*100 if treat == 1 & ses == 1

gen pcent_count_total_t1lses = ((count_rav_t1lses + count_eye_t1lses)/(n_t1lses*2))*100
replace pcent_count_total_t1lses = ((count_rav_t1lses + count_eye_t1lses)/((n_t1lses-1)*2))*100 if treat == 1 & ses == 1

//# ratio lses t2 refferal by observed_classmates
bysort net_class: egen n_t2lses = count(finished) if treat == 2 & ses == 1
egen __t = max(n_t2lses), by(net_class) 
replace n_t2lses = __t
drop __t 

gen pcent_count_rav_t2lses = (count_rav_t2lses/(n_t2lses))*100
replace pcent_count_rav_t2lses = (count_rav_t2lses/(n_t2lses - 1))*100 if treat == 2 & ses == 1

gen pcent_count_eye_t2lses = (count_eye_t2lses/(n_t2lses))*100
replace pcent_count_eye_t2lses = (count_eye_t2lses/(n_t2lses - 1))*100 if treat == 2 & ses == 1

gen pcent_count_total_t2lses = ((count_rav_t2lses + count_eye_t2lses)/(n_t2lses*2))*100
replace pcent_count_total_t2lses = ((count_rav_t2lses + count_eye_t2lses)/((n_t2lses-1)*2))*100 if treat == 2 & ses == 1

//# ratio hses t1 refferal by observed_classmates
bysort net_class: egen n_t1hses = count(finished) if treat == 1 & ses == 0
egen __t = max(n_t1hses), by(net_class) 
replace n_t1hses = __t
drop __t 
replace n_t1hses = 0 if n_t1hses == .

gen pcent_count_rav_t1hses = (count_rav_t1hses/(n_t1hses))*100
replace pcent_count_rav_t1hses = (count_rav_t1hses/(n_t1hses-1))*100 if treat == 1 & ses == 0

gen pcent_count_eye_t1hses = (count_eye_t1hses/(n_t1hses))*100
replace pcent_count_eye_t1hses = (count_eye_t1hses/(n_t1hses-1))*100 if treat == 1 & ses == 0

gen pcent_count_total_t1hses = ((count_rav_t1hses + count_eye_t1hses)/(n_t1hses*2))*100
replace pcent_count_total_t1hses = ((count_rav_t1hses + count_eye_t1hses)/((n_t1hses-1)*2))*100 if treat == 1 & ses == 0

//# ratio hses t2 refferal by observed_classmates
bysort net_class: egen n_t2hses = count(finished) if treat == 2 & ses == 0
egen __t = max(n_t2hses), by(net_class) 
replace n_t2hses = __t
drop __t 
replace n_t2hses = 0 if n_t2hses == .

gen pcent_count_rav_t2hses = (count_rav_t2hses/(n_t2hses))*100
replace pcent_count_rav_t2hses = (count_rav_t2hses/(n_t2hses-1))*100 if treat == 2 & ses == 0

gen pcent_count_eye_t2hses = (count_eye_t2hses/(n_t2hses))*100
replace pcent_count_eye_t2hses = (count_eye_t2hses/(n_t2hses-1))*100 if treat == 2 & ses == 0

gen pcent_count_total_t2hses = ((count_rav_t2hses + count_eye_t2hses)/(n_t2hses*2))*100
replace pcent_count_total_t2hses = ((count_rav_t2hses + count_eye_t2hses)/((n_t2hses-1)*2))*100 if treat == 2 & ses == 0

//# ratio top performers referral by treat
bysort net_class: egen n_rav_t1_top = count(finished) if z_rav > $rav_med_guess & treat == 1
egen __t = max(n_rav_t1_top), by(net_class) 
replace n_rav_t1_top = __t
drop __t 
replace n_rav_t1_top = 0 if n_rav_t1_top == .

gen pcent_rav_t1_top = (count_rav_t1_top/(n_rav_t1_top))*100
replace pcent_rav_t1_top = (count_rav_t1_top/(n_rav_t1_top-1))*100 if z_rav > $rav_med_guess & treat == 1

gen pcent_rav_t1_low = (count_rav_t1_low/(n_t1 - n_rav_t1_top))*100
replace pcent_rav_t1_low = (count_rav_t1_low/(n_t1 - n_rav_t1_top-1))*100 if z_rav <= $rav_med_guess & treat == 1

bysort net_class: egen n_eye_t1_top = count(finished) if z_eye > $eye_med_guess & treat == 1
egen __t = max(n_eye_t1_top), by(net_class) 
replace n_eye_t1_top = __t
drop __t 
replace n_eye_t1_top = 0 if n_eye_t1_top == .

gen pcent_eye_t1_top = (count_eye_t1_top/(n_eye_t1_top))*100
replace pcent_eye_t1_top = (count_eye_t1_top/(n_eye_t1_top-1))*100 if z_eye > $eye_med_guess & treat == 1

gen pcent_eye_t1_low = (count_eye_t1_low/(n_t1-n_eye_t1_top))*100
replace pcent_eye_t1_low = (count_eye_t1_low/(n_t1-n_eye_t1_top-1))*100 if z_eye <= $eye_med_guess & treat == 1

//
bysort net_class: egen n_rav_t2_top = count(finished) if z_rav > $rav_med_guess & treat == 2
egen __t = max(n_rav_t2_top), by(net_class) 
replace n_rav_t2_top = __t
drop __t 
replace n_rav_t2_top = 0 if n_rav_t2_top == .

gen pcent_rav_t2_top = (count_rav_t2_top/(n_rav_t2_top))*100
replace pcent_rav_t2_top = (count_rav_t2_top/(n_rav_t2_top-1))*100 if z_rav > $rav_med_guess & treat == 2

gen pcent_rav_t2_low = (count_rav_t2_low/(n_t2 - n_rav_t2_top))*100
replace pcent_rav_t2_low = (count_rav_t2_low/(n_t2 - n_rav_t2_top-1))*100 if z_rav <= $rav_med_guess & treat == 2

bysort net_class: egen n_eye_t2_top = count(finished) if z_eye > $eye_med_guess & treat == 2
egen __t = max(n_eye_t2_top), by(net_class) 
replace n_eye_t2_top = __t
drop __t 
replace n_eye_t2_top = 0 if n_eye_t2_top == .

gen pcent_eye_t2_top = (count_eye_t2_top/(n_eye_t2_top))*100
replace pcent_eye_t2_top = (count_eye_t2_top/(n_eye_t2_top-1))*100 if z_eye > $eye_med_guess & treat == 2

gen pcent_eye_t2_low = (count_eye_t2_low/(n_t2-n_eye_t2_top))*100
replace pcent_eye_t2_low = (count_eye_t2_low/(n_t2-n_eye_t2_top-1))*100 if z_eye <= $eye_med_guess & treat == 2

//# NORMALIZE BY POTENTIAL REFERRERS
gen pcent_twice_t1 = (count_twice_t1/(n_t1*2))*100 
replace pcent_twice_t1 = (count_twice_t1/((n_t1-1)*2))*100 if treat == 1 

gen pcent_twice_t1_lses = (count_twice_t1_lses/(n_t1lses*2))*100 
replace  pcent_twice_t1_lses = (count_twice_t1_lses/((n_t1lses-1)*2))*100 if treat == 1 & ses == 1 

gen pcent_twice_t1_hses = (count_twice_t1_hses/(n_t1hses*2))*100 
replace  pcent_twice_t1_hses = (count_twice_t1_hses/((n_t1hses-1)*2))*100 if treat == 1 & ses == 0 


gen pcent_single_rav_t1 = (count_singler_t1/n_t1)*100
replace pcent_single_rav_t1 = (count_singler_t1/(n_t1-1))*100 if treat == 1

gen pcent_single_rav_t1_lses = (count_singler_t1_lses/n_t1lses)*100
replace pcent_single_rav_t1_lses = (count_singler_t1_lses/(n_t1lses-1))*100 if treat == 1 & ses == 1

gen pcent_single_rav_t1_hses = (count_singler_t1_hses/n_t1hses)*100
replace pcent_single_rav_t1_hses = (count_singler_t1_hses/(n_t1hses-1))*100 if treat == 1 & ses == 0


gen pcent_single_eye_t1 = (count_singlee_t1/n_t1)*100
replace pcent_single_eye_t1 = (count_singlee_t1/(n_t1-1))*100 if treat == 1
//
gen pcent_twice_t2 = (count_twice_t2/(n_t2*2))*100 
replace pcent_twice_t2 = (count_twice_t2/((n_t2-1)*2))*100 if treat == 2 

gen pcent_twice_t2_lses = (count_twice_t2_lses/(n_t2lses*2))*100 
replace  pcent_twice_t2_lses = (count_twice_t2_lses/((n_t2lses-1)*2))*100 if treat == 2 & ses == 1 

gen pcent_twice_t2_hses = (count_twice_t2_hses/(n_t2hses*2))*100 
replace  pcent_twice_t2_hses = (count_twice_t2_hses/((n_t2hses-1)*2))*100 if treat == 2 & ses == 0 

gen pcent_single_rav_t2 = (count_singler_t2/n_t2)*100
replace pcent_single_rav_t2 = (count_singler_t2/(n_t2-1))*100 if treat == 2

gen pcent_single_rav_t2_lses = (count_singler_t2_lses/n_t2lses)*100
replace pcent_single_rav_t2_lses = (count_singler_t2_lses/(n_t2lses-1))*100 if treat == 2 & ses == 1

gen pcent_single_rav_t2_hses = (count_singler_t2_hses/n_t1hses)*100
replace pcent_single_rav_t2_hses = (count_singler_t2_hses/(n_t1hses-1))*100 if treat == 2 & ses == 0


gen pcent_single_eye_t2 = (count_singlee_t2/n_t2)*100
replace pcent_single_eye_t2 = (count_singlee_t2/(n_t2-1))*100 if treat == 2


save "referrals_wide.dta", replace
rm "temp.dta"






