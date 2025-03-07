/*******************************************************************************
    Project: SIR - descriptive figures
    Author: Reha Tuncer
    Date: 25.07.2024
    Description: Figures for 1st empirical specification
*******************************************************************************/


// Set up environment
version 18
clear all
macro drop _all
set more off
set scheme stsj , permanently
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
drop if z_gpa == . // students with gpa missing --> 2 classes premed school
drop if net_class == 22000 // 1 student
drop if net_class == 7000 // 3 students




	
egen total_twice = total(same_referral)	
gen _t = 3-same_referral 	
replace _t = _t * 2
egen total_referrals = total(_t)	


// cumulative

cumul pcent_total_t1, gen(cumt1) equal
cumul pcent_total_t2, gen(cumt2) equal
stack cumt1 pcent_total_t1 cumt2 pcent_total_t2, into(cum t) wide clear
line cumt1 cumt2 t, sort ylab(, grid) ytitle("") xlab(, grid)

// figures
histogram count_total, percent ///
    $graph_opts ///
    ylabel(, angle(0)) ///
    xtitle("Number of Referrals") ///
    bin(20) ///
	name(referral_total, replace)

histogram r_count_total, percent ///
    $graph_opts ///
    ylabel(, angle(0)) ///
    xtitle("Fraction of Referrals") ///
    bin(10) ///
	name(referral_fraction, replace)	
	
/////////
//# GPA BY SES
/////////

// Get summary statistics first
summarize z_gpa if ses == 1
local min1 = r(min)
local max1 = r(max)
local n1 = r(N)
summarize z_gpa if ses == 0
local min2 = r(min)
local max2 = r(max)
local n2 = r(N)

