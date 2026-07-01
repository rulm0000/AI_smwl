* 3_Manuscript_Figure2.do
* Generates the manuscript-reported Figure 2:
* Human participant PME ratings of researcher-generated vs. AI-refined warnings.

clear all
set more off

capture confirm global output
if _rc != 0 {
    do "setup.do"
}

set scheme s1mono

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

display "Loading Human Participant Data for manuscript Figure 2..."
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
    graphregion(color(white)) name(fig2_pme_rg_ai, replace)

graph export "$human_generated_figures/Figure2_Human_AI_Means_Researcher_vs_AI_Refined.png", name(fig2_pme_rg_ai) replace width(2200)

display "Manuscript Figure 2 generated successfully."
