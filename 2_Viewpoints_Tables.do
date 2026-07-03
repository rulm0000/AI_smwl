* 2_Viewpoints_Tables.do
* Creates Viewpoints manuscript Table 2, Table 3, and supplemental eTable 2.

clear all
set more off
version 19.5

if `"$output"' == "" {
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
    if (`t' == 2) local name "Screen time break warning"
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

local n_ai_s : display %9.0fc `n_ai'
local n_ai_s = trim("`n_ai_s'")
local n_human_s : display %9.0fc `n_human'
local n_human_s = trim("`n_human_s'")

putexcel A1 = ("Table 2. Sample characteristics, n=`n_ai_s' AI personas and n=`n_human_s' human participants"), bold
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
    if (`l' == 3) local lbl "Non-binary/preferred-to-self-describe"
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

putexcel A`row' = ("Race/ethnicity"), bold
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

putexcel A`row' = ("Note. AI personas could only be assigned a gender of female or male, so no personas were assigned to non-binary/preferred-to-self-describe."), italic
local row = `row' + 1
putexcel A`row' = ("AI personas could only be assigned one race/ethnicity from a fixed list of options, so no personas were assigned to American Indian/Alaska Native, Native Hawaiian/Pacific Islander, another race/ethnicity, or multiracial/ethnic."), italic

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

label define samplelab 0 "Human participants" 1 "AI personas", replace
label values sample samplelab
label define topiclab 1 "Control" 2 "Screen time break warning" 3 "Depression and anxiety" 4 "Negative body image" 5 "Addiction" 6 "Sleep disruption" 7 "Mental health harms to young people" 8 "Not been proven safe", replace
label values topic topiclab

tempfile pooled_data
save `pooled_data'

mixed pme ib1.topic##ib0.sample || pid: , vce(robust)

* ==============================================================================
* Supporting table: Regression coefficients
* ==============================================================================

display "Generating pooled interaction regression coefficient table..."
putexcel set "$tables/eTable2_Warning_Topic_Sample_PME_Coefficients.xlsx", replace
putexcel A1 = ("eTable 2. Effect of warning topic and sample on perceived message effectiveness, n=1,012 human participants and n=1,000 AI personas")
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

putexcel A`row' = ("Warning topics x Sample"), bold
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
* Table 3: PME means, rankings, and warning-vs-control effects by sample
* ==============================================================================

display "Generating Table 3..."
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

use `ranked_means', clear
rename mean pme_mean
rename se pme_se
rename rank pme_rank
reshape wide pme_mean pme_se pme_rank, i(topic) j(sample)
tempfile means_wide
save `means_wide'

tempfile d_stats
tempname dhold
postfile `dhold' byte sample byte topic double b lb ub p cohen_d using `d_stats', replace

foreach s in 0 1 {
    use `pooled_data', clear
    keep if sample == `s'

    quietly mixed pme ib1.topic || pid: , vce(robust)
    quietly estat icc
    local icc = r(icc2)
    matrix G = e(N_g)
    local clusters = G[1,1]
    quietly summarize pme if e(sample)
    local sy = r(sd)

    foreach t of numlist 2/8 {
        quietly lincom `t'.topic
        local b = r(estimate)
        local lb = r(lb)
        local ub = r(ub)
        local p = r(p)

        quietly count if topic == `t' & !missing(pme)
        local n_warn = r(N)
        quietly count if topic == 1 & !missing(pme)
        local n_control = r(N)

        local n = `n_warn' + `n_control'
        local spooled = sqrt(((`sy'^2) * (`n' - 1) - ((`b'^2) * `n_warn' * `n_control' / `n')) / (`n' - 2))
        local lambda = 1 - (2 * (`n' / `clusters') * `icc') / (`n' - 1)
        local d = (`b' / `spooled') * sqrt(`lambda')

        post `dhold' (`s') (`t') (`b') (`lb') (`ub') (`p') (`d')
    }
}
postclose `dhold'

use `d_stats', clear
reshape wide b lb ub p cohen_d, i(topic) j(sample)
merge 1:1 topic using `means_wide', nogen

gen topic_order = .
local order = 1
foreach t of numlist 1 5 2 8 6 4 3 7 {
    replace topic_order = `order' if topic == `t'
    local order = `order' + 1
}
sort topic_order

putexcel set "$tables/Table3_Warning_Topic_PME_by_Sample.xlsx", replace
putexcel A1 = ("Table 3. Perceived message effectiveness by warning topic and sample, n=1,012 human participants and n=1,000 AI personas"), bold
putexcel B2 = ("Human participants"), bold hcenter
putexcel G2 = ("AI personas"), bold hcenter
putexcel A3 = ("Topic"), bold
putexcel B3 = ("Mean (SE)"), bold
putexcel C3 = ("Rank"), bold
putexcel D3 = ("ADE (95% CI)"), bold
putexcel E3 = ("p-value"), bold
putexcel F3 = ("Cohen's d"), bold
putexcel G3 = ("Mean (SE)"), bold
putexcel H3 = ("Rank"), bold
putexcel I3 = ("ADE (95% CI)"), bold
putexcel J3 = ("p-value"), bold
putexcel K3 = ("Cohen's d"), bold

local row = 4
forvalues i = 1/`=_N' {
    local t = topic[`i']
    topic_name `t'
    local name = r(name)
    fmt2 pme_mean0[`i']
    local human_mean_s = r(out)
    fmt2 pme_se0[`i']
    local human_se_s = r(out)
    fmt2 pme_mean1[`i']
    local ai_mean_s = r(out)
    fmt2 pme_se1[`i']
    local ai_se_s = r(out)

    putexcel A`row' = ("`name'")
    putexcel B`row' = ("`human_mean_s' (`human_se_s')")
    putexcel C`row' = (pme_rank0[`i'])
    putexcel G`row' = ("`ai_mean_s' (`ai_se_s')")
    putexcel H`row' = (pme_rank1[`i'])

    if (`t' == 1) {
        putexcel D`row' = ("[Referent]")
        putexcel I`row' = ("[Referent]")
    }
    else {
        fmt2 b0[`i']
        local human_b_s = r(out)
        fmt2 lb0[`i']
        local human_lb_s = r(out)
        fmt2 ub0[`i']
        local human_ub_s = r(out)
        pformat p0[`i']
        local human_p_s = r(out)
        fmt2 cohen_d0[`i']
        local human_d_s = r(out)

        fmt2 b1[`i']
        local ai_b_s = r(out)
        fmt2 lb1[`i']
        local ai_lb_s = r(out)
        fmt2 ub1[`i']
        local ai_ub_s = r(out)
        pformat p1[`i']
        local ai_p_s = r(out)
        fmt2 cohen_d1[`i']
        local ai_d_s = r(out)

        putexcel D`row' = ("`human_b_s' (`human_lb_s', `human_ub_s')")
        putexcel E`row' = ("`human_p_s'")
        putexcel F`row' = ("`human_d_s'")
        putexcel I`row' = ("`ai_b_s' (`ai_lb_s', `ai_ub_s')")
        putexcel J`row' = ("`ai_p_s'")
        putexcel K`row' = ("`ai_d_s'")
    }
    local row = `row' + 1
}

display "Viewpoints tables generated successfully."
