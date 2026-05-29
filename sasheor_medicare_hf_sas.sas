/*=======================================================================
  HEOR PROJECT: Medicare Inpatient Payment Variation in Heart Failure
  Data:  CMS Medicare Inpatient Hospitals by Provider and Service (2024)
  Tool:  SAS (Base SAS + SAS/STAT)
  Author: [Sophie Tran]
  
  Research Questions:
  1. How do Medicare payments vary by HF severity (DRG 291/292/293)?
  2. What is the geographic variation in payments across states?
  3. What provider-level factors predict payment variation?
========================================================================*/


/*-----------------------------------------------------------------------
  00. SETUP library and file paths
------------------------------------------------------------------------*/
* Point this to wherever you unzipped the CMS download;
LIBNAME heor "C:\HEOR_project";

* Output folder for tables;
ODS PATH (PREPEND) heor.templat(UPDATE);
OPTIONS NODATE NONUMBER;


/*-----------------------------------------------------------------------
  01. IMPORT read the raw CSV
------------------------------------------------------------------------*/
PROC IMPORT
    DATAFILE = "C:\HEOR_project\data.csv"
    OUT      = heor.raw
    DBMS     = CSV
    REPLACE;
    GETNAMES = YES;
    GUESSINGROWS = 5000;   
RUN;

* Quick check confirm column names and types;
PROC CONTENTS DATA = heor.raw VARNUM; RUN;
PROC PRINT DATA = heor.raw (OBS=5); RUN;


/*-----------------------------------------------------------------------
  02. COHORT  filter to heart failure DRGs only
  DRG 291 = Heart failure & shock w/ MCC    (most severe)
  DRG 292 = Heart failure & shock w/ CC     (moderate)
  DRG 293 = Heart failure & shock w/o CC    (least severe)
------------------------------------------------------------------------*/
DATA heor.hf;
    SET heor.raw;

    * Keep only HF DRGs;
    IF DRG_Cd IN ("291", "292", "293");

    * Severity label (will appear in all tables);
    LENGTH drg_severity $20;
    SELECT (DRG_Cd);
        WHEN ("291") drg_severity = "Major (MCC)";
        WHEN ("292") drg_severity = "Moderate (CC)";
        WHEN ("293") drg_severity = "Minor (no CC)";
        OTHERWISE    drg_severity = "Other";
    END;

    * Derived variable: charge-to-payment ratio (CPR)
      High CPR = hospital submits much higher charges than Medicare pays;
    IF Avg_Mdcr_Pymt_Amt > 0 THEN
        charge_to_pmt_ratio = Avg_Submtd_Cvrd_Chrg / Avg_Mdcr_Pymt_Amt;

    * Log-transform payments for regression (right-skewed cost data);
    IF Avg_Mdcr_Pymt_Amt > 0 THEN
        log_medicare_pmt = LOG(Avg_Mdcr_Pymt_Amt);

    * Out-of-pocket gap: difference between total payment and Medicare payment;
    pmt_gap = Avg_Tot_Pymt_Amt - Avg_Mdcr_Pymt_Amt;

    LABEL
        drg_severity        = "DRG Severity Category"
        charge_to_pmt_ratio = "Charge-to-Payment Ratio"
        log_medicare_pmt    = "Log Medicare Payment"
        pmt_gap             = "Avg Non-Medicare Payment Gap ($)"
        Tot_Dschrgs         = "Total Discharges"
        Avg_Submtd_Cvrd_Chrg= "Avg Submitted Charges ($)"
        Avg_Tot_Pymt_Amt    = "Avg Total Payment ($)"
        Avg_Mdcr_Pymt_Amt   = "Avg Medicare Payment ($)";
RUN;

* Confirm sample size;
PROC FREQ DATA = heor.hf;
    TABLES drg_severity / NOCUM;
    TITLE "Table 0: HF Cohort Records by DRG Severity";
RUN;


