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
capture noisily use "cleaning/referrals_wide.dta"
if _rc != 0 {
    use "referrals_wide.dta"
}
drop if z_gpa == . // students with gpa missing --> 2 classes premed school
drop if net_class == 22000 // 1 student
drop if net_class == 7000 // 3 students

tabstat guess_ratio guess_ratio12 guess_ratio3 guess_ratio4 guess_ratio56, by(ses) stat(mean )
tabstat top3lses_rav top3lses_eye top3lses_gpa, by(net_class)

tabstat z_gpa, by(ses_dummy) stat(mean )

expand 2
bysort net_id: gen treat_dummy = _n
label define tlabel 1 "Baseline" 2 "Treat"
label values treat_dummy tlabel


// all
gen pcent_all = pcent_total_t1 if treat_dummy == 1
replace pcent_all = pcent_total_t2 if treat_dummy == 2
// rav
gen pcent_ravens = pcent_rav_t1 if treat_dummy == 1
replace pcent_ravens = pcent_rav_t2 if treat_dummy == 2
// eye
gen pcent_rmet = pcent_eye_t1 if treat_dummy == 1
replace pcent_rmet = pcent_eye_t2 if treat_dummy == 2

// referrals from by top vs low skill performance
gen pcent_ravens_top = pcent_rav_t1_top if treat_dummy == 1 
replace pcent_ravens_top = pcent_rav_t2_top if treat_dummy == 2 
gen pcent_ravens_low = pcent_rav_t1_low if treat_dummy == 1 
replace pcent_ravens_low = pcent_rav_t2_low if treat_dummy == 2 
gen pcent_rmet_top = pcent_eye_t1_top if treat_dummy == 1 
replace pcent_rmet_top = pcent_eye_t2_top if treat_dummy == 2 
gen pcent_rmet_low = pcent_eye_t1_low if treat_dummy == 1 
replace pcent_rmet_low = pcent_eye_t2_low if treat_dummy == 2 

// single - double ref
gen pcent_single_rav = pcent_single_rav_t1 if treat_dummy == 1 
replace pcent_single_rav = pcent_single_rav_t2 if treat_dummy == 2
gen pcent_single_eye = pcent_single_eye_t1 if treat_dummy == 1 
replace pcent_single_eye = pcent_single_eye_t2 if treat_dummy == 2
gen pcent_twice = pcent_twice_t1 if treat_dummy == 1 
replace pcent_twice = pcent_twice_t2 if treat_dummy == 2

// referrals by ses
gen pcent_rich = pcent_total_t1hses if treat_dummy == 1 
replace pcent_rich = pcent_total_t2hses if treat_dummy == 2 
gen pcent_poor = pcent_total_t1lses if treat_dummy == 1 
replace pcent_poor = pcent_total_t2lses if treat_dummy == 2 

// referrals by guessing ability
gen pcent_high = pcent_t1_high if treat_dummy == 1 
replace pcent_high = pcent_t2_high if treat_dummy == 2 
gen pcent_low = pcent_t1_low if treat_dummy == 1 
replace pcent_low = pcent_t2_low if treat_dummy == 2 

// referrals by guessing ability
gen pcent_rich_hg = pcent_t1hseshg if treat_dummy == 1 
replace pcent_rich_hg = pcent_t2hseshg if treat_dummy == 2 
gen pcent_poor_hg = pcent_t1lseshg if treat_dummy == 1 
replace pcent_poor_hg = pcent_t2lseshg if treat_dummy == 2 

gen pcent_rich_lg = pcent_t1hseslg if treat_dummy == 1 
replace pcent_rich_lg = pcent_t2hseslg if treat_dummy == 2 
gen pcent_poor_lg = pcent_t1lseslg if treat_dummy == 1 
replace pcent_poor_lg = pcent_t2lseslg if treat_dummy == 2 


// TREATMENT VS BASELINE

// Peers are good at identifying skills?
reg pcent_ravens i.treat_dummy##c.z_rav i.treat_dummy##i.ses, vce(cluster net_class)
est store cog1
reg pcent_rmet i.treat_dummy##c.z_eye i.treat_dummy##i.ses , vce(cluster net_class)   
est store soc1
esttab cog1,  b(%12.3f) se(%12.3f) r2 nobaselevels label mtitles star(* 0.10 ** 0.05 *** 0.01) // MARGINALLY TRUE FOR COGNITIVE SKILLS
esttab soc1,  b(%12.3f) se(%12.3f) r2 nobaselevels label mtitles star(* 0.10 ** 0.05 *** 0.01) // NOT TRUE FOR SOCIAL SKILLS


