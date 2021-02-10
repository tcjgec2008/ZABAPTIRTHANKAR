*&---------------------------------------------------------------------*
*& Report zdevops5_repo
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zdevops5_repo.

DATA: lv_vbeln TYPE vbeln_va VALUE '0000000001',
      ty_int   TYPE i.


SELECT sales_i~* FROM vbak AS sales_h
  INNER JOIN vbap AS sales_i
  ON sales_h~vbeln = sales_i~vbeln
  WHERE sales_h~vbeln = @lv_vbeln
  INTO TABLE @DATA(lt_data).

*Code Changes Starting from
LOOP AT lt_data INTO DATA(ty_ls).                    "select * code commented, Bug fixed                         "vbeln, posnr, matnr
  SELECT * FROM vbap INTO @data(ls_data) WHERE vbeln = '0000000001'.
  ENDSELECT.
ENDLOOP.

LOOP AT lt_data INTO DATA(ty_ls1).
  SELECT * FROM vbap INTO TABLE @lt_data WHERE vbeln = '0000000001'.

ENDLOOP.

cl_demo_output=>display( lt_data ).