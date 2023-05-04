import sys
import json

geojson = json.load(sys.stdin)

for feature in geojson["features"]:
    properties = feature["properties"]
    # male and female students ages 5-17
    properties["school_age_public"] = (
        properties["B14003_005E"]
        + properties["B14003_006E"]
        + properties["B14003_007E"]
        + properties["B14003_033E"]
        + properties["B14003_034E"]
        + properties["B14003_035E"]
    )

# Write the modified GeoJSON to standard output (stdout)
json.dump(geojson, sys.stdout)
