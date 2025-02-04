/*******************************************************************************
    Project: SIR - regression analysis
    Author: Reha Tuncer
    Date: 25.07.2024
    Description: Rerforms a regression analysis from referrer POV
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


//# correlation matrix
pwcorr z_gpa z_gpa_other z_rav z_rav_other z_eye z_eye_other z_test z_test_other if task != 3 & !self_referral, sig star(.05) bonferroni


//# are gpa of referrals much better?
foreach var in gpa  {
    display _newline "----------------------------------------"
	display _newline "Analysis for z_`var' and z_`var'_other"
    display _newline "----------------------------------------"
    
    quietly sum z_`var' if id_count == 1
    local t_m1 = r(mean)
    local t_sd1 = r(sd)
    local t_n1 = r(N)
    
    quietly sum z_`var'_other if task != 3 & !self_referral
    local t_m2 = r(mean)
    local t_sd2 = r(sd)
    local t_n2 = r(N)
    
    display _newline "T-test results: z_`var' and z_`var'_other"
    ttesti `t_n1' `t_m1' `t_sd1' `t_n2' `t_m2' `t_sd2'
	
}

/***
//# create single variables fraction of low-ses classmates

// gen fraction_lses_p50 = fraction_lses_p50_z_rav if task == 1
// replace fraction_lses_p50 = fraction_lses_p50_z_eye if task == 2 
//
// gen fraction_lses_p75 = fraction_lses_p75_z_rav if task == 1
// replace fraction_lses_p75 = fraction_lses_p75_z_eye if task == 2 
//
// gen difference = difference_z_rav if task == 1
// replace difference = difference_z_eye if task == 2
//
// gen difference_p50 = difference_p50_z_rav if task == 1
// replace difference_p50 = difference_p50_z_eye if task == 2
//
// gen difference_p75 = difference_p75_z_rav if task == 1
// replace difference_p75 = difference_p75_z_eye if task == 2
***/
/*===========================================================================*/
//# regression
/*===========================================================================*/

//# drop guesses and self-referrals and focus on baseline
keep if task != 3 & !self_referral 
bysort net_id: gen counter = _n

preserve
keep if task==1
tabstat z_gpa_other z_rav_other z_eye_other ses_other, stat (mean sd n)
restore
preserve
keep if task==2
tabstat z_gpa_other z_rav_other z_eye_other ses_other, stat (mean sd n)
restore

gen pcent_lses = 100*fraction_lses
preserve
keep if treat == 1
reg ses_other c.z_gpa_other i.ses_dummy c.pcent_lses, vce(cluster net_id)
est store baseline
restore
preserve
keep if treat == 2
reg ses_other c.z_gpa_other  i.ses_dummy c.pcent_lses, vce(cluster net_id)
est store quota
restore 
esttab baseline quota,  b(%12.3f) se(%12.3f) r2 nobaselevels label mtitles

// i dont need FE because GPA_OTHER is not correlated more than GPA between classes:
reghdfe z_gpa , absorb(net_class) vce(cluster net_id) // test 1
reghdfe z_gpa_other , absorb(net_class) vce(cluster net_id) // test 2


// IS GPA A BETTER PREDICTOR FOR OVERLAPPING REF
tabstat z_gpa_other z_rav_other z_eye_other if same_referral < 1,  stat(mean sd n)
tabstat z_gpa_other z_rav_other z_eye_other if same_referral >= 1,  stat(mean sd n)

preserve
keep if same_referral >= 2 & treat == 1
reg z_gpa_other c.z_gpa, vce(cluster net_id)
est store gpa_overlap
restore
preserve
keep if same_referral < 2 & treat == 1
reg z_gpa_other c.z_gpa, vce(cluster net_id)
est store gpa_unique
restore
esttab gpa_overlap gpa_unique,  b(%12.3f) se(%12.3f) r2 nobaselevels


