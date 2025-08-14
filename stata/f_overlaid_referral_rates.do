/*******************************************************************************
    Project: icfes referrals 
    Author: Reha Tuncer
    Date: 18.03.2025
    Description: figure referral rates overlaid with pop share - ALL SES COMBINATIONS
*******************************************************************************/

global dpath "/Users/reha.tuncer/Documents/GitHub/icfes-referrals/stata/"
global fpath "/Users/reha.tuncer/Documents/GitHub/icfes-referrals/figures/"
set scheme s2color, permanently

clear all
use "dataset_z.dta"

// Calculate referral proportions by SES and store statistics
foreach own in low middle high {
    foreach other in low middle high {
        global prop_`own'_`other' = ""
        global se_`own'_`other' = ""
        global prop_`own'_`other'2 = ""
        global se_`own'_`other'2 = ""
    }
}

// Low SES respondents - referrals
preserve
keep if own_estrato == 1 & nomination
proportion other_estrato
matrix props_low = r(table)
global prop_low_low = props_low[1,1]
global prop_low_middle = props_low[1,2]
global prop_low_high = props_low[1,3]
global se_low_low = props_low[2,1]
global se_low_middle = props_low[2,2]
global se_low_high = props_low[2,3]
tabstat other_estrato, stat(n) save
matrix stats = r(StatTotal)
global n_low = stats[1,1]
restore

// Low SES respondents - network
preserve
keep if own_estrato == 1
proportion other_estrato
matrix props_low = r(table)
global prop_low_low2 = props_low[1,1]
global prop_low_middle2 = props_low[1,2]
global prop_low_high2 = props_low[1,3]
global se_low_low2 = props_low[2,1]
global se_low_middle2 = props_low[2,2]
global se_low_high2 = props_low[2,3]
tabstat other_estrato, stat(n) save
matrix stats = r(StatTotal)
global n_low2 = stats[1,1]
restore

// Middle SES respondents - referrals
preserve
keep if own_estrato == 2 & nomination
proportion other_estrato
matrix props_middle = r(table)
global prop_middle_low = props_middle[1,1]
global prop_middle_middle = props_middle[1,2]
global prop_middle_high = props_middle[1,3]
global se_middle_low = props_middle[2,1]
global se_middle_middle = props_middle[2,2]
global se_middle_high = props_middle[2,3]
tabstat other_estrato, stat(n) save
matrix stats = r(StatTotal)
global n_middle = stats[1,1]
restore

// Middle SES respondents - network
preserve
keep if own_estrato == 2
proportion other_estrato
matrix props_middle = r(table)
global prop_middle_low2 = props_middle[1,1]
global prop_middle_middle2 = props_middle[1,2]
global prop_middle_high2 = props_middle[1,3]
global se_middle_low2 = props_middle[2,1]
global se_middle_middle2 = props_middle[2,2]
global se_middle_high2 = props_middle[2,3]
tabstat other_estrato, stat(n) save
matrix stats = r(StatTotal)
global n_middle2 = stats[1,1]
restore

// High SES respondents - referrals
preserve
keep if own_estrato == 3 & nomination
proportion other_estrato
matrix props_high = r(table)
global prop_high_low = props_high[1,1]
global prop_high_middle = props_high[1,2]
global prop_high_high = props_high[1,3]
global se_high_low = props_high[2,1]
global se_high_middle = props_high[2,2]
global se_high_high = props_high[2,3]
tabstat other_estrato, stat(n) save
matrix stats = r(StatTotal)
global n_high = stats[1,1]
restore

// High SES respondents - network
preserve
keep if own_estrato == 3
proportion other_estrato
matrix props_high = r(table)
global prop_high_low2 = props_high[1,1]
global prop_high_middle2 = props_high[1,2]
global prop_high_high2 = props_high[1,3]
global se_high_low2 = props_high[2,1]
global se_high_middle2 = props_high[2,2]
global se_high_high2 = props_high[2,3]
tabstat other_estrato, stat(n) save
matrix stats = r(StatTotal)
global n_high2 = stats[1,1]
restore

// Create visualization dataset with confidence intervals
clear
set obs 9  // 3 own_SES × 3 other_SES
gen own_ses = ceil(_n/3)
gen other_ses = mod(_n-1, 3) + 1
gen xpos = .
gen xpos2 = .

// Set x-positions for each bar pair with adjusted spacing for 0.3 width bars
// Groups of same sender SES are closer together, with larger gaps between different sender SES

// Low SES sender
replace xpos = 1 - 0.15 if own_ses == 1 & other_ses == 1      // Low-Low referral
replace xpos = 2 - 0.15 if own_ses == 1 & other_ses == 2      // Low-Middle referral
replace xpos = 3 - 0.15 if own_ses == 1 & other_ses == 3      // Low-High referral

// Middle SES sender (extra spacing between Low-High and Middle-Low)
replace xpos = 4.5 - 0.15 if own_ses == 2 & other_ses == 1    // Middle-Low referral
replace xpos = 5.5 - 0.15 if own_ses == 2 & other_ses == 2    // Middle-Middle referral
replace xpos = 6.5 - 0.15 if own_ses == 2 & other_ses == 3    // Middle-High referral

// High SES sender (extra spacing between Middle-High and High-Low)
replace xpos = 8 - 0.15 if own_ses == 3 & other_ses == 1      // High-Low referral
replace xpos = 9 - 0.15 if own_ses == 3 & other_ses == 2      // High-Middle referral
replace xpos = 10 - 0.15 if own_ses == 3 & other_ses == 3     // High-High referral

