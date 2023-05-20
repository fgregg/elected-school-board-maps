export OGR_GEOJSON_MAX_OBJ_SIZE=500MB

.PHONY : all
all : assignments.csv blocks.topojson may_5_draft_plan.csv may_5_draft_plan.gejson 

blocks.topojson : input.geojson
	npx geo2topo blocks=$< | npx toposimplify -f -s 1e-10 > $@

may_17_draft_plan.geojson : raw/may_17_map.kml
	ogr2ogr -nlt POLYGON -f GeoJSON $@ $< 

may_5_draft_plan.geojson : raw/senate
	ogr2ogr -nlt POLYGON -f GeoJSON $@ $< 

may_5_draft_plan.csv : chicago.db
	spatialite $< < scripts/may_5_draft_plan.sql > $@

may_17_draft_plan.csv : chicago.db
	spatialite $< < scripts/may_17_draft_plan.sql > $@

brottman_plan.csv : chicago.db
	spatialite $< < scripts/brottman_plan.sql > $@

kf_plan.csv : chicago.db
	spatialite $< < scripts/kf_plan.sql > $@

ctu_plan.csv : chicago.db
	spatialite $< < scripts/ctu_plan.sql > $@

assignments.csv : assignments.json
	cat $< | python scripts/assignment_csv.py > $@	

assignments.json : keeper_2.geojson
	python scripts/generate_maps.py $< --n_minority_districts=10 > $@

epoch_999.geojson : seed_partition.geojson
	python scripts/steer_maps.py $< --n_epochs=1000 > $@

seed_partition.geojson : input.geojson
	python scripts/seed.py $< > $@

input.geojson : chicago.db
	ogr2ogr -f GeoJSON $@ $< -sql @scripts/conform.sql

ei_samples.csv : cvap_general.csv
	Rscript scripts/eco.R

cvap_general.csv : chicago.db
	spatialite $< < scripts/votes_demo_2023.sql > $@

cvap_runoff.csv : chicago.db
	spatialite $< < scripts/votes_demo_runoff_2023.sql > $@

chicago.db : raw/blocks_2020.geojson public_school_cvap.geojson municipal_general_2023.geojson municipal_runoff_2023.geojson raw/senate_district_map.kml raw/Moderate_20-district_plan_shapefile.shp raw/brottman.kml raw/may_17_map.kml raw/ctu.geojson
	ogr2ogr -makevalid -f SQLite -dsco SPATIALITE=YES -t_srs "EPSG:4326" $@ $<
	for file in $(wordlist 2,$(words $^),$^); do \
            ogr2ogr -makevalid -f SQLite -dsco SPATIALITE=YES -append -t_srs "EPSG:4326" $@ $$file; \
        done
	echo "vacuum;" | spatialite $@

municipal_general_2023.geojson :
	wget -O $@ https://raw.githubusercontent.com/datamade/chicago-municipal-elections/master/data/municipal_general_2023.geojson

municipal_runoff_2023.geojson :
	wget -O $@ https://raw.githubusercontent.com/datamade/chicago-municipal-elections/master/data/municipal_runoff_2023.geojson

public_school_cvap.geojson :
	censusgeo -f "group(B14003)" -f B05003H_009E -f B05003H_011E -f B05003H_020E -f B05003H_022E -f B05003B_009E -f B05003B_011E -f B05003B_020E -f B05003B_022E -f B05003D_009E -f B05003D_011E -f B05003D_020E -f B05003D_022E -f B05003C_009E -f B05003C_011E -f B05003C_020E -f B05003C_022E -f B05003E_009E -f B05003E_011E -f B05003E_020E -f B05003E_022E -f B05003A_009E -f B05003A_011E -f B05003A_020E -f B05003A_022E -f B05003I_009E -f B05003I_011E -f B05003I_020E -f B05003I_022E -f B05003_009E -f B05003_011E -f B05003_020E -f B05003_022E -s 17 -p 14000 -v -v > $@ | python scripts/simplify_variables.py > $@
