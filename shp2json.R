library(sf)
library(jsonlite)
library(dplyr)
library(ggplot2)


# write_geojson = function (shp, output) {
#     if (!dir.exists(dirname(output))) {
#         dir.create(dirname(output))
#     }
#     if (file.exists(output)) {
#         unlink(output)
#     }
#     st_write(shp,
#              output)
#     json_data = fromJSON(output)
#     json_string = toJSON(json_data, pretty=TRUE,
#                          auto_unbox=TRUE)
#     writeLines(json_string, output)
# }

# sf_use_s2(TRUE) 

# dTolerance = 500

computer_data_path = "/home/louis/Documents/bouleau/INRAE/data/"
map_dir = "map"
data_dir = "data"

# france
output = file.path(data_dir, "france.geo.json")
france = st_read(file.path(computer_data_path, map_dir, "france"))
france = st_transform(france, 2154)
france = st_simplify(france,
                     preserveTopology=TRUE,
                     dTolerance=500)
france = st_transform(france, 4326)
bbox = st_bbox(france)


json_data = list(
    type="FeatureCollection",
    
    features = list(
        list(
            type="Feature",

            properties=list(
                short_name="FRA",
                name="France",
                bbox=list(xmin=bbox[1],
                          ymin=bbox[2],
                          xmax=bbox[3],
                          ymax=bbox[4]),
                centroid=unlist(st_centroid(france)$geometry)
            ),
            
            geometry=list(
                type="MultiPolygon",
                coordinates=sapply(seq(length(france$geometry[[1]])),
                                   function (i) {
                                       france$geometry[[1]][i]
                                   })
            )
        )
    )
)

json_string = toJSON(json_data,
                     pretty=TRUE,
                     auto_unbox=TRUE)
writeLines(json_string, output)


# river
output = file.path(data_dir, "river.geo.json")
river = st_read(file.path(computer_data_path, map_dir, "coursEau"))

river$length = as.numeric(st_length(river$geometry))
river = filter(river, length >= 100000)
river = st_simplify(river, preserveTopology=TRUE,
                    dTolerance=500)
river = st_transform(river, 4326)
river = st_cast(river, "MULTILINESTRING")
nRiver = length(river$geometry)

river$norm = (sqrt(river$length)-sqrt(min(river$length))) / (sqrt(max(river$length))-sqrt(min(river$length)))

max(river$length)

json_data = list(
    type="FeatureCollection",
    
    features = lapply(
        1:nRiver,
        function (i) {
            list(
                type="Feature",
                
                properties=list(
                    gid=river$gid[i],
                    CdOH=river$CdOH[i],
                    TopoOH=river$TopoOH[i],
                    length=river$length[i],
                    norm=river$norm[i]
                ),
                
                geometry=list(
                    type="MultiLineString",
                    coordinates=
                        lapply(        
                            1:length(river$geometry[[i]]),
                            function (j) {
                                river$geometry[[i]][[j]]
                            })
                )
            )
        })
)

json_string = toJSON(json_data,
                     pretty=TRUE,
                     auto_unbox=TRUE)
writeLines(json_string, output)





# entite hydro
output = file.path(data_dir, "entiteHydro.geo.json")
entiteHydro = read_sf(file.path(computer_data_path, map_dir,
                                'entiteHydro/BV_4207_stations.shp'))
entiteHydro = st_simplify(entiteHydro, preserveTopology=TRUE,
                          dTolerance=500)
entiteHydro = st_transform(entiteHydro, 4326)
# sf_use_s2(FALSE) # avoid bug in simplify https://github.com/r-spatial/sf/issues/1762
# entiteHydro = st_make_valid(entiteHydro)
# entiteHydro = st_simplify(entiteHydro, preserveTopology=TRUE,
                          # dTolerance=100)
# sf_use_s2(TRUE)



json_data = list(
    type="FeatureCollection",
    
    features = lapply(
        1:nrow(entiteHydro),
        function (i) {
            list(
                type="Feature",
                
                properties=list(
                    code=entiteHydro$Code[i],
                    surface=entiteHydro$S_km2[i]
                ),
                
                geometry=list(
                    type="Polygon",
                    coordinates=
                        list(
                            as.matrix(entiteHydro$geometry[[i]])
                        )
                )
            )
        })
)

json_string = toJSON(json_data,
                     pretty=TRUE,
                     auto_unbox=TRUE)
writeLines(json_string, output)