/*-----------------------------------------------------------------------
  03. DESCRIPTIVE ” Table 1: utilization and payments by severity
  Uses weighted means (weight = Tot_Dschrgs) to account for
  hospital volume ” standard HEOR practice
------------------------------------------------------------------------*/
PROC MEANS DATA  = heor.hf
           MEAN MEDIAN STD MIN MAX
           NWAY NOPRINT;
    CLASS  drg_severity;
    VAR    Tot_Dschrgs Avg_Submtd_Cvrd_Chrg
           Avg_Tot_Pymt_Amt Avg_Mdcr_Pymt_Amt
           charge_to_pmt_ratio pmt_gap;
    WEIGHT Tot_Dschrgs;
    OUTPUT OUT  = heor.table1
           MEAN = mean_dschrg mean_charge mean_totpmt mean_mcrpmt mean_cpr mean_gap
           SUM  = sum_dschrg;
    TITLE "Table 1: Utilization and Payments by DRG Severity (Discharge-Weighted)";
RUN;

PROC PRINT DATA = heor.table1 LABEL NOOBS;
    FORMAT mean_charge mean_totpmt mean_mcrpmt mean_gap DOLLAR12.2
           mean_cpr 6.2
           sum_dschrg COMMA12.0;
    TITLE "Table 1: Summary Statistics by DRG Severity";
RUN;


/*-----------------------------------------------------------------------
  04. GEOGRAPHIC VARIATION  state-level payment analysis
------------------------------------------------------------------------*/
* Step 4a: state-level weighted means per DRG;
PROC MEANS DATA  = heor.hf
           MEAN STD N
           NWAY NOPRINT;
    CLASS  Rndrng_Prvdr_State_Abrvtn drg_severity;
    VAR    Avg_Mdcr_Pymt_Amt;
    WEIGHT Tot_Dschrgs;
    OUTPUT OUT  = heor.state_means
           MEAN = state_avg_pmt
           SUM  = state_total_dschrg;
RUN;

* Step 4b: coefficient of variation ” quantifies geographic disparity;
PROC MEANS DATA  = heor.state_means
           MEAN STD CV
           NWAY NOPRINT;
    CLASS  drg_severity;
    VAR    state_avg_pmt;
    OUTPUT OUT  = heor.cv_table
           MEAN = national_mean_pmt
           STD  = national_sd_pmt
           CV   = coeff_variation;
RUN;

PROC PRINT DATA = heor.cv_table LABEL NOOBS;
    FORMAT national_mean_pmt national_sd_pmt DOLLAR10.2
           coeff_variation 6.1;
    TITLE "Table 2: Geographic Variation in Medicare Payments by DRG Severity";
    FOOTNOTE "CV = coefficient of variation (%). Higher CV = greater geographic disparity.";
RUN;

* Step 4c: top 10 and bottom 10 states by payment for DRG 291 (most severe);
PROC SORT DATA = heor.state_means
           OUT  = heor.state_drg291;
    BY DESCENDING state_avg_pmt;
    WHERE drg_severity = "Major (MCC)";
RUN;

PROC PRINT DATA = heor.state_drg291 (OBS=10) NOOBS;
    VAR Rndrng_Prvdr_State_Abrvtn state_avg_pmt state_total_dschrg;
    FORMAT state_avg_pmt DOLLAR10.2 state_total_dschrg COMMA10.0;
    TITLE "Table 3a: Top 10 States by Avg Medicare Payment ” DRG 291 (Major HF)";
RUN;

PROC SORT DATA = heor.state_means
           OUT  = heor.state_drg291_low;
    BY state_avg_pmt;
    WHERE drg_severity = "Major (MCC)";
RUN;

PROC PRINT DATA = heor.state_drg291_low (OBS=10) NOOBS;
    VAR Rndrng_Prvdr_State_Abrvtn state_avg_pmt state_total_dschrg;
    FORMAT state_avg_pmt DOLLAR10.2 state_total_dschrg COMMA10.0;
    TITLE "Table 3b: Bottom 10 States by Avg Medicare Payment ” DRG 291 (Major HF)";
RUN;


/*-----------------------------------------------------------------------
  05. REGRESSION  what predicts payment variation? 
------------------------------------------------------------------------*/

* Step 5a: create dummy/reference variables;
DATA heor.hf_model;
    SET heor.hf;

    * Reference category: DRG 293 (minor severity)  least costly;
    drg_291 = (DRG_Cd = "291");   /* MCC indicator */
    drg_292 = (DRG_Cd = "292");   /* CC indicator  */

    * High-volume hospital flag (> median discharges for that DRG);
    * Will merge in median below after PROC MEANS;
