  METHOD get_duplicates.

    SELECT DISTINCT i1~mandt, i1~klart, i1~obtab, i1~objek
      FROM inob AS i1 INNER JOIN inob AS i2
        ON i1~klart = i2~klart
       AND i1~obtab = i2~obtab
       AND i1~objek = i2~objek
       AND i1~cuobj <> i2~cuobj
      USING ALL CLIENTS
      ORDER BY i1~mandt, i1~klart, i1~obtab, i1~objek
      INTO TABLE @et_duplicates.

  ENDMETHOD.