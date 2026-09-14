* 0_Master.do
* Processes AI vs. Human comparison and replication analysis.

clear all
set more off
version 19.5
local supplied_project_root `"$project_root"'


* Anna file path
if `"`supplied_project_root'"' != "" {
	global project_root `"`supplied_project_root'"'
}
else if "`c(username)'" == "ag" {
	global project_root "/Users/ag/Documents/GitHub/AI_smwl"
}
else if "`c(username)'" == "culm" {
	global project_root "."
}
else {
	global project_root "."
}

* ----------------------------
* Options
* ----------------------------
* Step 5 draws the supplement box plot in Python through Stata's built-in
* Python integration (no shell commands; works on Windows and macOS).
* Set to 0 to skip it, e.g., if Stata is not linked to a Python installation
* with pandas and matplotlib. All other outputs run either way.
global run_python_figure 1

do "$project_root/setup.do"

display "========================================================="
display "Starting AI vs. Human Analysis Pipeline"
display "========================================================="

* 1. Analysis: AI-developed vs. Human-selected Priority (Human Experiment)
display "Running Analysis 1: AI vs. Human-selected Priority (Human study)..."
do "1_Human_AI_vs_Priority.do"

* 2. Viewpoints tables
display "Running Analysis 2: Generating Viewpoints tables..."
do "2_Viewpoints_Tables.do"

* 3. Manuscript Figure 2
display "Running Analysis 3: Generating manuscript Figure 2..."
do "3_Manuscript_Figure2.do"

* 4. Cohen's d warning-vs-control values and decomposition
display "Running Analysis 4: Cohen's d decomposition..."
do "4_Cohens_d_Decomposition.do"

* 5. Supplement eFigure: PME distributions, human participants vs. AI personas
*    (data prepared in Stata, figure drawn by the Python script;
*    controlled by global run_python_figure above)
display "Running Analysis 5: Generating PME distribution box plot..."
do "5_eFigure_PME_Distribution_BoxPlot.do"

display "========================================================="
display "AI vs. Human Analysis Pipeline Complete!"
display "Results are in the output/ folder."
display "========================================================="
