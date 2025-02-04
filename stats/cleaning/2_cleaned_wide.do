/*******************************************************************************
    Project: Skills inequality referrals
    Author: Reha Tuncer
    Date: 17.07.2024
    Description: This do-file creates the cleaned wide dataset
*******************************************************************************/


//# preamble
version 18
clear all
macro drop _all
set more off
set scheme s2color, permanently
set maxvar 32767

// Get the current working directory
local current_dir `c(pwd)'
global root_dir "`current_dir'"

// Set other directories using the global macro
global admin "$root_dir/Admin_database/NotAnonimized"

//# import admin data
clear all
import delimited "$admin/data_admin.csv"
save "$admin/admin.dta", replace

//# merge & save
merge 1:1 net_id using "qualtrics_merge.dta"
save "cleaned.dta", replace

//# clean up admin data gender
clear all
use "cleaned.dta"
gen gender_int = .
replace gender_int = 0 if lower(female) == "male"
replace gender_int = 1 if lower(female) == "female"
label define glabel 0 "Male" 1 "Female"
label values gender_int glabel

//# keep necessary variables only
keep programa gender_int age net_id net_class gpa ethnic rural scholarship escuela semester score_* test_score perc_score finished strato  ravens_beliefs_1 eye_beliefs_1 referrals_ravens referrals_eye guesses_ses class_size treat duration_min rav_sum eye_sum ses first_gen difference* fraction* z* rank* multiple_participation observed_classmates fraction_lses  fraction_ses12 count_low_ses ses_dummy

//# rename, order and label all variables
rename programa study
label variable study "Study Program"

label variable gpa "GPA"

rename gender_int gender
label variable gender "Gender"

label variable net_id "Unique ID"
label variable net_class "Classroom ID"

label variable ethnic "Ethnic Minority"
label define elabel 0 "Majority" 1 "Minority"
label values ethnic elabel

label variable rural "Rural Community"
label define rlabel 0 "Urban" 1 "Rural"
label values rural rlabel

label variable scholarship "Scholarship Status"
label define slabel 0 "Self-Funded" 1 "Scholarship"
label values scholarship slabel

rename escuela faculty
label variable faculty "UNAB Faculty"

label variable semester "Current semester"

rename score_reading reading
label variable reading "Percentage Reading Score in the National University Entry Exam"

rename score_math math
label variable math "Percentage Math Score in the National University Entry Exam"

rename score_social social
label variable social "Percentage Social Sciences Score in the National University Entry Exam"

rename score_science science
label variable science "Percentage Natural Sciences Score in the National University Entry Exam"

rename score_english english
label variable english "Percentage English Score in the National University Entry Exam"

label variable test_score "Percentage Total Score in the National University Entry Exam"
label variable perc_score "Percentile ranking in the National University Entry Exam"

label variable finished "Completed Experiment"

label variable strato "SES indicator (1-3 lower and 4-6 higher)"

rename ravens_beliefs_1 rav_belief
label variable rav_belief "n/10 of participants believed to score worse than participant in Ravens"
rename eye_beliefs_1 eye_belief
label variable eye_belief "n/10 of participants believed to score worse than participant in MRMET"

label variable referrals_ravens "3 referrals for Ravens by Unique ID's"
label variable referrals_eye "3 referrals for RMET by Unique ID's"
label variable guesses_ses "3 low-ses guesses by Unique ID's"

label variable class_size "Classroom size"

sort net_id
order net_id net_class treat ses referrals_ravens rav_belief referrals_eye guesses_ses eye_belief 

//# Fix math and test scores
replace math = . if math==364
replace test_score = . if inlist(test_score, 136, 136.5, 100)

//# standardize GPA and TEST
sum test_score
global test_mean = r(mean)
global test_std = r(sd)
gen z_test = (test_score - $test_mean)/$test_std

sum gpa
global gpa_mean = r(mean)
global gpa_std = r(sd)
gen z_gpa = (gpa - $gpa_mean)/$gpa_std

//# standardize beliefs
sum rav_belief
global rav_belief_mean = r(mean)
global rav_belief_std = r(sd)
gen z_rav_belief = (rav_belief - $rav_belief_mean)/$rav_belief_std

sum eye_belief
global eye_belief_mean = r(mean)
global eye_belief_std = r(sd)
gen z_eye_belief = (eye_belief - $eye_belief_mean)/$eye_belief_std


//# rank gpa in class
bysort net_class: egen rank_gpa_class = rank(-gpa), track
label variable rank_gpa_class "Rank by GPA per classroom"

//# standardize age / semester
sum age
global age_mean = r(mean)
global age_std = r(sd)
gen z_age = (age - $age_mean)/$age_std

