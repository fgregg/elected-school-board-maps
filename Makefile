export OGR_GEOJSON_MAX_OBJ_SIZE=500MB

.PHONY : all
all : districts.geojson

districts.geojson : seed_partition.geojson
	python scripts/generate_maps.py $< -s -e 0.7 > $@

seed_partition.geojson : input.geojson
	python scripts/seed.py $< > $@

input.geojson : chicago.db
	ogr2ogr -f GeoJSON $@ $< -sql @scripts/conform.sql

chicago.db : raw/blocks_2020.geojson public_school.geojson
	ogr2ogr -f SQLite -dsco SPATIALITE=YES -t_srs "EPSG:4326" $@ $<
	for file in $(wordlist 2,$(words $^),$^); do \
            ogr2ogr -f SQLite -dsco SPATIALITE=YES -append -t_srs "EPSG:4326" $@ $$file; \
        done
	echo "vacuum;" | spatialite $@

public_school.geojson :
	censusgeo -f "group(B14003)" -s 17 -p 14000 -v -v | python scripts/simplify_variables.py > $@

