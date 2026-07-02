## AI vs. Human Comparison Analysis - Analysis Code

This repository contains the Stata replication code and supporting files for the Viewpoints AI vs. human comparison analyses.
It compares AI-refined warning messages against researcher-generated priority messages and tests whether AI persona ratings replicate human participant patterns.

The full pipeline is orchestrated by `0_Master.do`, which runs the numbered analysis scripts in order.

### Repository layout

- `0_Master.do`
  - Master script; sets `project_root`, runs `setup.do`, then executes the numbered analyses in order.
- `setup.do`
  - Centralized path setup; validates `project_root` and the required clean data inputs.
- `1_Human_AI_vs_Priority.do`
  - Compares Version 4 (AI-refined) messages against the researcher-generated priority version for each topic (topics 3-8). Exports supplemental eTable 1.
- `2_Viewpoints_Tables.do`
  - Main manuscript sample characteristics table, warning-topic PME table by sample, and supplemental pooled interaction regression coefficient table (eTable 2).
- `3_Manuscript_Figure2.do`
  - Generates the manuscript-reported Figure 2: human participant PME ratings of researcher-generated vs. AI-refined warnings.
- `4_Cohens_d_Decomposition.do`
  - Campbell HLM/mixed-effects Cohen's d for warning-vs-control effects by sample, plus a Shapley-style decomposition of the AI-minus-human difference (generated locally, not tracked).
- `AI_vs_Human_Mapping.txt`
  - Documents which message version is AI-refined vs. researcher-generated for each topic.

### Output structure

```
AI_smwl/
├── AI_vs_Human_Data/
│   ├── human_participant_clean_data.dta
│   └── ai_persona_clean_data.dta
├── data/
│   └── 1_clean_data.dta                          (provenance copy of source clean data)
├── output/
│   ├── tables/
│   │   ├── Table_Viewpoints_Sample_Characteristics.xlsx
│   │   ├── Table3_Warning_Topic_PME_by_Sample.xlsx
│   │   ├── eTable1_Message_Source_PME.xlsx
│   │   └── eTable2_Warning_Topic_Sample_PME_Coefficients.xlsx
│   ├── figures/
│   │   └── human_generated_vs_ai_generated/
│   │       └── Figure2_Human_AI_Means_Researcher_vs_AI_Refined.png
│   └── Cohens_d/                                 (generated locally, not tracked)
├── 0_Master.do
├── setup.do
├── 1_Human_AI_vs_Priority.do
├── 2_Viewpoints_Tables.do
├── 3_Manuscript_Figure2.do
├── 4_Cohens_d_Decomposition.do
├── AI_vs_Human_Mapping.txt
└── README.md
```

Only the four tables and Figure 2 above are tracked manuscript/supplement outputs. `.gitignore` keeps any other locally regenerated tables, figures, and the `Cohens_d/` decomposition workbook out of version control.

### Data inputs

This repo expects pre-cleaned `.dta` inputs; there is no raw-data preparation script here (unlike the primary human-experiment pipeline's `1_Data_Preparation.do`). The required inputs must be present before running the pipeline:

| Data | Source | Path (relative to repo root) |
|------|--------|------------------------------|
| Human participant clean data | Approved clean analysis input copied from the social media warning label analyses pipeline | `AI_vs_Human_Data/human_participant_clean_data.dta` |
| AI persona clean data | Approved clean Viewpoints AI analysis input | `AI_vs_Human_Data/ai_persona_clean_data.dta` |

`setup.do` checks that both files are present in `AI_vs_Human_Data/` and exits with a clear error (code `601`) if either is missing.

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

### Notes

- Each script re-runs `setup.do` automatically if the `$output` global isn't already defined, so individual scripts can be run on their own, e.g. `do 3_Manuscript_Figure2.do`.
- Message version mapping: all AI-refined messages are **Version 4**; researcher-generated priority versions vary by topic (see `AI_vs_Human_Mapping.txt` for details).
