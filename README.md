# High Yields, Hot Currencies?

This repository contains the data, R code, and results behind the blog **“High Yields, Hot Currencies?”** It allows readers to reproduce the data transformations, correlations, and three figures used to examine how government bond yields relate to currency strength.

## Data and methods

The analysis covers the **United States, Japan, United Kingdom, Canada, and Switzerland**, using monthly observations from **January 2017 to April 2026**.

| Raw file | Source | Meaning and units |
|---|---|---|
| [`data/raw/oecd_yields.csv`](data/raw/oecd_yields.csv) | [OECD Financial Market](https://data-explorer.oecd.org/), `DSD_STES@DF_FINMARK` version 4.0; monthly `IRLT`, unit `PA` | National benchmark long-term government bond yields, conventionally ten-year, in percent per year. |
| [`data/raw/bis_neer.xml`](data/raw/bis_neer.xml) | [BIS effective exchange rates](https://data.bis.org/topics/EER), `WS_EER`; monthly, nominal, broad basket | Nominal effective exchange rate (NEER): a trade-weighted currency index, with 2020 averaging 100. A higher index means appreciation against the basket. |
| [`data/raw/bis_fx.xml`](data/raw/bis_fx.xml) | [BIS bilateral exchange rates](https://data.bis.org/topics/XRU), `WS_XRU` | Local currency units per US dollar for Japan, the UK, Canada, and Switzerland. A lower rate means local currency appreciation against the dollar. |

Exact API requests and raw-file checksums are recorded in [`data/raw/manifest.csv`](data/raw/manifest.csv). The included snapshot was downloaded on October 5, 2026, New York time; historical values may differ from later downloads.

### Processing

The code standardizes country codes and month labels, retains BIS **monthly-average** observations (`COLLECTION=A`), and joins the datasets by country and month. It also attaches the same month's US yield to each country. It checks for duplicate or missing observations, complete monthly coverage, positive exchange-rate values, and the NEER base-year average. No interpolation, outlier removal, or inflation adjustment is applied.

Let `y` be the domestic yield, `y_US` the US yield, `N` the NEER index, and `E` local currency units per dollar. The main variables are:

| Variable in the processed data | Calculation | Interpretation |
|---|---|---|
| `spread` | `y[t] - y_US[t]` | Domestic yield advantage over US Treasuries, in percentage points. |
| `dy12` | `y[t] - y[t-12]` | Change in the domestic yield over twelve months, in percentage points. |
| `ds12` | `spread[t] - spread[t-12]` | Change in the relative yield advantage over twelve months, in percentage points. |
| `neer12` | `100 * (N[t] / N[t-12] - 1)` | Twelve-month appreciation against the currency basket, in percent. |
| `fx12` | `100 * (E[t-12] / E[t] - 1)` | Twelve-month appreciation against the dollar, in percent. The ratio is reversed because the original quotation is local currency per dollar. |

The level data contain **112 months per country**: 560 yield observations, 560 NEER observations, and 448 retained bilateral exchange-rate observations. Twelve-month changes begin in January 2018, leaving **100 observations per country** through April 2026. The US is excluded from the dollar-relative comparison because its yield spread against itself is zero.

Correlations are calculated separately for each country using Pearson's correlation coefficient. Scatterplot lines are ordinary least-squares fits with an intercept. Both variables refer to the same twelve-month interval. Additional checks use one-month changes and nine non-overlapping January-to-January changes per non-US country. These are descriptive calculations; overlapping annual windows are not independent observations.

## Code

| Script | Role |
|---|---|
| [`R/01_download.R`](R/01_download.R) | Downloads data from the official OECD and BIS APIs when raw files are absent, or reuses the included snapshot. Records request URLs and checksums. |
| [`R/02_clean.R`](R/02_clean.R) | Filters and validates the data, builds the monthly panel, calculates yield and currency changes, and saves correlations and sensitivity results. |
| [`R/03_figures.R`](R/03_figures.R) | Creates the three blog figures in PNG and PDF formats. |
| [`run_all.R`](run_all.R) | Runs the download, cleaning, and plotting steps in order, then records the R session and package versions. |

## Results and their role in the blog

Numerical outputs are in `data/processed/`; charts are in `figures/`.

| Output | Role in the analysis |
|---|---|
| [`monthly_panel.csv`](data/processed/monthly_panel.csv) | Country-month dataset containing the source values, US benchmark yields, spreads, and currency changes used throughout the blog. |
| [`figure1.png`](figures/figure1.png) / [`figure1.pdf`](figures/figure1.pdf) | **Figure 1:** five country panels pairing domestic yields with NEER, introducing the question of whether they move together. |
| [`figure2.png`](figures/figure2.png) / [`figure2.pdf`](figures/figure2.pdf) | **Figure 2:** twelve-month domestic yield changes against NEER appreciation, examining the absolute-yield intuition. |
| [`figure3.png`](figures/figure3.png) / [`figure3.pdf`](figures/figure3.pdf) | **Figure 3:** twelve-month yield-spread changes against appreciation versus USD, examining relative yields. |
| [`correlations.csv`](data/processed/correlations.csv) | Supplies the correlations in Figures 2–3 and the blog's comparison table. The table compares domestic yield changes and spread changes using the same dollar-appreciation outcome and sample. |
| [`monthly_sensitivity.csv`](data/processed/monthly_sensitivity.csv) | Supplementary check using one-month yield and exchange-rate changes; not a separate blog figure. |
| [`nonoverlap_sensitivity.csv`](data/processed/nonoverlap_sensitivity.csv) | Supplementary check using nine January-to-January observations per country; not a separate blog figure. |
| [`base_year_check.csv`](data/processed/base_year_check.csv) | Data-validation output confirming that each country's 2020 NEER average is approximately 100. |

## Reproduce the analysis

1. Download this repository using **Code → Download ZIP**, unzip it, and open R or RStudio. Alternatively, clone it:

   ```sh
   git clone https://github.com/xia071212/blog4repo.git
   ```

2. Use R 4.1 or newer, set the working directory to the downloaded `blog4repo` folder, and install the packages required by the runner:

   ```r
   install.packages(c("curl", "xml2", "readr", "dplyr", "tidyr", "ggplot2", "knitr", "rmarkdown"))
   ```

3. Run the analysis from the R console:

   ```r
   source("run_all.R")
   ```

   Or, from a terminal inside the repository:

   ```sh
   Rscript run_all.R
   ```

4. Inspect the rebuilt CSV files in `data/processed/` and the three charts in `figures/`. The default run uses the included raw snapshot to reproduce the blog's numerical results. Tested package versions are recorded in [`session-info.txt`](session-info.txt).

To download updated official data instead of using the archived snapshot, run `Rscript run_all.R --refresh`. This overwrites the raw files and may change historical results if the providers have revised their data.
