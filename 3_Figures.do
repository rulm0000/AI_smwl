* 3_Figures.do
* Generates Viewpoints figures in the same visual style as the
* Social Media Warning Labels paper figures.

clear all
set more off

* Run setup if globals are not yet defined (e.g. when running this file on its own).
* Use an empty-string check rather than "confirm global", which is not a valid
* Stata command and always errors.
if "$output" == "" {
    do "setup.do"
}

set scheme s1mono

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
    if (`t' == 99) local name "OVERALL"
    return local name "`name'"
end

capture program drop post_ai_refined_mean
program define post_ai_refined_mean
    args handle outcome topic is_ai
    if (`topic' == 99) {
        if (`is_ai' == 0) quietly lincom _cons
        if (`is_ai' == 1) quietly lincom _cons + 1.is_ai
    }
    else {
        if (`is_ai' == 0) {
            if (`topic' == 3) quietly lincom _cons
            else quietly lincom _cons + `topic'.topic
        }
        if (`is_ai' == 1) {
            if (`topic' == 3) quietly lincom _cons + 1.is_ai
            else quietly lincom _cons + `topic'.topic + 1.is_ai + `topic'.topic#1.is_ai
        }
    }
    post `handle' (`topic') (`is_ai') (r(estimate)) (r(lb)) (r(ub))
end

capture program drop post_sample_mean
program define post_sample_mean
    args handle topic sample
    if (`sample' == 0) {
        if (`topic' == 1) quietly lincom _cons
        else quietly lincom _cons + `topic'.topic
    }
    if (`sample' == 1) {
        if (`topic' == 1) quietly lincom _cons + 1.sample
        else quietly lincom _cons + `topic'.topic + 1.sample + `topic'.topic#1.sample
    }
    post `handle' (`topic') (`sample') (r(estimate)) (r(lb)) (r(ub))
end

capture program drop post_sample_ade
program define post_sample_ade
    args handle topic sample
    if (`sample' == 0) quietly lincom `topic'.topic
    if (`sample' == 1) quietly lincom `topic'.topic + `topic'.topic#1.sample
    post `handle' (`topic') (`sample') (r(estimate)) (r(lb)) (r(ub))
end

capture program drop post_sample_difference
program define post_sample_difference
    args handle topic
    if (`topic' == 1) quietly lincom 1.sample
    else quietly lincom 1.sample + `topic'.topic#1.sample
    post `handle' (`topic') (r(estimate)) (r(lb)) (r(ub))
end

* ==============================================================================
* Human participant data: researcher-generated vs. AI-refined warnings
* ==============================================================================

display "Loading Human Participant Data for Figures..."
use "$human_file", clear

gen is_ai = .
replace is_ai = 1 if version == 4
replace is_ai = 0 if topic == 3 & version == 1
replace is_ai = 0 if topic == 4 & version == 2
replace is_ai = 0 if topic == 5 & version == 3
replace is_ai = 0 if topic == 6 & version == 1
replace is_ai = 0 if topic == 7 & version == 1
replace is_ai = 0 if topic == 8 & version == 1
keep if inlist(topic, 3, 4, 5, 6, 7, 8)
keep if !missing(is_ai)

tempfile main_data
save `main_data'

* ==============================================================================
* FIGURE 1: PME means, researcher-generated vs. AI-refined
* ==============================================================================

tempfile pme_rg_ai
tempname post_pme
postfile `post_pme' byte topic byte is_ai double estimate lb ub using `pme_rg_ai', replace

use `main_data', clear
mixed pme ib3.topic##ib0.is_ai || pid: , vce(robust) mle
foreach t of numlist 3/8 {
    post_ai_refined_mean `post_pme' pme `t' 0
    post_ai_refined_mean `post_pme' pme `t' 1
}
mixed pme ib0.is_ai || pid: , vce(robust) mle
post_ai_refined_mean `post_pme' pme 99 0
post_ai_refined_mean `post_pme' pme 99 1
postclose `post_pme'

tempfile pme_sig
tempname post_sig
postfile `post_sig' byte topic double p str3 star using `pme_sig', replace

foreach t of numlist 3/8 {
    quietly mixed pme ib0.is_ai if topic == `t' || pid: , vce(robust) mle
    quietly lincom 1.is_ai
    local p = r(p)
    local star ""
    if (`p' < 0.001) local star "***"
    else if (`p' < 0.01) local star "**"
    else if (`p' < 0.05) local star "*"
    post `post_sig' (`t') (`p') ("`star'")
}
quietly mixed pme ib0.is_ai || pid: , vce(robust) mle
quietly lincom 1.is_ai
local p = r(p)
local star ""
if (`p' < 0.001) local star "***"
else if (`p' < 0.01) local star "**"
else if (`p' < 0.05) local star "*"
post `post_sig' (99) (`p') ("`star'")
postclose `post_sig'

use `pme_rg_ai', clear
preserve
    keep if is_ai == 0 & topic != 99
    sort estimate
    gen topic_id = _n
    keep topic topic_id
    tempfile researcher_order
    save `researcher_order'
restore

merge m:1 topic using `researcher_order', nogen
merge m:1 topic using `pme_sig', nogen
replace topic_id = 7 if topic == 99
gen y = topic_id
replace y = topic_id - 0.18 if is_ai == 0
replace y = topic_id + 0.18 if is_ai == 1
bysort topic: egen max_ub = max(ub)
gen mean_lbl = trim(string(estimate, "%9.2f"))
gen mean_lbl_x = ub + 0.04
gen star_x = max_ub + 0.35
gen star_y = topic_id

local ylab ""
forvalues j = 1/7 {
    quietly summarize topic if topic_id == `j', meanonly
    local t = r(mean)
    topic_name `t'
    local lbl = r(name)
    local ylab `"`ylab' `j' "`lbl'""'
}

local ymin = 0.5
local ymax = 7.5
twoway (bar estimate y if is_ai == 0, horizontal barwidth(0.32) color(gs12) lcolor(black) lwidth(vthin)) ///
       (rspike lb ub y if is_ai == 0, horizontal lcolor(black) lwidth(vthin)) ///
       (bar estimate y if is_ai == 1, horizontal barwidth(0.32) color(gs8) lcolor(black) lwidth(vthin)) ///
       (rspike lb ub y if is_ai == 1, horizontal lcolor(black) lwidth(vthin)) ///
       (scatter y mean_lbl_x if is_ai == 0, msymbol(none) ///
           mlabel(mean_lbl) mlabsize(vsmall) mlabcolor(black) mlabposition(3)) ///
       (scatter y mean_lbl_x if is_ai == 1, msymbol(none) ///
           mlabel(mean_lbl) mlabsize(vsmall) mlabcolor(black) mlabposition(3)) ///
       (scatter star_y star_x if is_ai == 1 & star != "", msymbol(none) ///
           mlabel(star) mlabsize(small) mlabcolor(black) mlabposition(3)), ///
    yscale(reverse range(`ymin' `ymax')) ///
    ylabel(`ylab', angle(0) labsize(small) nogrid) ///
    ytick(1/7) ///
    xscale(range(1 5) alt) ///
    xlabel(1(1)5, labsize(vsmall)) ///
    xtitle("Mean perceived message effectiveness", size(small)) ///
    ytitle("") ///
    legend(order(1 "Researcher-generated" 3 "AI-refined") size(vsmall) rows(1) region(lcolor(white)) position(6) ring(1)) ///
    graphregion(color(white)) name(fig_pme_rg_ai, replace)

graph export "$human_generated_figures/Figure_AI_vs_Human_Means.png", name(fig_pme_rg_ai) replace width(2200)
graph export "$human_generated_figures/Figure3_AI_vs_Human_Means.png", name(fig_pme_rg_ai) replace width(2200)

* ==============================================================================
* FIGURE 2: Awareness means, researcher-generated vs. AI-refined
* ==============================================================================

tempfile aware_rg_ai
tempname post_aware
postfile `post_aware' byte topic byte is_ai double estimate lb ub using `aware_rg_ai', replace

use `main_data', clear
mixed aware ib3.topic##ib0.is_ai || pid: , vce(robust) mle
foreach t of numlist 3/8 {
    post_ai_refined_mean `post_aware' aware `t' 0
    post_ai_refined_mean `post_aware' aware `t' 1
}
mixed aware ib0.is_ai || pid: , vce(robust) mle
post_ai_refined_mean `post_aware' aware 99 0
post_ai_refined_mean `post_aware' aware 99 1
postclose `post_aware'

use `aware_rg_ai', clear
merge m:1 topic using `researcher_order', nogen
replace topic_id = 7 if topic == 99
gen y = topic_id
replace y = topic_id - 0.18 if is_ai == 0
replace y = topic_id + 0.18 if is_ai == 1

twoway (bar estimate y if is_ai == 0, horizontal barwidth(0.32) color(gs12) lcolor(black) lwidth(vthin)) ///
       (rspike lb ub y if is_ai == 0, horizontal lcolor(black) lwidth(vthin)) ///
       (bar estimate y if is_ai == 1, horizontal barwidth(0.32) color(gs8) lcolor(black) lwidth(vthin)) ///
       (rspike lb ub y if is_ai == 1, horizontal lcolor(black) lwidth(vthin)), ///
    yscale(reverse range(`ymin' `ymax')) ///
    ylabel(`ylab', angle(0) labsize(small) nogrid) ///
    ytick(1/7) ///
    xscale(range(1 5) alt) ///
    xlabel(1(1)5, labsize(vsmall)) ///
    xtitle("Predicted Mean Perceived Awareness of Harms", size(small)) ///
    ytitle("") ///
    legend(order(1 "Researcher-generated" 3 "AI-refined") size(vsmall) rows(1) region(lcolor(white)) position(6) ring(1)) ///
    graphregion(color(white)) name(fig_aware_rg_ai, replace)

graph export "$human_generated_figures/Figure_BarChart_Awareness_Means.png", name(fig_aware_rg_ai) replace width(2200)

* ==============================================================================
* FIGURE 3: Forest plot, PME differences
* ==============================================================================

tempfile diff_rg_ai
tempname post_diff
postfile `post_diff' byte topic double diff lb ub using `diff_rg_ai', replace

use `main_data', clear
mixed pme ib0.is_ai if topic == 3 || pid: , vce(robust) mle
foreach t of numlist 3/8 {
    quietly mixed pme ib0.is_ai if topic == `t' || pid: , vce(robust) mle
    quietly lincom 1.is_ai
    post `post_diff' (`t') (r(estimate)) (r(lb)) (r(ub))
}
quietly mixed pme ib0.is_ai || pid: , vce(robust) mle
quietly lincom 1.is_ai
post `post_diff' (99) (r(estimate)) (r(lb)) (r(ub))
postclose `post_diff'

