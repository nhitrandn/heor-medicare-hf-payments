# HEOR Analysis: Medicare Inpatient Payment Variation in Heart Failure

**Author:** Nhi (Sophie) Tran  
**Affiliation:** M.S. Applied Biostatistics, University of South Florida College of Public Health  
**Tools:** SAS (Base SAS + SAS/STAT)  
**Data:** CMS Medicare Inpatient Hospitals by Provider and Service, 2024 Release (FY 2022)  

---

## Background

Heart failure (HF) is one of the leading drivers of Medicare inpatient spending in the United States. Medicare reimburses HF hospitalizations under three MS-DRGs stratified by comorbidity burden:

| MS-DRG | Description | Severity |
|--------|-------------|----------|
| 291 | Heart failure & shock with MCC | Major |
| 292 | Heart failure & shock with CC | Moderate |
| 293 | Heart failure & shock without CC/MCC | Minor |

Despite standardized DRG-based reimbursement, substantial variation in Medicare payments across providers and states has been documented in the literature. This project quantifies that variation using publicly available CMS data and examines provider-level predictors of payment differences — directly relevant to payer formulary decisions, budget impact modeling, and value-based care policy.

---

## Research Questions

1. How do average Medicare payments differ across HF severity groups (DRG 291 vs 292)?
2. What is the magnitude of geographic variation in payments across U.S. states?
3. Do hospital volume and DRG severity independently predict payment variation?

---

## Data Source

**CMS Medicare Fee-For-Service Provider Utilization & Payment Data: Inpatient**  
- Source: [data.cms.gov](https://data.cms.gov/provider-summary-by-type-of-service/medicare-inpatient-hospitals/medicare-inpatient-hospitals-by-provider-and-service)  
- Year: 2024 release (FY 2022 claims)  
- Unit of analysis: Hospital × MS-DRG  
- Cost: **Free** — no data use agreement required  
- Download size: ~39 MB CSV

**Variables used:**

| Variable | Description |
|----------|-------------|
| `DRG_Cd` | MS-DRG code |
| `Rndrng_Prvdr_State_Abrvtn` | Provider state |
| `Tot_Dschrgs` | Total discharges per hospital-DRG |
| `Avg_Submtd_Cvrd_Chrg` | Average submitted charges ($) |
| `Avg_Tot_Pymt_Amt` | Average total payment ($) |
| `Avg_Mdcr_Pymt_Amt` | Average Medicare payment ($) |

---

## Methods

**Cohort definition:** Hospital-DRG records with MS-DRG 291 or 292 (DRG 293 excluded — only 1 hospital nationally, insufficient for analysis). Final analytic sample: **2,882 hospital-DRG records** across 51 states/territories.

**Derived variables:**
- `charge_to_pmt_ratio` = Avg submitted charges / Avg Medicare payment
- `log_medicare_pmt` = log(Avg Medicare payment) — used in regression to address right skew
- `pmt_gap` = Avg total payment − Avg Medicare payment (non-Medicare payment burden)
- `high_volume` = 1 if discharges > median for that DRG (volume flag)

**Statistical approach:**
- Discharge-weighted descriptive statistics (PROC MEANS with WEIGHT = Tot_Dschrgs)
- Geographic variation quantified by coefficient of variation (CV%) across states
- Weighted log-linear regression (PROC REG) to identify predictors of payment variation
- Pairwise severity comparisons with Tukey adjustment (PROC GLM, LSMEANS)

All analyses weighted by `Tot_Dschrgs` to ensure patient-volume representation. Analyses conducted in SAS 9.4.

---

## Key Findings

### Payment by severity (discharge-weighted)

| DRG Severity | Hospitals (n) | Avg Medicare Payment | Avg Submitted Charges | Charge-to-Payment Ratio |
|---|---|---|---|---|
| Major — DRG 291 (MCC) | 2,587 | $10,022 | $56,495 | 5.70 |
| Moderate — DRG 292 (CC) | 294 | $7,089 | $41,317 | 6.13 |

Medicare payments for major HF hospitalizations exceeded moderate by **41%** ($10,022 vs $7,089).

### Geographic variation (DRG 291)

- National mean payment: **$9,738**
- Coefficient of variation: **17.8%** — indicating meaningful geographic disparity
- Highest paying state: **Maryland** ($15,188)
- Lowest paying states in the South and Midwest (~$7,800–$8,200)

### Notable state-level findings (DRG 291)

| State | Avg Medicare Payment | Hospitals |
|---|---|---|
| MD | $15,188 | 68 |
| AK | $14,454 | 8 |
| CA | $13,248 | 274 |
| NY | $12,741 | 136 |
| VT | $6,363 | 7 |
| AR | $7,905 | 39 |

---

## Repository Structure

```
heor-medicare-hf-payments/
├── sas/
│   └── heor_medicare_hf_sas.sas     # Full analysis pipeline
├── output/
│   └── tables/
│       ├── table1_descriptive.csv   # Descriptive stats by severity
│       ├── table2_geo_cv.csv        # Geographic CV by severity
│       └── table3_top_states.csv    # Top 10 states DRG 291
├── docs/
│   └── ispor_abstract.md            # ISPOR-style abstract
├── .gitignore                       # Excludes raw CMS data file
└── README.md
```

---

## Limitations

- Aggregated provider-level data; individual patient-level longitudinal analysis not possible
- DRG 293 (minor severity) excluded due to insufficient hospital representation (n=1)
- Maryland payments may reflect state-specific all-payer rate-setting system (HSCRC), warranting cautious interpretation
- Analysis limited to fee-for-service Medicare; Medicare Advantage excluded

---

## Relevance to HEOR Practice

This project mirrors core HEOR analyst workflows used in:
- **Payer/managed care:** identifying high-cost DRG clusters for utilization management
- **Pharma/biotech:** establishing real-world cost benchmarks for budget impact models
- **Health policy:** documenting geographic payment disparities for value-based care design
- **CRO/consultancy:** provider-level payment variation analysis for client submissions

---

## How to Reproduce

1. Download CMS data: [data.cms.gov](https://data.cms.gov) → search "Medicare Inpatient Hospitals by Provider and Service" → Latest Dataset (2024)
2. Update file paths in `sas/heor_medicare_hf_sas.sas` (lines 14 and 22)
3. Run in SAS 9.4 or SAS OnDemand for Academics (free)
4. Outputs write to `output/tables/` and an Excel workbook

---

## Contact

**GitHub:** [github.com/nhitrandn](https://github.com/nhitrandn)  
**Program:** M.S. Applied Biostatistics, USF College of Public Health
