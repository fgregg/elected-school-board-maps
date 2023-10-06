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
precinct_pop AS (
    SELECT
        precinct_id,
        sum(block_precinct_pop) AS precinct_pop
    FROM
        btp
    GROUP BY
        precinct_id
),
block_level_precinct AS (
    SELECT
        block_id,
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
        sum("ballots cast" * (block_precinct_pop / precinct_pop)) AS "ballots cast"
    FROM
        btp
        INNER JOIN precinct_pop USING (precinct_id)
        INNER JOIN municipal_general_2023 AS precinct ON precinct_id = precinct.ogc_fid
    GROUP BY
        block_id
),
block_level_tract AS (
    SELECT
        block_id,
        sum(school_age_public * (block_tract_pop / tract_pop)) AS school_age_public,
        sum(total_cvap * (block_tract_pop / tract_pop)) AS total_cvap,
        sum(white_cvap * (block_tract_pop / tract_pop)) AS white_cvap,
        sum(black_cvap * (block_tract_pop / tract_pop)) AS black_cvap,
        sum(native_american_cvap * (block_tract_pop / tract_pop)) AS native_american_cvap,
        sum(asian_cvap * (block_tract_pop / tract_pop)) AS asian_cvap,
        sum(pacific_islander_cvap * (block_tract_pop / tract_pop)) AS pacific_islander_cvap,
        sum(latino_cvap * (block_tract_pop / tract_pop)) AS latino_cvap
    FROM
        btt
        INNER JOIN tract_pop USING (tract_id)
        INNER JOIN public_school_cvap AS tract ON tract_id = tract.ogc_fid
    GROUP BY
        block_id
),
district_overlap AS (
    SELECT
        ctu.district AS district_name,
	p1_001n,
        block.ogc_fid AS block_id,
        ROW_NUMBER() OVER (PARTITION BY block.ogc_fid ORDER BY ST_Area (ST_Intersection (block.geometry, ctu.geometry)) DESC) AS row_num
    FROM
        blocks_2020 as block
        INNER JOIN ctu_labeled as ctu ON ST_Intersects (block.geometry, ctu.geometry)
            AND block.ROWID IN (
                SELECT
                    ROWID
                FROM
                    SpatialIndex
            WHERE
                f_table_name = 'blocks_2020'
                AND search_frame = ctu.geometry))
SELECT
    district_name,
    sum(p1_001n) AS p1_001n,
    sum("paul vallas") AS vallas,
    sum("brandon johnson") AS johnson,
    sum("lori e. lightfoot") AS lightfoot,
    sum([jesus "chuy" garcia]) AS garcia,
    sum(school_age_public) AS school_age_public,
    sum("willie l. wilson") as wilson,
    sum(total_cvap) AS total_cvap,
    sum(white_cvap) / sum(total_cvap) AS percent_white_cvap,
    sum(black_cvap) / sum(total_cvap) AS percent_black_cvap,
    sum(latino_cvap) / sum(total_cvap) AS percent_latino_cvap
FROM
    district_overlap
    INNER JOIN block_level_precinct USING (block_id)
    INNER JOIN block_level_tract USING (block_id)
WHERE
    row_num = 1
GROUP BY
    district_name;









