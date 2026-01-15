# 00_download_data.R
# Downloads OWID datasets into data/raw/

dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)

life_url <- "https://ourworldindata.org/grapher/life-expectancy.csv"
gdp_url  <- "https://ourworldindata.org/grapher/gdp-per-capita-worldbank.csv"

life_path <- file.path("data/raw", "life-expectancy.csv")
gdp_path  <- file.path("data/raw", "gdp-per-capita-worldbank.csv")

download_if_missing <- function(url, dest) {
  if (!file.exists(dest)) {
    message("Downloading: ", url)
    utils::download.file(url, destfile = dest, mode = "wb", quiet = FALSE)
  } else {
    message("Already exists: ", dest)
  }
}

download_if_missing(life_url, life_path)
download_if_missing(gdp_url, gdp_path)

message("Done. Files saved in data/raw/")
