  METHOD has_duplicates.

    rv_has_duplicates = abap_false.

    SELECT SINGLE @abap_true
      FROM inob AS i1 INNER JOIN inob AS i2
        ON i1~klart = i2~klart
       AND i1~obtab = i2~obtab
       AND i1~objek = i2~objek
       AND i1~cuobj <> i2~cuobj
      USING ALL CLIENTS
      INTO @rv_has_duplicates.

  ENDMETHOD.