sum semester
global semester_mean = r(mean)
global semester_std = r(sd)
gen z_semester = (semester - $semester_mean)/$semester_std


// perc_score test
sum perc_score
global perc_score_mean = r(mean)
global perc_score_std = r(sd)
gen z_perc_score = (perc_score - $perc_score_mean)/$perc_score_std

//standardize fraction_lses
sum fraction_lses
global fraction_lses_mean = r(mean)
global fraction_lses_std = r(sd)
gen z_fraction_lses = (fraction_lses - $fraction_lses_mean)/$fraction_lses_std


// differences in score for GPA and TEST
foreach var in z_gpa z_test {
	
    // average score low-ses and high-ses
    bysort net_class: egen lses_avg_`var' = sum(`var') if  ses == 1
    egen __t = max(lses_avg_`var'), by(net_class)
    replace lses_avg_`var' = __t
    drop __t 
	replace lses_avg_`var' = (lses_avg_`var' - `var')/(count_low_ses-1) if  ses == 1
	replace lses_avg_`var' = (lses_avg_`var')/(count_low_ses) if  ses == 0

    bysort net_class: egen hses_avg_`var' =  sum(`var') if  ses == 0
    egen __t = max(hses_avg_`var'), by(net_class)
    replace hses_avg_`var' = __t
    drop __t 
	replace hses_avg_`var' = (hses_avg_`var' - `var')/(observed_classmates - count_low_ses-1) if  ses == 0
	replace hses_avg_`var' = (hses_avg_`var')/(observed_classmates - count_low_ses) if  ses == 1
	gen difference_`var' = lses_avg_`var' - hses_avg_`var'
    
	// 50th percentile low-ses fraction share
    bysort net_class: egen p50_`var' = pctile(`var'), p(50)
	bysort net_class: egen lses_above_p50_`var' = count(ses) if (`var' >= p50_`var') & (ses == 1)
	bysort net_class: egen above_p50_`var' = sum(`var' >= p50_`var')
	egen __t = max(lses_above_p50_`var'), by(net_class)
    replace lses_above_p50_`var' = __t
	replace lses_above_p50_`var' = 0 if lses_above_p50_`var' == .
    drop __t 
	gen fraction_lses_p50_`var' = lses_above_p50_`var'/above_p50_`var'
	replace fraction_lses_p50_`var' = (lses_above_p50_`var'-1)/(above_p50_`var'-1) if ses == 1 & (`var' >= p50_`var')
	
	// 75th percentile low-ses fraction share
	bysort net_class: egen p75_`var' = pctile(`var'), p(75)
	bysort net_class: egen lses_above_p75_`var' = count(ses) if (`var' >= p75_`var') & (ses == 1)	
	bysort net_class: egen above_p75_`var' = sum(`var' >= p75_`var')
	egen __t = max(lses_above_p75_`var'), by(net_class)
    replace lses_above_p75_`var' = __t
	replace lses_above_p75_`var' = 0 if lses_above_p75_`var' == .
    drop __t 
	gen fraction_lses_p75_`var' = lses_above_p75_`var'/above_p75_`var'
	replace fraction_lses_p75_`var' = (lses_above_p75_`var'-1)/(above_p75_`var'-1) if ses == 1 & (`var' >= p75_`var')
	
	// 50th percentile score difference
	bysort net_class: egen lses_avg_p50_`var' = sum(`var') if (`var' >= p50_`var') & (ses == 1)	
	egen __t = max(lses_avg_p50_`var'), by(net_class)
    replace lses_avg_p50_`var' = __t
	drop __t 
	replace lses_avg_p50_`var' = (lses_avg_p50_`var' - `var')/(lses_above_p50_`var'-1) if  ses == 1 & (`var' >= p50_`var')
	replace lses_avg_p50_`var' = (lses_avg_p50_`var')/(lses_above_p50_`var') if  ses == 0 & (`var' >= p50_`var')
	
	bysort net_class: egen hses_avg_p50_`var' = sum(`var') if (`var' >= p50_`var') & (ses == 0)	
	egen __t = max(hses_avg_p50_`var'), by(net_class)
    replace hses_avg_p50_`var' = __t
    drop __t 
	replace hses_avg_p50_`var' = (hses_avg_p50_`var' - `var')/(above_p50_`var'-lses_above_p50_`var'-1) if  ses == 0 & (`var' >= p50_`var')
	replace hses_avg_p50_`var' = (hses_avg_p50_`var')/(above_p50_`var'-lses_above_p50_`var') if  ses == 1 & (`var' >= p50_`var')
	gen difference_p50_`var' = lses_avg_p50_`var' - hses_avg_p50_`var'
	
	// 75th percentile score difference
	bysort net_class: egen lses_avg_p75_`var' = sum(`var') if (`var' >= p75_`var') & (ses == 1)	
	egen __t = max(lses_avg_p75_`var'), by(net_class)
    replace lses_avg_p75_`var' = __t
	drop __t 
	bysort net_class: egen hses_avg_p75_`var' = sum(`var') if (`var' >= p75_`var') & (ses == 0)	
	egen __t = max(hses_avg_p75_`var'), by(net_class)
    replace hses_avg_p75_`var' = __t
    drop __t 
	replace hses_avg_p75_`var' = (hses_avg_p75_`var' - `var')/(above_p75_`var'-lses_above_p75_`var'-1) if  ses == 0 & (`var' >= p75_`var')
	replace hses_avg_p75_`var' = (hses_avg_p75_`var')/(above_p75_`var'-lses_above_p75_`var') if  ses == 1 & (`var' >= p75_`var')
	gen difference_p75_`var' = lses_avg_p75_`var' - hses_avg_p75_`var'
}
drop lses* hses* p50* p75*

drop if net_class == 12000 // classroom did not join experiment 

// faculty
encode faculty, generate(faculty_num)
drop faculty
rename faculty_num faculty

// fix class_size
egen __t = max(class_size), by(net_class)
replace class_size = __t
drop __t 

egen __t = max(observed_classmates), by(net_class)
replace observed_classmates = __t
drop __t 

// share from own faculty in class
bysort net_class faculty: egen count_faculty = count(faculty)
gen fraction_faculty = (count_faculty-1)/(class_size-1)
sum fraction_faculty
global fraction_faculty_mean = r(mean)
global fraction_faculty_std = r(sd)
gen z_fraction_faculty = (fraction_faculty - $fraction_faculty_mean)/$fraction_faculty_std
drop count_faculty

// study
replace study = "ing_financiera" if study == "Ing_financiera"
encode study, generate(study_num)
drop study
rename study_num study

// share from own study in class
bysort net_class study: egen count_study = count(study)
gen fraction_study = (count_study-1)/(class_size-1)
sum fraction_study
global fraction_study_mean = r(mean)
global fraction_study_std = r(sd)
gen z_fraction_study = (fraction_study - $fraction_study_mean)/$fraction_study_std
drop count_study

//# pca
pca z_gpa z_test
predict pc1 pc2, score

//# top3 both
gen top3twice = (rank_rav_class <=3 & rank_eye_class <=3)
replace top3twice = . if rank_rav_class == . | rank_eye_class ==.

//# top3 is lowSES
// raven
gen top3lses_rav = (rank_rav_class <=3 & ses == 1)
replace top3lses_rav = . if ses == .
egen __t = max(top3lses_rav), by(net_class)
replace top3lses_rav = __t
drop __t 
// eye
gen top3lses_eye = (rank_eye_class <=3 & ses == 1)
replace top3lses_eye = . if ses == .
egen __t = max(top3lses_eye), by(net_class)
replace top3lses_eye = __t
drop __t 
// gpa
gen top3lses_gpa = (rank_gpa_class <=3 & ses == 1)
replace top3lses_gpa = . if ses == .
egen __t = max(top3lses_gpa), by(net_class)
replace top3lses_gpa = __t
drop __t 



//# split referrals by comma
split referrals_ravens, parse(,) generate(rav_ref_)
destring rav_ref_*, replace
drop referrals_ravens
split referrals_eye, parse(,) generate(eye_ref_)
destring eye_ref_*, replace
drop referrals_eye
split guesses_ses, parse(,) generate(guess_)
destring guess_*, replace
drop guesses_ses

rename (rav_ref_1 rav_ref_2 rav_ref_3 eye_ref_1 eye_ref_2 eye_ref_3 guess_1 guess_2 guess_3) (ref_1 ref_2 ref_3 ref_4 ref_5 ref_6 ref_7 ref_8 ref_9)

//# count overlapping referrals 
gen count_same_1 = (ref_1 == ref_4 | ref_1 == ref_5 | ref_1 == ref_6)&(net_id != ref_1)
gen count_same_2 = (ref_2 == ref_4 | ref_2 == ref_5 | ref_2 == ref_6)&(net_id != ref_2)
gen count_same_3 = (ref_3 == ref_4 | ref_3 == ref_5 | ref_3 == ref_6)&(net_id != ref_3)
gen same_referral = count_same_1+count_same_2+count_same_3 // nb of overlapping referrals (non-self)
gen own_referral = (net_id == ref_1 |net_id == ref_2 |net_id == ref_3 | net_id == ref_4 |net_id == ref_5 |net_id == ref_6) // did self-refer?
replace same_referral = . if ref_1 == . 
gen same_and_own = same_referral+own_referral
drop count_same_*

save "cleaned_wide.dta", replace
