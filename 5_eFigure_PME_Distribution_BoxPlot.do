* 5_eFigure_PME_Distribution_BoxPlot.do
* Prepares the pooled human participant and AI persona data and calls the
* Python script that draws the supplement box-and-whisker plot of perceived
* message effectiveness (PME) ratings by warning topic and sample.
* Human ratings use the researcher-generated priority version of each topic,
* matching the messages shown to AI personas (same data as Table 3).

clear all
set more off
version 19.5

if `"$output"' == "" {
    do "setup.do"
}

* ------------------------------------------------------------------------------
* Prepare pooled human participant and AI persona data
* ------------------------------------------------------------------------------

display "Preparing pooled data for PME distribution box plot..."
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

* Box plot statistics (quartiles and N) by topic and sample, for the figure note
tabstat pme if sample == 0, by(topic) statistics(n p25 p50 p75) nototal format(%4.2f)
tabstat pme if sample == 1, by(topic) statistics(n p25 p50 p75) nototal format(%4.2f)

* ------------------------------------------------------------------------------
* Export pooled data and draw the figure in Python
* ------------------------------------------------------------------------------
* The figure is drawn with matplotlib (see 5_eFigure_PME_Distribution_BoxPlot.py),
* using Stata's built-in Python integration (`python script`). This works the
* same on Windows and macOS and does not need shell access. Stata must be linked
* to a Python 3 installation that has pandas and matplotlib; see README.md.
* Set global run_python_figure to 0 (e.g., in 0_Master.do) to skip this step.

if `"$run_python_figure"' == "0" {
    display as text "Skipping PME distribution box plot (run_python_figure = 0)."
    exit
}

capture python which pandas
local rc_pandas = _rc
capture python which matplotlib
local rc_matplotlib = _rc
if `rc_pandas' != 0 | `rc_matplotlib' != 0 {
    display as error "Skipping PME distribution box plot: Stata's Python integration is not"
    display as error "available or is missing pandas/matplotlib. To fix, in Stata run:"
    display as error "    python search"
    display as error `"    python set exec "<path to python3>", permanently"'
    display as error "then install the packages for that Python: pip install pandas matplotlib"
    display as error "All other pipeline outputs are unaffected."
    exit
}

local csv_file "$ai_human_rated_figures/eFigure_PME_Distribution_data.csv"
local png_file "$ai_human_rated_figures/eFigure_PME_Distribution_Humans_vs_AI_Personas_BoxPlot.png"

export delimited pid topic sample pme using "`csv_file'", nolabel replace

capture erase "`png_file'"

display "Running 5_eFigure_PME_Distribution_BoxPlot.py via Stata's Python integration..."
python script "5_eFigure_PME_Distribution_BoxPlot.py", args("`csv_file'" "`png_file'")

capture confirm file "`png_file'"
if _rc != 0 {
    display as error "Python did not produce the PME distribution box plot:"
    display as error "  `png_file'"
    exit 601
}

display "PME distribution box plot saved to `png_file'"
