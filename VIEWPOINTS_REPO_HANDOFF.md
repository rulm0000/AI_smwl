# Viewpoints Repository Handoff Checklist

Use this checklist after the Viewpoints figures and tables are approved and the team is ready to create a separate GitHub repository.

## Proposed Repository

- Default visibility: private
- Suggested name: `viewpoints-social-media-warnings`
- Source folder: this `AI vs. human` folder

## Include

- Stata analysis scripts:
  - `0_Master.do`
  - `setup.do`
  - `1_Human_AI_vs_Priority.do`
  - `2_Replication_Analysis.do`
  - `3_Figures.do`
  - `4_Distributions.do`
  - `5_Distribution_Replication.do`
  - `6_Viewpoints_Tables.do`
- Documentation:
  - `README.md`
  - `AI_vs_Human_Mapping.txt`
  - `VIEWPOINTS_REPO_HANDOFF.md`
- Clean analysis data, if approved for the private repository:
  - `AI_vs_Human_Data/human_participant_clean_data.dta`
  - `AI_vs_Human_Data/ai_persona_clean_data.dta`
- Manuscript-ready outputs from `output/`, if the team wants figures and tables versioned:
  - `output/figures/human_generated_vs_ai_generated/`
  - `output/figures/ai_rated_vs_human_rated/`
  - `output/tables/`

## Exclude

- Raw Qualtrics exports
- ACS files
- Temporary Stata files
- Log files
- Office lock files
- Any direct identifiers or unapproved participant-level exports

## Before Creating The Repo

1. Confirm the copied human participant clean data is approved for private GitHub storage.
2. Confirm no direct identifiers are present in `AI_vs_Human_Data/human_participant_clean_data.dta`.
3. Decide whether generated figures and tables should be committed or regenerated only.
4. Create a repo-level `.gitignore` blocking raw data, logs, temp files, and Office lock files.
5. Create the private GitHub repository and push the approved file set.
6. Add a link to the new repo in the original issue thread or project README.
