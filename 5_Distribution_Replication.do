* 5_Distribution_Replication.do
* Visualizes the distributions of PME ratings between Human Participants and AI Personas.

clear all
set more off
set scheme s1mono

* Ensure setup is run
* Run setup if globals are not yet defined (e.g. when running this file on its own).
* Use an empty-string check rather than "confirm global", which is not a valid
* Stata command and always errors.
if "$output" == "" {
    do "setup.do"
}

* 1. Prepare Human Participant Data (Priority versions matching AI persona exposure)
display "Preparing Human Participant Data..."
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
gen sample = 0 // Human

* Ensure pid is numeric for consistency
capture confirm string variable pid
if _rc == 0 {
    destring pid, replace force
}

tempfile human
save `human'

* 2. Prepare AI Persona Data
display "Preparing AI Persona Data..."
use "$ai_file", clear

* Harmonize ID type
capture confirm string variable pid
if _rc == 0 {
    tempvar numeric_pid
    egen `numeric_pid' = group(pid)
    drop pid
    rename `numeric_pid' pid
}
replace pid = pid + 100000 

gen sample = 1 // AI Persona
append using `human'

label define samplelab 0 "Human Participants" 1 "AI Personas"
label values sample samplelab

* ==============================================================================
* 1. OVERLAID DENSITY PLOT (Overall)
* ==============================================================================

twoway (kdensity pme if sample == 0, color(gs12) recast(area) fcolor(gs14%50) lcolor(gs10)) ///
       (kdensity pme if sample == 1, color(black) lwidth(medium)), ///
    title("PME Distribution: Humans vs. AI Personas (Overall)", size(medium)) ///
    subtitle("Comparing ratings for matched warning topics", size(vsmall)) ///
    xtitle("PME Rating (1-5 Scale)", size(small)) ///
    ytitle("Density", size(small)) ///
    legend(order(1 "Human Participants" 2 "AI Personas") size(small) region(lcolor(white))) ///
    xlabel(1(1)5) ///
    graphregion(color(white))

graph export "$ai_human_rated_figures/Figure_Distribution_Humans_vs_AI_Personas_Density.png", replace width(2000)

* ==============================================================================
* 2. BOX PLOTS BY TOPIC
* ==============================================================================

* Define labels manually to avoid append conflicts
label define topiclab_fig 1 "Control" 2 "Screentime break" 3 "Depression" 4 "Negative body image" 5 "Addiction" 6 "Sleep disruption" 7 "Mental health" 8 "Not proven safe"
label values topic topiclab_fig

graph box pme, over(sample, label(labsize(vsmall))) over(topic, label(labsize(vsmall))) ///
    asyvars box(1, color(gs14) lcolor(black)) box(2, color(black)) ///
    title("PME Distributions by Topic: Humans vs. AI Personas", size(medium)) ///
    ytitle("PME Rating (1-5 Scale)", size(small)) ///
    ylabel(1(1)5) ///
    legend(order(1 "Human Participants" 2 "AI Personas") size(small) region(lcolor(white)) position(6) rows(1)) ///
    graphregion(color(white))

graph export "$ai_human_rated_figures/Figure_Distribution_Humans_vs_AI_Personas_BoxPlot.png", replace width(2000)

* ==============================================================================
* 3. DISCRETE HISTOGRAM (Binned by 1)
* ==============================================================================
* Comparing the percentage of each rating (1, 2, 3, 4, 5) side-by-side
* Round PME to nearest integer so the x-axis shows only 1-5
gen pme_round = round(pme)

preserve
    keep if inrange(pme_round, 1, 5)
    contract sample pme_round, freq(n)
    bysort sample: egen sample_total = total(n)
    gen percent = 100 * n / sample_total
    gen x = pme_round
    replace x = pme_round - 0.18 if sample == 0
    replace x = pme_round + 0.18 if sample == 1

    twoway (bar percent x if sample == 0, barwidth(0.32) color(gs12) lcolor(black) lwidth(vthin)) ///
           (bar percent x if sample == 1, barwidth(0.32) color(gs8) lcolor(black) lwidth(vthin)), ///
        xlabel(1(1)5, labsize(small)) ///
        ylabel(0(5)25, labsize(small) nogrid) ///
        xscale(range(0.5 5.5)) ///
        yscale(range(0 25)) ///
        xtitle("PME rating", size(small)) ///
        ytitle("Percent of responses", size(small)) ///
        title("Distribution of PME Ratings: Humans vs. AI Personas", size(medsmall)) ///
        legend(order(1 "Human participants" 2 "AI personas") size(vsmall) rows(1) region(lcolor(white)) position(6) ring(1)) ///
        graphregion(color(white)) plotregion(margin(r+2)) name(fig_hist, replace)

    graph export "$ai_human_rated_figures/Figure_Distribution_Humans_vs_AI_Personas_Histogram.png", name(fig_hist) replace width(2200)
restore


display "Replication distribution plots (including histogram) generated successfully!"
