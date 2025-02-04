/*******************************************************************************
    Project: SIR - figure referral rate by SES
    Author: Reha Tuncer
    Date: 15.10.2024
    Description: Create figure
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

// drop guesses and self-referrals
keep if task != 3 & !self_referral

// Calculate required percentages
sum ses
gen overall_low_ses = r(mean) * 100

// Calculate referrals by SES and treatment
foreach t in 1 2 {
    sum ses_other if treat == `t'
    gen low_ses_ref_t`t' = r(mean) * 100
    
    foreach s in 0 1 {
        sum ses_other if ses == `s' & treat == `t'
        gen low_ses_ref_`=cond(`s'==1, "low", "high")'_t`t' = r(mean) * 100
    }
}

// Create positioning variables
forvalues i = 1/7 {
    gen pos`i' = cond(`i'==1, 1, cond(`i'==2, 3, cond(`i'==3, 3.8, cond(`i'==4, 6, cond(`i'==5, 6.8, cond(`i'==6, 9, 9.8))))))
}

// Calculate confidence intervals
foreach t in 1 2 {
    ci means ses_other if treat == `t'
    gen m`t' = r(mean)*100
    gen lb`t' = r(lb)*100
    gen ub`t' = r(ub)*100
    
    foreach s in 0 1 {
        local sname = cond(`s'==1, "low", "high")
        ci means ses_other if ses == `s' & treat == `t'
        gen m_`sname'_t`t' = r(mean)*100
        gen lb_`sname'_t`t' = r(lb)*100
        gen ub_`sname'_t`t' = r(ub)*100
    }
}

// Create the graph
twoway ///
    (bar overall_low_ses pos1, barw(0.8) color(gs6)) ///
    (bar low_ses_ref_t1 pos2, barw(0.8) color(gs12)) ///
    (bar low_ses_ref_t2 pos3, barw(0.8) color(gs8)) ///
    (bar low_ses_ref_low_t1 pos4, barw(0.8) color(gs12)) ///
    (bar low_ses_ref_low_t2 pos5, barw(0.8) color(gs8)) ///
    (bar low_ses_ref_high_t1 pos6, barw(0.8) color(gs12)) ///
    (bar low_ses_ref_high_t2 pos7, barw(0.8) color(gs8)) ///
    (rcap lb1 ub1 pos2, color(black) lwidth(thin)) ///
    (rcap lb2 ub2 pos3, color(black) lwidth(thin)) ///
    (rcap lb_low_t1 ub_low_t1 pos4, color(black) lwidth(thin)) ///
    (rcap lb_low_t2 ub_low_t2 pos5, color(black) lwidth(thin)) ///
    (rcap lb_high_t1 ub_high_t1 pos6, color(black) lwidth(thin)) ///
    (rcap lb_high_t2 ub_high_t2 pos7, color(black) lwidth(thin)), ///
    ylabel(0(10)60, angle(0)) ///
    ytitle("Percentage") ///
    xtitle("") ///
    title("") ///
    xlabel(1 "Sample" 3.4 "All Referrals" 6.4 "by Low-SES" 9.4 "by High-SES", angle(0) labsize(vsmall)) ///
    text(5 1 "`=string(overall_low_ses, "%9.1f")'", color(black) size(small)) ///
    text(5 3 "`=string(low_ses_ref_t1, "%9.1f")'", color(black) size(small)) ///
    text(5 3.8 "`=string(low_ses_ref_t2, "%9.1f")'", color(black) size(small)) ///
    text(5 6 "`=string(low_ses_ref_low_t1, "%9.1f")'", color(black) size(small)) ///
    text(5 6.8 "`=string(low_ses_ref_low_t2, "%9.1f")'", color(black) size(small)) ///
    text(5 9 "`=string(low_ses_ref_high_t1, "%9.1f")'", color(black) size(small)) ///
    text(5 9.8 "`=string(low_ses_ref_high_t2, "%9.1f")'", color(black) size(small)) ///
	legend(order(2 3) label(2 "Baseline Treatment") label(3 "Quota Treatment") rows(1) size(small)) ///
    graphregion(color(white)) plotregion(lcolor(black)) ///
    name(combined_graph, replace)

graph export "combined_low_ses_referrals_graph.png", replace width(1200) height(800)

// Perform pr-test
prtest ses_other if task != 3, by(ses)
local pval = r(p)
local pval_rounded_t = round(`pval', 0.0001)     
local text = cond(`pval_rounded_t' < 0.001, "pr-test {it:p} < 0.001", "pr-test {it:p} = " + string(`pval_rounded_t', "%9.3f"))

// text(5 3.4 "`text'", size(small)) ///
