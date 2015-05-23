# Name: MakeZonalStatistics_wc_oregon.py
# Description: Summarizes impervious land within the huc4, huc8, and county
# Requirements: Spatial Analyst Extension
# Author: Tyler Scott

# Import system modules
import arcpy
from arcpy import env
from arcpy.sa import *
arcpy.CheckOutExtension("Spatial")

# Set environment settings
env.workspace = "H:/quinalt"

# Set local variables
inZoneData = "SpatialData/watershed_councils/OregonWatershedCouncils.shp"
zoneField = "altName"
inValueRaster = "SpatialData/tf_rasters/tf_ag_1992"
outTable = "LandUse_RasterData/ag_wc_1992.dbf"

# Execute ZonalStatisticsAsTable
outZSaT = ZonalStatisticsAsTable(inZoneData, zoneField, inValueRaster, 
                                 outTable, "DATA", "ALL")
 
inZoneData = "SpatialData/watershed_councils/OregonWatershedCouncils.shp"
zoneField = "altName"
inValueRaster = "SpatialData/tf_rasters/tf_past_2001"
outTable = "LandUse_RasterData/past_wc_2001.dbf"

# Execute ZonalStatisticsAsTable
outZSaT = ZonalStatisticsAsTable(inZoneData, zoneField, inValueRaster, 
                                 outTable, "DATA", "ALL")                               
                     
                                 
inZoneData = "SpatialData/watershed_councils/OregonWatershedCouncils.shp"
zoneField = "altName"
inValueRaster = "SpatialData/tf_rasters/tf_crop_2001"
outTable = "LandUse_RasterData/crop_wc_2001.dbf"

# Execute ZonalStatisticsAsTable
outZSaT = ZonalStatisticsAsTable(inZoneData, zoneField, inValueRaster, 
                                 outTable, "DATA", "ALL")                                    
                                 
                                 
inZoneData = "SpatialData/watershed_councils/OregonWatershedCouncils.shp"
zoneField = "altName"
inValueRaster = "SpatialData/tf_rasters/tf_past_2006"
outTable = "LandUse_RasterData/past_wc_2006.dbf"

# Execute ZonalStatisticsAsTable
outZSaT = ZonalStatisticsAsTable(inZoneData, zoneField, inValueRaster, 
                                 outTable, "DATA", "ALL")                               
                     
                                 
inZoneData = "SpatialData/watershed_councils/OregonWatershedCouncils.shp"
zoneField = "altName"
inValueRaster = "SpatialData/tf_rasters/tf_crop_2006"
outTable = "LandUse_RasterData/crop_wc_2006.dbf"

# Execute ZonalStatisticsAsTable
outZSaT = ZonalStatisticsAsTable(inZoneData, zoneField, inValueRaster, 
                                 outTable, "DATA", "ALL")                                    
                                                                             

                                 
inZoneData = "SpatialData/watershed_councils/OregonWatershedCouncils.shp"
zoneField = "altName"
inValueRaster = "SpatialData/tf_rasters/tf_past_2011"
outTable = "LandUse_RasterData/past_wc_2011.dbf"

# Execute ZonalStatisticsAsTable
outZSaT = ZonalStatisticsAsTable(inZoneData, zoneField, inValueRaster, 
                                 outTable, "DATA", "ALL")                               
                     
                                 
inZoneData = "SpatialData/watershed_councils/OregonWatershedCouncils.shp"
zoneField = "altName"
inValueRaster = "SpatialData/tf_rasters/tf_crop_2011"
outTable = "LandUse_RasterData/crop_wc_2011.dbf"

# Execute ZonalStatisticsAsTable
outZSaT = ZonalStatisticsAsTable(inZoneData, zoneField, inValueRaster, 
                                 outTable, "DATA", "ALL")                                   
                                 
                                 
                                 
# Set local variables
inZoneData = "SpatialData/watershed_councils/OregonWatershedCouncils.shp"
zoneField = "altName"
inValueRaster = "SpatialData/tf_rasters/tf_forst_1992"
outTable = "LandUse_RasterData/forst_wc_1992.dbf"

# Execute ZonalStatisticsAsTable
outZSaT = ZonalStatisticsAsTable(inZoneData, zoneField, inValueRaster, 
                                 outTable, "DATA", "ALL")                                 
                                 
                                 
# Set local variables
inZoneData = "SpatialData/watershed_councils/OregonWatershedCouncils.shp"
zoneField = "altName"
inValueRaster = "SpatialData/tf_rasters/tf_forst_2001"
outTable = "LandUse_RasterData/forst_wc_2001.dbf"

# Execute ZonalStatisticsAsTable
outZSaT = ZonalStatisticsAsTable(inZoneData, zoneField, inValueRaster, 
                                 outTable, "DATA", "ALL")                                 
                                                                  
                                 
# Set local variables
inZoneData = "SpatialData/watershed_councils/OregonWatershedCouncils.shp"
zoneField = "altName"
inValueRaster = "SpatialData/tf_rasters/tf_forst_2006"
outTable = "LandUse_RasterData/forst_wc_2006.dbf"

