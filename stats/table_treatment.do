/*******************************************************************************
    Project: SIR - table across treatments
    Author: Reha Tuncer
    Date: 14.10.2024
    Description: Compare treatments
*******************************************************************************/


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

// load dataset
capture noisily use "cleaning/referrals_wide.dta"
if _rc != 0 {
    use "referrals_wide.dta"
}

// referrals received
gen r_count_rav = count_rav/(observed_classmates-1)
gen r_count_eye = count_eye/(observed_classmates-1)
gen r_count_total = (r_count_rav + r_count_eye)*0.5

// compare outcomes
ttest rav_sum, by(treat)
ttest eye_sum, by(treat)
ttest gpa, by(treat)
ttest test_score, by(treat)
ttest semester, by(treat)
ttest age, by(treat)
prtest gender, by(treat)
prtest first_gen, by(treat)
prtest ethnic, by(treat)
prtest rural, by(treat)
prtest scholarship, by(treat)
prtest ses, by(treat)
