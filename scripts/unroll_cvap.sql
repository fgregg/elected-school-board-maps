CREATE TABLE cvap AS
SELECT
    'total' as type,
    geometry
FROM
    ElementaryGeometries
WHERE
    f_table_name = 'points_cvap_total'
    AND origin_rowid = 1;

INSERT INTO cvap
SELECT
    'black',
    geometry
FROM
    elementarygeometries
WHERE
    f_table_name = 'points_cvap_black'
    AND origin_rowid = 1;

INSERT INTO cvap
SELECT
    'asian',
    geometry
FROM
    elementarygeometries
WHERE
    f_table_name = 'points_cvap_asian'
    AND origin_rowid = 1;

INSERT INTO cvap
SELECT
    'white',
    geometry
FROM
    elementarygeometries
WHERE
    f_table_name = 'points_cvap_white'
    AND origin_rowid = 1;

INSERT INTO cvap
SELECT
    'hispanic',
    geometry
FROM
    elementarygeometries
WHERE
    f_table_name = 'points_cvap_hispanic'
    AND origin_rowid = 1;

SELECT
    RecoverGeometryColumn ('cvap', 'geometry', 4326, 'POINT', 'XY');

SELECT
    CreateSpatialIndex ('cvap', 'geometry');


DROP table points_cvap_total;
DROP table points_cvap_black;
DROP table points_cvap_asian;
DROP table points_cvap_white;
DROP table points_cvap_hispanic;
