# ISPOR-Style Abstract

**Title:** Geographic and Severity-Based Variation in Medicare Inpatient Payments for Heart Failure: A Provider-Level Analysis of CMS Fee-For-Service Data

**Authors:** Ngoc Yen Nhi (Sophie) Tran, M.S. Candidate in Applied Biostatistics, University of South Florida

---

## Objectives

Heart failure (HF) is among the costliest conditions in the Medicare fee-for-service (FFS) program. Despite standardized diagnosis-related group (DRG) reimbursement, payment variation across providers and geographies may signal inefficiencies relevant to payer formulary decisions and budget impact modeling. This study quantifies Medicare payment variation for HF hospitalizations by severity and geography using publicly available CMS data.

## Methods

We analyzed the 2024 CMS Medicare Inpatient Hospitals by Provider and Service Public Use File (FY 2022), which reports hospital-level utilization and payment data for Medicare FFS beneficiaries. The analytic cohort was restricted to MS-DRGs 291 (HF with major comorbidity, MCC) and 292 (HF with comorbidity, CC); DRG 293 was excluded due to insufficient hospital representation (n=1). The final sample comprised 2,882 hospital-DRG records across 51 U.S. states and territories. Discharge-weighted descriptive statistics were computed using PROC MEANS. Geographic variation was quantified using the coefficient of variation (CV%) across states. A weighted log-linear regression model (PROC REG) examined associations between DRG severity, hospital volume, and Medicare payment. Analyses were conducted in SAS 9.4.

## Results

Average discharge-weighted Medicare payments were $10,022 (DRG 291, n=2,587 hospitals) and $7,089 (DRG 292, n=294 hospitals), representing a 41% severity-based payment differential. Average submitted charges exceeded Medicare payments by a factor of 5.70 and 6.13 for DRG 291 and 292 respectively, indicating substantial charge-to-payment gaps. Geographic variation was meaningful for major HF (CV=17.8%), with state-level payments ranging from $6,363 (VT) to $15,188 (MD) for DRG 291. High-payment states were concentrated in the Northeast and Pacific regions, while lower-payment states clustered in the South and Midwest. In weighted regression, DRG 291 severity and high hospital volume were both significant positive predictors of Medicare payment (p<0.05).

## Conclusions

Substantial variation in Medicare HF payments exists across both severity levels and U.S. geographies, exceeding what DRG standardization would predict. Maryland's notably elevated payments likely reflect the state's unique all-payer rate-setting system and warrant separate analysis. These findings have direct relevance for payers constructing budget impact models, HEOR teams benchmarking real-world treatment costs, and policymakers designing value-based care programs targeting HF readmission reduction. Future work should incorporate patient-level claims data to examine comorbidity burden and readmission as additional cost drivers.

---

*Presented as an independent portfolio analysis. Data: CMS Medicare Inpatient PUF, FY2022. Tool: SAS 9.4.*
