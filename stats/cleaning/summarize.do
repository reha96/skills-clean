/*******************************************************************************
    Project: SIR - summarize dataset
    Author: Reha Tuncer
    Date: 23.10.2024
    Description: Summarize variables in a dataset
*******************************************************************************/

// Load dataset
capture noisily use "cleaning/referrals_wide.dta"
if _rc != 0 {
    use "referrals_wide.dta"
}

// Summarize dataset
* Display basic dataset info
describe, short

* Summarize all variables
summarize, separator(0)

* Display summary statistics for string variables
ds, has(type string)
foreach var in study faculty  {
    display _newline "Variable: `var'"
    tabulate `var', sort
}

* Show missing data for all variables
misstable summarize, all

* Display value labels for categorical variables
label list

* Show correlation matrix for key numeric variables
correlate z_rav z_eye gpa test_score

* Display unique values for selected categorical variables
foreach var in ses treat gender first_gen ethnic rural scholarship {
    display _newline "Unique values for `var':"
    levelsof `var', local(levels)
    display "`levels'"
}


// load dataset
capture noisily use "cleaning/cleaned_long.dta"
if _rc != 0 {
    use "cleaned_long.dta"
}

// Summarize dataset
* Display basic dataset info
capture noisily describe, short

* Summarize all variables
capture noisily summarize, separator(0)

* Display summary statistics for string variables
capture noisily ds, has(type string)
foreach var in study faculty {
    capture noisily {
        display _newline "Main Variable: `var'"
        tabulate `var', sort
    }
    capture noisily {
        display _newline "Other Variable: `var'_other"
        tabulate `var'_other, sort
    }
}

* Show missing data for all variables
capture noisily misstable summarize, all

* Display value labels for categorical variables
capture noisily label list

* Show correlation matrix for key numeric variables
capture noisily correlate z_rav z_eye gpa test_score

* Display unique values for selected categorical variables
foreach var in ses treat gender first_gen ethnic rural scholarship {
    capture noisily {
        display _newline "Main Variable: `var'"
        levelsof `var', local(levels)
        display "`levels'"
    }
    capture noisily {
        display _newline "Other Variable: `var'_other"
        levelsof `var'_other, local(levels)
        display "`levels'"
    }
}
