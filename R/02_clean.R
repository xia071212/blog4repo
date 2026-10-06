library(dplyr)
library(readr)
library(xml2)
countries <- c('United States','Japan','United Kingdom','Canada','Switzerland')
map <- c(US='United States',JP='Japan',GB='United Kingdom',CA='Canada',CH='Switzerland',
 USA='United States',JPN='Japan',GBR='United Kingdom',CAN='Canada',CHE='Switzerland')
read_bis <- function(path, value_name) {
 ss <- xml_find_all(read_xml(path), './/*[local-name()="Series"]')
 result <- bind_rows(lapply(ss, function(s) {
  if (xml_attr(s,'COLLECTION') != 'A') return(NULL)
  o <- xml_find_all(s, './*[local-name()="Obs"]')
  data.frame(country=unname(map[xml_attr(s,'REF_AREA')]),
   date=as.Date(paste0(xml_attr(o,'TIME_PERIOD'),'-01')),
   value=as.numeric(xml_attr(o,'OBS_VALUE')), status=xml_attr(o,'OBS_STATUS'))
 }))
 names(result)[3:4] <- c(value_name,paste0(value_name,'_status')); result
}
y <- read_csv('data/raw/oecd_yields.csv', show_col_types=FALSE)
stopifnot(all(y$FREQ=='M'),all(y$MEASURE=='IRLT'),all(y$UNIT_MEASURE=='PA'),all(y$UNIT_MULT==0),all(y$METHODOLOGY=='N'))
y <- y |> transmute(country=unname(map[REF_AREA]), date=as.Date(paste0(TIME_PERIOD,'-01')),yield=OBS_VALUE,yield_status=OBS_STATUS)
n <- read_bis('data/raw/bis_neer.xml','neer')
f <- read_bis('data/raw/bis_fx.xml','lcu_per_usd')
months <- seq(as.Date('2017-01-01'),as.Date('2026-04-01'),by='month')
validate <- function(x, expected_countries, variable) {
 stopifnot(!anyNA(x[[variable]]), !anyNA(x$country),!anyDuplicated(x[c('country','date')]),
  setequal(unique(x$country),expected_countries))
 for (c in expected_countries) stopifnot(identical(sort(x$date[x$country==c]),months))
}
validate(y,countries,'yield'); validate(n,countries,'neer');validate(f,countries[-1],'lcu_per_usd')
stopifnot(all(n$neer>0),all(f$lcu_per_usd>0))
# 2020 calendar-year mean confirms the published index base, within rounding.
base <- n |> filter(format(date,'%Y')=='2020') |> group_by(country) |> summarise(base=mean(neer))
stopifnot(all(abs(base$base-100)<0.1))
panel <- y |> left_join(n,by=c('country','date')) |> left_join(f,by=c('country','date')) |>
 left_join(y |> filter(country=='United States') |> select(date,us_yield=yield),by='date') |>
 arrange(country,date) |> group_by(country) |> mutate(
 spread=yield-us_yield,
 dy12=yield-lag(yield,12), ds12=spread-lag(spread,12),
 neer12=100*(neer/lag(neer,12)-1),
 fx12=100*(lag(lcu_per_usd,12)/lcu_per_usd-1),
 dy1=yield-lag(yield),ds1=spread-lag(spread),fx1=100*(lag(lcu_per_usd)/lcu_per_usd-1)) |> ungroup()
analysis <- panel |> filter(!is.na(dy12))
stopifnot(nrow(panel)==560,nrow(analysis)==500,all(table(analysis$country)==100),sum(!is.na(analysis$fx12))==400)
stats <- analysis |> group_by(country) |> summarise(n=n(),
 r_absolute_neer=cor(dy12,neer12),
 r_relative_usd=if(all(is.na(fx12))) NA_real_ else cor(ds12,fx12),
 r_absolute_usd=if(all(is.na(fx12))) NA_real_ else cor(dy12,fx12))
robust <- panel |> filter(country!='United States') |> group_by(country) |> summarise(
 r_absolute_monthly=cor(dy1,fx1,use='complete.obs'),r_relative_monthly=cor(ds1,fx1,use='complete.obs'))
# Non-overlapping 12-month changes: every January, 2018-2026 (only nine points).
annual <- analysis |> filter(country!='United States',format(date,'%m')=='01') |> group_by(country) |>
 summarise(n=n(),r_absolute=cor(dy12,fx12),r_relative=cor(ds12,fx12))
dir.create('data/processed',recursive=TRUE,showWarnings=FALSE)
write_csv(panel,'data/processed/monthly_panel.csv'); write_csv(stats,'data/processed/correlations.csv')
write_csv(robust,'data/processed/monthly_sensitivity.csv');write_csv(annual,'data/processed/nonoverlap_sensitivity.csv')
write_csv(base,'data/processed/base_year_check.csv')
print(stats,width=Inf);print(robust);print(annual)
