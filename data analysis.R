
# Load libraries ----------------------------------------------------------
require(pacman)
pacman::p_load(terra, sf, fs, tidyverse, glue, rgeos, gtools, RColorBrewer, ggspatial, showtext)

g <- gc(reset = T)
rm(list = ls())
options(scipen = 999, warn = -1)

# Load data ---------------------------------------------------------------
path <- 'data/GEE_exports'
fles <- dir_ls(path)
vlle <- vect('D:/data/spatial/igac/mpios.gpkg')
dpto <- vect('D:/data/spatial/igac/dptos.gpkg')

sinus <- "+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +a=6371007.181 +b=6371007.181 +units=m +no_defs"

# Filtering only for Valle del Cauca --------------------------------------
vlle <- vlle[vlle$DPTO_CNMBR == 'VALLE DEL CAUCA',]
vlle <- project(vlle, '+proj=longlat +datum=WGS84 +no_defs +type=crs')
writeVector(vlle, 'data/shpf/valle_mpios_geo.shp')

# Read as rasters files ---------------------------------------------------
rstr <- map(fles, rast)
rstr <- map(1:length(rstr), function(i){rstr[[i]][[5]]})
rstr <- do.call('c', rstr)

# Project the shapefile of dptos ------------------------------------------
dpto <- terra::project(dpto, sinus)
vlle <- terra::project(vlle, sinus)
rstr <- terra::mask(rstr, vlle)
names(rstr) <- glue('LC_{2001:2020}')

# Raster to table ---------------------------------------------------------
tble <- terra::as.data.frame(rstr, xy = T)
tble <- as_tibble(tble)

# Tidy the table
tble <- mutate(tble, gid = 1:nrow(tble)) %>% 
  gather(var, value, -x, -y, -gid) %>% 
  as_tibble() %>% 
  mutate(year = parse_number(var)) %>% 
  dplyr::select(-var)

# Labels of values (raster) - To check please visit: https://developers.google.com/earth-engine/datasets/catalog/MODIS_061_MCD12Q1#bands
lbls <- read.table('data/tble/labels.csv', sep = ';', header = T)

# Join both tables into only one
tble <- inner_join(tble, lbls, by = c('value' = 'Value'))
tble <- mutate(tble, year = factor(year, levels = 2001:2020))

# To make the maps --------------------------------------------------------

# Get the colors
unqs <- tble %>% distinct(value, Color, Description) %>% arrange(value) 
clrs <- glue('#{pull(unqs, Color)}')
names(clrs) <- pull(unqs, 3)

# Making the map
gmap <- ggplot() + 
  geom_tile(data = tble, aes(x = x, y = y, fill = Description)) + 
  facet_wrap(.~year) +
  scale_fill_manual(values = clrs) +
  coord_sf() + 
  labs(x = '', y = '', fill = 'Landcover') +
  theme_minimal() + 
  theme(axis.text.y = element_text(angle = 90, hjust = 0.5), 
        legend.position = 'bottom') +
  guides(fill = guide_legend(ncol = 2, title.position = "top", title.hjust = 0.5)) 

dir_create('png')
ggsave(plot = gmap, filename = 'png/map_v1.png', units = 'in', width = 29, height = 15, dpi = 300)




