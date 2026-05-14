* setup.do
* Centralized path setup for AI vs. Human analysis.

version 15.0
set more off

* Define project root
capture confirm global project_root
if _rc != 0 {
    global project_root "."
}

* project_root points to the AI vs. human analysis folder.
global analysis_root "$project_root"
global output "$analysis_root/output"
global figures "$output/figures"
global human_generated_figures "$figures/human_generated_vs_ai_generated"
global ai_human_rated_figures "$figures/ai_rated_vs_human_rated"
global tables "$output/tables"
global data_root "$analysis_root/AI_vs_Human_Data"
capture mkdir "$output"
capture mkdir "$figures"
capture mkdir "$human_generated_figures"
capture mkdir "$ai_human_rated_figures"
capture mkdir "$tables"
capture mkdir "$data_root"

* Self-contained clean data for Viewpoints AI vs. human analyses
global human_file "$data_root/human_participant_clean_data.dta"
global ai_file "$data_root/ai_persona_clean_data.dta"

* Backward-compatible folder globals
global human_data "$data_root"
global ai_data "$data_root"
