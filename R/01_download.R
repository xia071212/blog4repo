# Run from the blog4 directory. Cached raw files preserve the submitted vintage.
options(timeout = 120)
dir.create('data/raw', recursive = TRUE, showWarnings = FALSE)
urls <- c(
 oecd_yields.csv = 'https://sdmx.oecd.org/public/rest/v1/data/OECD.SDD.STES,DSD_STES@DF_FINMARK,4.0/USA+JPN+GBR+CAN+CHE.M.IRLT.PA._Z._Z._Z._Z.N?startPeriod=2017-01&endPeriod=2026-04',
 bis_neer.xml = 'https://stats.bis.org/api/v1/data/WS_EER/M.N.B.US+JP+GB+CA+CH?startPeriod=2017-01&endPeriod=2026-04',
 bis_fx.xml = 'https://stats.bis.org/api/v1/data/WS_XRU/M.JP+GB+CA+CH?startPeriod=2017-01&endPeriod=2026-04')
refresh <- '--refresh' %in% commandArgs(trailingOnly = TRUE)
for (file in names(urls)) {
 dest <- file.path('data/raw', file)
 if (!file.exists(dest) || refresh) {
  tmp <- tempfile(tmpdir = 'data/raw')
  h <- curl::new_handle()
  curl::handle_setheaders(h, Accept = if (grepl('csv$', file)) 'text/csv' else 'application/vnd.sdmx.structurespecificdata+xml;version=2.1')
  curl::curl_download(urls[[file]], tmp, handle = h, quiet = FALSE)
  if (grepl('csv$', file)) {
   x <- read.csv(tmp); stopifnot(all(c('TIME_PERIOD','OBS_VALUE') %in% names(x)), nrow(x) == 560)
  } else stopifnot(length(xml2::xml_find_all(xml2::read_xml(tmp), './/*[local-name()="Series"]')) > 0)
  stopifnot(file.copy(tmp, dest, overwrite = TRUE)); unlink(tmp)
 }
}
# Manifest timestamps describe the file vintage, not the latest offline rerun.
manifest <- data.frame(file=names(urls), url=unname(urls),
 downloaded_utc=format(file.info(file.path('data/raw',names(urls)))$mtime,tz='UTC',usetz=TRUE),
 md5=unname(tools::md5sum(file.path('data/raw',names(urls)))))
write.csv(manifest, 'data/raw/manifest.csv', row.names=FALSE)