# Execute ZonalStatisticsAsTable
outZSaT = ZonalStatisticsAsTable(inZoneData, zoneField, inValueRaster, 
                                 outTable, "DATA", "ALL")                                 
                                                                  
                                 
                                 
# Set local variables
inZoneData = "SpatialData/watershed_councils/OregonWatershedCouncils.shp"
zoneField = "altName"
inValueRaster = "SpatialData/tf_rasters/tf_forst_2011"
outTable = "LandUse_RasterData/forst_wc_2011.dbf"

# Execute ZonalStatisticsAsTable
outZSaT = ZonalStatisticsAsTable(inZoneData, zoneField, inValueRaster, 
                                 outTable, "DATA", "ALL")                                 
                                                                  
                                 
                              
                                 
                                 
# Set local variables
inZoneData = "SpatialData/watershed_councils/OregonWatershedCouncils.shp"
zoneField = "altName"
inValueRaster = "SpatialData/tf_rasters/tf_dev_1992"
outTable = "LandUse_RasterData/dev_wc_1992.dbf"

# Execute ZonalStatisticsAsTable
outZSaT = ZonalStatisticsAsTable(inZoneData, zoneField, inValueRaster, 
                                 outTable, "DATA", "ALL")                                 
                                 
                                 
# Set local variables
inZoneData = "SpatialData/watershed_councils/OregonWatershedCouncils.shp"
zoneField = "altName"
inValueRaster = "SpatialData/tf_rasters/tf_dev_2001"
outTable = "LandUse_RasterData/dev_wc_2001.dbf"

# Execute ZonalStatisticsAsTable
outZSaT = ZonalStatisticsAsTable(inZoneData, zoneField, inValueRaster, 
                                 outTable, "DATA", "ALL")                                 
                                                                  
                                 
# Set local variables
inZoneData = "SpatialData/watershed_councils/OregonWatershedCouncils.shp"
zoneField = "altName"
inValueRaster = "SpatialData/tf_rasters/tf_dev_2006"
outTable = "LandUse_RasterData/dev_wc_2006.dbf"

# Execute ZonalStatisticsAsTable
outZSaT = ZonalStatisticsAsTable(inZoneData, zoneField, inValueRaster, 
                                 outTable, "DATA", "ALL")                                 
                                                                  
                                 
                                 
# Set local variables
inZoneData = "SpatialData/watershed_councils/OregonWatershedCouncils.shp"
zoneField = "altName"
inValueRaster = "SpatialData/tf_rasters/tf_dev_2011"
outTable = "LandUse_RasterData/dev_wc_2011.dbf"

# Execute ZonalStatisticsAsTable
outZSaT = ZonalStatisticsAsTable(inZoneData, zoneField, inValueRaster, 
                                 outTable, "DATA", "ALL")                                 
                                                                  
                                 
                                
    
                                 
                                 
                                 
# Set local variables
inZoneData = "SpatialData/watershed_councils/OregonWatershedCouncils.shp"
zoneField = "altName"
inValueRaster = "SpatialData/tf_rasters/tf_wetl_1992"
outTable = "LandUse_RasterData/wetl_wc_1992.dbf"

# Execute ZonalStatisticsAsTable
outZSaT = ZonalStatisticsAsTable(inZoneData, zoneField, inValueRaster, 
                                 outTable, "DATA", "ALL")                                 
                                 
                                 
# Set local variables
inZoneData = "SpatialData/watershed_councils/OregonWatershedCouncils.shp"
zoneField = "altName"
inValueRaster = "SpatialData/tf_rasters/tf_wetl_2001"
outTable = "LandUse_RasterData/wetl_wc_2001.dbf"

# Execute ZonalStatisticsAsTable
outZSaT = ZonalStatisticsAsTable(inZoneData, zoneField, inValueRaster, 
                                 outTable, "DATA", "ALL")                                 
                                                                  
                                 
# Set local variables
inZoneData = "SpatialData/watershed_councils/OregonWatershedCouncils.shp"
zoneField = "altName"
inValueRaster = "SpatialData/tf_rasters/tf_wetl_2006"
outTable = "LandUse_RasterData/wetl_wc_2006.dbf"

# Execute ZonalStatisticsAsTable
outZSaT = ZonalStatisticsAsTable(inZoneData, zoneField, inValueRaster, 
                                 outTable, "DATA", "ALL")                                 
                                                                  
                                 
                                 
# Set local variables
inZoneData = "SpatialData/watershed_councils/OregonWatershedCouncils.shp"
zoneField = "altName"
inValueRaster = "SpatialData/tf_rasters/tf_wetl_2011"
outTable = "LandUse_RasterData/wetl_wc_2011.dbf"

# Execute ZonalStatisticsAsTable
outZSaT = ZonalStatisticsAsTable(inZoneData, zoneField, inValueRaster, 
                                 outTable, "DATA", "ALL")                                 
                                                                  
                                        
                                                                                                                                              
arcpy.CheckInExtension("Spatial")