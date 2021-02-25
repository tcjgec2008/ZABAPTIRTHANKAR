  METHOD _get_clients_to_be_checked.
*    This method sets the individual clients that should be check
*    depending on the execution client.
*      a) perform checks over all clients existing in the customer system
*      b) perform checks just in a specific client
*--------------------------------------------------------------------*
* PRECONDITION
    REFRESH et_t000.

* DEFINITIONS
* None

* BODY
    SELECT mandt mtext FROM t000 INTO CORRESPONDING FIELDS OF TABLE et_t000.

* POSTCONDITION
* None

  ENDMETHOD.