// Do better skills mean better referrals?  ---> NOT MAIN RESULT
qui reg pcent_ravens_top i.treat_dummy##c.z_rav i.treat_dummy##i.ses, vce(cluster net_class)
est store cog_top
qui reg pcent_rmet_top i.treat_dummy##c.z_eye i.treat_dummy##i.ses, vce(cluster net_class)
est store soc_top
esttab cog_top cog1,  b(%12.3f) se(%12.3f) r2 nobaselevels label mtitles star(* 0.10 ** 0.05 *** 0.01) // NOT FOR COGNITIVE SKILLS
esttab soc_top soc1,  b(%12.3f) se(%12.3f) r2 nobaselevels label mtitles star(* 0.10 ** 0.05 *** 0.01) // TRUE FOR SOCIAL SKILLS

// // Do peers identify good students as a proxy for skills (with GPA)?
reg pcent_ravens i.treat_dummy##c.z_rav i.treat_dummy##c.z_gpa i.treat_dummy##i.ses, vce(cluster net_class)
est store cog4
reg pcent_rmet i.treat_dummy##c.z_eye i.treat_dummy##c.z_gpa i.treat_dummy##i.ses, vce(cluster net_class)
est store soc4
esttab cog1 cog4,  b(%12.3f) se(%12.3f) r2 nobaselevels label mtitles star(* 0.10 ** 0.05 *** 0.01) // MARGINALLY TRUE FOR COGNITIVE SKILLS
esttab soc1 soc4,  b(%12.3f) se(%12.3f) r2 nobaselevels label mtitles star(* 0.10 ** 0.05 *** 0.01) // TRUE FOR COGNITIVE SKILLS

////
reg pcent_ravens i.ses#i.treat_dummy i.treat_dummy#c.z_gpa#i.ses i.treat_dummy#c.z_rav#i.ses, vce(cluster net_class) // ER. reg


// Are double referrals better in GPA but not skills?
qui reg pcent_single_rav i.treat_dummy##c.z_rav i.treat_dummy##c.z_gpa i.treat_dummy##i.ses , vce(cluster net_class)
est store cog_single
qui reg pcent_single_eye i.treat_dummy##c.z_eye i.treat_dummy##c.z_gpa i.treat_dummy##i.ses  , vce(cluster net_class)
est store soc_single
qui reg pcent_twice i.treat_dummy##c.z_rav i.treat_dummy##c.z_gpa i.treat_dummy##i.ses  , vce(cluster net_class)
est store twice_cog
qui reg pcent_twice i.treat_dummy##c.z_eye i.treat_dummy##c.z_gpa i.treat_dummy##i.ses  , vce(cluster net_class)
est store twice_soc
esttab cog4 cog_single twice_cog,  b(%12.3f) se(%12.3f) r2 nobaselevels label mtitles star(* 0.10 ** 0.05 *** 0.01) // TRUE FOR COGNITIVE SKILLS
esttab soc4 soc_single twice_soc,  b(%12.3f) se(%12.3f) r2 nobaselevels label mtitles star(* 0.10 ** 0.05 *** 0.01) // TRUE FOR SOCIAL SKILLS


// relationship between gpa and skills
qui reg pcent_all i.treat_dummy##c.z_gpa i.treat_dummy##i.ses, vce(cluster net_class)
est store all_ses
esttab all_ses,  b(%12.3f) se(%12.3f) r2 nobaselevels label mtitles star(* 0.10 ** 0.05 *** 0.01)

// RICH REFER POOR WHEN IN BASELINE, NOT IN QUOTA
qui reg pcent_rich i.treat_dummy##c.z_gpa i.treat_dummy##i.ses  , vce(cluster net_class)
est store ref_by_hses
qui reg pcent_poor i.treat_dummy##c.z_gpa i.treat_dummy##i.ses, vce(cluster net_class)
est store ref_by_lses
esttab ref*,  b(%12.3f) se(%12.3f) r2 nobaselevels label mtitles star(* 0.10 ** 0.05 *** 0.01)

// RICH REFER POOR WHEN IN BASELINE, NOT IN QUOTA
qui reg pcent_high i.treat_dummy##i.ses c.z_gpa, vce(cluster net_class)
est store high_guess
qui reg pcent_low i.treat_dummy##i.ses c.z_gpa, vce(cluster net_class)
est store low_guess
esttab *_guess,  b(%12.3f) se(%12.3f) r2 nobaselevels label mtitles star(* 0.10 ** 0.05 *** 0.01)

// QUOTA, RICH WHO CAN ID INCREASE LOWSES REFERRALS
qui reg pcent_rich_hg i.treat_dummy##i.ses c.z_gpa, vce(cluster net_class)
est store rich_hg
qui reg pcent_rich_lg i.treat_dummy##i.ses c.z_gpa, vce(cluster net_class)
est store rich_lg
qui reg pcent_poor_hg i.treat_dummy##i.ses c.z_gpa, vce(cluster net_class)
est store poor_hg
qui reg pcent_poor_lg i.treat_dummy##i.ses c.z_gpa, vce(cluster net_class)
est store poor_lg
esttab rich_* poor_*,  b(%12.3f) se(%12.3f) r2 nobaselevels label mtitles star(* 0.10 ** 0.05 *** 0.01)


