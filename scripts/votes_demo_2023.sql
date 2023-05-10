.header on
.mode csv

WITH ptp AS (
    SELECT
        tract.ogc_fid AS tract_id,
        precinct.ogc_fid AS precinct_id,
        "registered voters" * (ST_Area (ST_Intersection (precinct.geometry, tract.geometry)) / ST_Area (precinct.geometry)) AS precinct_tract_pop
    FROM
        municipal_general_2023 AS precinct
        INNER JOIN public_school_cvap AS tract ON ST_Intersects (precinct.geometry, tract.geometry)
            AND precinct.ROWID IN (
                SELECT
                    ROWID
                FROM
                    SpatialIndex
            WHERE
                f_table_name = 'municipal_general_2023'
                AND search_frame = tract.geometry)
),
tract_pop AS (
    SELECT
        tract_id,
        sum(precinct_tract_pop) AS tract_pop
    FROM
        ptp
    GROUP BY
        tract_id
),
weights AS (
    SELECT
        precinct_id,
        tract_id,
        precinct_tract_pop / tract_pop AS weight
    FROM
        ptp
        INNER JOIN tract_pop USING (tract_id))
SELECT
    ward,
    precinct,
    "ja_mal green",
    "sophia king",
    "kam buckner",
    "willie l. wilson",
    "brandon johnson",
    "paul vallas",
    "lori e. lightfoot",
    "roderick t. sawyer",
    [jesus "chuy" garcia],
    "registered voters",
    "ballots cast",
    cast(sum(total_cvap * weight) as integer) AS total_cvap,
    cast(sum(white_cvap * weight) as integer) AS white_cvap,
    cast(sum(black_cvap * weight) as integer) AS black_cvap,
    cast(sum(asian_cvap * weight) as integer) AS asian_cvap,
    cast(sum(latino_cvap * weight) as integer) AS latino_cvap
FROM
    weights
    INNER JOIN municipal_general_2023 AS precinct ON precinct_id = precinct.ogc_fid
    INNER JOIN public_school_cvap AS tract ON tract_id = tract.ogc_fid
GROUP BY
    precinct_id;



