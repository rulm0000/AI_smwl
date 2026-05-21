* 6_Viewpoints_Tables.do
* Creates Viewpoints sample characteristics table and eTables 1-2.

clear all
set more off

capture confirm global output
if _rc != 0 {
    do "setup.do"
}

capture program drop fmt2
program define fmt2, rclass
    args x
    return local out "`=trim(string(`x', "%9.2f"))'"
end

capture program drop pformat
program define pformat, rclass
    args p
    if (`p' < 0.001) {
        return local out "<0.001"
    }
    else if (`p' >= 0.9995) {
        return local out ">.99"
    }
    else {
        return local out "`=trim(string(`p', "%9.3f"))'"
    }
end

capture program drop format_pct
program define format_pct, rclass
    args pct
    if (`pct' < 1) {
        return local formatted "`=trim(string(`pct', "%9.1f"))'%"
    }
    else {
        return local formatted "`=trim(string(round(`pct'), "%9.0f"))'%"
    }
end

capture program drop format_pct_count
program define format_pct_count, rclass
    args pct
    if missing(`pct') {
        return local formatted "NA"
    }
    else if (`pct' < 1 & `pct' > 0) {
        return local formatted "`=trim(string(`pct', "%9.1f"))'%"
    }
    else {
        return local formatted "`=trim(string(round(`pct'), "%9.0f"))'%"
    }
end

capture program drop topic_name
program define topic_name, rclass
    args t
    local name ""
    if (`t' == 1) local name "Control"
    if (`t' == 2) local name "Screentime break warning"
    if (`t' == 3) local name "Depression and anxiety"
    if (`t' == 4) local name "Negative body image"
    if (`t' == 5) local name "Addiction"
    if (`t' == 6) local name "Sleep disruption"
    if (`t' == 7) local name "Mental health harms to young people"
    if (`t' == 8) local name "Not been proven safe"
    return local name "`name'"
end

capture program drop write_coef
program define write_coef
    args row label
    quietly lincom `label'
    local est = r(estimate)
    local lb = r(lb)
    local ub = r(ub)
    local p = r(p)
    fmt2 `est'
    local est_s = r(out)
    fmt2 `lb'
    local lb_s = r(out)
    fmt2 `ub'
    local ub_s = r(out)
    pformat `p'
    local p_s = r(out)
    putexcel B`row' = ("`est_s' (`lb_s', `ub_s')")
    putexcel C`row' = ("`p_s'")
end

* ==============================================================================
* Table: Viewpoints sample characteristics
* ==============================================================================

display "Generating Viewpoints sample characteristics table..."
use "$human_file", clear
duplicates drop pid, force
gen sample = 0
drop pid
tempfile human_chars
save `human_chars'

putexcel set "$tables/Table_Viewpoints_Sample_Characteristics.xlsx", replace

use "$ai_file", clear
duplicates drop pid, force
gen sample = 1
drop pid
append using `human_chars'

quietly count if sample == 1
local n_ai = r(N)
quietly count if sample == 0
local n_human = r(N)

putexcel A1 = ("Table 2. Sample characteristics, n=`n_ai' AI personas and n=`n_human' human participants"), bold
putexcel A2 = ("Characteristic"), bold
putexcel B2 = ("AI personas"), bold hcenter
putexcel D2 = ("Human participants"), bold hcenter
putexcel B3 = ("%"), bold hcenter
putexcel C3 = ("N"), bold hcenter
putexcel D3 = ("%"), bold hcenter
putexcel E3 = ("N"), bold hcenter

local row = 4

putexcel A`row' = ("Age"), bold
local row = `row' + 1
foreach l of numlist 1 2 {
    local lbl : label (age_group) `l'
    quietly count if sample == 1 & !missing(age_group)
    local den_ai = r(N)
    quietly count if sample == 1 & age_group == `l'
    local n_ai_row = r(N)
    local pct_ai = 100 * `n_ai_row' / `den_ai'
    format_pct_count `pct_ai'
    local pct_ai_s = r(formatted)

    quietly count if sample == 0 & !missing(age_group)
    local den_human = r(N)
    quietly count if sample == 0 & age_group == `l'
    local n_human_row = r(N)
    local pct_human = 100 * `n_human_row' / `den_human'
    format_pct_count `pct_human'
    local pct_human_s = r(formatted)

    putexcel A`row' = ("   `lbl'")
    putexcel B`row' = ("`pct_ai_s'")
    putexcel C`row' = (`n_ai_row')
    putexcel D`row' = ("`pct_human_s'")
    putexcel E`row' = (`n_human_row')
    local row = `row' + 1
}

putexcel A`row' = ("Gender"), bold
local row = `row' + 1
foreach l of numlist 1 2 3 {
    local lbl : label (gender_cat) `l'
    quietly count if sample == 1 & !missing(gender_cat)
    local den_ai = r(N)
    quietly count if sample == 1 & gender_cat == `l'
    local n_ai_row = r(N)
    quietly count if sample == 0 & !missing(gender_cat)
    local den_human = r(N)
    quietly count if sample == 0 & gender_cat == `l'
    local n_human_row = r(N)

    if (`n_ai_row' == 0) {
        local pct_ai_s "NA"
        local n_ai_s "-"
    }
    else {
        local pct_ai = 100 * `n_ai_row' / `den_ai'
        format_pct_count `pct_ai'
        local pct_ai_s = r(formatted)
        local n_ai_s "`n_ai_row'"
    }

    local pct_human = 100 * `n_human_row' / `den_human'
    format_pct_count `pct_human'
    local pct_human_s = r(formatted)

    putexcel A`row' = ("   `lbl'")
    putexcel B`row' = ("`pct_ai_s'")
    putexcel C`row' = ("`n_ai_s'")
    putexcel D`row' = ("`pct_human_s'")
    putexcel E`row' = (`n_human_row')
    local row = `row' + 1
}

putexcel A`row' = ("Race or ethnicity"), bold
local row = `row' + 1
foreach l of numlist 1 2 3 4 5 6 7 {
    local lbl : label (race_cat) `l'
    quietly count if sample == 1 & !missing(race_cat)
    local den_ai = r(N)
    quietly count if sample == 1 & race_cat == `l'
    local n_ai_row = r(N)
    quietly count if sample == 0 & !missing(race_cat)
    local den_human = r(N)
    quietly count if sample == 0 & race_cat == `l'
    local n_human_row = r(N)

    if (`n_ai_row' == 0) {
        local pct_ai_s "NA"
        local n_ai_s "-"
    }
    else {
        local pct_ai = 100 * `n_ai_row' / `den_ai'
        format_pct_count `pct_ai'
        local pct_ai_s = r(formatted)
        local n_ai_s "`n_ai_row'"
    }

    local pct_human = 100 * `n_human_row' / `den_human'
    format_pct_count `pct_human'
    local pct_human_s = r(formatted)

    putexcel A`row' = ("   `lbl'")
    putexcel B`row' = ("`pct_ai_s'")
    putexcel C`row' = ("`n_ai_s'")
    putexcel D`row' = ("`pct_human_s'")
    putexcel E`row' = (`n_human_row')
    local row = `row' + 1
}

putexcel A`row' = ("Note. AI personas could only be assigned a gender of female or male, so no personas were assigned to non-binary or another gender identity."), italic
local row = `row' + 1
putexcel A`row' = ("AI personas could only be assigned one race/ethnicity from a fixed list of options, so no personas were assigned to American Indian or Alaska Native, Native Hawaiian or Pacific Islander, another race or ethnicity, or multiracial/ethnic."), italic

display "Sample characteristics saved to $tables/Table_Viewpoints_Sample_Characteristics.xlsx"

* ==============================================================================
* Prepare pooled human participant and AI persona data
* ==============================================================================

display "Preparing pooled data for eTables 1 and 2..."
use "$human_file", clear
keep if topic <= 8

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
gen sample = 0

capture confirm string variable pid
if _rc == 0 {
    destring pid, replace force
}

tempfile human_subset
save `human_subset'

use "$ai_file", clear
capture confirm string variable pid
if _rc == 0 {
    tempvar numeric_pid
    egen `numeric_pid' = group(pid)
    drop pid
    rename `numeric_pid' pid
}
replace pid = pid + 100000
gen sample = 1
append using `human_subset'

label define samplelab 0 "Human participant" 1 "AI persona", replace
label values sample samplelab
label define topiclab 1 "Control" 2 "Screentime break warning" 3 "Depression and anxiety" 4 "Negative body image" 5 "Addiction" 6 "Sleep disruption" 7 "Mental health harms to young people" 8 "Not been proven safe", replace
label values topic topiclab

tempfile pooled_data
save `pooled_data'

mixed pme ib1.topic##ib0.sample || pid: , vce(robust)

* ==============================================================================
* Supporting table: Regression coefficients
* ==============================================================================

display "Generating pooled interaction regression coefficient table..."
putexcel set "$tables/Human_AI_Regression_Coefficients.xlsx", replace
putexcel A1 = ("Supplemental model output. Impact of warning topic and sample on perceived message effectiveness, n=1,012 human participants and n=1,000 AI personas")
putexcel A2 = ("Variable"), bold
putexcel B2 = ("Coefficient (95% CI)"), bold
putexcel C2 = ("p-value"), bold

local row = 3
putexcel A`row' = ("Warning topics"), bold
local row = `row' + 1
putexcel A`row' = ("   Control")
putexcel B`row' = ("[Referent]")
local row = `row' + 1
local manuscript_topic_order "5 2 8 6 4 3 7"
foreach t of local manuscript_topic_order {
    topic_name `t'
    putexcel A`row' = ("   `r(name)'")
    write_coef `row' "`t'.topic"
    local row = `row' + 1
}

putexcel A`row' = ("Sample"), bold
local row = `row' + 1
putexcel A`row' = ("   Human participants")
putexcel B`row' = ("[Referent]")
local row = `row' + 1
putexcel A`row' = ("   AI personas")
write_coef `row' "1.sample"
local row = `row' + 1

putexcel A`row' = ("Warning topics x sample"), bold
local row = `row' + 1
foreach t of local manuscript_topic_order {
    topic_name `t'
    putexcel A`row' = ("   `r(name)' x AI personas")
    write_coef `row' "`t'.topic#1.sample"
    local row = `row' + 1
}

quietly testparm 2.topic#1.sample 3.topic#1.sample 4.topic#1.sample 5.topic#1.sample 6.topic#1.sample 7.topic#1.sample 8.topic#1.sample
pformat r(p)
local joint_p = r(out)
putexcel A`row' = ("Note. The p-value for the joint significance of the interaction terms was `joint_p'."), italic

* ==============================================================================
* eTable 2: PME means, SEs, and rankings
* ==============================================================================

display "Generating eTable 2..."
tempfile means_tbl
tempname meanshold
postfile `meanshold' topic sample mean se using `means_tbl', replace

foreach t of numlist 1/8 {
    if (`t' == 1) quietly lincom _cons
    else quietly lincom _cons + `t'.topic
    post `meanshold' (`t') (0) (r(estimate)) (r(se))

    if (`t' == 1) quietly lincom _cons + 1.sample
    else quietly lincom _cons + `t'.topic + 1.sample + `t'.topic#1.sample
    post `meanshold' (`t') (1) (r(estimate)) (r(se))
}
postclose `meanshold'

use `means_tbl', clear
gen neg_mean = -mean
bysort sample: egen rank = rank(neg_mean), unique
drop neg_mean
tempfile ranked_means
save `ranked_means'

keep if sample == 0
rename mean human_mean
rename se human_se
rename rank human_rank
keep topic human_mean human_se human_rank
tempfile human_means
save `human_means'

use `ranked_means', clear
keep if sample == 1
rename mean ai_mean
rename se ai_se
rename rank ai_rank
keep topic ai_mean ai_se ai_rank
merge 1:1 topic using `human_means', nogen
sort human_mean

putexcel set "$tables/eTable2_Human_AI_Means_Rankings.xlsx", replace
putexcel A1 = ("eTable 2. Perceived message effectiveness of warning topics by sample, n=1,012 human participants and n=1,000 AI personas")
putexcel B2 = ("Human participants"), bold hcenter
putexcel D2 = ("AI personas"), bold hcenter
putexcel A3 = ("Warning topic"), bold
putexcel B3 = ("Mean (SE)"), bold
putexcel C3 = ("Rank"), bold
putexcel D3 = ("Mean (SE)"), bold
putexcel E3 = ("Rank"), bold

local row = 4
forvalues i = 1/8 {
    local t = topic[`i']
    topic_name `t'
    local name = r(name)
    fmt2 human_mean[`i']
    local human_mean_s = r(out)
    fmt2 human_se[`i']
    local human_se_s = r(out)
    fmt2 ai_mean[`i']
    local ai_mean_s = r(out)
    fmt2 ai_se[`i']
    local ai_se_s = r(out)

    putexcel A`row' = ("`name'")
    putexcel B`row' = ("`human_mean_s' (`human_se_s')")
    putexcel C`row' = (human_rank[`i'])
    putexcel D`row' = ("`ai_mean_s' (`ai_se_s')")
    putexcel E`row' = (ai_rank[`i'])
    local row = `row' + 1
}

display "Viewpoints tables generated successfully."