use `diff_rg_ai', clear
merge m:1 topic using `researcher_order', nogen
replace topic_id = 7.2 if topic == 99
gen diff_lbl = trim(string(diff, "%9.2f"))

local ylab_box ""
forvalues j = 1/6 {
    quietly summarize topic if topic_id == `j', meanonly
    local t = r(mean)
    topic_name `t'
    local lbl = r(name)
    local ylab_box `"`ylab_box' `j' "`lbl'""'
}
local ylab_box `"`ylab_box' 7.2 "OVERALL""'

twoway (pci 0.5 -0.255 0.5 0.255, lcolor(black) lwidth(vthin)) ///
       (pci 6.5 -0.255 6.5 0.255, lcolor(black) lwidth(vthin)) ///
       (pci 0.5 -0.255 6.5 -0.255, lcolor(black) lwidth(vthin)) ///
       (pci 0.5 0.255 6.5 0.255, lcolor(black) lwidth(vthin)) ///
       (pci 6.75 -0.255 6.75 0.255, lcolor(black) lwidth(vthin)) ///
       (pci 7.55 -0.255 7.55 0.255, lcolor(black) lwidth(vthin)) ///
       (pci 6.75 -0.255 7.55 -0.255, lcolor(black) lwidth(vthin)) ///
       (pci 6.75 0.255 7.55 0.255, lcolor(black) lwidth(vthin)) ///
       (pci 0.5 0 6.5 0, lcolor(gs8) lpattern(shortdash)) ///
       (pci 6.75 0 7.55 0, lcolor(gs8) lpattern(shortdash)) ///
       (pci 7.55 -0.2 7.68 -0.2, lcolor(black) lwidth(vthin)) ///
       (pci 7.55 -0.1 7.68 -0.1, lcolor(black) lwidth(vthin)) ///
       (pci 7.55 0 7.68 0, lcolor(black) lwidth(vthin)) ///
       (pci 7.55 0.1 7.68 0.1, lcolor(black) lwidth(vthin)) ///
       (pci 7.55 0.2 7.68 0.2, lcolor(black) lwidth(vthin)) ///
       (rspike lb ub topic_id, horizontal lcolor(black) lwidth(vthin)) ///
       (scatter topic_id diff, mcolor(black) msymbol(D) msize(small) ///
           mlabel(diff_lbl) mlabsize(small) mlabcolor(black) mlabposition(12)), ///
    yscale(noline reverse range(0.5 7.68)) ///
    ylabel(`ylab_box', angle(0) labsize(small) nogrid) ///
    ytick(1/6 7.2) ///
    xscale(noline range(-0.255 0.255)) ///
    xlabel(-0.2(0.1)0.2, labsize(small) noticks) ///
    xtitle("AI-refined minus researcher-generated", size(small)) ///
    ytitle("") ///
    legend(off) ///
    plotregion(lcolor(none)) ///
    graphregion(color(white) margin(l+12 r+8 t+4 b+2)) ///
    title("Mean Difference in Perceived Message Effectiveness" "(95% CI)", size(medsmall) span margin(l+48)) ///
    name(fig_fp_rg_ai, replace)

graph export "$human_generated_figures/Figure_AI_vs_Human_BarChart.png", name(fig_fp_rg_ai) replace width(2200)
graph export "$human_generated_figures/Figure_ForestPlot_PME_Differences.png", name(fig_fp_rg_ai) replace width(2200)

* Alternative Figure 3 option: Campbell HLM Cohen's d, AI-refined vs researcher-generated
tempfile d_rg_ai
tempname post_d_rg_ai
postfile `post_d_rg_ai' byte topic double d lb ub using `d_rg_ai', replace

use `main_data', clear
foreach t of numlist 3/8 {
    quietly mixed pme ib0.is_ai if topic == `t' || pid: , vce(robust) mle
    quietly lincom 1.is_ai
    local b = r(estimate)
    local lb = r(lb)
    local ub = r(ub)

    quietly estat icc
    local icc = r(icc2)
    matrix G = e(N_g)
    local clusters = G[1,1]

    preserve
        keep if topic == `t' & !missing(is_ai) & !missing(pme)
        quietly summarize pme
        local sy = r(sd)
        quietly count if is_ai == 1
        local n1 = r(N)
        quietly count if is_ai == 0
        local n2 = r(N)
    restore

    local n = `n1' + `n2'
    local spooled = sqrt(((`sy'^2) * (`n' - 1) - ((`b'^2) * `n1' * `n2' / `n')) / (`n' - 2))
    local lambda = 1 - (2 * (`n' / `clusters') * `icc') / (`n' - 1)
    local scale = sqrt(`lambda') / `spooled'
    post `post_d_rg_ai' (`t') (`b' * `scale') (`lb' * `scale') (`ub' * `scale')
}

quietly mixed pme ib0.is_ai || pid: , vce(robust) mle
quietly lincom 1.is_ai
local b = r(estimate)
local lb = r(lb)
local ub = r(ub)
quietly estat icc
local icc = r(icc2)
matrix G = e(N_g)
local clusters = G[1,1]
preserve
    keep if !missing(is_ai) & !missing(pme)
    quietly summarize pme
    local sy = r(sd)
    quietly count if is_ai == 1
    local n1 = r(N)
    quietly count if is_ai == 0
    local n2 = r(N)
restore
local n = `n1' + `n2'
local spooled = sqrt(((`sy'^2) * (`n' - 1) - ((`b'^2) * `n1' * `n2' / `n')) / (`n' - 2))
local lambda = 1 - (2 * (`n' / `clusters') * `icc') / (`n' - 1)
local scale = sqrt(`lambda') / `spooled'
post `post_d_rg_ai' (99) (`b' * `scale') (`lb' * `scale') (`ub' * `scale')
postclose `post_d_rg_ai'

use `d_rg_ai', clear
merge m:1 topic using `researcher_order', nogen
replace topic_id = 7.2 if topic == 99
gen d_lbl = trim(string(d, "%9.2f"))

twoway (pci 0.5 -0.13 0.5 0.13, lcolor(black) lwidth(vthin)) ///
       (pci 6.5 -0.13 6.5 0.13, lcolor(black) lwidth(vthin)) ///
       (pci 0.5 -0.13 6.5 -0.13, lcolor(black) lwidth(vthin)) ///
       (pci 0.5 0.13 6.5 0.13, lcolor(black) lwidth(vthin)) ///
       (pci 6.75 -0.13 6.75 0.13, lcolor(black) lwidth(vthin)) ///
       (pci 7.55 -0.13 7.55 0.13, lcolor(black) lwidth(vthin)) ///
       (pci 6.75 -0.13 7.55 -0.13, lcolor(black) lwidth(vthin)) ///
       (pci 6.75 0.13 7.55 0.13, lcolor(black) lwidth(vthin)) ///
       (pci 0.5 0 6.5 0, lcolor(gs8) lpattern(shortdash)) ///
       (pci 6.75 0 7.55 0, lcolor(gs8) lpattern(shortdash)) ///
       (pci 7.55 -0.1 7.68 -0.1, lcolor(black) lwidth(vthin)) ///
       (pci 7.55 0 7.68 0, lcolor(black) lwidth(vthin)) ///
       (pci 7.55 0.1 7.68 0.1, lcolor(black) lwidth(vthin)) ///
       (rspike lb ub topic_id, horizontal lcolor(black) lwidth(vthin)) ///
       (scatter topic_id d, mcolor(black) msymbol(D) msize(small) ///
           mlabel(d_lbl) mlabsize(small) mlabcolor(black) mlabposition(12)), ///
    yscale(noline reverse range(0.5 7.68)) ///
    ylabel(`ylab_box', angle(0) labsize(small) nogrid) ///
    ytick(1/6 7.2) ///
    xscale(noline range(-0.13 0.13)) ///
    xlabel(-0.1 0 0.1, labsize(small) noticks) ///
    xtitle("AI-refined minus researcher-generated", size(small)) ///
    ytitle("") ///
    legend(off) ///
    plotregion(lcolor(none)) ///
    graphregion(color(white) margin(l+12 r+8 t+4 b+2)) ///
    title("Cohen's d" "(95% CI)", size(medsmall) span margin(l+48)) ///
    name(fig_fp_rg_ai_d, replace)

graph export "$human_generated_figures/Figure_ForestPlot_Cohens_d_AI_Refined_vs_Researcher_Generated.png", name(fig_fp_rg_ai_d) replace width(2200)

* ==============================================================================
* Pooled data: human participants vs. AI personas
* ==============================================================================

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

tempfile human_replication
save `human_replication'

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
append using `human_replication'

label define samplelab 0 "Human participants" 1 "AI personas", replace
label values sample samplelab

tempfile pooled_data
save `pooled_data'

mixed pme ib1.topic##ib0.sample || pid: , vce(robust) mle

* ==============================================================================
* FIGURE 4: ADEs vs. control, human participants vs. AI personas
* ==============================================================================

tempfile ade_data
tempname adehold
postfile `adehold' byte topic byte sample double ade lb ub using `ade_data', replace

foreach t of numlist 2/8 {
    post_sample_ade `adehold' `t' 0
    post_sample_ade `adehold' `t' 1
}
postclose `adehold'

use `ade_data', clear
preserve
    keep if sample == 0
    sort ade
    gen topic_id = _n
    keep topic topic_id
    tempfile human_ade_order
    save `human_ade_order'
restore

merge m:1 topic using `human_ade_order', nogen
gen y = topic_id
replace y = topic_id - 0.12 if sample == 0
replace y = topic_id + 0.12 if sample == 1
gen ade_lbl = trim(string(ade, "%9.2f"))

local ylab_ade ""
forvalues j = 1/7 {
    quietly summarize topic if topic_id == `j', meanonly
    local t = r(mean)
    topic_name `t'
    local lbl = r(name)
    local ylab_ade `"`ylab_ade' `j' "`lbl'""'
}

local ymin_ade = 0.5
local ymax_ade = 7.5
twoway (rspike lb ub y if sample == 0, horizontal lcolor(gs8) lwidth(vthin)) ///
       (scatter y ade if sample == 0, mcolor(gs8) msymbol(D) msize(small) ///
           mlabel(ade_lbl) mlabsize(vsmall) mlabcolor(gs8) mlabposition(12)) ///
       (rspike lb ub y if sample == 1, horizontal lcolor(black) lwidth(vthin)) ///
       (scatter y ade if sample == 1, mcolor(black) msymbol(D) msize(small) ///
           mlabel(ade_lbl) mlabsize(vsmall) mlabcolor(black) mlabposition(12)), ///
    yscale(reverse range(`ymin_ade' `ymax_ade')) ///
    ylabel(`ylab_ade', angle(0) labsize(small) nogrid) ///
    ytick(1/7) ///
    xscale(range(-0.1 1.6)) ///
    xlabel(0 0.5 1 1.5, labsize(small)) ///
    xline(0, lcolor(gs8) lpattern(shortdash)) ///
    xtitle("") ///
    ytitle("") ///
    title("Effects on Perceived Message Effectiveness" "ADE (95% CI)", size(medsmall) span margin(l+42)) ///
    legend(order(2 "Human participants" 4 "AI personas") size(vsmall) rows(1) region(lcolor(white)) position(6) ring(1)) ///
    graphregion(color(white) margin(l+12 r+8 t+4 b+2)) name(fig_human_ai_ade, replace)

graph export "$ai_human_rated_figures/Figure_Human_AI_ADE.png", name(fig_human_ai_ade) replace width(2400)
graph export "$ai_human_rated_figures/Figure_BarChart_ADE_Replication.png", name(fig_human_ai_ade) replace width(2400)

* ==============================================================================
* FIGURE 5: PME means with control, human participants vs. AI personas
* ==============================================================================

tempfile sample_means
tempname meanshold
postfile `meanshold' byte topic byte sample double estimate lb ub using `sample_means', replace

foreach t of numlist 1/8 {
    post_sample_mean `meanshold' `t' 0
    post_sample_mean `meanshold' `t' 1
}
postclose `meanshold'

tempfile sample_pairwise
tempname pairhold
postfile `pairhold' byte topic double p str3 star using `sample_pairwise', replace

foreach t of numlist 1/8 {
    if (`t' == 1) quietly lincom 1.sample
    else quietly lincom 1.sample + `t'.topic#1.sample
    local p = r(p)
    local star ""
    if (`p' < 0.001) local star "***"
    else if (`p' < 0.01) local star "**"
    else if (`p' < 0.05) local star "*"
    post `pairhold' (`t') (`p') ("`star'")
}
postclose `pairhold'

use `sample_means', clear
preserve
    keep if sample == 0
    sort estimate
    gen topic_id = _n
    keep topic topic_id
    tempfile human_mean_order
    save `human_mean_order'
restore

merge m:1 topic using `human_mean_order', nogen
merge m:1 topic using `sample_pairwise', nogen
gen y = topic_id
replace y = topic_id - 0.18 if sample == 0
replace y = topic_id + 0.18 if sample == 1
gen mean_lbl = trim(string(estimate, "%9.2f"))
gen mean_lbl_x = ub + 0.08
bysort topic: egen max_ub_pair = max(ub)
gen star_x = max_ub_pair + 0.45
gen star_y = topic_id

local ylab_mean ""
forvalues j = 1/8 {
    quietly summarize topic if topic_id == `j', meanonly
    local t = r(mean)
    topic_name `t'
    local lbl = r(name)
    local ylab_mean `"`ylab_mean' `j' "`lbl'""'
}

local ymin_mean = 0.5
local ymax_mean = 8.5
twoway (bar estimate y if sample == 0, horizontal barwidth(0.32) color(gs12) lcolor(black) lwidth(vthin)) ///
       (rspike lb ub y if sample == 0, horizontal lcolor(black) lwidth(vthin)) ///
       (bar estimate y if sample == 1, horizontal barwidth(0.32) color(gs8) lcolor(black) lwidth(vthin)) ///
       (rspike lb ub y if sample == 1, horizontal lcolor(black) lwidth(vthin)) ///
       (scatter y mean_lbl_x if sample == 0, msymbol(none) ///
           mlabel(mean_lbl) mlabsize(vsmall) mlabcolor(black) mlabposition(3)) ///
       (scatter y mean_lbl_x if sample == 1, msymbol(none) ///
           mlabel(mean_lbl) mlabsize(vsmall) mlabcolor(black) mlabposition(3)) ///
       (scatter star_y star_x if sample == 1 & star != "", msymbol(none) ///
           mlabel(star) mlabsize(small) mlabcolor(black) mlabposition(3)), ///
    yscale(reverse range(`ymin_mean' `ymax_mean')) ///
    ylabel(`ylab_mean', angle(0) labsize(small) nogrid) ///
    ytick(1/8) ///
    xscale(range(1 5) alt) ///
    xlabel(1(1)5, labsize(vsmall)) ///
    xtitle("Mean perceived message effectiveness", size(small)) ///
    ytitle("") ///
    legend(order(1 "Human participants" 3 "AI personas") size(vsmall) rows(1) region(lcolor(white)) position(6) ring(1)) ///
    graphregion(color(white)) name(fig_human_ai_means, replace)

graph export "$ai_human_rated_figures/Figure_Human_AI_Means_Bars_With_Control.png", name(fig_human_ai_means) replace width(2400)
graph export "$ai_human_rated_figures/Figure2_Human_AI_Means_Bars_With_Control.png", name(fig_human_ai_means) replace width(2400)

tempfile sample_diffs
tempname diffhold
postfile `diffhold' byte topic double diff lb ub using `sample_diffs', replace

foreach t of numlist 1/8 {
    post_sample_difference `diffhold' `t'
}
postclose `diffhold'

use `sample_diffs', clear
merge m:1 topic using `human_mean_order', nogen
gen diff_lbl = trim(string(diff, "%9.2f"))

twoway (rspike lb ub topic_id, horizontal lcolor(black) lwidth(vthin)) ///
       (scatter topic_id diff, mcolor(black) msymbol(D) msize(small) ///
           mlabel(diff_lbl) mlabsize(vsmall) mlabcolor(black) mlabposition(12)), ///
    yscale(reverse range(`ymin_mean' `ymax_mean')) ///
    ylabel(`ylab_mean', angle(0) labsize(small) nogrid) ///
    ytick(1/8) ///
    xscale(range(-0.8 0.6)) ///
    xlabel(-0.8(0.2)0.6, labsize(small)) ///
    xline(0, lcolor(gs8) lpattern(shortdash)) ///
    xtitle("AI personas minus human participants", size(small)) ///
    ytitle("") ///
    title("Mean Difference in Perceived Message Effectiveness" "(95% CI)", size(medsmall) span margin(l+48)) ///
    legend(off) ///
    graphregion(color(white) margin(l+12 r+8 t+4 b+2)) name(fig_human_ai_sample_diff, replace)

graph export "$ai_human_rated_figures/Figure_Human_AI_Means_With_Control.png", name(fig_human_ai_sample_diff) replace width(2400)

* Alternative Figure 2 option: mean differences with pooled overall row
tempfile sample_diffs_overall
use `pooled_data', clear
quietly mixed pme ib0.sample || pid: , vce(robust) mle
quietly lincom 1.sample

clear
set obs 1
gen byte topic = 99
gen double diff = r(estimate)
gen double lb = r(lb)
gen double ub = r(ub)
gen double topic_id = 8.4
tempfile sample_overall_row
save `sample_overall_row'

use `sample_diffs', clear
merge m:1 topic using `human_mean_order', nogen
append using `sample_overall_row'
replace topic_id = 9.2 if topic == 99
gen diff_lbl_overall = trim(string(diff, "%9.2f"))

local ylab_sample_box ""
forvalues j = 1/8 {
    quietly summarize topic if topic_id == `j', meanonly
    local t = r(mean)
    topic_name `t'
    local lbl = r(name)
    local ylab_sample_box `"`ylab_sample_box' `j' "`lbl'""'
}
local ylab_sample_box `"`ylab_sample_box' 9.2 "OVERALL""'

twoway (pci 0.5 -0.805 0.5 0.605, lcolor(black) lwidth(vthin)) ///
       (pci 8.5 -0.805 8.5 0.605, lcolor(black) lwidth(vthin)) ///
       (pci 0.5 -0.805 8.5 -0.805, lcolor(black) lwidth(vthin)) ///
       (pci 0.5 0.605 8.5 0.605, lcolor(black) lwidth(vthin)) ///
       (pci 8.75 -0.805 8.75 0.605, lcolor(black) lwidth(vthin)) ///
       (pci 9.55 -0.805 9.55 0.605, lcolor(black) lwidth(vthin)) ///
       (pci 8.75 -0.805 9.55 -0.805, lcolor(black) lwidth(vthin)) ///
       (pci 8.75 0.605 9.55 0.605, lcolor(black) lwidth(vthin)) ///
       (pci 0.5 0 8.5 0, lcolor(gs8) lpattern(shortdash)) ///
       (pci 8.75 0 9.55 0, lcolor(gs8) lpattern(shortdash)) ///
       (pci 1 -0.805 1 -0.775, lcolor(black) lwidth(vthin)) ///
       (pci 2 -0.805 2 -0.775, lcolor(black) lwidth(vthin)) ///
       (pci 3 -0.805 3 -0.775, lcolor(black) lwidth(vthin)) ///
       (pci 4 -0.805 4 -0.775, lcolor(black) lwidth(vthin)) ///
       (pci 5 -0.805 5 -0.775, lcolor(black) lwidth(vthin)) ///
       (pci 6 -0.805 6 -0.775, lcolor(black) lwidth(vthin)) ///
       (pci 7 -0.805 7 -0.775, lcolor(black) lwidth(vthin)) ///
       (pci 8 -0.805 8 -0.775, lcolor(black) lwidth(vthin)) ///
       (pci 9.2 -0.805 9.2 -0.775, lcolor(black) lwidth(vthin)) ///
       (pci 9.55 -0.8 9.68 -0.8, lcolor(black) lwidth(vthin)) ///
       (pci 9.55 -0.6 9.68 -0.6, lcolor(black) lwidth(vthin)) ///
       (pci 9.55 -0.4 9.68 -0.4, lcolor(black) lwidth(vthin)) ///
       (pci 9.55 -0.2 9.68 -0.2, lcolor(black) lwidth(vthin)) ///
       (pci 9.55 0 9.68 0, lcolor(black) lwidth(vthin)) ///
       (pci 9.55 0.2 9.68 0.2, lcolor(black) lwidth(vthin)) ///
       (pci 9.55 0.4 9.68 0.4, lcolor(black) lwidth(vthin)) ///
       (pci 9.55 0.6 9.68 0.6, lcolor(black) lwidth(vthin)) ///
       (rspike lb ub topic_id, horizontal lcolor(black) lwidth(vthin)) ///
       (scatter topic_id diff, mcolor(black) msymbol(D) msize(small) ///
           mlabel(diff_lbl_overall) mlabsize(vsmall) mlabcolor(black) mlabposition(12)), ///
    yscale(noline reverse range(0.5 9.68)) ///
    ylabel(`ylab_sample_box', angle(0) labsize(small) nogrid noticks labgap(vsmall)) ///
    ytick("") ///
    xscale(noline range(-0.805 0.605)) ///
    xlabel(-0.8(0.2)0.6, labsize(small) noticks labgap(vsmall)) ///
    xtitle("AI personas minus human participants", size(small)) ///
    ytitle("") ///
    legend(off) ///
    plotregion(lcolor(none)) ///
    graphregion(color(white) margin(l+12 r+8 t+4 b+2)) ///
    title("Mean Difference in Perceived Message Effectiveness" "(95% CI)", size(medsmall) span margin(l+24)) ///
    name(fig_human_ai_sample_diff_overall, replace)

graph export "$ai_human_rated_figures/Figure_Human_AI_Means_With_Control_With_Overall.png", name(fig_human_ai_sample_diff_overall) replace width(2400) height(1900)

* Alternative Figure 2 option: Campbell HLM Cohen's d, AI personas vs human participants
tempfile sample_diffs_d
tempname diffdhold
postfile `diffdhold' byte topic double d lb ub using `sample_diffs_d', replace

use `pooled_data', clear
quietly mixed pme ib1.topic##ib0.sample || pid: , vce(robust) mle
quietly estat icc
local icc = r(icc2)

foreach t of numlist 1/8 {
    if (`t' == 1) quietly lincom 1.sample
    else quietly lincom 1.sample + `t'.topic#1.sample
    local b = r(estimate)
    local lb = r(lb)
    local ub = r(ub)

    preserve
        keep if topic == `t' & !missing(sample) & !missing(pme)
        quietly summarize pme
        local sy = r(sd)
        quietly count if sample == 1
        local n1 = r(N)
        quietly count if sample == 0
        local n2 = r(N)
        quietly levelsof pid, local(pid_levels)
        local clusters : word count `pid_levels'
    restore

    local n = `n1' + `n2'
    local spooled = sqrt(((`sy'^2) * (`n' - 1) - ((`b'^2) * `n1' * `n2' / `n')) / (`n' - 2))
    local lambda = 1 - (2 * (`n' / `clusters') * `icc') / (`n' - 1)
    local scale = sqrt(`lambda') / `spooled'
    post `diffdhold' (`t') (`b' * `scale') (`lb' * `scale') (`ub' * `scale')
}
postclose `diffdhold'

use `sample_diffs_d', clear
merge m:1 topic using `human_mean_order', nogen
gen d_lbl = trim(string(d, "%9.2f"))

twoway (rspike lb ub topic_id, horizontal lcolor(black) lwidth(vthin)) ///
       (scatter topic_id d, mcolor(black) msymbol(D) msize(small) ///
           mlabel(d_lbl) mlabsize(vsmall) mlabcolor(black) mlabposition(12)), ///
    yscale(reverse range(`ymin_mean' `ymax_mean')) ///
    ylabel(`ylab_mean', angle(0) labsize(small) nogrid) ///
    ytick(1/8) ///
    xscale(range(-1.2 0.8)) ///
    xlabel(-1.2(0.4)0.8, labsize(small)) ///
    xline(0, lcolor(gs8) lpattern(shortdash)) ///
    xtitle("AI personas minus human participants", size(small)) ///
    ytitle("") ///
    title("Cohen's d" "(95% CI)", size(medsmall) span margin(l+24)) ///
    legend(off) ///
    graphregion(color(white) margin(l+12 r+8 t+4 b+2)) name(fig_human_ai_sample_diff_d, replace)

graph export "$ai_human_rated_figures/Figure_Human_AI_Means_With_Control_Cohens_d.png", name(fig_human_ai_sample_diff_d) replace width(2400)

display "Viewpoints figures generated successfully."
