METHOD fill_item.

  DATA lo_cx_gdt_conversion               TYPE REF TO cx_gdt_conversion.
  DATA lt_message_log                     TYPE bapirettab.
  DATA ls_message                         TYPE bapiret2.
  DATA lv_kzsysfe(60)                     TYPE c VALUE 'KZSYSFE'.
  DATA ls_qn_item                         TYPE rfc_viqmfe.
  DATA ls_item_cause                      TYPE rfc_viqmur.
  DATA ls_item_task                       TYPE rfc_viqmsm.
  DATA ls_item_act                        TYPE rfc_viqmma.
  DATA lt_notif_longtext                  TYPE tt_rfctline.
  DATA lv_langu                           TYPE sy-langu.
  DATA ls_item                            TYPE arbcig_qltyiss_notif_itm.

  CONSTANTS: lc_qmfe                      TYPE swo_objtyp VALUE 'QMFE',
             lc_msg_qqm_ea                TYPE c LENGTH 20 VALUE 'QQM_EA'.

  FIELD-SYMBOLS: <ls_input_item_cause>    TYPE arbcig_qltyiss_notif_itm_cause,
                 <kzsysfe>                TYPE ANY.

  LOOP AT i_item INTO ls_item.
    CLEAR ls_qn_item. " SAP Note 2939603
*   MaterialInternalID
    IF NOT ls_item-material_internal_id-content IS INITIAL AND gv_enb_masd_ext_format EQ 'X'. "Defect fix 4676.
      CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
        EXPORTING
          input        = ls_item-material_internal_id-content
        IMPORTING
          output       = ls_qn_item-bautl
        EXCEPTIONS
          length_error = 1
          OTHERS       = 2.
      IF sy-subrc <> 0.
        ls_message-type = sy-msgty.
        ls_message-id   = sy-msgid.
        ls_message-number = sy-msgno.
        ls_message-message_v1 = sy-msgv1.
        ls_message-message_v2 = sy-msgv2.
        ls_message-message_v3 = sy-msgv3.
        ls_message-message_v4 = sy-msgv4.
        APPEND ls_message TO c_message.
        CLEAR ls_message.
        EXIT.
      ENDIF.
    ELSE.
      ls_qn_item-bautl = ls_item-material_internal_id-content.
    ENDIF.

*   MaterialInspectionSampleID
    IF NOT ls_item-material_inspection_sample_id-content IS INITIAL AND gv_enb_masd_ext_format EQ 'X'. "Defect fix 4676.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = ls_item-material_inspection_sample_id-content
        IMPORTING
          output = ls_qn_item-phynr.
    ELSE.
      ls_qn_item-phynr = ls_item-material_inspection_sample_id-content.
    ENDIF.

*   DefectTypeQualityIssueCatalogue
    MOVE ls_item-defect_typ_qltyiss_catgry_id-content TO ls_qn_item-fecod.
    MOVE ls_item-defect_typ_parent_qltyiss_cat-content TO ls_qn_item-fegrp.
    MOVE ls_item-defect_typ_qltyiss_catclg_id-content TO ls_qn_item-fekat.

*   DefectLocationQualityIssueCatalogue
    MOVE ls_item-defect_loc_qltyiss_catclg_id-content TO ls_qn_item-otkat.
    MOVE ls_item-defect_loc_parent_qltyiss_cat-content TO ls_qn_item-otgrp.
    MOVE ls_item-defect_loc_qltyiss_catgry_id-content TO ls_qn_item-oteil.

*   DefectNumberValue
    MOVE ls_item-defect_number_value TO ls_qn_item-anzfehler.

*   DefectClassCode (extendable code list -> no mapping)
    MOVE ls_item-defect_class_code-content TO ls_qn_item-feqklas.

*   DefectWeightingClassCode
    MOVE ls_item-defect_weighting_class_code-content TO ls_qn_item-fehlbew.

*   Internal- & ExternalNonconformingQuantity
    MOVE ls_item-external_nonconforming_qunty-content TO ls_qn_item-fmgfrd.
    MOVE ls_item-internal_nonconforming_qunty-content TO ls_qn_item-fmgeig.

