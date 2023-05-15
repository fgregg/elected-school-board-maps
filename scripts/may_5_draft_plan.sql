.header on
.mode csv

WITH btt AS (
    SELECT
        tract.ogc_fid AS tract_id,
        block.ogc_fid AS block_id,
        p1_001n * (ST_Area (ST_Intersection (block.geometry, tract.geometry)) / ST_Area (block.geometry)) AS block_tract_pop
    FROM
        blocks_2020 AS block
        INNER JOIN public_school_cvap AS tract ON ST_Intersects (block.geometry, tract.geometry)
            AND block.ROWID IN (
                SELECT
                    ROWID
                FROM
                    SpatialIndex
            WHERE
                f_table_name = 'blocks_2020'
                AND search_frame = tract.geometry)
),
tract_pop AS (
    SELECT
        tract_id,
        sum(block_tract_pop) AS tract_pop
    FROM
        btt
    GROUP BY
        tract_id
),
btp AS (
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
block_level AS (
    SELECT
        block_id,
        p1_001n,
        senate_plan.Name AS district_name,
        sum("ja_mal green" * (block_precinct_pop / precinct_pop)) AS "ja_mal green",
        sum("sophia king" * (block_precinct_pop / precinct_pop)) AS "sophia king",
        sum("kam buckner" * (block_precinct_pop / precinct_pop)) AS "kam buckner",
        sum("willie l. wilson" * (block_precinct_pop / precinct_pop)) AS "willie l. wilson",
        sum("brandon johnson" * (block_precinct_pop / precinct_pop)) AS "brandon johnson",
        sum("paul vallas" * (block_precinct_pop / precinct_pop)) AS "paul vallas",
        sum("lori e. lightfoot" * (block_precinct_pop / precinct_pop)) AS "lori e. lightfoot",
        sum("roderick t. sawyer" * (block_precinct_pop / precinct_pop)) AS "roderick t. sawyer",
        sum([jesus "chuy" garcia] * (block_precinct_pop / precinct_pop)) AS[jesus "chuy" garcia],
        sum("registered voters" * (block_precinct_pop / precinct_pop)) AS "registered voters",
        sum("ballots cast" * (block_precinct_pop / precinct_pop)) AS "ballots cast",
        sum(school_age_public * (block_tract_pop / tract_pop)) AS school_age_public,
        sum(total_cvap * (block_tract_pop / tract_pop)) AS total_cvap,
        sum(white_cvap * (block_tract_pop / tract_pop)) AS white_cvap,
        sum(black_cvap * (block_tract_pop / tract_pop)) AS black_cvap,
        sum(native_american_cvap * (block_tract_pop / tract_pop)) AS native_american_cvap,
        sum(asian_cvap * (block_tract_pop / tract_pop)) AS asian_cvap,
        sum(pacific_islander_cvap * (block_tract_pop / tract_pop)) AS pacific_islander_cvap,
        sum(latino_cvap * (block_tract_pop / tract_pop)) AS latino_cvap,
        block.geometry
    FROM
        btt
        INNER JOIN btp USING (block_id)
        INNER JOIN tract_pop USING (tract_id)
        INNER JOIN precinct_pop USING (precinct_id)
        INNER JOIN municipal_general_2023 AS precinct ON precinct_id = precinct.ogc_fid
        INNER JOIN blocks_2020 AS block ON block_id = block.ogc_fid
        INNER JOIN public_school_cvap AS tract ON tract_id = tract.ogc_fid
        INNER JOIN "20 district draft 1" AS senate_plan ON (ST_Area (ST_Intersection (block.geometry, senate_plan.geometry)) / ST_Area (block.geometry)) > 0.5
            AND block.ROWID IN (
                SELECT
                    ROWID
                FROM
                    SpatialIndex
            WHERE
                f_table_name = 'blocks_2020'
                AND search_frame = senate_plan.geometry)
        GROUP BY
            block_id
)
SELECT
    district_name,
    sum(p1_001n) AS p1_001n,
    sum("paul vallas") AS vallas,
    sum("brandon johnson") AS johnson,
    sum("lori e. lightfoot") AS lightfoot,
    sum([jesus "chuy" garcia]) AS garcia,
    sum(school_age_public) AS school_age_public
FROM
    block_level
GROUP BY
    district_name;



