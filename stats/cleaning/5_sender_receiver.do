/*******************************************************************************
    Project: Skills inequality referrals
    Author: Reha Tuncer
    Date: 21.11.2024
    Description: This do-file uses guess ratio to separate hses referrals
*******************************************************************************/

//# preamble
version 18
clear all
macro drop _all
set more off
set scheme s2color, permanently
set maxvar 32767

* First try both data file locations
capture noisily use "cleaning/referrals_wide.dta"
if _rc != 0 {
    capture noisily use "referrals_wide.dta"
	}

keep net_id guess_ratio

//# save cleaned data 
save "temp.dta", replace

merge 1:1 net_id using "cleaned_wide.dta"
drop _merge
save "cleaned_wide.dta", replace

//# reshape long
reshape long ref_, i(net_id) j(ref_num)

//# cut non valid refs
gen self_ref = net_id == ref_
keep if  ref_num <=6
keep if  !self_ref
keep if  ref_ !=.


//# REFERRALS FOR SKILLS BY SKILL BELIEFS
sum  z_rav_belief, det
global med_rav = r(p50)

sum  z_eye_belief, det
global med_eye = r(p50)

bysort net_class ref_: gen count_rav_t1_hb = sum(finished) if ref_num <= 3 & treat == 1 & z_rav_belief> $med_rav
egen __t = max(count_rav_t1_hb), by(ref_) 
replace count_rav_t1_hb = __t
drop __t  
replace count_rav_t1_hb = 0 if count_rav_t1_hb == . 

bysort net_class ref_: gen count_rav_t1_lb = sum(finished) if ref_num <= 3 & treat == 1 & z_rav_belief <= $med_rav
egen __t = max(count_rav_t1_lb), by(ref_) 
replace count_rav_t1_lb = __t
drop __t  
replace count_rav_t1_lb = 0 if count_rav_t1_lb == . 
//
bysort net_class ref_: gen count_rav_t2_hb = sum(finished) if ref_num <= 3 & treat == 2 & z_rav_belief > $med_rav
egen __t = max(count_rav_t2_hb), by(ref_) 
replace count_rav_t2_hb = __t
drop __t  
replace count_rav_t2_hb = 0 if count_rav_t2_hb == . 

bysort net_class ref_: gen count_rav_t2_lb = sum(finished) if ref_num <= 3 & treat == 2 & z_rav_belief<= $med_rav
egen __t = max(count_rav_t2_lb), by(ref_) 
replace count_rav_t2_lb = __t
drop __t  
replace count_rav_t2_lb = 0 if count_rav_t2_lb == . 
//
bysort net_class ref_: gen count_eye_t1_hb = sum(finished) if ref_num > 3 & treat == 1 & z_eye_belief > $med_eye
egen __t = max(count_eye_t1_hb), by(ref_) 
replace count_eye_t1_hb = __t
drop __t  
replace count_eye_t1_hb = 0 if count_eye_t1_hb == . 

bysort net_class ref_: gen count_eye_t1_lb = sum(finished) if ref_num > 3 & treat == 1 & z_eye_belief <= $med_eye
egen __t = max(count_eye_t1_lb), by(ref_) 
replace count_eye_t1_lb = __t
drop __t  
replace count_eye_t1_lb = 0 if count_eye_t1_lb == . 
//
bysort net_class ref_: gen count_eye_t2_hb = sum(finished) if ref_num > 3 & treat == 2 & z_eye_belief > $med_eye
egen __t = max(count_eye_t2_hb), by(ref_) 
replace count_eye_t2_hb = __t
drop __t  
replace count_eye_t2_hb = 0 if count_eye_t2_hb == .

bysort net_class ref_: gen count_eye_t2_lb = sum(finished) if ref_num > 3 & treat == 2  & z_eye_belief <= $med_eye
egen __t = max(count_eye_t2_lb), by(ref_) 
replace count_eye_t2_lb = __t
drop __t  
replace count_eye_t2_lb = 0 if count_eye_t2_lb == . 
// 
gen count_total_t1_hb = count_eye_t1_hb + count_rav_t1_hb
gen count_total_t1_lb = count_eye_t1_lb + count_rav_t1_lb

gen count_total_t2_hb = count_eye_t2_hb + count_rav_t2_hb
gen count_total_t2_lb = count_eye_t2_lb + count_rav_t2_lb

