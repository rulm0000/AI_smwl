* 4_Cohens_d_Decomposition.do
* Calculates Campbell HLM Cohen's d values for warning-vs-control effects
* and decomposes AI-minus-human differences in Cohen's d.
*
* Cohen's d formula source:
* Campbell Collaboration equation 1.34, Regression coefficient from an
* HLM/mixed effects model (clustered data):
* https://www.campbellcollaboration.org/calculator/equations#regression-coefficient-from-an-hlmmixed-effects-model-clustered-data
*
* Decomposition method:
* Shapley-style two-factor decomposition of d = ADE / D, where
* D = s_pooled / sqrt(lambda), the Campbell effective denominator.
*
* Reference for Shapley decomposition:
* Shorrocks AF. Decomposition procedures for distributional analysis:
* a unified framework based on the Shapley value. J Econ Inequal. 2013.
* https://doi.org/10.1007/s10888-011-9214-z

clear all
set more off
version 19.5

if `"$output"' == "" {
    do "setup.do"
}
capture mkdir "$output/Cohens_d"

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

display "Preparing pooled human participant and AI persona data..."
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
keep if topic <= 8
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

tempfile pooled
save `pooled'

tempfile ddata
tempname dpost
postfile `dpost' str22 sample_name byte sample byte topic str45 topic_name ///
    double b seb lb ub p sy n_warn n_control icc clusters spooled lambda cohen_d denom ///
    using `ddata', replace

foreach s in 0 1 {
    use `pooled', clear
    keep if sample == `s'

    quietly mixed pme ib1.topic || pid: , vce(robust)
    quietly estat icc
    local icc = r(icc2)
    matrix G = e(N_g)
    local clusters = G[1,1]
    quietly summarize pme if e(sample)
    local sy = r(sd)
    local sample_name = cond(`s' == 0, "Human participants", "AI personas")

    foreach t of numlist 2/8 {
        quietly lincom `t'.topic
        local b = r(estimate)
        local seb = r(se)
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
        local denom = `spooled' / sqrt(`lambda')

        topic_name `t'
        local nm = r(name)
        post `dpost' ("`sample_name'") (`s') (`t') ("`nm'") ///
            (`b') (`seb') (`lb') (`ub') (`p') (`sy') (`n_warn') (`n_control') ///
            (`icc') (`clusters') (`spooled') (`lambda') (`d') (`denom')
    }
}
postclose `dpost'

use `ddata', clear
format b seb lb ub p sy icc spooled lambda cohen_d denom %12.9f

