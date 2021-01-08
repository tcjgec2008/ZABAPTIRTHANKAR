CLASS zcl_mon_mach2 DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
  methods get_amount_in_coins
  importing i_amount         type i
  returning value(r_value)   type i.
  methods get_amount_in_notes
  importing i_amount type i
  returning value(r_notes_amount) type i.
