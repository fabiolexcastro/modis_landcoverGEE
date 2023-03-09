// Cargar shapefile de biomas
var biomas = ee.FeatureCollection("projects/ee-fabioalexandercastro/assets/biomes_geo_col");

// Definir rango de años
var startYear = 2001;
var endYear = 2020;

// Función para filtrar imágenes de MODIS
function filterMODIS(image) {
  var date = ee.Date(image.get('system:time_start'));
  var year = date.get('year');
  var month = date.get('month');
  var day = date.get('day');
  return ee.Image(image)
  .set('year', year)
  .set('month', month)
  .set('day', day)
  .select('LC_Type1')
  .clip(biomas);
}

// Filtrar imágenes de MODIS y renombrarlas
var collection = ee.ImageCollection('MODIS/006/MCD12Q1')
.filterDate(startYear + '-01-01', endYear + '-12-31')
.map(filterMODIS)
.map(function(image) {
  return image.rename(ee.String(image.date().format('YYYY_MM_dd')));
});

// Iterar sobre los biomas
biomas.distinct('DeCodigo').aggregate_array('DeCodigo').getInfo().forEach(function(bioma) {
  
  // Filtrar bioma
  var biomaFilter = biomas.filterMetadata('DeCodigo', 'equals', bioma).first();
  
  // Recortar imágenes de MODIS por bioma y año
  var filtered = collection.filterBounds(biomaFilter.geometry())
  .map(function(image) {
    var date = ee.Date(image.get('system:time_start'));
    var year = date.get('year');
    var month = date.get('month');
    var day = date.get('day');
    var new_name = ee.String(bioma).cat('_').cat(ee.String(year)).cat('_').cat(ee.String(month)).cat('_').cat(ee.String(day));
    return image.rename(new_name);
  });
  
  // Exportar a Google Drive
  Export.image.toDrive({
    image: filtered.toBands(),
    description: bioma + '_MODIS_LC',
    folder: 'MODIS_LC',
    scale: 500,
    maxPixels: 1e13,
    region: biomaFilter.geometry()
  });
});
