# ============================================================
# Extract Soil Water Index values at fixed sites from multiple NetCDF files
# ============================================================

# --- Libraries ------------------------------------------------
library(ncdf4)
library(tidyverse)
library(RANN)

# --- Paths ----------------------------------------------------
nc_folder <- "path/to/nc/files"     # <-- set folder path
output_csv <- "SWI_002_sites.csv"   

# --- Site coordinates ----------------------------------------
sites <- tibble(
  site = c("Sanpietro", "Ceregnano", "Legnaro", "Landriano"),
  lon  = c(11.623616, 11.851802, 11.952149, 9.267466),
  lat  = c(44.65368, 45.05828, 45.34737, 45.32167)
)

points_of_interest <- sites %>%
  select(lon, lat)

# --- List NetCDF files ---------------------------------------
nc_files <- list.files(
  path = nc_folder,
  pattern = "\\.nc$",
  full.names = TRUE
)

# --- Storage --------------------------------------------------
results <- list()

# --- Loop over files -----------------------------------------
for (file in nc_files) {

  nc <- nc_open(file)

  lon  <- ncvar_get(nc, "lon")
  lat  <- ncvar_get(nc, "lat")
  time <- ncvar_get(nc, "time")
  swi  <- ncvar_get(nc, "SWI_002")

  nc_close(nc)

  date <- as.Date(time, origin = "1970-01-01")

  grid <- expand.grid(lon = lon, lat = lat)

  swi_df <- tibble(
    lon   = grid$lon,
    lat   = grid$lat,
    value = as.vector(swi)
  ) %>%
    drop_na() %>%
    mutate(
      value = ifelse(value > 200, NA, value),
      value = value * 0.5
    ) %>%
    drop_na()

  nn <- nn2(
    data  = swi_df[, c("lon", "lat")],
    query = points_of_interest,
    k = 1
  )

  extracted <- swi_df$value[nn$nn.idx]

  results[[file]] <- tibble(
    Date = date,
    !!!setNames(as.list(extracted), sites$site)
  )
}

# --- Combine all dates ---------------------------------------
final_df <- bind_rows(results) %>%
  arrange(Date)

# --- Export ---------------------------------------------------
write.csv(final_df, output_csv, row.names = FALSE)
