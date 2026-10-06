# High Yields, Hot Currencies? — Blog 4

Open `blog4.html` for the rendered, self-contained article; edit `blog4.qmd` for submission. The source computes every numerical statement from data. Replication repository: [xia071212/blog4repo](https://github.com/xia071212/blog4repo). The HTML is a downloadable standalone article; GitHub Pages has not been enabled. The course also asks for a blog URL and a corresponding GitHub repository URL when submitting a coding project.

## Reproduce

From this directory, use R 4.1+ (tested with R 4.6.1) and Quarto:

```r
install.packages(c('curl','xml2','readr','dplyr','tidyr','ggplot2','knitr','rmarkdown'))
```

```sh
Rscript run_all.R
quarto render blog4.qmd
```

The default uses the included official raw snapshot, preserving the submitted vintage. To retrieve a new vintage from the same official APIs, deliberately run:

```sh
Rscript run_all.R --refresh
quarto render blog4.qmd
```

A refresh overwrites raw snapshots and can revise historical results. Preserve a copy before refreshing. There is no fallback to another provider, synthetic data, interpolation, or silent date truncation. Download failures and incomplete/duplicate monthly coverage stop execution. `quarto render` cleans and rebuilds figures from raw data; run `run_all.R --refresh` separately for a new download.

`session-info.txt` records tested package versions. Install Quarto and make its `quarto` command available on your PATH. All analysis paths are relative to this repository.

## Contents

- `R/01_download.R`: official API requests, cached download, retrieval times and MD5 hashes.
- `R/02_clean.R`: parse SDMX, validate series/months/units, join, transform and calculate descriptive correlations and sensitivity checks.
- `R/03_figures.R`: all three figures, in PNG and vector PDF.
- `run_all.R`: complete download/clean/figures pipeline; accepts `--refresh`.
- `data/raw/`: unedited official responses, API manifest and OECD structural metadata.
- `data/processed/`: monthly panel, correlations, sensitivities and base-year checks.
- `figures/`: three non-redundant figures.
- `blog4.qmd`, `blog4.html`: article source and standalone rendered page.

## Verified sources and dimensions

1. OECD Financial Market: `OECD.SDD.STES,DSD_STES@DF_FINMARK,4.0`. Monthly long-term interest rate `IRLT`, annual percentage `PA`, national methodology `N`; countries USA, JPN, GBR, CAN, CHE. Current official API version was discovered from the dataflow registry. The old 1.0 endpoint no longer returned this dataflow. [Indicator definition](https://www.oecd.org/en/data/indicators/long-term-interest-rates.html) and [Data Explorer](https://data-explorer.oecd.org/). These are national benchmark long-term government yields, conventionally ten-year; they are not a perfectly identical security across markets. The OECD website's explanatory indicator page was blocked in the retrieval environment; the API structure and observations were accessible and verified. We preserve that distinction rather than claiming that page was successfully downloaded.
2. BIS `WS_EER`, key `M.N.B.US+JP+GB+CA+CH`: monthly, nominal, broad basket, collection `A`. The official [EER documentation](https://data.bis.org/topics/EER) confirms geometric trade-weighted indices, 2020=100, appreciation when the index rises, and business-day-average monthly inputs. The mean of the twelve 2020 observations is checked against 100 within rounding tolerance. Common index bases permit comparison of changes since the base year, not currency valuations.
3. BIS `WS_XRU`: monthly bilateral rates for JP, GB, CA, CH. The request returns both average (`A`) and end-period (`E`) series; the cleaner explicitly retains only `A`. Official [XRU documentation](https://data.bis.org/topics/XRU) confirms local currency units per USD and the inverse appreciation direction. Units are JPY, GBP, CAD and CHF per USD. No fabricated US/USD series is added.

Full reproducible URLs, retrieval timestamps (UTC), and MD5 hashes are in `data/raw/manifest.csv`. Snapshot downloaded October 5, 2026 in America/New_York (October 6 UTC). This is a current data vintage restricted to April 2026, not data as known in April 2026.

## Sample and formulas

Fixed level window: 2017-01 to 2026-04, inclusive: 112 months per country. Yield and NEER each have 560 observations; bilateral FX has 448 retained monthly-average observations. All requested months are present. No 2016 data are imported. Consequently, twelve-month changes start 2018-01 and end 2026-04: 100 observations per country, 500 in Figure 2 and 400 in Figure 3. All retained observations have source status `A`; flags are retained in the processed panel.

Let y be a yield in percent per year, N the NEER index, E local currency per dollar, and s=y-y_US.

- Domestic yield change: y_t-y_(t-12), in percentage points.
- Spread change: s_t-s_(t-12), in percentage points.
- Broad appreciation: 100*(N_t/N_(t-12)-1), percent.
- Bilateral appreciation: 100*(E_(t-12)/E_t-1), percent. This is the return on the reciprocal monthly-average rate, not an average of daily inverse-rate returns.

No inflation adjustment is used: absolute yield is not real yield. Higher yields are not realized bond returns. Monthly average rates are not tradeable endpoint prices. Figures describe contemporaneous comovement rather than a trading strategy, forecast or causal capital-flow test.

## Figures and interpretation safeguards

Figure 1 contains five country panels, each with two lines and dual axes. Blue solid lines are domestic yields; gold dashed lines are domestic NEER. All five panels use identical axis ranges. The explicit mapping is right-axis NEER = 10*left-axis plotting coordinate + 80; the displayed ranges are -2% to 6% and 60 to 140. Line crossings and relative visual slopes are not evidence of correlation. No data are excluded by these limits.

Figure 2 compares domestic yield changes with NEER appreciation; Figure 3 compares spread changes with appreciation versus USD. Facets use common scales within each figure. Lines are descriptive OLS fits, with Pearson correlations; there are no significance tests or confidence intervals. Overlapping windows are serially dependent.

The article table fixes the currency outcome (USD appreciation) and the exact sample to compare domestic versus relative yield changes fairly. A higher signed correlation means closer alignment with the positive-yield intuition, not necessarily a stronger fit. Switzerland's absolute correlation magnitude is also slightly larger than its relative magnitude (0.266 versus 0.258); the substantive change is the sign. Britain's remains negative and becomes weaker in magnitude. Avoid claiming relative yields universally have greater explanatory power.

Sensitivity outputs use (a) 111 one-month changes per non-US country and (b) nine non-overlapping January-to-January changes, January 2018 through January 2026. The relative-yield signs persist in both, but nine observations cannot establish stability or statistical significance. These are checks of descriptive signs, not causal identification or out-of-sample validation.

Three figures deliver the requested progression. No fourth chart is added: a country-specific event explanation would require additional evidence, and the UK exception is reported directly without inventing an event-driven cause.

## Editorial and style revision — October 6, 2026

The article follows the existing course blog’s Flatly theme and copied site stylesheet, with author/date/categories, a table of contents, and a source note. The added stylesheet contains two Blog 4 selectors for the description and figure widths. Every section opens with its question; indicator meanings and quotation direction are explained; the conclusion answers the opening question before limitations. All data, calculations and charts are unchanged. Signed correlation and explanatory strength remain distinguished. The page is a standalone preview, not a published website update.
