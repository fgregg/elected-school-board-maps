export OGR_GEOJSON_MAX_OBJ_SIZE=500MB

.PHONY : all
all : seed_partition.geojson ei_samples.csv

seed_partition.geojson : raw/blocks_2020.geojson
	python scripts/seed.py $< > $@

ei_samples.csv : cvap_general.csv
	Rscript scripts/eco.R

cvap_general.csv : chicago.db
	spatialite $< < scripts/votes_demo_2023.sql > $@

chicago.db : municipal_general_2023.geojson points_cvap_total.geojson	\
             points_cvap_black.geojson points_cvap_white.geojson	\
             points_cvap_hispanic.geojson points_cvap_asian.geojson
	ogr2ogr -f SQLite -dsco SPATIALITE=YES -t_srs "EPSG:4326" $@ $<
	for file in $(wordlist 2,$(words $^),$^); do \
            ogr2ogr -f SQLite -dsco SPATIALITE=YES -append -t_srs "EPSG:4326" $@ $$file; \
        done
	spatialite $@ < scripts/unroll_cvap.sql
	echo "vacuum;" | spatialite $@

municipal_general_2023.geojson :
	wget -O $@ https://raw.githubusercontent.com/datamade/chicago-municipal-elections/master/data/municipal_general_2023.geojson

points_cvap_%.geojson :
	wget -O $@ https://github.com/fgregg/chicago-dots/raw/main/points/points_cvap_$*.geojson

public_school.geojson :
	censusgeo -f "group(B14003)" -s 17 -p 14000 -v -v > $@

