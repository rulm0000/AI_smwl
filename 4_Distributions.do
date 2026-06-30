* 4_Distributions.do
* "Just for fun" visualizations of the PME distributions
* Compares AI-developed vs. Human-selected warnings using density and box plots.

clear all
set more off

* Ensure setup is run
* Run setup if globals are not yet defined (e.g. when running this file on its own).
* Use an empty-string check rather than "confirm global", which is not a valid
* Stata command and always errors.
if "$output" == "" {
    do "setup.do"
}

display "Loading Human Participant Data for Distribution Analysis..."
use "$human_file", clear

* Define versions based on mapping
gen is_ai = .
replace is_ai = 1 if version == 4
replace is_ai = 0 if topic == 3 & version == 1
replace is_ai = 0 if topic == 4 & version == 2
replace is_ai = 0 if topic == 5 & version == 3
replace is_ai = 0 if topic == 6 & version == 1
replace is_ai = 0 if topic == 7 & version == 1
replace is_ai = 0 if topic == 8 & version == 1

* Keep only the relevant topics and versions
keep if inlist(topic, 3, 4, 5, 6, 7, 8)
keep if !missing(is_ai)

label define ai_lab 0 "Researcher-generated" 1 "AI-refined"
label values is_ai ai_lab

* ==============================================================================
* 1. OVERLAID DENSITY PLOT (Overall)
* ==============================================================================
* Shows the "shape" of the data. Since PME is a 1-5 scale, we use a small bandwidth.

twoway (kdensity pme if is_ai == 0, color(gs12) recast(area) fcolor(gs14%50) lcolor(gs10)) ///
       (kdensity pme if is_ai == 1, color(black) lwidth(medium)), ///
    title("Distribution of Perceived Effectiveness (Overall)", size(medium)) ///
    subtitle("Comparing all 6 warning topics", size(vsmall)) ///
    xtitle("PME Rating (1-5 Scale)", size(small)) ///
    ytitle("Density", size(small)) ///
    legend(order(1 "Researcher-generated" 2 "AI-refined") size(small) region(lcolor(white))) ///
    xlabel(1(1)5) ///
    graphregion(color(white))

graph export "$human_generated_figures/Figure_Distribution_Density_Overall.png", replace width(2000)

* ==============================================================================
* 2. GROUPED BOX PLOTS (By Topic)
* ==============================================================================
* Shows median, quartiles, and outliers for each topic.

* Shorten labels for the plot
label define topiclab 3 "Depression" 4 "Negative body image" 5 "Addiction" 6 "Sleep disruption" 7 "Mental health" 8 "Not proven safe", modify
label values topic topiclab

graph box pme, over(is_ai, label(labsize(vsmall))) over(topic, label(labsize(vsmall))) ///
    asyvars box(1, color(gs14) lcolor(black)) box(2, color(black)) ///
    title("PME Distributions by Topic", size(medium)) ///
    ytitle("PME Rating (1-5 Scale)", size(small)) ///
    ylabel(1(1)5) ///
    legend(order(1 "Researcher-generated" 2 "AI-refined") size(small) region(lcolor(white)) position(6) rows(1)) ///
    graphregion(color(white))

graph export "$human_generated_figures/Figure_Distribution_BoxPlots.png", replace width(2000)

display "Distribution plots generated successfully!"
