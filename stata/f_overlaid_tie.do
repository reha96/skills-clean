/*******************************************************************************
    Project: icfes referrals 
    Author: Reha Tuncer
    Date: 02.04.2025
    Description: figure referral tie strength by SES overlaid 
*******************************************************************************/
global lowSES "255 99 132"    // Pink/red for low SES
global medSES "54 162 235"    // Blue for medium SES
global highSES "75 192 112"   // Green for high SES
global reading "130 202 157" 
global math "136 132 216"
global path "/Users/reha.tuncer/Documents/GitHub/icfes-referrals/figures/"
clear all
use "dataset_z.dta"
 
// First calculate means and store them in globals
foreach own in 1 2 3 {
    foreach other in 1 2 3 {
        quietly summ tie if own_estrato == `own' & other_estrato == `other' & nomination
        global mean_`own'_`other' = r(mean)
        global se_`own'_`other' = r(sd)/sqrt(r(N))
        global n_`own'_`other' = r(N)
    }
}

foreach own in 1 2 3 {
    foreach other in 1 2 3 {
        quietly summ tie if own_estrato == `own' & other_estrato == `other'
        global mean_`own'_`other'2 = r(mean)
        global se_`own'_`other'2 = r(sd)/sqrt(r(N))
        global n_`own'_`other'2 = r(N)
    }
}


// Create visualization dataset
clear
set obs 9  // 3 own_SES × 3 other_SES
gen own_ses = ceil(_n/3)
gen other_ses = mod(_n-1, 3) + 1
gen xpos = .

// Set x-positions for each bar
replace xpos = 0.7 if own_ses == 1 & other_ses == 1  // Low-Low
replace xpos = 1.0 if own_ses == 1 & other_ses == 2  // Low-Middle
replace xpos = 1.3 if own_ses == 1 & other_ses == 3  // Low-High

replace xpos = 2.2 if own_ses == 2 & other_ses == 1  // Middle-Low
replace xpos = 2.5 if own_ses == 2 & other_ses == 2  // Middle-Middle
replace xpos = 2.8 if own_ses == 2 & other_ses == 3  // Middle-High

replace xpos = 3.7 if own_ses == 3 & other_ses == 1  // High-Low
replace xpos = 4.0 if own_ses == 3 & other_ses == 2  // High-Middle
replace xpos = 4.3 if own_ses == 3 & other_ses == 3  // High-High

gen tie_strength = .
gen se = .

// original
replace tie_strength = ${mean_1_1} if own_ses == 1 & other_ses == 1
replace tie_strength = ${mean_1_2} if own_ses == 1 & other_ses == 2
replace tie_strength = ${mean_1_3} if own_ses == 1 & other_ses == 3
replace se = ${se_1_1} if own_ses == 1 & other_ses == 1
replace se = ${se_1_2} if own_ses == 1 & other_ses == 2
replace se = ${se_1_3} if own_ses == 1 & other_ses == 3

replace tie_strength = ${mean_2_1} if own_ses == 2 & other_ses == 1
replace tie_strength = ${mean_2_2} if own_ses == 2 & other_ses == 2
replace tie_strength = ${mean_2_3} if own_ses == 2 & other_ses == 3
replace se = ${se_2_1} if own_ses == 2 & other_ses == 1
replace se = ${se_2_2} if own_ses == 2 & other_ses == 2
replace se = ${se_2_3} if own_ses == 2 & other_ses == 3

replace tie_strength = ${mean_3_1} if own_ses == 3 & other_ses == 1
replace tie_strength = ${mean_3_2} if own_ses == 3 & other_ses == 2
replace tie_strength = ${mean_3_3} if own_ses == 3 & other_ses == 3
replace se = ${se_3_1} if own_ses == 3 & other_ses == 1
replace se = ${se_3_2} if own_ses == 3 & other_ses == 2
replace se = ${se_3_3} if own_ses == 3 & other_ses == 3

// Calculate 95% confidence intervals
gen ci_lower = tie_strength - 1.96*se
gen ci_upper = tie_strength + 1.96*se

// overlaid
gen tie_strength2 = .
gen se2 = .
replace tie_strength2 = ${mean_1_12} if own_ses == 1 & other_ses == 1
replace tie_strength2 = ${mean_1_22} if own_ses == 1 & other_ses == 2
replace tie_strength2 = ${mean_1_32} if own_ses == 1 & other_ses == 3
replace se2 = ${se_1_12} if own_ses == 1 & other_ses == 1
replace se2 = ${se_1_22} if own_ses == 1 & other_ses == 2
replace se2 = ${se_1_32} if own_ses == 1 & other_ses == 3

replace tie_strength2 = ${mean_2_12} if own_ses == 2 & other_ses == 1
replace tie_strength2 = ${mean_2_22} if own_ses == 2 & other_ses == 2
replace tie_strength2 = ${mean_2_32} if own_ses == 2 & other_ses == 3
replace se2 = ${se_2_12} if own_ses == 2 & other_ses == 1
replace se2 = ${se_2_22} if own_ses == 2 & other_ses == 2
replace se2 = ${se_2_32} if own_ses == 2 & other_ses == 3

replace tie_strength2 = ${mean_3_12} if own_ses == 3 & other_ses == 1
replace tie_strength2 = ${mean_3_22} if own_ses == 3 & other_ses == 2
replace tie_strength2 = ${mean_3_32} if own_ses == 3 & other_ses == 3
replace se2 = ${se_3_12} if own_ses == 3 & other_ses == 1
replace se2 = ${se_3_22} if own_ses == 3 & other_ses == 2
replace se2 = ${se_3_32} if own_ses == 3 & other_ses == 3


// Calculate 95% confidence intervals
gen ci_lower2 = tie_strength2 - 1.96*se2
gen ci_upper2 = tie_strength2 + 1.96*se2

// Label the groups
label define ses_lab 1 "Low" 2 "Middle" 3 "High"
label values own_ses ses_lab
label values other_ses ses_lab

// Create the twoway bar graph with confidence intervals
twoway (bar tie_strength xpos if other_ses == 1, barw(0.25) color("${lowSES}%70")) ///
       (bar tie_strength xpos if other_ses == 2, barw(0.25) color("${medSES}%70")) ///
       (bar tie_strength xpos if other_ses == 3, barw(0.25) color("${highSES}%70")) ///
	   (bar tie_strength2 xpos if other_ses == 1, barw(0.25) color("${lowSES}")) ///
       (bar tie_strength2 xpos if other_ses == 2, barw(0.25) color("${medSES}")) ///
       (bar tie_strength2 xpos if other_ses == 3, barw(0.25) color("${highSES}")) ///
       (rcap ci_upper ci_lower xpos, lcolor(gs4)) ///
	   (rcap ci_upper2 ci_lower2 xpos, lcolor(gs4)) ///
       , ///
       xlabel(1 "Low" 2.5 "Middle" 4 "High") ///
       ylabel(0(5)25, angle(0) format(%9.0f)) ///
       ytitle("Classes taken together") ///
       xtitle("") ///
       title("Referral Tie Strength by SES") ///
       legend(order(1 "Low" 2 "Middle" 3 "High") ///
              ring(0) pos(11) rows(3) region(lcolor(none))) ///
       graphregion(color(white)) bgcolor(white) ///
       xscale(range(0.5 4.5)) ///
       name(overlaid_tie_strength, replace)

graph export "/Users/reha.tuncer/Documents/GitHub/icfes-referrals/figures/overlaid_tie_strength.png", replace
