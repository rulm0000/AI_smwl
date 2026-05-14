* 0_Master.do
* Orchestrates the AI vs. Human comparison and replication analysis.

clear all
set more off
macro drop _all

* ----------------------------
* GitHub-friendly setup
* ----------------------------
* project_root should point to this analysis folder.

* Anna file path
if "`c(username)'" == "ag" {
	global project_root "/Users/ag/Documents/GitHub/AI_smwl"
}
else if "`c(username)'" == "culm" {
	global project_root "."
}
else {
	global project_root "."
}

do "setup.do"

display "========================================================="
display "Starting AI vs. Human Analysis Pipeline"
display "========================================================="

* 1. Analysis: AI-developed vs. Human-selected Priority (Human Experiment)
display "Running Analysis 1: AI vs. Human-selected Priority (Human study)..."
do "1_Human_AI_vs_Priority.do"

* 2. Analysis: Replication (AI Personas vs. Human Participants)
display "Running Analysis 2: Replication (AI Persona vs. Human Participant)..."
do "2_Replication_Analysis.do"

* 3. Viewpoints tables
display "Running Analysis 3: Generating Viewpoints tables..."
do "6_Viewpoints_Tables.do"

* 4. Figures
display "Running Analysis 4: Generating Figures..."
do "3_Figures.do"

* 5. Distribution visualizations
display "Running Analysis 5: Distribution visualizations..."
do "4_Distributions.do"

* 6. Replication distribution visualizations
display "Running Analysis 6: Replication distribution visualizations..."
do "5_Distribution_Replication.do"

* 7. Cohen's d warning-vs-control values and decomposition
display "Running Analysis 7: Cohen's d decomposition..."
do "7_Cohens_d_Decomposition.do"

display "========================================================="
display "AI vs. Human Analysis Pipeline Complete!"
display "Results are in the output/ folder."
display "========================================================="
