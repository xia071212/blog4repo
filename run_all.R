# Usage: Rscript run_all.R [--refresh]
required <- c('curl','xml2','readr','dplyr','tidyr','ggplot2','knitr','rmarkdown')
missing <- required[!vapply(required,requireNamespace,logical(1),quietly=TRUE)]
if(length(missing)) stop('Install required packages: ',paste(missing,collapse=', '))
source('R/01_download.R')
source('R/02_clean.R')
source('R/03_figures.R')
writeLines(capture.output(sessionInfo()),'session-info.txt')