//# REFERRALS FOR SKILLS BY GUESSING ABILITY
sum  guess_ratio, det
global med_guess = r(p50)

bysort net_class ref_: gen count_rav_t1_high = sum(finished) if ref_num <= 3 & treat == 1 & guess_ratio> $med_guess
egen __t = max(count_rav_t1_high), by(ref_) 
replace count_rav_t1_high = __t
drop __t  
replace count_rav_t1_high = 0 if count_rav_t1_high == . 

bysort net_class ref_: gen count_rav_t1_low = sum(finished) if ref_num <= 3 & treat == 1 & guess_ratio <= $med_guess
egen __t = max(count_rav_t1_low), by(ref_) 
replace count_rav_t1_low = __t
drop __t  
replace count_rav_t1_low = 0 if count_rav_t1_low == . 
//
bysort net_class ref_: gen count_rav_t2_high = sum(finished) if ref_num <= 3 & treat == 2 & guess_ratio > $med_guess
egen __t = max(count_rav_t2_high), by(ref_) 
replace count_rav_t2_high = __t
drop __t  
replace count_rav_t2_high = 0 if count_rav_t2_high == . 

bysort net_class ref_: gen count_rav_t2_low = sum(finished) if ref_num <= 3 & treat == 2 & guess_ratio<= $med_guess
egen __t = max(count_rav_t2_low), by(ref_) 
replace count_rav_t2_low = __t
drop __t  
replace count_rav_t2_low = 0 if count_rav_t2_low == . 
//
bysort net_class ref_: gen count_eye_t1_high = sum(finished) if ref_num > 3 & treat == 1 & guess_ratio > $med_guess
egen __t = max(count_eye_t1_high), by(ref_) 
replace count_eye_t1_high = __t
drop __t  
replace count_eye_t1_high = 0 if count_eye_t1_high == . 

bysort net_class ref_: gen count_eye_t1_low = sum(finished) if ref_num > 3 & treat == 1 & guess_ratio <= $med_guess
egen __t = max(count_eye_t1_low), by(ref_) 
replace count_eye_t1_low = __t
drop __t  
replace count_eye_t1_low = 0 if count_eye_t1_low == . 
//
bysort net_class ref_: gen count_eye_t2_high = sum(finished) if ref_num > 3 & treat == 2 & guess_ratio > $med_guess
egen __t = max(count_eye_t2_high), by(ref_) 
replace count_eye_t2_high = __t
drop __t  
replace count_eye_t2_high = 0 if count_eye_t2_high == .

bysort net_class ref_: gen count_eye_t2_low = sum(finished) if ref_num > 3 & treat == 2  & guess_ratio <= $med_guess
egen __t = max(count_eye_t2_low), by(ref_) 
replace count_eye_t2_low = __t
drop __t  
replace count_eye_t2_low = 0 if count_eye_t2_low == . 
// 
gen count_total_t1_high = count_eye_t1_high + count_rav_t1_high
gen count_total_t1_low = count_eye_t1_low + count_rav_t1_low

gen count_total_t2_high = count_eye_t2_high + count_rav_t2_high
gen count_total_t2_low = count_eye_t2_low + count_rav_t2_low


//# REFERRALS FOR SKILLS BY SES AND BY GUESSING ABILITY
sum  guess_ratio if ses == 0, det
global hses_med_guess = r(p50)

sum  guess_ratio if ses == 1, det
global lses_med_guess = r(p50)