preserve
    keep sample topic topic_name b lb ub p cohen_d
    reshape wide b lb ub p cohen_d, i(topic topic_name) j(sample)
    gen topic_order = .
    local order = 1
    foreach t of numlist 5 2 8 6 4 3 7 {
        replace topic_order = `order' if topic == `t'
        local order = `order' + 1
    }
    sort topic_order

    putexcel set "$tables/eTable1_Human_AI_ADEs_Cohens_d.xlsx", replace
    putexcel A1 = ("eTable 1. Effect of warning topic on perceived message effectiveness by sample, n=1,012 human participants and n=1,000 AI personas"), bold
    putexcel B2 = ("Human participants"), bold hcenter
    putexcel E2 = ("AI personas"), bold hcenter
    putexcel A3 = ("Warning topic"), bold
    putexcel B3 = ("ADE (95% CI)"), bold
    putexcel C3 = ("p-value"), bold
    putexcel D3 = ("Cohen's d"), bold
    putexcel E3 = ("ADE (95% CI)"), bold
    putexcel F3 = ("p-value"), bold
    putexcel G3 = ("Cohen's d"), bold

    local row = 4
    putexcel A`row' = ("Control")
    putexcel B`row' = ("[Referent]")
    putexcel E`row' = ("[Referent]")
    local row = `row' + 1

    forvalues i = 1/`=_N' {
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

        putexcel A`row' = (topic_name[`i'])
        putexcel B`row' = ("`human_b_s' (`human_lb_s', `human_ub_s')")
        putexcel C`row' = ("`human_p_s'")
        putexcel D`row' = ("`human_d_s'")
        putexcel E`row' = ("`ai_b_s' (`ai_lb_s', `ai_ub_s')")
        putexcel F`row' = ("`ai_p_s'")
        putexcel G`row' = ("`ai_d_s'")
        local row = `row' + 1
    }
restore

putexcel set "$output/Cohens_d/Cohens_d.xlsx", sheet("Warning_vs_Control") modify
putexcel A1 = ("Cohen's d for warning topics vs. control by sample"), bold
putexcel A2 = ("Formula source") B2 = ("https://www.campbellcollaboration.org/calculator/equations#regression-coefficient-from-an-hlmmixed-effects-model-clustered-data"), bold
putexcel A4 = ("Sample") B4 = ("Warning topic") C4 = ("ADE vs control") D4 = ("SE B") E4 = ("95% CI lower") F4 = ("95% CI upper") G4 = ("p-value") H4 = ("SD of DV") I4 = ("Warning n") J4 = ("Control n") K4 = ("ICC") L4 = ("Clusters") M4 = ("s_pooled") N4 = ("lambda") O4 = ("Cohen's d") P4 = ("Effective denominator"), bold

local row = 5
forvalues i = 1/`=_N' {
    putexcel A`row' = (sample_name[`i']) B`row' = (topic_name[`i']) C`row' = (b[`i']) D`row' = (seb[`i']) E`row' = (lb[`i']) F`row' = (ub[`i']) G`row' = (p[`i']) H`row' = (sy[`i']) I`row' = (n_warn[`i']) J`row' = (n_control[`i']) K`row' = (icc[`i']) L`row' = (clusters[`i']) M`row' = (spooled[`i']) N`row' = (lambda[`i']) O`row' = (cohen_d[`i']) P`row' = (denom[`i'])
    local row = `row' + 1
}

putexcel A21 = ("Rounded Cohen's d ranges"), bold
quietly summarize cohen_d if sample == 0
putexcel A22 = ("Human participants") B22 = (r(min)) C22 = (r(max))
quietly summarize cohen_d if sample == 1
putexcel A23 = ("AI personas") B23 = (r(min)) C23 = (r(max))
putexcel A24 = ("Note") B24 = ("Ranges should be rounded to two decimals in manuscript text."), italic

preserve
    keep sample topic topic_name b cohen_d denom
    reshape wide b cohen_d denom, i(topic topic_name) j(sample)
    rename b0 ade_human
    rename b1 ade_ai
    rename cohen_d0 d_human
    rename cohen_d1 d_ai
    rename denom0 denom_human
    rename denom1 denom_ai

    gen double d_difference = d_ai - d_human
    gen double d_ade_ai_denom_human = ade_ai / denom_human
    gen double d_ade_human_denom_ai = ade_human / denom_ai

    gen double contribution_ade = 0.5 * ((d_ade_ai_denom_human - d_human) + (d_ai - d_ade_human_denom_ai))
    gen double contribution_denom = 0.5 * ((d_ade_human_denom_ai - d_human) + (d_ai - d_ade_ai_denom_human))
    gen double pct_ade = 100 * contribution_ade / d_difference
    gen double pct_denom = 100 * contribution_denom / d_difference

    egen double total_d_diff = total(d_difference)
    egen double total_ade_contrib = total(contribution_ade)
    egen double total_denom_contrib = total(contribution_denom)
    gen double overall_pct_ade = 100 * total_ade_contrib / total_d_diff
    gen double overall_pct_denom = 100 * total_denom_contrib / total_d_diff

    format ade_ai ade_human denom_ai denom_human d_ai d_human d_difference contribution_ade contribution_denom %12.9f
    format pct_ade pct_denom overall_pct_ade overall_pct_denom %9.1f
    sort topic

    putexcel set "$output/Cohens_d/Cohens_d.xlsx", sheet("D_Decomposition") modify
    putexcel A1 = ("Decomposition of AI persona vs human participant Cohen's d differences"), bold
    putexcel A2 = ("Method") B2 = ("Exact Shapley-style decomposition of d=ADE/effective denominator, where effective denominator=s_pooled/sqrt(lambda)."), bold
    putexcel A3 = ("Interpretation") B3 = ("Contribution columns show how much of the AI-minus-human Cohen's d difference is attributable to larger ADEs vs smaller effective denominators."), italic
    putexcel A4 = ("Citation") B4 = ("Shorrocks AF. Decomposition procedures for distributional analysis: a unified framework based on the Shapley value. J Econ Inequal. 2013. https://doi.org/10.1007/s10888-011-9214-z"), italic
    putexcel A6 = ("Warning topic") B6 = ("Human ADE") C6 = ("AI ADE") D6 = ("Human eff. denominator") E6 = ("AI eff. denominator") F6 = ("Human d") G6 = ("AI d") H6 = ("AI-human d diff") I6 = ("ADE contribution") J6 = ("Denominator contribution") K6 = ("ADE contribution %") L6 = ("Denominator contribution %"), bold

    local row = 7
    forvalues i = 1/`=_N' {
        putexcel A`row' = (topic_name[`i']) B`row' = (ade_human[`i']) C`row' = (ade_ai[`i']) D`row' = (denom_human[`i']) E`row' = (denom_ai[`i']) F`row' = (d_human[`i']) G`row' = (d_ai[`i']) H`row' = (d_difference[`i']) I`row' = (contribution_ade[`i']) J`row' = (contribution_denom[`i']) K`row' = (pct_ade[`i']) L`row' = (pct_denom[`i'])
        local row = `row' + 1
    }
    putexcel A15 = ("Across topics") B15 = ("Share of summed AI-human d difference") I15 = (total_ade_contrib[1]) J15 = (total_denom_contrib[1]) K15 = (overall_pct_ade[1]) L15 = (overall_pct_denom[1]), bold
restore

display "Cohen's d warning-vs-control and decomposition sheets updated."
display "Results saved to $output/Cohens_d/Cohens_d.xlsx"
