 method check_role_category_bup003.

   data:
     lt_bp_with_employee_role type bu_partner_t,

     lv_error_header          type string,
     lt_error_list            type salv_wd_t_string,
     lv_error_description     like line of lt_error_list.

   field-symbols:
     <partner>    type ty_partner_data.

   clear r_chk_results.
   check i_client is not initial.

*-------------------------------------------------------------------------------------
*--- Fetch all relevant partners with an employee role assigned
*-------------------------------------------------------------------------------------
   if partner_data is not initial.
     select distinct a~partner from but000 as a
         inner join but100 as b on a~partner = b~partner
         inner join tb003  as c on b~rltyp = c~role using client @i_client
         for all entries in @partner_data
           where a~partner = @partner_data-partner
            and c~rolecategory = 'BUP003'
           into table @lt_bp_with_employee_role.       "#EC CI_BUFFJOIN
   endif.

   sort lt_bp_with_employee_role.

*-------------------------------------------------------------------------------------
*--- Check if relevant BP001 entries have an employee role
*-------------------------------------------------------------------------------------
   loop at partner_data assigning <partner>.
     read table lt_bp_with_employee_role with key partner = <partner>-partner binary search transporting no fields.
     if sy-subrc <> 0.
       lv_error_header = _build_error_header( is_partner = <partner> ).
       concatenate lv_error_header 'has no employee role assigned'
                   into lv_error_description respecting blanks. "#EC NOTEXT

       append lv_error_description to lt_error_list.
     endif.
   endloop.
*-------------------------------------------------------------------------------------
*--- Return result list
*-------------------------------------------------------------------------------------
   r_chk_results = _build_error_list(
                     i_check_sub_id = 'FS-BP / BP001 / 3 / Employee Role missing' "#EC NOTEXT
                     i_error_list   = lt_error_list ).

 endmethod.