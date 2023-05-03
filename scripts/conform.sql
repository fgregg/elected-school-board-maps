WITH btp AS (
    SELECT
        tract.ogc_fid AS tract_id,
        block.ogc_fid AS block_id,
        p1_001n * (ST_Area (ST_Intersection (block.geometry, tract.geometry)) / ST_Area (block.geometry)) AS block_tract_pop
    FROM
        blocks_2020 AS block
        INNER JOIN public_school AS tract ON ST_Intersects (block.geometry, tract.geometry)
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
        btp
    GROUP BY
        tract_id
)
SELECT
    block_id,
    p1_001n,
    sum(school_age_public * (block_tract_pop / tract_pop)) AS school_age_public,
    block.geometry
FROM
    btp
    INNER JOIN tract_pop USING (tract_id)
    INNER JOIN blocks_2020 AS block ON block_id = block.ogc_fid
    INNER JOIN public_school AS tract ON tract_id = tract.ogc_fid
GROUP BY
    block_id;


