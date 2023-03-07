seed_partition.geojson : raw/blocks_2020.geojson
	python scripts/seed.py $< > $@
