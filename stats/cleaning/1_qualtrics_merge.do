/*******************************************************************************
    Project: Skills inequality referrals
    Author: Reha Tuncer
    Date: 17.07.2024
    Description: This do-file merges qualtrics surveys
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
global qualtrics "$root_dir/Raw_Qualtrics/NotAnonimized"
global admin "$root_dir/Admin_database/NotAnonimized"


//# merge qualtrics loop
forvalues j = 1/36 {
	clear all
	if `j' <= 9 {		
			capture confirm file "$qualtrics/raw_class0`j'.csv"
			if _rc != 0 {
				continue
			}
			import delimited "$qualtrics/raw_class0`j'.csv"
			keep if progress >=86 // 1 observation (net_id 3020) * if else change 
			save "$qualtrics/class_`j'_qualtrics.dta", replace
			}
		else {
			capture confirm file "$qualtrics/raw_class`j'.csv"
			if _rc != 0 {
				continue
			}
			import delimited "$qualtrics/raw_class`j'.csv"
			keep if progress >=86 // 3 observations (net_id 35013 31028)
			save "$qualtrics/class_`j'_qualtrics.dta", replace
			}	
	
}

use "$qualtrics/class_1_qualtrics.dta"
forvalues j = 2/36 {
	capture confirm file "$qualtrics/class_`j'_qualtrics.dta"
		if _rc != 0 {
		continue
	}
	append using "$qualtrics/class_`j'_qualtrics.dta"
	save "$qualtrics/classes_complete.dta", replace
}

//# merge "missing" survey
clear all
import delimited "$qualtrics/raw_missing.csv" 
replace finished = 1 if progress >=95 // 1 observation (1 missing)
keep if finished == 1
save "$qualtrics/missing.dta", replace

use "$qualtrics/classes_complete.dta"
append using "$qualtrics/missing.dta", force

//# check manually from admin data to replace missing net_id's
replace net_id = 23005 if recipientemail == "csaavedra178@unab.edu.co"
replace net_id = 21013 if recipientemail == "lreatiga@unab.edu.co"
replace net_id = 4010 if recipientemail == "msanabria487@unab.edu.co"
replace net_id = 33001 if recipientemail == "aduran224@unab.edu.co"
replace net_id = 33003 if recipientemail == "cortiz352@unab.edu.co"
replace net_id = 21008 if recipientemail == "drestrepo334@unab.edu.co"
replace net_id = 13009 if recipientemail == "jrojas275@unab.edu.co"
replace net_id = 11012 if recipientemail == "sballesteros568@unab.edu.co"
replace net_id = 6003 if recipientemail == "dpalomino607@unab.edu.co"
replace net_id = 10003 if recipientemail == "crivera781@unab.edu.co"
replace net_id = 36007 if recipientemail == "dpatino257@unab.edu.co"

//# increment net_id by 1 for net_id's 25028 and 25029 to match admin data
replace net_id = 25029 if net_id == 25028 
replace net_id = 25030 if net_id == 25029
replace net_id = 25028 if net_id == 25030 & recipientemail ==  "ycubillos853@unab.edu.co"

//# fix finished 
replace finished = 1 if progress >=86
keep if finished == 1

//# fix class 31 by matching to admin data (31005 is missing in Qualtrics)
replace net_id = net_id - 1 if net_id >= 31006 & net_id <= 31030

//# drop 1 anonymous participant
drop if net_id == . // drop 1 obs 


/*******************************************************************************		
Create new variables and drop unnecessary ones for Qualtrics
*******************************************************************************/


//# completion time in minutes
gen duration_min = duration/60
label variable duration_min "Survey completion time in minutes"

//# rav scores
* keep if 1 (correct answer to each question) or replace with 0 otherwise
local i 1 
while `i' <= 18 {
replace rav`i' = 0 if rav`i' > 1
local ++i
}
egen rav_sum = rowtotal(rav1 rav2 rav3 rav4 rav5 rav6 rav7 rav8 rav9 rav10 rav11 rav12 rav13 rav14 rav15 rav16 rav17 rav18) if finished == 1
label variable rav_sum "Nb of Correct Ravens (out of 18)"
gen rav_pcent = (rav_sum/18)*100  if finished == 1
label variable rav_pcent "Percetange of Correct Ravens"
	   
//# eye scores
* keep if 1 (correct answer to each question) or replace with 0 otherwise
local i 1  
while `i' <= 36 {
replace eye`i' = 0 if eye`i' > 1
local ++i 
}
egen eye_sum = rowtotal(eye1 eye2 eye3 eye4 eye5 eye6 eye7 eye8 eye9 eye10 eye11 eye12 eye13 eye14 eye15 eye16 eye17 eye18 eye19 eye20 eye21 eye22 eye23 eye24 eye25 eye26 eye27 eye28 eye29 eye30 eye31 eye32 eye33 eye34 eye35 eye36) if finished == 1
label variable eye_sum "Nb of Correct RMET (out of 36)"
gen eye_pcent = (eye_sum/36)*100 if finished == 1
label variable eye_pcent "Percentage of Correct RMET"

//# socioeconomic status (stratum)
gen ses = 0 if finished == 1
replace ses = 1 if strato <= 3 & finished == 1
label define seslabel 0 "High" 1 "Low"
label values ses seslabel
label variable ses "Socio Economic Background by Strata"

//# first generation uni
gen first_gen = 0 if finished == 1 & (mother != 6 | father != 6) // 6 is not applicable
replace first_gen = 1 if mother <= 3 & father<=3 & finished == 1 & (mother != 6 | father != 6) // values 4 and 5 are university level studies
label define firstgenlabel 0 "Continuing Gen" 1 "First Gen"
label values first_gen firstgenlabel
label variable first_gen "First Generation College Status"

