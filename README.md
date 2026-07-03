## Using Large Language Models to Develop and Test Public Health Messages - Analysis Code

This repository contains the Stata replication code and supporting files for the two within-subjects experiments reported in "Using large language models to develop and test public health messages: Two randomized experiments with AI personas and human participants."

The analyses test whether a large language model (LLM) can (1) refine researcher-generated social media warnings to be perceived as more effective by human participants and (2) replicate human participant contrasts between warnings and a control message using LLM-powered AI personas.

The full pipeline is orchestrated by `0_Master.do`, which runs the numbered analysis scripts in order.

### Repository layout

- `0_Master.do`
  - Master script; sets `project_root`, runs `setup.do`, then executes the numbered analyses in order.
- `setup.do`
  - Centralized path setup; validates `project_root` and the required clean data inputs.
- `1_Human_AI_vs_Priority.do`
  - Compares AI-refined vs. researcher-generated warnings among human participants. Produces eTable 1. Effect of message source on perceived message effectiveness, n=1,012 human participants.
- `2_Viewpoints_Tables.do`
  - Produces Table 2. Sample characteristics, n=1,000 AI personas and n=1,012 human participants; Table 3. Effect of warning topic on perceived message effectiveness by sample, n=1,012 human participants and n=1,000 AI personas; and eTable 2. Effect of warning topic and sample on perceived message effectiveness, n=1,012 human participants and n=1,000 AI personas.
- `3_Manuscript_Figure2.do`
  - Produces Figure 2. Human participant ratings of perceived message effectiveness of researcher-generated vs. AI-refined warnings.
- `4_Cohens_d_Decomposition.do`
  - Exploratory (non-pre-registered) decomposition of the AI-minus-human difference in Cohen's d for warning-vs-control effects, using Campbell HLM/mixed-effects Cohen's d.
- `AI_vs_Human_Mapping.txt`
  - Documents which message version is AI-refined vs. researcher-generated for each topic.

### Output structure

```
AI_smwl/
├── AI_vs_Human_Data/
│   ├── human_participant_clean_data.dta
│   └── ai_persona_clean_data.dta
├── data/
│   └── 1_clean_data.dta
├── output/
│   ├── tables/
│   │   ├── Table_Viewpoints_Sample_Characteristics.xlsx
│   │   ├── Table3_Warning_Topic_PME_by_Sample.xlsx
│   │   ├── eTable1_Message_Source_PME.xlsx
│   │   └── eTable2_Warning_Topic_Sample_PME_Coefficients.xlsx
│   ├── figures/
│   │   └── human_generated_vs_ai_generated/
│   │       └── Figure2_Human_AI_Means_Researcher_vs_AI_Refined.png
│   └── Cohens_d/
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

### Outputs

The pipeline produces the following tracked outputs. Titles match the paper and supplement:

- Table 2. Sample characteristics, n=1,000 AI personas and n=1,012 human participants — `output/tables/Table_Viewpoints_Sample_Characteristics.xlsx`
- Table 3. Effect of warning topic on perceived message effectiveness by sample, n=1,012 human participants and n=1,000 AI personas — `output/tables/Table3_Warning_Topic_PME_by_Sample.xlsx`
- eTable 1. Effect of message source on perceived message effectiveness, n=1,012 human participants — `output/tables/eTable1_Message_Source_PME.xlsx`
- eTable 2. Effect of warning topic and sample on perceived message effectiveness, n=1,012 human participants and n=1,000 AI personas — `output/tables/eTable2_Warning_Topic_Sample_PME_Coefficients.xlsx`
- Figure 2. Human participant ratings of perceived message effectiveness of researcher-generated vs. AI-refined warnings — `output/figures/human_generated_vs_ai_generated/Figure2_Human_AI_Means_Researcher_vs_AI_Refined.png`

### Data inputs

This repo expects pre-cleaned `.dta` inputs; there is no raw-data preparation script here. The pipeline reads exactly two data files, both of which must be present before running:

| Data | Source | Path (relative to repo root) |
|------|--------|------------------------------|
| Human participant clean data | Approved clean analysis input from the social media warning label analyses pipeline | `AI_vs_Human_Data/human_participant_clean_data.dta` |
| AI persona clean data | Approved clean Viewpoints AI analysis input | `AI_vs_Human_Data/ai_persona_clean_data.dta` |

These two files are the only data inputs the analysis scripts load. `setup.do` checks that both are present in `AI_vs_Human_Data/` and exits with a clear error (code `601`) if either is missing.

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
