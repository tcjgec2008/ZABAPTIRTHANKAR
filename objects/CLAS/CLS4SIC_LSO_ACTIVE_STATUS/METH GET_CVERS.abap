  method GET_CVERS.
     SELECT SINGLE * FROM cvers INTO es_cvers WHERE component = 'LSOFE'.
  endmethod.