//# gender label
label define genderlabel 0 "Male" 1 "Female"
label values gender genderlabel
label variable gender "Gender"

//# treatment label
label define treatlabel 1 "Baseline" 2 "Quota"
label values treat treatlabel
label variable treat "Experimental Condition"

//# keep necessary variables
keep id recipientemail email recipientfirstname recipientlastname net_class net_id gender duration_min strato ravens_beliefs_1 eye_beliefs_1 referrals_ravens referrals_eye q510 class_size treat rav_sum rav_pcent eye_sum eye_pcent ses first_gen finished

//# rename low-ses guesses 
rename q510 guesses_ses
// rename recipientemail email

//# string separate name and program
gen position = strpos(recipientlastname, " - ")
* extract the substring after " - "
gen program_qualtrics = substr(recipientlastname, position + 3, .)
* clean up - trim any leading or trailing spaces
replace program_qualtrics = strtrim(program_qualtrics)
* handle cases where " - " is not found
replace program_qualtrics = "" if position == 0
drop position

duplicates tag net_id, gen(dup)
gsort -dup
order net_id dup recipientemail
drop dup

// dummy duplicates
sort recipientemail
by recipientemail: gen multiple_participation = (_N > 1)

// replace missing net_class
replace net_class = floor(net_id/1000)*1000 if missing(net_class)

sort net_id


//# classroom level variables
bysort net_class : egen count_low_ses = total(ses)
bysort net_class : egen missing_classmate = total(ses == .)
order class_size, last
bysort net_class: gen observed_classmates = _N
gen fraction_lses = count_low_ses/ (observed_classmates - 1)
replace fraction_lses = (count_low_ses - 1)/ (observed_classmates - 1) if ses
label variable fraction_lses "Fraction of low-SES classmates"

// estrato dummies
gen ses_dummy = 1 if strato <= 2
replace ses_dummy = 3 if strato == 3
replace ses_dummy = 4 if strato == 4
replace ses_dummy = 6 if strato > 4
replace ses_dummy = . if strato == .

label define sdlabel 1 "1&2" 3 "3" 4 "4"  6 "5&6"
label values ses_dummy sdlabel

// estrato analysis: can people differentiate strata?
bysort net_class: egen count_ses12 = count(strato) if strato<=2
replace count_ses12 = 0 if count_ses12 == .
egen __t = max(count_ses12), by(net_class)
replace count_ses12 = __t
drop __t 
gen fraction_ses12 = count_ses12/ (observed_classmates - 1) if strato<=2
replace fraction_ses12 = 0 if fraction_ses12 == .
egen __t = max(fraction_ses12), by(net_class)
replace fraction_ses12 = __t
drop __t 
replace fraction_ses12 = (count_ses12 - 1)/ (observed_classmates - 1) if  strato<=2

bysort net_class: egen count_ses3 = count(strato) if strato==3
replace count_ses3 = 0 if count_ses3 == .
egen __t = max(count_ses3), by(net_class)
replace count_ses3 = __t
drop __t 
gen fraction_ses3 = count_ses3/ (observed_classmates - 1) if strato==3
replace fraction_ses3 = 0 if fraction_ses3 == .
egen __t = max(fraction_ses3), by(net_class)
replace fraction_ses3 = __t
drop __t 
replace fraction_ses3 = (count_ses3 - 1)/ (observed_classmates - 1) if  strato==3

bysort net_class: egen count_ses4 = count(strato) if strato==4
replace count_ses4 = 0 if count_ses4 == .
egen __t = max(count_ses4), by(net_class)
replace count_ses4 = __t
drop __t 
gen fraction_ses4 = count_ses4/ (observed_classmates - 1) if strato==4
replace fraction_ses4 = 0 if fraction_ses4 == .
egen __t = max(fraction_ses4), by(net_class)
replace fraction_ses4 = __t
drop __t 
replace fraction_ses4 = (count_ses4 - 1)/ (observed_classmates - 1) if  strato==4

bysort net_class: egen count_ses56 = count(strato) if strato>4
replace count_ses56 = 0 if count_ses56 == .
egen __t = max(count_ses56), by(net_class)
replace count_ses56 = __t
drop __t 
gen fraction_ses56 = count_ses56/ (observed_classmates - 1) if strato>4
replace fraction_ses56 = 0 if fraction_ses56 == .
egen __t = max(fraction_ses56), by(net_class)
replace fraction_ses56 = __t
drop __t 
replace fraction_ses56 = (count_ses56 - 1)/ (observed_classmates - 1) if  strato>4

//# ranking raven & eye
bysort net_class: egen rank_rav_class = rank(-rav_sum), track
label variable rank_rav_class "Rank by Raven's score per classroom"
bysort net_class: egen rank_eye_class = rank(-eye_sum), track
label variable rank_eye_class "Rank by MRMET score per classroom"



/*===========================================================================*/
//# Calculate delta difference in performance (COGNITIVE AND SOCIAL SKILL)
/*===========================================================================*/

//# standardized scores
sum rav_sum 
global rav_mean = r(mean)
global rav_std = r(sd)
gen z_rav = (rav_sum - $rav_mean)/$rav_std

sum eye_sum 
global eye_mean = r(mean)
global eye_std = r(sd)
gen z_eye = (eye_sum - $eye_mean)/$eye_std


// differences in score
foreach var in z_rav z_eye {
	
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

save "qualtrics_merge.dta", replace