bysort net_class ref_: gen count_rav_t1hses_hg = sum(finished) if ref_num <= 3 & treat == 1 & ses == 0 & guess_ratio> $hses_med_guess
egen __t = max(count_rav_t1hses_hg), by(ref_) 
replace count_rav_t1hses_hg = __t
drop __t  
replace count_rav_t1hses_hg = 0 if count_rav_t1hses_hg == . 
bysort net_class ref_: gen count_rav_t1hses_lg = sum(finished) if ref_num <= 3 & treat == 1 & ses == 0 & guess_ratio<= $hses_med_guess
egen __t = max(count_rav_t1hses_lg), by(ref_) 
replace count_rav_t1hses_lg = __t
drop __t  
replace count_rav_t1hses_lg = 0 if count_rav_t1hses_lg == . 
//
bysort net_class ref_: gen count_rav_t1lses_hg = sum(finished) if ref_num <= 3 & treat == 1 & ses == 1 & guess_ratio > $lses_med_guess
egen __t = max(count_rav_t1lses_hg), by(ref_) 
replace count_rav_t1lses_hg = __t
drop __t  
replace count_rav_t1lses_hg = 0 if count_rav_t1lses_hg == . 
bysort net_class ref_: gen count_rav_t1lses_lg = sum(finished) if ref_num <= 3 & treat == 1 & ses == 1 & guess_ratio <= $lses_med_guess
egen __t = max(count_rav_t1lses_lg), by(ref_) 
replace count_rav_t1lses_lg = __t
drop __t  
replace count_rav_t1lses_lg = 0 if count_rav_t1lses_lg == . 
//
bysort net_class ref_: gen count_eye_t1hses_hg = sum(finished) if ref_num > 3 & treat == 1 & ses == 0 & guess_ratio> $hses_med_guess
egen __t = max(count_eye_t1hses_hg), by(ref_) 
replace count_eye_t1hses_hg = __t
drop __t  
replace count_eye_t1hses_hg = 0 if count_eye_t1hses_hg == .
bysort net_class ref_: gen count_eye_t1hses_lg = sum(finished) if ref_num > 3 & treat == 1 & ses == 0 & guess_ratio< $hses_med_guess
egen __t = max(count_eye_t1hses_lg), by(ref_) 
replace count_eye_t1hses_lg = __t
drop __t  
replace count_eye_t1hses_lg = 0 if count_eye_t1hses_lg == .
//
bysort net_class ref_: gen count_eye_t1lses_hg = sum(finished) if ref_num > 3 & treat == 1 & ses == 1 & guess_ratio > $lses_med_guess
egen __t = max(count_eye_t1lses_hg), by(ref_) 
replace count_eye_t1lses_hg = __t
drop __t  
replace count_eye_t1lses_hg = 0 if count_eye_t1lses_hg == .
bysort net_class ref_: gen count_eye_t1lses_lg = sum(finished) if ref_num > 3 & treat == 1 & ses == 1 & guess_ratio <= $lses_med_guess
egen __t = max(count_eye_t1lses_lg), by(ref_) 
replace count_eye_t1lses_lg = __t
drop __t  
replace count_eye_t1lses_lg = 0 if count_eye_t1lses_lg == .
// 
gen count_total_t1hseshg = count_eye_t1hses_hg + count_rav_t1hses_hg
gen count_total_t1hseslg = count_eye_t1hses_lg + count_rav_t1hses_lg
gen count_total_t1lseshg = count_eye_t1lses_hg + count_rav_t1lses_hg
gen count_total_t1lseslg = count_eye_t1lses_lg + count_rav_t1lses_lg
gen count_total_t1 = count_total_t1lseslg + count_total_t1lseshg + count_total_t1hseslg + count_total_t1hseshg

//

bysort net_class ref_: gen count_rav_t2hses_hg = sum(finished) if ref_num <= 3 & treat == 2 & ses == 0 & guess_ratio> $hses_med_guess
egen __t = max(count_rav_t2hses_hg), by(ref_) 
replace count_rav_t2hses_hg = __t
drop __t  
replace count_rav_t2hses_hg = 0 if count_rav_t2hses_hg == . 

bysort net_class ref_: gen count_rav_t2hses_lg = sum(finished) if ref_num <= 3 & treat == 2 & ses == 0 & guess_ratio<= $hses_med_guess
egen __t = max(count_rav_t2hses_lg), by(ref_) 
replace count_rav_t2hses_lg = __t
drop __t  
replace count_rav_t2hses_lg = 0 if count_rav_t2hses_lg == . 
//
bysort net_class ref_: gen count_rav_t2lses_hg = sum(finished) if ref_num <= 3 & treat == 2 & ses == 1 & guess_ratio > $lses_med_guess
egen __t = max(count_rav_t2lses_hg), by(ref_) 
replace count_rav_t2lses_hg = __t
drop __t  
replace count_rav_t2lses_hg = 0 if count_rav_t2lses_hg == . 

