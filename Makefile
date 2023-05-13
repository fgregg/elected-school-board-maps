export OGR_GEOJSON_MAX_OBJ_SIZE=500MB

.PHONY : all
all : districts.geojson

districts.geojson : seed_partition.geojson
	python scripts/generate_maps.py $< -e 0.7 > $@

seed_partition.geojson : input.geojson
	python scripts/seed.py $< > $@

input.geojson : chicago.db
	ogr2ogr -f GeoJSON $@ $< -sql @scripts/conform.sql

chicago.db : raw/blocks_2020.geojson public_school_cvap.geojson municipal_general_2023.geojson municipal_runoff_2023.geojson raw/senate_district_map.kml raw/Moderate_20-district_plan_shapefile.shp
	ogr2ogr -makevalid -f SQLite -dsco SPATIALITE=YES -t_srs "EPSG:4326" $@ $<
	for file in $(wordlist 2,$(words $^),$^); do \
            ogr2ogr -makevalid -f SQLite -dsco SPATIALITE=YES -append -t_srs "EPSG:4326" $@ $$file; \
        done
	echo "vacuum;" | spatialite $@

ei_samples.csv : cvap_general.csv
	Rscript scripts/eco.R

cvap_general.csv : chicago.db
	spatialite $< < scripts/votes_demo_2023.sql > $@

cvap_runoff.csv : chicago.db
	spatialite $< < scripts/votes_demo_runoff_2023.sql > $@

public_school_cvap.geojson :
	censusgeo -f "group(B14003)" -f B05003H_009E -f B05003H_011E -f B05003H_020E -f B05003H_022E -f B05003B_009E -f B05003B_011E -f B05003B_020E -f B05003B_022E -f B05003D_009E -f B05003D_011E -f B05003D_020E -f B05003D_022E -f B05003C_009E -f B05003C_011E -f B05003C_020E -f B05003C_022E -f B05003E_009E -f B05003E_011E -f B05003E_020E -f B05003E_022E -f B05003A_009E -f B05003A_011E -f B05003A_020E -f B05003A_022E -f B05003I_009E -f B05003I_011E -f B05003I_020E -f B05003I_022E -f B05003_009E -f B05003_011E -f B05003_020E -f B05003_022E -s 17 -p 14000 -v -v > $@ #| python scripts/simplify_variables.py > $@

blocks.topojson : input.geojson
	npx geo2topo blocks=$< | npx toposimplify -f -s 1e-10 > $@

municipal_general_2023.geojson :
	wget -O $@ https://raw.githubusercontent.com/datamade/chicago-municipal-elections/master/data/municipal_general_2023.geojson

municipal_runoff_2023.geojson :
	wget -O $@ https://raw.githubusercontent.com/datamade/chicago-municipal-elections/master/data/municipal_runoff_2023.geojson
