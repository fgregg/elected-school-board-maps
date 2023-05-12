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
    properties["total_cvap"] = (
        properties['B05003_009E']
        + properties['B05003_011E']
        + properties['B05003_020E']
        + properties['B05003_022E']
        )

    properties["white_cvap"] = (
        properties['B05003H_009E']
        + properties['B05003H_011E']
        + properties['B05003H_020E']
        + properties['B05003H_022E']
        )

    properties["black_cvap"] = (
        properties['B05003B_009E']
        + properties['B05003B_011E']
        + properties['B05003B_020E']
        + properties['B05003B_022E']
        )

    properties["native_american_cvap"] = (
        properties['B05003C_009E']
        + properties['B05003C_011E']
        + properties['B05003C_020E']
        + properties['B05003C_022E']
        )

    properties["asian_cvap"] = (
        properties['B05003D_009E']
        + properties['B05003D_011E']
        + properties['B05003D_020E']
        + properties['B05003D_022E']
        )

    properties["pacific_islander_cvap"] = (
        properties['B05003E_009E']
        + properties['B05003E_011E']
        + properties['B05003E_020E']
        + properties['B05003E_022E']
        )

    properties["latino_cvap"] = (
        properties['B05003I_009E']
        + properties['B05003I_011E']
        + properties['B05003I_020E']
        + properties['B05003I_022E']
        )
    

# Write the modified GeoJSON to standard output (stdout)
json.dump(geojson, sys.stdout)