RUN;

* Step 5b: get median discharges per DRG for volume flag;
PROC MEANS DATA = heor.hf_model MEDIAN NWAY NOPRINT;
    CLASS DRG_Cd;
    VAR Tot_Dschrgs;
    OUTPUT OUT = heor.drg_medians MEDIAN = median_dschrg;
RUN;

PROC SORT DATA = heor.hf_model;     BY DRG_Cd; RUN;
PROC SORT DATA = heor.drg_medians;  BY DRG_Cd; RUN;

DATA heor.hf_model;
    MERGE heor.hf_model heor.drg_medians;
    BY DRG_Cd;
    high_volume = (Tot_Dschrgs > median_dschrg);
    LABEL high_volume = "High-Volume Hospital (above median discharges)";
RUN;

* Step 5c: weighted linear regression on log(Medicare payment);
PROC REG DATA   = heor.hf_model
         PLOTS  = (ResidualPlot FitPlot);
    WEIGHT Tot_Dschrgs;
    MODEL  log_medicare_pmt = drg_291 drg_292 high_volume
           / CLB          /* confidence limits for betas */
             VIF          /* variance inflation ” check multicollinearity */
             R;           /* residual output */
    TITLE "Table 4: Weighted Log-Linear Regression ” Predictors of Medicare Payment";
    FOOTNOTE "Reference: DRG 293 (minor severity), low-volume hospital";
RUN;
QUIT;

* Step 5d: exponentiate coefficients back to dollar scale for interpretation;

/*-----------------------------------------------------------------------
  06. PAIRWISE COMPARISON ” are payment differences significant?
  PROC GLM with LSMEANS for adjusted means by severity
------------------------------------------------------------------------*/
PROC GLM DATA   = heor.hf_model;
    WEIGHT Tot_Dschrgs;
    CLASS  drg_severity;
    MODEL  Avg_Mdcr_Pymt_Amt = drg_severity high_volume;
    LSMEANS drg_severity / PDIFF ADJUST=TUKEY CL;
    TITLE "Table 5: Adjusted Mean Payments by DRG Severity (Tukey-adjusted pairwise)";
RUN;
QUIT;


/*-----------------------------------------------------------------------
  07. OUTPUT 
------------------------------------------------------------------------*/

ODS EXCEL FILE    = "C:HEOR_project\output\heor_hf_results.xlsx"
          STYLE   = JOURNAL
          OPTIONS (SHEET_INTERVAL = "PROC"
                   EMBEDDED_TITLES = "YES");

PROC PRINT DATA = heor.table1       NOOBS LABEL; TITLE "Table 1 - Descriptive Stats"; RUN;
PROC PRINT DATA = heor.cv_table     NOOBS LABEL; TITLE "Table 2 - Geographic CV";     RUN;
PROC PRINT DATA = heor.state_drg291 (OBS=10) NOOBS; TITLE "Table 3 - Top States DRG291"; RUN;

ODS EXCEL CLOSE;

 


/*-----------------------------------------------------------------------
  08. MACRO 
------------------------------------------------------------------------*/
%MACRO heor_summary(data=, groupvar=, outdata=, title=);

    PROC MEANS DATA  = &data MEAN MEDIAN STD N NWAY NOPRINT;
        CLASS  &groupvar;
        VAR    Avg_Mdcr_Pymt_Amt Tot_Dschrgs charge_to_pmt_ratio;
        WEIGHT Tot_Dschrgs;
        OUTPUT OUT  = &outdata
               MEAN = mean_pmt mean_dschrg mean_cpr
               N    = n_hospitals;
    RUN;

    PROC PRINT DATA = &outdata NOOBS LABEL;
        FORMAT mean_pmt DOLLAR10.2 mean_cpr 6.2 mean_dschrg COMMA10.0;
        TITLE "&title";
    RUN;

%MEND heor_summary;

* Call the macro for two different groupings;
%heor_summary(
    data     = heor.hf,
    groupvar = drg_severity,
    outdata  = heor.summary_drg,
    title    = Payment Summary by DRG Severity
);

%heor_summary(
    data     = heor.hf,
    groupvar = Rndrng_Prvdr_State_Abrvtn,
    outdata  = heor.summary_state,
    title    = Payment Summary by State
);