// homophily in GPA
reg z_gpa_other c.z_gpa, vce(cluster net_id)
est store gpa1
reg z_gpa_other c.z_gpa i.treat, vce(cluster net_id)
est store gpa2
reg z_gpa_other c.z_gpa##i.treat, vce(cluster net_id)
est store gpa3
margins, at(z_gpa=(-1(0.5)1) treat=(1 2) )
marginsplot, name(m1, replace)
esttab  gpa*,  b(%12.3f) se(%12.3f) r2 nobaselevels

// homophily in SES
gen pcent_lses = 100*fraction_lses
// linear first
reg ses_other i.ses, vce(cluster net_id)
est store ses1
reg ses_other i.ses c.pcent_lses, vce(cluster net_id)
est store ses2
reg ses_other i.ses c.pcent_lses c.z_guess_ratio , vce(cluster net_id)
est store ses3
reg ses_other i.ses c.pcent_lses c.z_guess_ratio  i.treat, vce(cluster net_id)
est store ses4
margins, at(pcent_lses=(20(30)100) treat=(1 2) z_guess_ratio=(-1 2) )
marginsplot, name(m1, replace)
esttab  ses*,  b(%12.3f) se(%12.3f) r2 nobaselevels
reghdfe ses_other i.ses c.pcent_lses c.z_guess_ratio  i.treat, absorb(net_class) vce(cluster net_id)

// corelates
// i.same_study c.z_test  i.task i.first_gen  i.gender i.ethnic i.rural c.age c.semester

//# linear models
//# FGLS estimator for population-averaged model
xtset net_class
xtreg ses_other c.z_gpa c.z_test i.ses i.treat c.z_guess_ratio , pa corr(exchangeable) vce(robust)
est store pa
//# re
xtreg ses_other c.z_gpa c.z_test i.ses i.treat c.z_guess_ratio, re vce(robust)
est store re
//# fe
xtreg ses_other c.z_gpa c.z_test i.ses i.treat c.z_guess_ratio, fe vce(robust)
est store fe
//fe2
reghdfe ses_other c.z_gpa c.z_test i.ses i.treat c.z_guess_ratio, absorb(net_class)
est store fe2
//# hierhical 
mixed ses_other c.z_gpa c.z_test i.ses i.treat c.z_guess_ratio || net_class: || net_id:, mle difficult vce(cluster net_class)
est store hm
//# reg
reg ses_other c.z_gpa c.z_test i.ses i.treat c.z_guess_ratio, vce(cluster net_class)
est store base
est tab pa re base fe fe2 hm, star(.1 .05 .01) stats(r2 N) 



// logistic
// dropping observations with missing z_test
gen sample_flag = !missing(z_test, z_gpa, ses_other, fraction_lses, fraction_lses_p75_z_test, fraction_lses_p75_z_gpa, treat, z_guess_ratio, same_study)

// Full model
melogit ses_other c.fraction_lses c.fraction_lses_p75_z_test c.fraction_lses_p75_z_gpa c.z_test##c.z_gpa##i.ses i.treat c.z_guess_ratio i.same_study if sample_flag || net_class: || net_id:, difficult
estimates store full_model

// Reduced model
melogit ses_other c.fraction_lses c.fraction_lses_p75_z_gpa c.z_gpa##i.ses i.treat c.z_guess_ratio i.same_study if sample_flag || net_class: || net_id:, difficult
estimates store reduced_model

* likelihood ratio test
lrtest full_model reduced_model // keep reduced model

melogit ses_other c.fraction_lses c.fraction_lses_p75_z_gpa c.z_gpa##i.ses i.treat c.z_guess_ratio i.same_study  c.z_test i.task i.first_gen  i.gender i.ethnic i.rural c.age c.semester || net_class: || net_id:, difficult vce(cluster net_class)
estimates store reduced_model
predict xb, xb
predict pr, pr
estat ic
estat group
estat icc
estat sd
margins, at ( z_gpa=(-2(0.5)2) ses=(0 1))
marginsplot, name(m1, replace)
melogit ses_other c.fraction_lses c.z_gpa_other##i.ses i.treat i.task || net_class: || net_id:
mixed ses_other c.fraction_lses c.z_gpa##i.ses i.treat i.task || net_class: || net_id:


