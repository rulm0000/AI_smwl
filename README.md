## AI vs. Human Comparison Analysis

This folder compares AI-refined warning messages against researcher-generated priority messages and tests whether AI persona ratings replicate human participant patterns.

### Analyses

1. **AI-refined vs. researcher-generated priority messages** (`1_Human_AI_vs_Priority.do`)
   - Within the human experiment, compares Version 4 (AI-refined) messages against the researcher-generated priority version for each topic (topics 3--8).
   - Exports supplemental eTable 1 with ADEs, 95% CIs, p-values, and Cohen's d.

2. **Viewpoints tables** (`2_Viewpoints_Tables.do`)
   - Main manuscript sample characteristics table, main manuscript warning-topic PME table by sample, and supplemental pooled interaction regression coefficient table.

3. **Manuscript Figure 2** (`3_Manuscript_Figure2.do`)
   - Generates the manuscript-reported Figure 2: human participant PME ratings of researcher-generated vs. AI-refined warnings.

4. **Cohen's d decomposition** (`4_Cohens_d_Decomposition.do`)
   - Calculates Campbell HLM/mixed-effects Cohen's d values for warning-vs-control effects by sample.
   - Decomposes the AI-minus-human difference in Cohen's d into ADE and effective-denominator contributions using a Shapley-style two-factor decomposition.

### Folder structure

- `AI_vs_Human_Data/` -- self-contained clean data for the Viewpoints analyses
  - `human_participant_clean_data.dta`
  - `ai_persona_clean_data.dta`
- `data/` -- original AI persona clean data copy retained for provenance
- `output/` -- generated outputs, organized by type:
  - `output/figures/human_generated_vs_ai_generated/` -- manuscript Figure 2 only
  - `output/tables/` -- generated Excel tables
  - `output/Cohens_d/` -- Cohen's d calculator inputs, formula checks, and decomposition outputs
- `AI_vs_Human_Mapping.txt` -- documents which message version is AI-refined vs. researcher-generated for each topic

### Data dependencies

| Data | Source | Path (relative to repo root) |
|------|--------|------------------------------|
| Human participant clean data | Approved clean analysis input copied from the social media warning label analyses pipeline | `AI_vs_Human_Data/human_participant_clean_data.dta` |
| AI persona clean data | Approved clean Viewpoints AI analysis input | `AI_vs_Human_Data/ai_persona_clean_data.dta` |

These clean data files are required inputs for the standalone Viewpoints analysis. `setup.do` checks that they are present in `AI_vs_Human_Data/` before running downstream analyses.

### Quick start

1. Open Stata.
2. `cd` into this folder (the one containing `0_Master.do`).
3. Run:

```stata
do 0_Master.do
```

Alternatively, from another working directory, set `project_root` to this folder before running the master file:

```stata
global project_root "C:/path/to/AI_smwl"
do "$project_root/0_Master.do"
```

Results will be saved under the `output/` folder.

### What gets produced

- Tables (`output/tables/`)
  - `Table_Viewpoints_Sample_Characteristics.xlsx`
  - `Table3_Warning_Topic_PME_by_Sample.xlsx`
  - `eTable1_Message_Source_PME.xlsx`
  - `eTable2_Warning_Topic_Sample_PME_Coefficients.xlsx`
- Figures (`output/figures/human_generated_vs_ai_generated/`)
  - `Figure2_Human_AI_Means_Researcher_vs_AI_Refined.png`

These are the only tracked manuscript/supplement outputs; `.gitignore` keeps any other locally regenerated tables/figures out of version control.

### Notes

- `setup.do` validates `project_root` and the two required clean `.dta` inputs (`AI_vs_Human_Data/human_participant_clean_data.dta` and `AI_vs_Human_Data/ai_persona_clean_data.dta`), exiting with code `601` and a clear error message if either is missing.
- This repo expects pre-cleaned `.dta` inputs; there is no raw-data preparation script here (unlike the primary human-experiment pipeline's `1_Data_Preparation.do`).
- Each script re-runs `setup.do` automatically if the `$output` global isn't already defined, so individual scripts can be run on their own, e.g. `do 3_Manuscript_Figure2.do`.

### Message version mapping

- All AI-refined messages are **Version 4**.
- Researcher-generated priority versions vary by topic (see `AI_vs_Human_Mapping.txt` for details).