bysort net_class ref_: gen count_rav_t2lses_lg = sum(finished) if ref_num <= 3 & treat == 2 & ses == 1 & guess_ratio <= $lses_med_guess
egen __t = max(count_rav_t2lses_lg), by(ref_) 
replace count_rav_t2lses_lg = __t
drop __t  
replace count_rav_t2lses_lg = 0 if count_rav_t2lses_lg == . 
//
bysort net_class ref_: gen count_eye_t2hses_hg = sum(finished) if ref_num > 3 & treat == 2 & ses == 0 & guess_ratio> $hses_med_guess
egen __t = max(count_eye_t2hses_hg), by(ref_) 
replace count_eye_t2hses_hg = __t
drop __t  
replace count_eye_t2hses_hg = 0 if count_eye_t2hses_hg == .

bysort net_class ref_: gen count_eye_t2hses_lg = sum(finished) if ref_num > 3 & treat == 2 & ses == 0 & guess_ratio< $hses_med_guess
egen __t = max(count_eye_t2hses_lg), by(ref_) 
replace count_eye_t2hses_lg = __t
drop __t  
replace count_eye_t2hses_lg = 0 if count_eye_t2hses_lg == .
//
bysort net_class ref_: gen count_eye_t2lses_hg = sum(finished) if ref_num > 3 & treat == 2 & ses == 1 & guess_ratio > $lses_med_guess
egen __t = max(count_eye_t2lses_hg), by(ref_) 
replace count_eye_t2lses_hg = __t
drop __t  
replace count_eye_t2lses_hg = 0 if count_eye_t2lses_hg == .

bysort net_class ref_: gen count_eye_t2lses_lg = sum(finished) if ref_num > 3 & treat == 2 & ses == 1 & guess_ratio <= $lses_med_guess
egen __t = max(count_eye_t2lses_lg), by(ref_) 
replace count_eye_t2lses_lg = __t
drop __t  
replace count_eye_t2lses_lg = 0 if count_eye_t2lses_lg == .
// 
gen count_total_t2hseshg = count_eye_t2hses_hg + count_rav_t2hses_hg
gen count_total_t2hseslg = count_eye_t2hses_lg + count_rav_t2hses_lg
gen count_total_t2lseshg = count_eye_t2lses_hg + count_rav_t2lses_hg
gen count_total_t2lseslg = count_eye_t2lses_lg + count_rav_t2lses_lg
gen count_total_t2 = count_total_t2lseslg + count_total_t2lseshg + count_total_t2hseslg + count_total_t2hseshg

// MERGE
keep ref_ count*
collapse (mean) count*, by(ref_)
rename ref_ net_id 
drop if net_id == .
merge 1:1 net_id using "referrals_wide.dta"

//# MEDIAN BELIEFS
bysort net_class: egen n_t1_hb_rav = count(finished) if treat == 1 & z_rav_belief> $med_rav
egen __t = max(n_t1_hb_rav), by(net_class) 
replace n_t1_hb_rav = __t
drop __t 
replace n_t1_hb_rav = 0 if n_t1_hb_rav ==.

bysort net_class: egen n_t1_lb_rav = count(finished) if treat == 1 & z_rav_belief <= $med_rav
egen __t = max(n_t1_lb_rav), by(net_class) 
replace n_t1_lb_rav = __t
drop __t 
replace n_t1_lb_rav = 0 if n_t1_lb_rav ==.

bysort net_class: egen n_t1_hb_eye = count(finished) if treat == 1 & z_eye_belief> $med_eye
egen __t = max(n_t1_hb_eye), by(net_class) 
replace n_t1_hb_eye = __t
drop __t 
replace n_t1_hb_eye = 0 if n_t1_hb_eye ==.

bysort net_class: egen n_t1_lb_eye = count(finished) if treat == 1 & z_eye_belief <= $med_eye
egen __t = max(n_t1_lb_eye), by(net_class) 
replace n_t1_lb_eye = __t
drop __t 
replace n_t1_lb_eye = 0 if n_t1_lb_eye ==.


gen pcent_rav_t1_hb = (count_rav_t1_hb/(n_t1_hb_rav))*100
replace pcent_rav_t1_hb = (count_rav_t1_hb/((n_t1_hb_rav-1)))*100 if treat == 1 & z_rav_belief> $med_rav

