/*******************************************************************************
    Project: SIR - classroom data
    Author: Reha Tuncer
    Date: 14.10.2024
    Description: Compare classrooms by SES, study program
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


bysort net_class: egen fr_lses = mean(ses)
sort fr_lses

* Generate a new variable for ordered classrooms
egen ordered_class = group(net_class)

* Create the histogram
histogram study, percent by(ordered_class)