*   OrdinalNumberValue
    MOVE ls_item-ordinal_number_value TO ls_qn_item-posnr.

*   Description
    MOVE ls_item-description-content TO ls_qn_item-fetxt.
*   Populate Language code as well
    IF ls_item-description-content IS NOT INITIAL.
      TRY.
          CALL METHOD cl_gdt_conversion=>language_code_inbound
            EXPORTING
              im_value = ls_item-description-language_code
            IMPORTING
              ex_value = ls_qn_item-kzmla.
        CATCH cx_gdt_conversion INTO lo_cx_gdt_conversion.
          CALL FUNCTION 'BALW_BAPIRETURN_GET2'
            EXPORTING
              type   = lo_cx_gdt_conversion->message-type
              cl     = lo_cx_gdt_conversion->message-id
              number = lo_cx_gdt_conversion->message-number
              par1   = lo_cx_gdt_conversion->message-message_v1
            IMPORTING
              return = ls_message.
          APPEND ls_message TO c_message.
          CLEAR: ls_message.
      ENDTRY.
    ENDIF.
*   DetailedText
    IF NOT ls_item-detailed_text-content IS INITIAL.
      CALL METHOD cl_gdt_conversion=>language_code_inbound
        EXPORTING
          im_value = ls_item-detailed_text-language_code
        IMPORTING
          ex_value = lv_langu.

      CALL METHOD me->fill_longtexts
        EXPORTING
          i_text        = ls_item-detailed_text
          i_object      = lc_qmfe
          i_langu       = lv_langu
          i_objkey      = ls_qn_item-posnr
          i_action_code = gv_operation
        IMPORTING
          e_text_exists = ls_qn_item-indtx
        CHANGING
          c_messages    = c_message
          c_tline       = t_longtexts.

    ENDIF.

*   SystematicIndicator
    ASSIGN COMPONENT lv_kzsysfe OF STRUCTURE ls_qn_item TO <kzsysfe>.
    IF sy-subrc = 0.
      IF ls_item-systematic_indicator IS NOT INITIAL.
        TRY.
            CALL METHOD cl_gdt_conversion=>indicator_inbound
              EXPORTING
                im_value = ls_item-systematic_indicator
              IMPORTING
                ex_value = <kzsysfe>.
          CATCH cx_gdt_conversion INTO lo_cx_gdt_conversion.
            CALL FUNCTION 'BALW_BAPIRETURN_GET2'
              EXPORTING
                type   = lo_cx_gdt_conversion->message-type
                cl     = lo_cx_gdt_conversion->message-id
                number = lo_cx_gdt_conversion->message-number
                par1   = lo_cx_gdt_conversion->message-message_v1
                par2   = lo_cx_gdt_conversion->message-message_v2
                par3   = lo_cx_gdt_conversion->message-message_v3
                par4   = lo_cx_gdt_conversion->message-message_v4
              IMPORTING
                return = ls_message.
            APPEND ls_message TO c_message.
            CLEAR: ls_message.
        ENDTRY.
      ENDIF.
    ENDIF.

    APPEND ls_qn_item TO e_qin_item.

*** ItemCause ***
    LOOP AT ls_item-cause ASSIGNING <ls_input_item_cause>.
      CLEAR: ls_item_cause, lt_notif_longtext, lt_message_log.

*      TRY.
      CALL METHOD me->fill_cause
        EXPORTING
          is_cause      = <ls_input_item_cause>
          i_posnr       = ls_qn_item-posnr
        IMPORTING
          e_qin_cause   = ls_item_cause
*          e_notif_ltext =
        CHANGING
          c_message     = c_message
          .
*       CATCH ARBCIG_cx_standard_message_fau6 .
*      ENDTRY.

      APPEND ls_item_cause TO e_qin_item_cause.
      APPEND LINES OF lt_notif_longtext TO e_notif_ltext.

    ENDLOOP.

  ENDLOOP.

ENDMETHOD.