gen pcent_eye_t1_hb = (count_eye_t1_hb/(n_t1_hb_eye))*100
replace pcent_eye_t1_hb = (count_eye_t1_high/((n_t1_hb_eye-1)))*100 if treat == 1 & z_eye_belief> $med_eye

gen pcent_rav_t1_lb = (count_rav_t1_lb/(n_t1_lb_rav))*100
replace pcent_rav_t1_lb = (count_rav_t1_lb/((n_t1_lb_rav-1)))*100 if treat == 1 & z_rav_belief <= $med_rav

gen pcent_eye_t1_lb = (count_eye_t1_lb/(n_t1_lb_eye))*100
replace pcent_eye_t1_lb = (count_eye_t1_lb/((n_t1_lb_eye-1)))*100 if treat == 1 & z_eye_belief <= $med_eye

//
bysort net_class: egen n_t2_hb_rav = count(finished) if treat == 2 & z_rav_belief> $med_rav
egen __t = max(n_t2_hb_rav), by(net_class) 
replace n_t2_hb_rav = __t
drop __t 
replace n_t2_hb_rav = 0 if n_t2_hb_rav ==.

bysort net_class: egen n_t2_lb_rav = count(finished) if treat == 2 & z_rav_belief <= $med_rav
egen __t = max(n_t2_lb_rav), by(net_class) 
replace n_t2_lb_rav = __t
drop __t 
replace n_t2_lb_rav = 0 if n_t2_lb_rav ==.

bysort net_class: egen n_t2_hb_eye = count(finished) if treat == 2 & z_eye_belief> $med_eye
egen __t = max(n_t2_hb_eye), by(net_class) 
replace n_t2_hb_eye = __t
drop __t 
replace n_t2_hb_eye = 0 if n_t2_hb_eye ==.

bysort net_class: egen n_t2_lb_eye = count(finished) if treat == 2 & z_eye_belief <= $med_eye
egen __t = max(n_t2_lb_eye), by(net_class) 
replace n_t2_lb_eye = __t
drop __t 
replace n_t2_lb_eye = 0 if n_t2_lb_eye ==.


gen pcent_rav_t2_hb = (count_rav_t2_hb/(n_t2_hb_rav))*100
replace pcent_rav_t2_hb = (count_rav_t2_hb/((n_t2_hb_rav-1)))*100 if treat == 2 & z_rav_belief> $med_rav

gen pcent_eye_t2_hb = (count_eye_t2_hb/(n_t2_hb_eye))*100
replace pcent_eye_t2_hb = (count_eye_t2_high/((n_t2_hb_eye-1)))*100 if treat == 2 & z_eye_belief> $med_eye

gen pcent_rav_t2_lb = (count_rav_t2_lb/(n_t2_lb_rav))*100
replace pcent_rav_t2_lb = (count_rav_t2_lb/((n_t2_lb_rav-1)))*100 if treat == 2 & z_rav_belief <= $med_rav

gen pcent_eye_t2_lb = (count_eye_t2_lb/(n_t2_lb_eye))*100
replace pcent_eye_t2_lb = (count_eye_t2_lb/((n_t2_lb_eye-1)))*100 if treat == 2 & z_eye_belief <= $med_eye

//# MEDIAN GUESSING ABILITY
bysort net_class: egen n_t1_high = count(finished) if treat == 1 & guess_ratio> $med_guess
egen __t = max(n_t1_high), by(net_class) 
replace n_t1_high = __t
drop __t 
replace n_t1_high = 0 if n_t1_high ==.

bysort net_class: egen n_t1_low = count(finished) if treat == 1 & guess_ratio <= $med_guess
egen __t = max(n_t1_low), by(net_class) 
replace n_t1_low = __t
drop __t 
replace n_t1_low = 0 if n_t1_low ==.


gen pcent_rav_t1_hg = (count_rav_t1_high/(n_t1_high))*100
replace pcent_rav_t1_hg = (count_rav_t1_high/((n_t1_high-1)))*100 if treat == 1 & guess_ratio> $med_guess

gen pcent_eye_t1_hg = (count_eye_t1_high/(n_t1_high))*100
replace pcent_eye_t1_hg = (count_eye_t1_high/((n_t1_high-1)))*100 if treat == 1 & guess_ratio> $med_guess

