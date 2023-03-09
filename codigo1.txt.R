// Importar el shapefile de biomas
var biomas = ee.FeatureCollection("projects/ee-fabioalexandercastro/assets/biomes_geo_col");

// Definir la colección de Land Cover de MODIS
var landcover = ee.ImageCollection("MODIS/006/MCD12Q1")
.select('LC_Type1')
.filterDate('2001-01-01', '2020-12-31');

// Iterar sobre los biomas y exportar los datos
biomas.distinct('DeCodigo').aggregate_array('DeCodigo').evaluate(function(biomasList) {
  biomasList.forEach(function(bioma) {
    var folder = bioma;
    var roi = biomas.filterMetadata('DeCodigo', 'equals', bioma);
    var landcover_filtered = landcover.filterBounds(roi.geometry());
    var landcover_bioma = landcover_filtered.map(function(image) {
      return image.clip(roi);
    });
    var landcover_bioma_renamed = landcover_bioma.map(function(image) {
      return image.rename(bioma + '_' + image.date().format('YYYY_MM_dd'));
    });
    Export.image.toDrive({
      image: landcover_bioma_renamed.toBands(),
      description: bioma + '_LandCover_MODIS',
      folder: folder,
      scale: 500,
      region: roi.geometry().bounds(),
      maxPixels: 1e13
    });
  });
});