WITH btp AS (
    SELECT
        precinct.ogc_fid AS precinct_id,
        block.ogc_fid AS block_id,
        p1_001n * (ST_Area (ST_Intersection (block.geometry, precinct.geometry)) / ST_Area (block.geometry)) AS block_precinct_pop
    FROM
        blocks_2020 AS block
        INNER JOIN municipal_general_2023 AS precinct ON ST_Intersects (block.geometry, precinct.geometry)
            AND block.ROWID IN (
                SELECT
                    ROWID
                FROM
                    SpatialIndex
            WHERE
                f_table_name = 'blocks_2020'
                AND search_frame = precinct.geometry)
),
precinct_pop AS (
    SELECT
        precinct_id,
        sum(block_precinct_pop) AS precinct_pop
    FROM
        btp
    GROUP BY
        precinct_id
),
ptt AS (
    SELECT
        precinct.ogc_fid AS precinct_id,
        tract.ogc_fid AS tract_id,
        precinct_pop * (ST_Area (ST_Intersection (precinct.geometry, tract.geometry)) / ST_Area (precinct.geometry)) AS precinct_tract_pop
    FROM
        municipal_general_2023 AS precinct
        INNER JOIN precinct_pop ON precinct.ogc_fid = precinct_id
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
        ptt
    GROUP BY
        tract_id
)
SELECT
    precinct_id,
    precinct_pop AS p1_001n,
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
    sum(school_age_public * (precinct_tract_pop / tract_pop)) AS school_age_public,
    sum(total_cvap * (precinct_tract_pop / tract_pop)) AS total_cvap,
    sum(white_cvap * (precinct_tract_pop / tract_pop)) AS white_cvap,
    sum(black_cvap * (precinct_tract_pop / tract_pop)) AS black_cvap,
    sum(native_american_cvap * (precinct_tract_pop / tract_pop)) AS native_american_cvap,
    sum(asian_cvap * (precinct_tract_pop / tract_pop)) AS asian_cvap,
    sum(pacific_islander_cvap * (precinct_tract_pop / tract_pop)) AS pacific_islander_cvap,
    sum(latino_cvap * (precinct_tract_pop / tract_pop)) AS latino_cvap,
    precinct.geometry
FROM
    btp
    INNER JOIN ptt USING (precinct_id)
    INNER JOIN precinct_pop USING (precinct_id)
    INNER JOIN tract_pop USING (tract_id)
    INNER JOIN public_school_cvap as tract on tract.ogc_fid = tract_id
    INNER JOIN municipal_general_2023 AS precinct ON precinct_id = precinct.ogc_fid
GROUP BY
    precinct_id;














