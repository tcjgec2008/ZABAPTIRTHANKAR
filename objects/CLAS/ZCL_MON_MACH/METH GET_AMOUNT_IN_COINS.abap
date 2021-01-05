        method get_amount_in_coins.
        r_value = cond #( when i_amount <= 0
                          then -1
                          else i_amount mod 5 ).

        endmethod.