// plot margins --> with interactions, worse gpa = refer more to in-group
logit ses_other c.fraction_lses c.fraction_lses_p75_z_gpa c.z_gpa##i.ses i.treat##i.ses i.task c.z_guess_ratio i.same_study , vce(cluster net_id )
estimates store test1
margins, at(z_gpa=(-2(0.5)2) ses=(0 1) )
marginsplot, name(m1, replace)

reg ses_other c.fraction_lses c.z_gpa##i.ses i.treat i.task, vce(cluster net_id net_class)
estimates store test1
margins, at(z_gpa=(-2(0.5)2) ses=(0 1))
marginsplot, name(model2, replace)






// choose which fraction of low-ses
reg ses_other c.fraction_lses c.fraction_lses_p50_z_gpa c.fraction_lses_p50_z_test  i.task i.ses i.treat , vce(cluster net_id)
estimates store all1
reg ses_other c.fraction_lses c.fraction_lses_p50  i.task i.ses i.treat , vce(cluster net_id)
estimates store med_skill
reg ses_other c.fraction_lses c.fraction_lses_p50_z_gpa i.task i.ses i.treat , vce(cluster net_id)
estimates store med_gpa
reg ses_other c.fraction_lses c.fraction_lses_p50_z_test i.task i.ses i.treat , vce(cluster net_id)
estimates store med_test

reg ses_other c.fraction_lses c.fraction_lses_p75_z_gpa c.fraction_lses_p75_z_test  i.task i.ses i.treat , vce(cluster net_id)
estimates store all2
reg ses_other c.fraction_lses c.fraction_lses_p75 i.task i.ses i.treat , vce(cluster net_id)
estimates store top_skill
reg ses_other c.fraction_lses c.fraction_lses_p75_z_gpa i.task i.ses i.treat , vce(cluster net_id)
estimates store top_gpa
reg ses_other c.fraction_lses c.fraction_lses_p75_z_test i.task i.ses i.treat , vce(cluster net_id)
estimates store top_test

estimates table all1 med*, star(.1 .05 .01) stats(r2 N) 
estimates table all2 top*, star(.1 .05 .01) stats(r2 N) 


// choose which difference in scores between ses

reg ses_other c.fraction_lses c.difference c.difference_z_gpa c.difference_z_test i.task i.ses i.treat , vce(cluster net_id)
estimates store all_diff
reg ses_other c.fraction_lses c.difference_p50 c.difference_p50_z_gpa c.difference_p50_z_test i.task i.ses i.treat , vce(cluster net_id)
estimates store med_diff
reg ses_other c.fraction_lses c.difference_p75 c.difference_p75_z_gpa c.difference_p75_z_test i.task i.ses i.treat , vce(cluster net_id)
estimates store top_diff
estimates table all_diff med_diff top_diff, star(.1 .05 .01) stats(r2 N) 

// predict probability of referring a low ses

logistic ses_other i.same_semester c.fraction_lses c.fraction_lses_p50_z_gpa c.difference_z_gpa i.task i.ses i.treat , vce(cluster net_id)
estimates store all_diff2
margins ses, at(fraction_lses=(0(0.2)1))
marginsplot, name(model1, replace)



// esttab rav eye , b(%9.3f) p(%9.3f) star(* 0.1 ** 0.05 *** 0.01) r2


//# test predict gpa
reghdfe z_gpa_other c.z_gpa c.z_test c.z_rav c.z_eye , absorb(net_class)
estimates store gpa_other
reghdfe z_test_other c.z_gpa c.z_test c.z_rav c.z_eye , absorb(net_class)
estimates store exam_other
reghdfe z_rav_other c.z_gpa c.z_test c.z_rav c.z_eye , absorb(net_class)
estimates store rav_other
reghdfe z_eye_other c.z_gpa c.z_test c.z_rav c.z_eye , absorb(net_class)
estimates store eye_other
estimates table gpa_other exam_other rav_other eye_other, star(.1 .05 .01) stats(r2 N) 