gen pcent_t1_high = (count_total_t1_high/(n_t1_high*2))*100
replace pcent_t1_high = (count_total_t1_high/((n_t1_high-1)*2))*100 if treat == 1 & guess_ratio> $med_guess

gen pcent_rav_t1_lg = (count_rav_t1_low/(n_t1_low))*100
replace pcent_rav_t1_lg = (count_rav_t1_low/((n_t1_low-1)))*100 if treat == 1 & guess_ratio <= $med_guess

gen pcent_eye_t1_lg = (count_eye_t1_low/(n_t1_low))*100
replace pcent_eye_t1_lg = (count_eye_t1_low/((n_t1_low-1)))*100 if treat == 1 & guess_ratio <= $med_guess

gen pcent_t1_low = (count_total_t1_low/(n_t1_low*2))*100
replace pcent_t1_low = (count_total_t1_low/((n_t1_low-1)*2))*100 if treat == 1 & guess_ratio <= $med_guess
//
bysort net_class: egen n_t2_high = count(finished) if treat == 2 & guess_ratio > $med_guess
egen __t = max(n_t2_high), by(net_class) 
replace n_t2_high = __t
drop __t 
replace n_t2_high = 0 if n_t2_high ==.

bysort net_class: egen n_t2_low = count(finished) if treat == 2 & guess_ratio <= $med_guess
egen __t = max(n_t2_low), by(net_class) 
replace n_t2_low = __t
drop __t 
replace n_t2_low = 0 if n_t2_low ==.


gen pcent_rav_t2_hg = (count_rav_t2_high/(n_t2_high))*100
replace pcent_rav_t2_hg = (count_rav_t2_high/((n_t2_high-1)))*100 if treat == 1 & guess_ratio> $med_guess

gen pcent_eye_t2_hg = (count_eye_t2_high/(n_t2_high))*100
replace pcent_eye_t2_hg = (count_eye_t2_high/((n_t2_high-1)))*100 if treat == 1 & guess_ratio> $med_guess

gen pcent_t2_high = (count_total_t2_high/(n_t2_high*2))*100
replace pcent_t2_high = (count_total_t2_high/((n_t2_high-1)*2))*100 if treat == 1 & guess_ratio> $med_guess

gen pcent_rav_t2_lg = (count_rav_t2_low/(n_t2_low))*100
replace pcent_rav_t2_lg = (count_rav_t2_low/((n_t2_low-1)))*100 if treat == 1 & guess_ratio <= $med_guess

gen pcent_eye_t2_lg = (count_eye_t2_low/(n_t2_low))*100
replace pcent_eye_t2_lg = (count_eye_t2_low/((n_t2_low-1)))*100 if treat == 1 & guess_ratio <= $med_guess

gen pcent_t2_low = (count_total_t2_low/(n_t2_low*2))*100
replace pcent_t2_low = (count_total_t2_low/((n_t2_low-1)*2))*100 if treat == 1 & guess_ratio <= $med_guess


//# MEDIAN GUESSING ABILITY BY SES
bysort net_class: egen n_t1hseshg = count(finished) if treat == 1 & ses == 0 & guess_ratio> $hses_med_guess
egen __t = max(n_t1hseshg), by(net_class) 
replace n_t1hseshg = __t
drop __t 
replace n_t1hseshg = 0 if n_t1hseshg ==.
//
bysort net_class: egen n_t1hseslg = count(finished) if treat == 1 & ses == 0 & guess_ratio<= $hses_med_guess
egen __t = max(n_t1hseslg), by(net_class) 
replace n_t1hseslg = __t
drop __t 
replace n_t1hseslg = 0 if n_t1hseslg ==.
//
bysort net_class: egen n_t1lseshg = count(finished) if treat == 1 & ses == 1 & guess_ratio> $lses_med_guess
egen __t = max(n_t1lseshg), by(net_class) 
replace n_t1lseshg = __t
drop __t 
replace n_t1lseshg = 0 if n_t1lseshg ==.
//
bysort net_class: egen n_t1lseslg = count(finished) if treat == 1 & ses == 1 & guess_ratio<= $lses_med_guess
egen __t = max(n_t1lseslg), by(net_class) 
replace n_t1lseslg = __t
drop __t 
replace n_t1lseslg = 0 if n_t1lseslg ==.
//
gen pcent_t1hseshg = (count_total_t1hseshg/(n_t1hseshg*2))*100
replace pcent_t1hseshg = (count_total_t1hseshg/((n_t1hseshg-1)*2))*100 if treat == 1 & ses == 0 & guess_ratio> $hses_med_guess

