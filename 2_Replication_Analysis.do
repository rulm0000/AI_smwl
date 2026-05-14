* 2_Replication_Analysis.do
* Pools AI Persona and Human Participant data and tests for replication of topic effects.

clear all
set more off

* Ensure setup is run
capture confirm global output
if _rc != 0 {
    do "setup.do"
}

* 1. Load and Prepare Human Data (Priority Versions only)
display "Preparing Human Participant Data..."
use "$human_file", clear

* Keep only topics 1-8 (as AI personas only rated 1-8)
keep if topic <= 8

* Filter for Human Priority Versions (based on AI_vs_Human_Mapping.txt)
* Topic 1 & 2: v1
* Topic 3: v1
* Topic 4: v2
* Topic 5: v3
* Topic 6: v1
* Topic 7: v1
* Topic 8: v1
gen is_priority = 0
replace is_priority = 1 if topic == 1 & version == 1
replace is_priority = 1 if topic == 2 & version == 1
replace is_priority = 1 if topic == 3 & version == 1
replace is_priority = 1 if topic == 4 & version == 2
replace is_priority = 1 if topic == 5 & version == 3
replace is_priority = 1 if topic == 6 & version == 1
replace is_priority = 1 if topic == 7 & version == 1
replace is_priority = 1 if topic == 8 & version == 1

keep if is_priority == 1
gen sample = 0 // 0 = Human Participant

* Ensure pid is numeric
capture confirm string variable pid
if _rc == 0 {
    destring pid, replace force
}

tempfile human_subset
save `human_subset'

* 2. Load and Prepare AI Persona Data
display "Preparing AI Persona Data..."
use "$ai_file", clear

* Ensure pid is numeric and unique from humans
capture confirm string variable pid
if _rc == 0 {
    * If it's a hex string (common in Viewpoints data), egen group is safer than destring
    tempvar numeric_pid
    egen `numeric_pid' = group(pid)
    drop pid
    rename `numeric_pid' pid
}
* Use a large offset for AI Persona IDs to avoid collision with Human IDs
replace pid = pid + 100000 
gen sample = 1 // 1 = AI Persona

* Harmonize Topic 8 label (match Human study capitalization/text)
label define topiclab 8 "Not been proven safe", modify

* 3. Append Datasets
display "Pooling datasets..."
append using `human_subset'

label define samplelab 0 "Human Participant" 1 "AI Persona"
label values sample samplelab

* 4. Statistical Test (Topic x Sample Interaction)
* Topic 1 (Control) is the reference.
display "--- Replication Analysis: mixed pme i.topic##i.sample ---"
mixed pme i.topic##i.sample || pid: , vce(robust)

* 5. Export Results
putexcel set "$tables/Replication_Analysis_Results.xlsx", replace
putexcel A1 = "Replication Analysis: Comparing Warning Topic Effects (Human vs. AI Persona)"
putexcel A2 = "Warning Topic"
putexcel B2 = "Interaction Coeff (Topic x AI Persona)"
putexcel C2 = "SE"
putexcel D2 = "p-value"

* Overall interaction test
testparm i.topic#i.sample
local p_overall = r(p)
putexcel A3 = "OVERALL INTERACTION (Joint Test)"
putexcel D3 = `p_overall', nformat(number_d3)

* Individual topic interaction effects vs Control
local row = 4
foreach t of numlist 2/8 {
    local name : label (topic) `t'
    putexcel A`row' = "`name'"
    
    * Coefficient for interaction term: i.topic#i.sample
    local b = _b[`t'.topic#1.sample]
    local se = _se[`t'.topic#1.sample]
    local p = 2 * normal(-abs(`b'/`se'))
    
    putexcel B`row' = `b', nformat(number_d3)
    putexcel C`row' = `se', nformat(number_d3)
    putexcel D`row' = `p', nformat(number_d3)
    
    local row = `row' + 1
}

display "Replication Analysis Complete. Results saved to $tables/Replication_Analysis_Results.xlsx"
