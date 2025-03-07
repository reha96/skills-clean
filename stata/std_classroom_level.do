foreach var in gpa rav_sum eye_sum {  // Changed to full variable names
    * Create classroom-specific standardized variables

    
    * Loop through each classroom
    levelsof net_class, local(classrooms)
    gen class_z_`var' = .
    
    foreach classroom of local classrooms {
        * Calculate mean and standard deviation for this variable within this classroom
        quietly sum `var' if net_class == `classroom'
        // Check if there's enough variation to standardize
        if r(sd) > 0 {
            local mean_`var' = r(mean)
            local sd_`var' = r(sd)
            
            * Generate classroom-specific standardized variable directly in the main variable
            replace class_z_`var' = (`var' - `mean_`var'') / `sd_`var'' if net_class == `classroom'
        }
        else {
            display "Warning: No variation in `var' for classroom `classroom', skipping standardization"
        }
    }
    
}

//# table 1 : can peers identify skills
reg pcent_count_rav_t1 c.class_z_rav_sum, vce(cluster net_class)
estimates store ravt1_1 
reg pcent_count_eye_t1 c.class_z_eye_sum, vce(cluster net_class)
estimates store eyet1_1 
esttab  ravt1_1 eyet1_1 ,  b(%12.3f) se(%12.3f) r2 nobaselevels label mtitles star(* 0.10 ** 0.05 *** 0.01)

//# table 2: it could be that people proxy skills with GPA
qui reg pcent_count_rav_t1 c.class_z_rav_sum c.class_z_gpa, vce(cluster net_class)
estimates store ravt1_2 
qui reg pcent_count_eye_t1 c.class_z_eye_sum c.class_z_gpa, vce(cluster net_class)
estimates store eyet1_2 
esttab  ravt1_2 eyet1_2 ,  b(%12.3f) se(%12.3f) r2 nobaselevels label mtitles star(* 0.10 ** 0.05 *** 0.01)