// Position the network bars 0.3 units to the right of the referral bars
replace xpos2 = xpos + 0.3

// Fill in the proportions and standard errors
gen proportion = .
gen se = .
gen proportion2 = .
gen se2 = .

// Low SES (own_ses = 1)
replace proportion = ${prop_low_low} if own_ses == 1 & other_ses == 1
replace proportion = ${prop_low_middle} if own_ses == 1 & other_ses == 2
replace proportion = ${prop_low_high} if own_ses == 1 & other_ses == 3
replace se = ${se_low_low} if own_ses == 1 & other_ses == 1
replace se = ${se_low_middle} if own_ses == 1 & other_ses == 2
replace se = ${se_low_high} if own_ses == 1 & other_ses == 3
replace proportion2 = ${prop_low_low2} if own_ses == 1 & other_ses == 1
replace proportion2 = ${prop_low_middle2} if own_ses == 1 & other_ses == 2
replace proportion2 = ${prop_low_high2} if own_ses == 1 & other_ses == 3
replace se2 = ${se_low_low2} if own_ses == 1 & other_ses == 1
replace se2 = ${se_low_middle2} if own_ses == 1 & other_ses == 2
replace se2 = ${se_low_high2} if own_ses == 1 & other_ses == 3

// Middle SES (own_ses = 2)
replace proportion = ${prop_middle_low} if own_ses == 2 & other_ses == 1
replace proportion = ${prop_middle_middle} if own_ses == 2 & other_ses == 2
replace proportion = ${prop_middle_high} if own_ses == 2 & other_ses == 3
replace se = ${se_middle_low} if own_ses == 2 & other_ses == 1
replace se = ${se_middle_middle} if own_ses == 2 & other_ses == 2
replace se = ${se_middle_high} if own_ses == 2 & other_ses == 3
replace proportion2 = ${prop_middle_low2} if own_ses == 2 & other_ses == 1
replace proportion2 = ${prop_middle_middle2} if own_ses == 2 & other_ses == 2
replace proportion2 = ${prop_middle_high2} if own_ses == 2 & other_ses == 3
replace se2 = ${se_middle_low2} if own_ses == 2 & other_ses == 1
replace se2 = ${se_middle_middle2} if own_ses == 2 & other_ses == 2
replace se2 = ${se_middle_high2} if own_ses == 2 & other_ses == 3

// High SES (own_ses = 3)
replace proportion = ${prop_high_low} if own_ses == 3 & other_ses == 1
replace proportion = ${prop_high_middle} if own_ses == 3 & other_ses == 2
replace proportion = ${prop_high_high} if own_ses == 3 & other_ses == 3
replace se = ${se_high_low} if own_ses == 3 & other_ses == 1
replace se = ${se_high_middle} if own_ses == 3 & other_ses == 2
replace se = ${se_high_high} if own_ses == 3 & other_ses == 3
replace proportion2 = ${prop_high_low2} if own_ses == 3 & other_ses == 1
replace proportion2 = ${prop_high_middle2} if own_ses == 3 & other_ses == 2
replace proportion2 = ${prop_high_high2} if own_ses == 3 & other_ses == 3
replace se2 = ${se_high_low2} if own_ses == 3 & other_ses == 1
replace se2 = ${se_high_middle2} if own_ses == 3 & other_ses == 2
replace se2 = ${se_high_high2} if own_ses == 3 & other_ses == 3

// Multiply all proportions and standard errors by 100 for percentages
replace proportion = proportion * 100
replace se = se * 100
replace proportion2 = proportion2 * 100
replace se2 = se2 * 100

// Calculate 95% confidence intervals
gen ci_lower = proportion - 1.96*se
gen ci_upper = proportion + 1.96*se
gen ci_lower2 = proportion2 - 1.96*se2
gen ci_upper2 = proportion2 + 1.96*se2

// Create the twoway bar graph with all 9 SES combinations
twoway (bar proportion xpos, barw(0.3) fcolor(gs8) lcolor(gs4)) ///
       (rcap ci_lower ci_upper xpos, lcolor(gs4)) ///
       (bar proportion2 xpos2, barw(0.3) fcolor(gs14) lcolor(gs4)) ///
       (rcap ci_lower2 ci_upper2 xpos2, lcolor(gs4)) ///
       (pci 0 3.75 80 3.75, lwidth(thin) lpattern(dash) lcolor(gs4)) /// 
       (pci 0 7.25 80 7.25, lwidth(thin) lpattern(dash) lcolor(gs4)) /// 
       , ///
       xlabel(1 "L-L" 2 "L-M" 3 "L-H" 4.5 "M-L" 5.5 "M-M" 6.5 "M-H" 8 "H-L" 9 "H-M" 10 "H-H", angle(0)) ///
       ylabel(0(10)80, angle(0) format(%9.0f) gmin gmax) ///
       ytitle("Percent") ///
       xtitle("") ///
       title("Referral rates compared to network shares") ///
       legend(order(1 "Referral" 3 "Network") ///
              ring(0) pos(12) rows(1) region(lcolor(none)) ) ///
       graphregion(color(white)) bgcolor(white) ///
       xscale(range(0.5 10.5)) ///
       name(referral_rates, replace)

graph export "${fpath}all_ses_referral_rates.png", replace