// Calculate the global min and max
local min_global = min(`min1',`min2')
local max_global = max(`max1',`max2')

// For exactly 10 bins, calculate width
local width = (`max_global'-`min_global')/9

// Modified histogram with exactly 10 bins
twoway (histogram z_gpa if ses == 1, percent start(`min_global') width(`width') color(ebblue%40)) ///
       (histogram z_gpa if ses == 0, percent start(`min_global') width(`width') color(maroon%40)), ///
       legend(ring(0) pos(2) order(1 2) label(1 "Low-SES") label(2 "High-SES") rows(2) size(small) region(lcolor(none) fcolor(none))) ///
       xtitle("Standardized GPA") ///
	   ylabel(, angle(0)) ///
       ytitle("Percent") ///
       $graph_opts ///
       name(gpa_ses, replace)	

//# SKILLS 
// Get summary statistics first
summarize z_rav if ses == 1
local min1 = r(min)
local max1 = r(max)
local n1 = r(N)
summarize z_rav if ses == 0
local min2 = r(min)
local max2 = r(max)
local n2 = r(N)

// Calculate the global min and max
local min_global = min(`min1',`min2')
local max_global = max(`max1',`max2')

// For exactly 10 bins, calculate width
local width = (`max_global'-`min_global')/9

// Modified histogram with exactly 10 bins
twoway (histogram z_rav if ses == 1, percent start(`min_global') width(`width') color(ebblue%40)) ///
       (histogram z_rav if ses == 0, percent start(`min_global') width(`width') color(maroon%40)), ///
       legend(ring(0) pos(2) order(1 2) label(1 "Low-SES") label(2 "High-SES") rows(2) size(small) region(lcolor(none) fcolor(none))) ///
       xtitle("Standardized Cognitive Skill") ///
	   ylabel(0(5)25, angle(0)) ///
	   yscale(range(0 25)) ///
	   xlabel(-4(2)4) ///
       ytitle("Percent") ///
       $graph_opts ///
       name(rav_ses, replace)	
	   
//////////	   
summarize z_eye if ses == 1
local min1 = r(min)
local max1 = r(max)
local n1 = r(N)
summarize z_eye if ses == 0
local min2 = r(min)
local max2 = r(max)
local n2 = r(N)

// Calculate the global min and max
local min_global = min(`min1',`min2')
local max_global = max(`max1',`max2')

// For exactly 10 bins, calculate width
local width = (`max_global'-`min_global')/9

// Modified histogram with exactly 10 bins
twoway (histogram z_eye if ses == 1, percent start(`min_global') width(`width') color(ebblue%40)) ///
       (histogram z_eye if ses == 0, percent start(`min_global') width(`width') color(maroon%40)), ///
       legend(ring(0) pos(2) order(1 2) label(1 "Low-SES") label(2 "High-SES") rows(2) size(small) region(lcolor(none) fcolor(none))) ///
       xtitle("Standardized Social Skill") ///
       ytitle("Percent") ///
	   ylabel(, angle(0)) ///
       $graph_opts ///
       name(eye_ses, replace)		   
	
/////////
//# referrals by skills in BASELINE
/////////

// Get summary statistics first
summarize pcent_count_rav_t1
local m1 = r(mean)
local sd1 = r(sd)
local min1 = r(min)
local max1 = r(max)
local n1 = r(N)

summarize pcent_count_eye_t1
local m2 = r(mean)
local sd2 = r(sd)
local min2 = r(min)
local max2 = r(max)
local n2 = r(N)

// Calculate the global min and max
local min_global = min(`min1',`min2')
local max_global = max(`max1',`max2')

// Modified histogram with offset
twoway (histogram pcent_count_rav_t1, percent width(8) fcolor(gs12) lcolor(none)) ///
       (histogram pcent_count_eye_t1, percent width(8) fcolor(white%0) lpattern(dash) lcolor(gs4) lwidth(medthick)), ///
       legend(ring(0) pos(2) order(1 2) label(1 "Cognitive") label(2 "Social") rows(2) size(small) region(lcolor(none) fcolor(none))) ///
       xtitle("Percent referral share") ///
       ytitle("Percent") ///
       ylabel(, angle(0)) ///
       xsize(4) ///
       $graph_opts ///
       name(ref_skill_baseline, replace)

// Export the graph
graph export "/Users/reha.tuncer/Documents/GitHub/Inequality-Skills-and-Referrals/figures/ref_skill_baseline.png", ///
    replace
	
// Generate fractional ranks for y-axis (cumulative probabilities)
local vars "pcent_count_rav_t1 pcent_count_eye_t1"
foreach v of local vars {
    sort `v'
    gen rank_`v' = _n/_N
}
twoway ///
(scatter rank_pcent_count_rav_t1 pcent_count_rav_t1 , ///
        msymbol(none) ///
        msize(small) ///
        mcolor(gs12) ///
        sort(rank_pcent_count_rav_t1) ///
        connect(J) ///
		lcolor(gs12) ///
		lwidth(vthick)  ///
        lpattern(solid)) ///
    (scatter rank_pcent_count_eye_t1 pcent_count_eye_t1 , ///
	msymbol(circle) ///
    msize(vsmall) ///
    mcolor(gs4) ///
    sort(rank_pcent_count_eye_t1)), ///	
    ylabel(0(.2)1, angle(0) format(%2.1f)) ///
    xlabel(0(20)80, format(%3.0f)) ///
	xsize(4) ///
    ytitle("Cumulative Probability") ///
    xtitle("Percent referral share") ///
    legend(ring(0) pos(11) order(1 2) label(1 "Cognitive") label(2 "Social") rows(2) symxsize(3) size(small) region(lcolor(none) fcolor(none))) ///
    $graph_opts
	
	graph export "/Users/reha.tuncer/Documents/GitHub/Inequality-Skills-and-Referrals/figures/cdf1.png", ///
    replace
drop rank_*

// quantil2 pcent_count_rav_t1 pcent_count_eye_t1
// qqplot pcent_count_rav_t1 pcent_count_eye_t1	   

preserve
expand 2
bysort net_id: gen dummy = _n
gen test_stat = pcent_count_rav_t1 if dummy == 1
replace test_stat = pcent_count_eye_t1 if dummy == 2
ksmirnov test_stat, by(dummy)
gen test_stat2 = pcent_single_rav_t1 if dummy == 1
replace test_stat2 = pcent_single_eye_t1 if dummy == 2
ksmirnov test_stat2, by(dummy)
gen test_stat3 = pcent_twice_t1 if dummy == 1
replace test_stat3 = pcent_single_rav_t1 if dummy == 2
ksmirnov test_stat3, by(dummy)
gen test_stat4 = pcent_twice_t1 if dummy == 1
replace test_stat4 = pcent_single_eye_t1 if dummy == 2
ksmirnov test_stat4, by(dummy)
restore	   
	   
graph bar (mean) same_and_own ///
           (mean) same_referral, ///
    bargap(100) ///
    legend(ring(0) pos(2) order(1 2) label(1 "same_and_own") label(2 "same_referral") rows(2) size(small) region(lcolor(none) fcolor(none))) ///
    name(bar_1, replace) ///
    bar(1, color(eltblue%80)) ///
    bar(2, color(orange)) ///
    ylabel(0(0.5)3, angle(0)) ///
    ytitle("Percentage") ///
	$graph_opts
	
graph box same_and_own same_referral
	   
	   
	   
/////////
//# SELF-OWN REFERRALS -- TEMPLATE
/////////

// summarize same_and_own
// local min1 = r(min)
// local max1 = r(max)
// local n1 = r(N)
// summarize same_referral
// local min2 = r(min)
// local max2 = r(max)
// local n2 = r(N)
// local min = min(`min1',`min2')
// local max = max(`max1',`max2')
// local n = min(`n1',`n2')
// local width = 1  // Fixed wider width for bars
//
// twoway (histogram same_and_own, percent start(-0.5) width(`width') color(gs12)) ///
//        (histogram same_referral, percent start(-0.5) width(`width') fcolor(white%0) lcolor(gs4) lpattern(dash)), ///
//        xlabel(0(1)3) ///
//        xscale(range(-0.5 3.5)) ///
//        legend(ring(0) pos(11) order(1 2) label(1 "Inc. self-referrals") label(2 "Excl. self-referrals") rows(2) size(small) region(lcolor(none) fcolor(none))) ///
//        xtitle("Number of Common Referrals") ///
// 	   xsize(4) ///
//        ytitle("Percent") ///
//        $graph_opts ///
// 	   ylabel(, angle(0)) ///
//        name(ses_dist3, replace)	   
//	   
// 	   	graph export "/Users/reha.tuncer/Documents/GitHub/Inequality-Skills-and-Referrals/figures/ses_dist3.png", ///
//     replace
	   	   
tabulate same_and_own, matcell(freq1)
matrix pct1 = freq1 / r(N) * 100
tabulate same_referral, matcell(freq2)
matrix pct2 = freq2 / r(N) * 100
preserve 
clear
set obs 4
generate x = _n - 1
generate pct_self = .
generate pct_no_self = .

// Swap the percentage assignments
replace pct_self = 20.50 if x == 0     // Previously this was pct_no_self
replace pct_self = 26.86 if x == 1
replace pct_self = 38.04 if x == 2
replace pct_self = 14.60 if x == 3

replace pct_no_self = 13.35 if x == 0  // Previously this was pct_self
replace pct_no_self = 22.36 if x == 1
replace pct_no_self = 33.54 if x == 2
replace pct_no_self = 30.75 if x == 3

twoway (bar pct_self x, color(gs12) barwidth(0.8)) ///
       (bar pct_no_self x, fcolor(white%0) lcolor(gs4) lwidth(medthick) lpattern(dash) barwidth(0.8)), ///
       xlabel(0(1)3) ///
       xscale(range(-0.5 3.5)) ///
       legend(ring(0) pos(11) order(1 2) label(2 "Self-referrals") label(1 "No self-referrals") rows(2) size(small) region(lcolor(none) fcolor(none))) ///
       xtitle("Number of Common Referrals") ///
       xsize(4) ///
       ytitle("Percent") ///
       $graph_opts ///
       ylabel(0(10)40, angle(0)) ///
       name(ses_dist3, replace)

graph export "/Users/reha.tuncer/Documents/GitHub/Inequality-Skills-and-Referrals/figures/ses_dist3.png", ///
    replace		   
restore

preserve 
keep if same_and_own != .		   
local vars "same_and_own same_referral"
foreach v of local vars {
    sort `v'
    gen rank_`v' = _n/_N
}
twoway ///
(scatter rank_same_and_own same_and_own , ///
        msymbol(circle) ///
        msize(medlarge) ///
        mcolor(gs12) ///
        sort(rank_same_and_own) ///
        connect(none) ///
        lcolor(eltblue) ///
        lwidth(vthick)  ///
        lpattern(solid)) ///
    (scatter rank_same_referral same_referral , ///
        msymbol(circle) ///
        msize(medium) ///
        mcolor(gs4) ///
        connect(none) ///
        sort(rank_same_referral)), ///
    ylabel(0(.2)1, angle(0) format(%2.1f)) ///
    xlabel(0(1)3, format(%3.0f)) ///
    xsize(4) ///
    ytitle("Cumulative Probability") ///
    xtitle("Number of Common Referrals") ///
    legend(ring(0) pos(11) order(1 2) label(1 "Self-referrals") label(2 "No self-referrals") rows(2) size(small) region(lcolor(none) fcolor(none))) ///
    $graph_opts

    graph export "/Users/reha.tuncer/Documents/GitHub/Inequality-Skills-and-Referrals/figures/cdf2.png", ///
    replace
drop rank_*
restore	   
	   
	   
	   
////////


// Modified histogram with offset
twoway (histogram pcent_twice_t1, percent width(6) color(gs12)) ///
	   (histogram pcent_single_rav_t1, percent width(6) fcolor(none) lcolor(orange) ) ///
       (histogram pcent_single_eye_t1, percent width(6) fcolor(white%0) lpattern(dash) lcolor(gs4) lwidth(medthick)), ///
       legend(ring(0) pos(2) order(1 2 3)  label(1 "Common") label(2 "Unique Cognitive") label(3 "Unique Social") rows(3) size(small) region(lcolor(none) fcolor(none))) ///
       xtitle("Percent referral share") ///
       ytitle("Percent") ///
       ylabel(, angle(0)) ///
       xsize(4) ///
       $graph_opts ///
       name(ref_skill_baseline_all3, replace)

// Export the graph
graph export "/Users/reha.tuncer/Documents/GitHub/Inequality-Skills-and-Referrals/figures/ref_skill_baseline_all3.png", ///
    replace
	
// Generate fractional ranks for y-axis (cumulative probabilities)
local vars "pcent_twice_t1 pcent_single_rav_t1 pcent_single_eye_t1"
foreach v of local vars {
    sort `v'
    gen rank_`v' = _n/_N
}

twoway ///
    (scatter rank_pcent_single_rav_t1 pcent_single_rav_t1, ///
        msymbol(circle) ///
        msize(vsmall) ///
        mcolor(orange) ///
        connect(none) ///
        sort(rank_pcent_single_rav_t1)) ///
    (scatter rank_pcent_single_eye_t1 pcent_single_eye_t1, ///
        msymbol(circle) ///
        msize(vsmall) ///
        mcolor(gs4) ///
        sort(rank_pcent_single_eye_t1) ///
        connect(none)) ///
 (scatter rank_pcent_twice_t1 pcent_twice_t1, ///
        msymbol(none) ///
        msize(small) ///
        mcolor(eltblue) ///
        sort(rank_pcent_twice_t1) ///
        connect(J) ///
        lcolor(gs12) ///
        lwidth(thick) ///
        lpattern(solid)) ///
    , ///
    ylabel(0(.2)1, angle(0) format(%2.1f)) ///
    xlabel(0(20)60, format(%3.0f)) ///
    xsize(4) ///
    ytitle("Cumulative Probability") ///
    xtitle("Percent referral share") ///
    legend(ring(0) pos(3) order(3 1 2) ///
           label(3 "Common") ///
		   label(1 "Unique Cognitive") ///
           label(2 "Unique Social") ///
           rows(3) size(small) ///
           region(lcolor(none) fcolor(none))) ///
    $graph_opts

graph export "/Users/reha.tuncer/Documents/GitHub/Inequality-Skills-and-Referrals/figures/cdf3.png", ///
    replace

drop rank_*
	   
	   
	   
	   
	   
	   
	   
	   

	   
	   
	   
/////////
//# pcent_count_total by treatment	
/////////
summarize pcent_total_t1
local min1 = r(min)
local max1 = r(max)
local n1 = r(N)

summarize pcent_total_t2
local min2 = r(min)
local max2 = r(max)
local n2 = r(N)

local min = min(`min1',`min2')
local max = max(`max1',`max2')
local n = min(`n1',`n2')

local bins = min(sqrt(`n'),10*ln(`n')/ln(10))
local width = (`max'-`min')/`bins'

twoway (histogram pcent_total_t1, percent start(`min') width(`width') color(ebblue%40)) ///
       (histogram pcent_total_t2, percent start(`min') width(`width') color(maroon%40)), ///
       legend(ring(0) pos(2) order(1 2) label(1 "Baseline") label(2 "Quota") rows(2) size(small) region(lcolor(none) fcolor(none))) ///
xtitle("Referral share by treatment (%)") ///
ytitle("Percent") ///
$graph_opts ///
name(ref_dist_treat, replace)

/////////
//# pcent_count_total by skill	
/////////
summarize pcent_rav
local min1 = r(min)
local max1 = r(max)
local n1 = r(N)

summarize pcent_eye
local min2 = r(min)
local max2 = r(max)
local n2 = r(N)

local min = min(`min1',`min2')
local max = max(`max1',`max2')
local n = min(`n1',`n2')

local bins = min(sqrt(`n'),10*ln(`n')/ln(10))
local width = (`max'-`min')/`bins'

twoway (histogram pcent_total_t1, percent start(`min') width(`width') color(ebblue%40)) ///
       (histogram pcent_total_t2, percent start(`min') width(`width') color(maroon%40)), ///
       legend(ring(0) pos(2) order(1 2) label(1 "Cognitive") label(2 "Social") rows(2) size(small) region(lcolor(none) fcolor(none))) ///
xtitle("Referral share by skill (%)") ///
ytitle("Percent") ///
$graph_opts ///
name(skillref_dist, replace)

/////////
//# pcent_rav by treatment -- TEMPLATE
/////////
summarize pcent_rav_t1
local min1 = r(min)
local max1 = r(max)
local n1 = r(N)

summarize pcent_rav_t2
local min2 = r(min)
local max2 = r(max)
local n2 = r(N)

local min = min(`min1',`min2')
local max = max(`max1',`max2')
local n = min(`n1',`n2')

local bins = min(sqrt(`n'),10*ln(`n')/ln(10))
local width = (`max'-`min')/`bins'

twoway (histogram pcent_rav_t1, percent start(`min') width(`width') color(ebblue%40)) ///
       (histogram pcent_rav_t2, percent start(`min') width(`width') color(maroon%40)), ///
       legend(ring(0) pos(2) order(1 2) label(1 "Baseline") label(2 "Quota") rows(2) size(small) region(lcolor(none) fcolor(none))) ///
xtitle("Cognitive skill referral share by treatment (%)") ///
ytitle("Percent") ///
$graph_opts ///
name(ravref_dist, replace)

/////////
//# hses referrals by treatment -- TEMPLATE
/////////
summarize pcent_total_t1hses
local min1 = r(min)
local max1 = r(max)
local n1 = r(N)

summarize pcent_total_t2hses
local min2 = r(min)
local max2 = r(max)
local n2 = r(N)

local min = min(`min1',`min2')
local max = max(`max1',`max2')
local n = min(`n1',`n2')

local bins = min(sqrt(`n'),10*ln(`n')/ln(10))
local width = (`max'-`min')/`bins'

twoway (histogram pcent_total_t1hses, percent start(`min') width(`width') color(ebblue%40)) ///
       (histogram pcent_total_t2hses, percent start(`min') width(`width') color(maroon%40)), ///
       legend(ring(0) pos(2) order(1 2) label(1 "Baseline") label(2 "Quota") rows(2) size(small) region(lcolor(none) fcolor(none))) ///
xtitle("High SES referral share by treatment (%)") ///
ytitle("Percent") ///
$graph_opts ///
name(hses_dist, replace)

/////////
//# Referrals by SES -- TEMPLATE
/////////
summarize pcent_total_hses
local min1 = r(min)
local max1 = r(max)
local n1 = r(N)

summarize pcent_total_lses
local min2 = r(min)
local max2 = r(max)
local n2 = r(N)

local min = min(`min1',`min2')
local max = max(`max1',`max2')
local n = min(`n1',`n2')

local bins = min(sqrt(`n'),10*ln(`n')/ln(10))
local width = (`max'-`min')/`bins'

twoway (histogram pcent_total_t1hses, percent start(`min') width(`width') color(ebblue%40)) ///
       (histogram pcent_total_t2hses, percent start(`min') width(`width') color(maroon%40)), ///
       legend(ring(0) pos(2) order(1 2) label(1 "High-SES") label(2 "Low-SES") rows(2) size(small) region(lcolor(none) fcolor(none))) ///
xtitle("Referral share by referrer SES (%)") ///
ytitle("Percent") ///
ylabel(, angle(0)) ///
$graph_opts ///
name(ses_dist, replace)
	   
	   
/////////
//# Referrals by GUESSING -- TEMPLATE
/////////
summarize guess_ratio if ses == 0
local min1 = r(min)
local max1 = r(max)
local n1 = r(N)

summarize guess_ratio if ses == 1
local min2 = r(min)
local max2 = r(max)
local n2 = r(N)

local min = min(`min1',`min2')
local max = max(`max1',`max2')
local n = min(`n1',`n2')

local bins = min(sqrt(`n'),10*ln(`n')/ln(10))
local width = (`max'-`min')/10

twoway (histogram guess_ratio if ses == 0, percent start(`min') width(`width') color(ebblue%40)) ///
       (histogram guess_ratio if ses == 1, percent start(`min') width(`width') color(maroon%40)), ///
       legend(ring(0) pos(2) order(1 2) label(1 "High-SES") label(2 "Low-SES") rows(2) size(small) region(lcolor(none) fcolor(none))) ///
xtitle("Guessing ability to identify low-SES") ///
ytitle("Percent") ///
$graph_opts ///
name(guess_ratio, replace)

summarize hyper_ratio if ses == 0
local min1 = r(min)
local max1 = r(max)
local n1 = r(N)

summarize hyper_ratio if ses == 1
local min2 = r(min)
local max2 = r(max)
local n2 = r(N)

local min = min(`min1',`min2')
local max = max(`max1',`max2')
local n = min(`n1',`n2')

local bins = min(sqrt(`n'),10*ln(`n')/ln(10))
local width = (`max'-`min')/9

twoway (histogram hyper_ratio if ses == 0, percent start(`min') width(`width') color(ebblue%40)) ///
       (histogram hyper_ratio if ses == 1, percent start(`min') width(`width') color(maroon%40)), ///
       legend(ring(0) pos(2) order(1 2) label(1 "High-SES") label(2 "Low-SES") rows(2) size(small) region(lcolor(none) fcolor(none))) ///
xtitle("Guessing ability to identify low-SES") ///
ytitle("Percent") ///
$graph_opts ///
name(hyp_guess_ratio, replace)


/////////
//# Referrals by SELF-OWN REFERRALS -- TEMPLATE
/////////

summarize same_and_own
local min1 = r(min)
local max1 = r(max)
local n1 = r(N)
summarize same_referral
local min2 = r(min)
local max2 = r(max)
local n2 = r(N)
local min = min(`min1',`min2')
local max = max(`max1',`max2')
local n = min(`n1',`n2')
local width = 1  // Fixed wider width for bars

twoway (histogram same_and_own, percent start(-0.5) width(`width') color(ebblue%40)) ///
       (histogram same_referral, percent start(-0.5) width(`width') color(maroon%40)), ///
       xlabel(0(1)3) ///
       xscale(range(-0.5 3.5)) ///
       legend(ring(0) pos(11) order(1 2) label(1 "Inc. self-referrals") label(2 "Excl. self-referrals") rows(2) size(small) region(lcolor(none) fcolor(none))) ///
       xtitle("Number of overlapping referrals") ///
       ytitle("Percent") ///
       $graph_opts ///
	   ylabel(, angle(0)) ///
       name(ses_dist3, replace)
	   
summarize same_referral if treat == 1
local min1 = r(min)
local max1 = r(max)
local n1 = r(N)
summarize same_referral  if treat == 2
local min2 = r(min)
local max2 = r(max)
local n2 = r(N)
local min = min(`min1',`min2')
local max = max(`max1',`max2')
local n = min(`n1',`n2')
local width = 1  // Fixed wider width for bars

twoway (histogram same_referral if treat == 1, percent start(-0.5) width(`width') color(ebblue%40)) ///
       (histogram same_referral  if treat == 2, percent start(-0.5) width(`width') color(maroon%40)), ///
       xlabel(0(1)3) ///
       xscale(range(-0.5 3.5)) ///
       legend(ring(0) pos(11) order(1 2) label(1 "Baseline") label(2 "Quota") rows(2) size(small) region(lcolor(none) fcolor(none))) ///
       xtitle("Number of overlapping referrals") ///
       ytitle("Percent") ///
       $graph_opts ///
	   ylabel(, angle(0)) ///
       name(ses_dist, replace)	   

/////////
//# GUESSING RATIO's -- TEMPLATE
/////////

summarize guess_ratio if ses ==0
local min1 = r(min)
local max1 = r(max)
local n1 = r(N)

summarize guess_ratio if ses ==1
local min2 = r(min)
local max2 = r(max)
local n2 = r(N)

local min = min(`min1',`min2')
local max = max(`max1',`max2')
local n = min(`n1',`n2')

local bins = min(sqrt(`n'),10*ln(`n')/ln(10))
local width = (`max'-`min')/10

twoway (histogram guess_ratio if ses ==0, percent start(`min') width(`width') color(ebblue%40)) ///
       (histogram guess_ratio if ses ==1, percent start(`min') width(`width') color(maroon%40)), ///
       legend(ring(0) pos(2) order(1 2) label(1 "High-SES") label(2 "Low-SES") rows(2) size(small) region(lcolor(none) fcolor(none))) ///
xtitle("Guessing ability by SES") ///
ytitle("Percent") ///
$graph_opts ///
name(guess_ratio, replace)
	   
	   
// histograms	   
histogram strato, percent ///
    $graph_opts ///
    ylabel(, angle(0)) ///
	color(ebblue%40) ///
    xtitle("SES indicator (1-3 low and 4-6 high)") ///
    xlabel(1(1)6) ///
	ylabel(, angle(0)) ///
    xscale(range(1 6)) ///
    discrete addlabel ///
    name(strato, replace)

histogram same_referral, percent ///
    $graph_opts ///
	color(ebblue%40) ///
    ylabel(, angle(0)) ///
    xtitle("Number of overlapping referrals ") ///
    xlabel(0(1)3) ///
    xscale(range(0 3)) ///
    discrete addlabel ///
    name(same_referral, replace)
	

	
	
//
twoway (kdensity z_gpa if ses == 1 ,  lcolor(black) ) ///
(kdensity z_gpa if ses == 0,  lcolor(pink%60)  ), ///
ytitle("Density") ///
    xtitle("Standardized GPA") ///
    xlabel(-3(1)3) ///
    legend(ring(0) pos(2) order(1 2) label(1 "Low SES") label(2 "High SES") rows(2) size(small) region(lcolor(none) fcolor(none))) ///
    $graph_opts
ttest z_gpa, by(ses) unequal	

twoway (kdensity z_rav if ses == 1 ,  lcolor(black) ) ///
(kdensity z_rav if ses == 0,  lcolor(pink%60)  ), ///
ytitle("Density") ///
    xtitle("Standardized GPA") ///
    xlabel(-3(1)3) ///
    legend(ring(0) pos(2) order(1 2) label(1 "Low SES") label(2 "High SES") rows(2) size(small) region(lcolor(none) fcolor(none))) ///
    $graph_opts
ttest z_rav, by(ses) unequal	


//
twoway (kdensity guess_ratio if ses == 1 ,  lcolor(ebblue%80) ) ///
(kdensity  guess_ratio if ses == 0,  lcolor(maroon%80)  ), ///
ytitle("Density") ///
    xtitle("Ability to identify Low-SES") ///
    xlabel(0(1)4) ///
    legend(ring(0) pos(2) order(1 2) label(1 "Low-SES") label(2 "High-SES") rows(2) size(small) region(lcolor(none) fcolor(none))) ///
    $graph_opts
ttest  guess_ratio, by(ses) unequal

//

graph box pcent_count_rav_t1  pcent_count_rav_t2, horizontal $graph_opts
vioplot pcent_total_t1  pcent_total_t2, horizontal $graph_opts

// 
bysort net_class: egen max_study = max(fraction_study)
sum max_study, det













* First, create a unique classroom index
preserve
keep net_class
duplicates drop
gen class_index = _n
sort net_class
save temp_class_index, replace
restore

* Merge the index back to the main dataset
merge m:1 net_class using temp_class_index, nogen

* Now run the graph loop
foreach var of varlist z_gpa z_rav z_eye {
   
    * Preserve the original dataset
    preserve
    
    * Collapse the data to get mean by class_index and net_class
    collapse (mean) `var', by(class_index net_class)
    
    * Sort by the index
    sort class_index
   
    * Create variable name for title
    local vartitle = upper(substr("`var'", 3, .))
   
    * Create the bar graph with sorted values
    graph bar `var', over(class_index, gap(100) label(labsize(vsmall))) ///
        title("Classroom Average `vartitle'") ///
        ytitle("Standardized `vartitle' (z-score)") ///
        blabel(bar, format(%9.2f)angle(45) size(vsmall)) ///
        yscale(range(-1.25 1.25)) ylabel(-1.25(.5)1.25) ///
        scheme(s1color)
   
    * Save the graph
    graph export "/Users/reha.tuncer/Documents/GitHub/Inequality-Skills-and-Referrals/figures/`var'_by_class.png", replace
   
    * Restore the original dataset
    restore
   
}

* Clean up
capture erase temp_class_index.dta





twoway (lpolyci z_gpa pcent_count_rav_t1 if pcent_count_rav_t1<=60, degree(1) bwidth(20) lcolor(blue) lwidth(thick) ///
        ciplot(rline) clpattern(dash) clcolor(blue%30)) ///
       (lpolyci z_rav pcent_count_rav_t1 if pcent_count_rav_t1<=60, degree(1) bwidth(20) lcolor(red) lwidth(thick) ///
        ciplot(rline) clpattern(dash) clcolor(red%30)), ///
       ylabel(-2(1)2, grid) ///
       ytitle("Standardized score") ///
       xtitle("Share of referrals at Baseline (%)") ///
       legend(ring(0) pos(11) rows(2) order(1 "GPA" 3 "Cognitive score")) ///
       title("Cognitive") ///
       name(cog, replace) nodraw $graph_opts

twoway (lpolyci z_gpa pcent_count_eye_t1 if pcent_count_eye_t1<=60, degree(1) bwidth(20) lcolor(blue) lwidth(thick) ///
        ciplot(rline) clpattern(dash) clcolor(blue%30)) ///
       (lpolyci z_eye pcent_count_eye_t1 if pcent_count_eye_t1<=60, degree(1) bwidth(20) lcolor(green) lwidth(thick) ///
        ciplot(rline) clpattern(dash) clcolor(green%30)), ///
       ylabel(-2(1)2, grid) ///
       ytitle("Standardized score") ///
       xtitle("Share of referrals at Baseline (%)") ///
       legend(ring(0) pos(11) rows(2) order(1 "GPA" 3 "Social score")) ///
       title("Social") ///
       name(soc, replace) nodraw $graph_opts

graph combine cog soc, xcommon ycommon
graph export "/Users/reha.tuncer/Documents/GitHub/Inequality-Skills-and-Referrals/figures/gpa_scores_desc.png", replace



* Generate top 3 indicator variables
gen top3cog = (rank_rav_class <= 3)*100
gen top3soc = (rank_eye_class <= 3)*100


preserve
twoway (lpolyci top3cog pcent_count_rav_t1 if pcent_count_rav_t1 <= 60, degree(1) bwidth(20) ///
        lcolor(blue) lwidth(thick) ciplot(rline) clpattern(dash) clcolor(blue%30)) ///
       (lpolyci top3cog pcent_count_rav_t2 if pcent_count_rav_t2 <= 60, degree(1) bwidth(20) ///
        lcolor(red) lwidth(thick) ciplot(rline) clpattern(dash) clcolor(red%30)), ///
       ylabel(0(.2)1, grid) ///
       ytitle("Probability of Top 3 Ranking") ///
       xtitle("Share of referrals (%)") ///
       legend(ring(0) pos(11) rows(2) order(1 "Baseline" 3 "Quota")) ///
       title("Cognitive") ///
       name(cog_top3, replace) nodraw $graph_opts
restore


preserve
twoway (lpolyci top3soc pcent_count_eye_t1 if pcent_count_eye_t1 <= 60, degree(1) bwidth(20) ///
        lcolor(blue) lwidth(thick) ciplot(rline) clpattern(dash) clcolor(blue%30)) ///
       (lpolyci top3soc pcent_count_eye_t2 if pcent_count_eye_t2 <= 60, degree(1) bwidth(20) ///
        lcolor(red) lwidth(thick) ciplot(rline) clpattern(dash) clcolor(red%30)), ///
       ylabel(0(.2)1, grid) ///
       ytitle("Probability of Top 3 Ranking") ///
       xtitle("Share of referrals (%)") ///
       legend(ring(0) pos(11) rows(2) order(1 "Baseline" 3 "Quota")) ///
       title("Social") ///
       name(soc_top3, replace) nodraw $graph_opts
restore
graph combine cog_top3 soc_top3 , xcommon ycommon
graph export "/Users/reha.tuncer/Documents/GitHub/Inequality-Skills-and-Referrals/figures/top3_cogsoc.png", replace


preserve
expand 2
bysort net_id: gen treat_dummy = _n
label define tlabel 1 "Baseline" 2 "Quota"
label values treat_dummy tlabel
// rav
gen pcent_ravens = pcent_count_rav_t1 if treat_dummy == 1
replace pcent_ravens = pcent_count_rav_t2 if treat_dummy == 2
// eye
gen pcent_rmet = pcent_count_eye_t1 if treat_dummy == 1
replace pcent_rmet = pcent_count_eye_t2 if treat_dummy == 2
//
ksmirnov pcent_ravens, by(treat_dummy)
ksmirnov pcent_rmet, by(treat_dummy)
restore



