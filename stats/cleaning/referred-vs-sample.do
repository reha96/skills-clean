/*******************************************************************************
    Project: SIR - figure & table compare skills referred vs sample
    Author: Reha Tuncer
    Date: 15.10.2024
    Description: Create figure & table
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
capture noisily use "cleaning/cleaned_long.dta"
if _rc != 0 {
    use "cleaned_long.dta"
}


bysort net_id: gen counter = _n
bysort net_id task: gen task_counter = _n

// drop guesses and self-referrals
keep if task != 3 & !self_referral

sum z_rav_other z_gpa_other if task==1
sum z_eye_other z_gpa_other if task==2
sum z_rav z_gpa if task==1 & task_counter==1
sum z_eye z_gpa if task==2 & task_counter==1

graph box z_rav_other z_gpa_other if task==1, vertical $graph_opts
graph box z_rav z_gpa if task==1 & counter==1, vertical $graph_opts

