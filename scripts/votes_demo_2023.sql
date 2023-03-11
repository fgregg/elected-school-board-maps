.header on
.mode csv

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
    count(*) filter (where cvap.type = 'total') as total,
    count(*) filter (where cvap.type = 'asian') as asian,
    count(*) filter (where cvap.type = 'black') as black,
    count(*) filter (where cvap.type = 'white') as white,
    count(*) filter (where cvap.type = 'hispanic') as hispanic    
FROM
    municipal_general_2023
    INNER JOIN cvap ON st_intersects (municipal_general_2023.geometry, cvap.geometry)
        AND municipal_general_2023.ROWID IN (
            SELECT
                ROWID
            FROM
                SpatialIndex
        WHERE
            f_table_name = 'municipal_general_2023'
            AND search_frame = cvap.geometry)
group by ward, precinct;

