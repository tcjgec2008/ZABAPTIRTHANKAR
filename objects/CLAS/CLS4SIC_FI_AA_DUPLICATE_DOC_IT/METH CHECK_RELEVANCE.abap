  METHOD check_relevance.
*--------------------------------------------------------------------*
* Method for checking relevance.
* Return option apply from the structure c_pre_chk_relevance
* -yes    Use if item is relevant - consistency method will be called
* -no     Use if item is not relevant - consistency method will not be called,
*                                     - SUM will continue with next item
* -space  Use if you leave the method empty - consistency method will be called (default)
*--------------------------------------------------------------------*
* PRECONDITION
    "None

* DEFINITIONS
    "None

* BODY
    "None

*  ev_relevance = c_pre_chk_relevance-yes/no/space.
*  ev_description = 'Provide text here.'.

* POSTCONDITION
    "None

  ENDMETHOD.