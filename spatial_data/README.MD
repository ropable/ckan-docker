# Spatial Data

This directory is used to store GeoJSON files that will be loaded from docker entrypoint file `02_setup_dbca.sh` using the CLI command `ckan -c $CKAN_INI dbca load_spatial_data` if the mapping exists in `ckanext.dbca.spatial_data_mapping`.

## Creating the data files

As each base layer can have many rows per named feature, it is important that we convert this to a dataset that contains only one row for each named feature. The base layers can have many rows because some features are naturally separate from one another, such as the polygon for an island in the same named feature as that on the mainland.

| Layer Name             | Agency Layer Name                 | Property for Label | Property for Code | Output Filename         |
|------------------------|-----------------------------------|--------------------|-------------------|-------------------------|
| IBRA Regions           | IBRA Vegetation (Subregions) - WA | IWA_REG_NAME_7     | IWA_REG_CODE_7    | ibra-regions.geojson    |
| IBRA Subregions        | IBRA Vegetation (Subregions) - WA | IWA_SUB_NAME_7     | IWA_SUB_CODE_7    | ibra-subregions.geojson |
| IMCRA Regions          | IMCRA Regions (Australia)         | MESO_NAME          | MESO_ABBR         | imcra-regions.geojson   |
| Local Government Areas | Local Govt. Authorities (LGA)     | LGA_LGA_NAME       | LGA_TYPE          | lga-wa.geojson          |
| DBCA Managed Tenure    | Managed Tenure                    | LEG_NAME           | LEG_TENURE        | tenure.geojson          |

For each layer:

1. Firstly, we must convert the layer into a single row for each unique label-polygon instance. We accomplish this by using the “Dissolve” command in QGIS.
   1. With the new temporary layer selected, choose <kbd>Vector > Geoprocessing Tools > Dissolve…</kbd> from the menu.
   2. Select the layer property for the label for the newly created temporary layer (see the table above) to tell QGIS which attribute to “unique” on.
   3. Run the command.

2. Secondly, we must simplify each polygon in a layer so it takes up less than 1 MB per polygon. We accomplish this by using the “Simplify” command in QGIS.
   1. Open one of the target layers (above) in QGIS, then select <kbd>Vector > Geometry Tools > Simplify…</kbd> from the menu.
   2. While the layer is selected in the Layers window, choose <kbd>Distance (Douglas-Peucker)</kbd> from the <kbd>Simplification</kbd> method dropdown and use a tolerance of <kbd>0.05</kbd>. Leave the other options as they are to generate a temporary layer.
   3. Run the command.

3. Lastly, export the resulting layer to GeoJSON.

   1. Right-click the layer in the Layer window and choose <kbd>Export > Save Features As…</kbd> from the popup menu.
   2. Give the file a name, e.g. <kbd>ibra-subregions.geojson</kbd> matching the above name in the Output Filename column.
   3. Run the command.
   4. Archive the file to zip, e.g. <kbd>ibra-subregions.zip</kbd>.

## Usage

To add a new GeoJSON file, simply place it in this directory. The ckan-worker container will automatically load any files on deployment if there is a corresponding mapping defined in `ckanext.dbca.spatial_data_mapping`.

Please ensure that the GeoJSON file follows the correct format and contains valid spatial data.

## Mapping

The mapping between the GeoJSON files and the data fields in the CKAN database is defined in the `ckanext.dbca.spatial_data_mapping` configuration. Make sure to update the mapping accordingly if you add or modify any GeoJSON files.

Each mapping consists of a filename, layer field, a code field, and a name field.

The mappings are defined as a dictionary where the key is the filename of the GeoJSON file and the value is another dictionary containing the layer, code, and name fields.

Example:
```
{
    "ibra.geojson": {"layer": "IBRA Regions", "code":"IWA_REG_CODE_7", "name":"IWA_REG_NAME_7"}, 
    "ibra-sub.geojson": {"layer": "IBRA Subregions)", "code":"IWA_SUB_CODE_7", "name":"IWA_SUB_NAME_7"}, 
    "imcra.geojson": {"layer": "IMCRA Regions", "code": "MESO_ABBR", "name":"MESO_NAME"}, 
    "lga-wa.geojson": {"layer": " Local Government Areas", "code":"LGA_TYPE", "name":"LGA_LGA_NAME"}, 
    "tenure.geojson": {"layer": "DBCA Managed Tenure", "code":"LEG_TENURE", "name":"LEG_NAME"}
}
```

## Delete all spatial data and reload geojson files
 
 This is recommended any time there are updates to any of the geojson files
 
 Truncate database table dbca_spatial
 ```
 TRUNCATE "public"."dbca_spatial";
 ```
 ReDeploy ckan-worker container or run CLI command in container ckan-worker to load spatial data
 ```
 ckan -c $CKAN_INI dbca load_spatial_data
 ```

 ## Delete dataset spatial metadata values

 If there is a case where all or most current dataset spatial coordinates are incorrect and they need to be removed, run the below commands

 Set dataset spatial values you to NULL in the database
 ```
 update "public"."package_extra"
 set value = null
 where key = 'spatial';
 ```

 Rebuild Solr index by running the CLI command in either the ckan or ckan-worker containers
 ```
 ckan -c $CKAN_INI search-index rebuild
 ```