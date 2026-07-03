* setup.do
* Centralized path setup for AI vs. Human analysis.

version 19.5
set more off

* Define project root. A caller may set this before running setup.do; otherwise
* use the current working directory. Avoid `confirm global` for compatibility.
if `"$project_root"' == "" {
    global project_root "."
}

capture confirm file "$project_root/setup.do"
if _rc != 0 {
    display as error "project_root does not point to the AI_smwl analysis folder:"
    display as error "  $project_root"
    display as error "Set project_root to the folder containing setup.do, or cd there before running the master do-file."
    exit 601
}

quietly cd "$project_root"

* project_root points to the AI vs. human analysis folder.
global analysis_root "`c(pwd)'"
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

capture confirm file "$human_file"
if _rc != 0 {
    display as error "Required human participant clean data file not found:"
    display as error "  $human_file"
    display as error "This repo expects the approved clean data file to be present in AI_vs_Human_Data/."
    exit 601
}

capture confirm file "$ai_file"
if _rc != 0 {
    display as error "Required AI persona clean data file not found:"
    display as error "  $ai_file"
    display as error "This repo expects the approved clean data file to be present in AI_vs_Human_Data/."
    exit 601
}

* Backward-compatible folder globals
global human_data "$data_root"
global ai_data "$data_root"