gen pcent_t1hseslg = (count_total_t1hseslg/(n_t1hseslg))*100
replace pcent_t1hseslg = (count_total_t1hseslg/((n_t1hseslg-1)*2))*100 if treat == 1 & ses == 0 & guess_ratio<= $hses_med_guess

gen pcent_t1lseshg = (count_total_t1lseshg/(n_t1lseshg*2))*100
replace pcent_t1lseshg = (count_total_t1lseshg/((n_t1lseshg-1)*2))*100 if treat == 1 & ses == 1 & guess_ratio> $lses_med_guess

gen pcent_t1lseslg = (count_total_t1lseslg/(n_t1lseslg*2))*100
replace pcent_t1lseslg = (count_total_t1lseslg/((count_total_t1lseslg-1)*2))*100 if treat == 1 & ses == 1 & guess_ratio<= $lses_med_guess

//
bysort net_class: egen n_t2hseshg = count(finished) if treat == 2 & ses == 0 & guess_ratio> $hses_med_guess
egen __t = max(n_t2hseshg), by(net_class) 
replace n_t2hseshg = __t
drop __t 
replace n_t2hseshg = 0 if n_t2hseshg ==.

bysort net_class: egen n_t2hseslg = count(finished) if treat == 2 & ses == 0 & guess_ratio<= $hses_med_guess
egen __t = max(n_t2hseslg), by(net_class) 
replace n_t2hseslg = __t
drop __t 
replace n_t2hseslg = 0 if n_t2hseslg ==.
//
bysort net_class: egen n_t2lseshg = count(finished) if treat == 2 & ses == 1 & guess_ratio> $lses_med_guess
egen __t = max(n_t2lseshg), by(net_class) 
replace n_t2lseshg = __t
drop __t 
replace n_t2lseshg = 0 if n_t2lseshg ==.

bysort net_class: egen n_t2lseslg = count(finished) if treat == 2 & ses == 1 & guess_ratio<= $lses_med_guess
egen __t = max(n_t2lseslg), by(net_class) 
replace n_t2lseslg = __t
drop __t 
replace n_t2lseslg = 0 if n_t2lseslg ==.
//
gen pcent_t2hseshg = (count_total_t2hseshg/(n_t2hseshg*2))*100
replace pcent_t2hseshg = (count_total_t2hseshg/((n_t2hseshg-1)*2))*100 if treat == 2 & ses == 0 & guess_ratio> $hses_med_guess

gen pcent_t2hseslg = (count_total_t2hseslg/(n_t2hseslg*2))*100
replace pcent_t2hseslg = (count_total_t2hseslg/((n_t2hseslg-1)*2))*100 if treat == 2 & ses == 0 & guess_ratio<= $hses_med_guess

gen pcent_t2lseshg = (count_total_t2lseshg/(n_t2lseshg*2))*100
replace pcent_t2lseshg = (count_total_t2lseshg/((n_t2lseshg-1)*2))*100 if treat == 2 & ses == 1 & guess_ratio> $lses_med_guess

gen pcent_t2lseslg = (count_total_t2lseslg/(n_t2lseslg*2))*100
replace pcent_t2lseslg = (count_total_t2lseslg/((n_t2lseslg-1)*2))*100 if treat == 2 & ses == 1 & guess_ratio<= $lses_med_guess

//

misstable sum pcent_t1_low pcent_t1_high pcent_t2_low pcent_t2_high

misstable sum pcent_t2hseshg pcent_t2hseslg pcent_t2lseshg pcent_t2lseslg
sum pcent_t2hseshg pcent_t2hseslg pcent_t2lseshg pcent_t2lseslg
misstable sum pcent_t1hseshg pcent_t1hseslg pcent_t1lseshg pcent_t1lseslg
sum pcent_t1hseshg pcent_t1hseslg pcent_t1lseshg pcent_t1lseslg

save "referrals_wide.dta", replace

rm "cleaned_wide.dta"
rm "temp.dta"

