## AI vs. Human Comparison Analysis

This folder compares AI-refined warning messages against researcher-generated priority messages and tests whether AI persona ratings replicate human participant patterns.

### Analyses

1. **AI-refined vs. researcher-generated priority messages** (`1_Human_AI_vs_Priority.do`)
   - Within the human experiment, compares Version 4 (AI-refined) messages against the researcher-generated priority version for each topic (topics 3--8).
   - Exports supplemental eTable 1 with ADEs, 95% CIs, p-values, and Cohen's d.

2. **Replication: AI Personas vs. Human Participants** (`2_Replication_Analysis.do`)
   - Pools AI persona ratings (from Viewpoints AI) with human participant ratings.
   - Tests whether the pattern of topic effects replicates across samples via a `topic x sample` interaction model.

3. **Figures** (`3_Figures.do`)
   - Bar charts for researcher-generated vs. AI-refined ratings, human participant vs. AI persona ADEs, and human participant vs. AI persona means with the control message.

4. **Viewpoints tables** (`6_Viewpoints_Tables.do`)
   - Main manuscript sample characteristics table, main manuscript warning-topic PME table by sample, and supplemental pooled interaction regression coefficient table.

5. **Distribution visualizations** (`4_Distributions.do`, `5_Distribution_Replication.do`)
   - Density plots, box plots, and histograms comparing distributions.

6. **Cohen's d decomposition** (`7_Cohens_d_Decomposition.do`)
   - Calculates Campbell HLM/mixed-effects Cohen's d values for warning-vs-control effects by sample.
   - Decomposes the AI-minus-human difference in Cohen's d into ADE and effective-denominator contributions using a Shapley-style two-factor decomposition.

### Folder structure

- `AI_vs_Human_Data/` -- self-contained clean data for the Viewpoints analyses
  - `human_participant_clean_data.dta`
  - `ai_persona_clean_data.dta`
- `data/` -- original AI persona clean data copy retained for provenance
- `output/` -- generated outputs, organized by type:
  - `output/figures/human_generated_vs_ai_generated/` -- researcher-generated vs. AI-refined warning figures
  - `output/figures/ai_rated_vs_human_rated/` -- AI persona-rated vs. human participant-rated figures
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

Results will be saved under the `output/` folder in the `tables/`, `figures/human_generated_vs_ai_generated/`, and `figures/ai_rated_vs_human_rated/` subfolders.

### Manuscript and supplement table outputs

Final tracked manuscript/supplement tables are saved in `output/tables/`:

- `Table_Viewpoints_Sample_Characteristics.xlsx`
- `Table3_Warning_Topic_PME_by_Sample.xlsx`
- `eTable1_Message_Source_PME.xlsx`
- `eTable2_Warning_Topic_Sample_PME_Coefficients.xlsx`

### Message version mapping

- All AI-refined messages are **Version 4**.
- Researcher-generated priority versions vary by topic (see `AI_vs_Human_Mapping.txt` for details).
