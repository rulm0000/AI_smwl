* 1_Human_AI_vs_Priority.do
* Compares AI-refined warnings vs. researcher-generated priority warnings
* among human participants and exports eTable 3.

clear all
set more off

* Run setup if globals are not yet defined (e.g. when running this file on its own).
* Use an empty-string check rather than "confirm global", which is not a valid
* Stata command and always errors.
if "$output" == "" {
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

capture program drop topic_name
program define topic_name, rclass
    args t
    local name ""
    if (`t' == 3) local name "Depression and anxiety"
    if (`t' == 4) local name "Negative body image"
    if (`t' == 5) local name "Addiction"
    if (`t' == 6) local name "Sleep disruption"
    if (`t' == 7) local name "Mental health harms to young people"
    if (`t' == 8) local name "Not been proven safe"
    if (`t' == 99) local name "Overall"
    return local name "`name'"
end

display "Loading Human Participant Data..."
use "$human_file", clear

gen is_ai = .
replace is_ai = 1 if version == 4
replace is_ai = 0 if topic == 3 & version == 1
replace is_ai = 0 if topic == 4 & version == 2
replace is_ai = 0 if topic == 5 & version == 3
replace is_ai = 0 if topic == 6 & version == 1
replace is_ai = 0 if topic == 7 & version == 1
replace is_ai = 0 if topic == 8 & version == 1

local topic_order "5 8 6 4 3 7 99"

putexcel set "$tables/eTable3_AI_Refined_vs_Researcher_Generated_ADEs.xlsx", replace
putexcel A1 = ("eTable 3. Impact of message source on perceived message effectiveness, n=1,012 human participants")
putexcel B2 = ("Difference in perceived message effectiveness, AI-refined vs. researcher-generated"), bold
putexcel A3 = ("Message topic"), bold
putexcel B3 = ("ADE (95% CI)"), bold
putexcel C3 = ("p-value"), bold
putexcel D3 = ("Cohen's d"), bold

/*
Cohen's d is calculated using the Campbell Collaboration HLM/mixed-effects
formula for a regression coefficient from a clustered data model:
https://www.campbellcollaboration.org/calculator/equations#regression-coefficient-from-an-hlmmixed-effects-model-clustered-data

Inputs are the ADE/B from mixed pme is_ai || pid:, vce(robust); the plain SD of
pme in the analytic sample; AI-refined and researcher-generated sample sizes;
the ICC from estat icc; and pid cluster counts.
*/

local row = 4
foreach t of local topic_order {
    if (`t' == 99) {
        local condition "inlist(topic, 3,4,5,6,7,8)"
    }
    else {
        local condition "topic == `t'"
    }
    topic_name `t'
    local name = r(name)

    display "--- ADE: `name' ---"
    quietly mixed pme is_ai if `condition' & !missing(is_ai) || pid: , vce(robust)
    quietly lincom is_ai

    local ade = r(estimate)
    local lb = r(lb)
    local ub = r(ub)
    local p = r(p)

    quietly estat icc
    local icc = r(icc2)
    matrix G = e(N_g)
    local clusters = G[1,1]

    preserve
        keep if `condition' & !missing(is_ai) & !missing(pme)
        quietly summarize pme
        local sy = r(sd)
        quietly count if is_ai == 1
        local n1 = r(N)
        quietly count if is_ai == 0
        local n2 = r(N)
    restore

    local n = `n1' + `n2'
    local spooled = sqrt(((`sy'^2) * (`n' - 1) - ((`ade'^2) * `n1' * `n2' / `n')) / (`n' - 2))
    local lambda = 1 - (2 * (`n' / `clusters') * `icc') / (`n' - 1)
    local cohen_d = (`ade' / `spooled') * sqrt(`lambda')

    fmt2 `ade'
    local ade_s = r(out)
    fmt2 `lb'
    local lb_s = r(out)
    fmt2 `ub'
    local ub_s = r(out)
    pformat `p'
    local p_s = r(out)
    fmt2 `cohen_d'
    local d_s = r(out)

    if (`t' == 99) {
        putexcel A`row' = ("`name'"), bold
        putexcel B`row' = ("`ade_s' (`lb_s', `ub_s')"), bold
        putexcel C`row' = ("`p_s'"), bold
        putexcel D`row' = ("`d_s'"), bold
    }
    else {
        putexcel A`row' = ("`name'")
        putexcel B`row' = ("`ade_s' (`lb_s', `ub_s')")
        putexcel C`row' = ("`p_s'")
        putexcel D`row' = ("`d_s'")
    }

    local row = `row' + 1
}

copy "$tables/eTable3_AI_Refined_vs_Researcher_Generated_ADEs.xlsx" "$tables/Human_AI_vs_Priority_Results.xlsx", replace

display "Human AI vs. priority analysis complete."
display "Results saved to $tables/eTable3_AI_Refined_vs_Researcher_Generated_ADEs.xlsx"
