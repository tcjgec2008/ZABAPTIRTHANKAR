private section.

  types:
    begin of ty_partner_data,
      partner       type bu_partner,
      partner_sobid type sobid,
      guid          type bu_partner_guid,
      guid_text     type c length 32,
      type          type bu_type,
      pers_nr       type bp_pers_nr,
      pers_nr_text  type c length 15,
      pers_nr_numc8 type n length 8,
      xubname       type bp_xubname,
      xubname_text  type c length 12,
    end of ty_partner_data .
  types:
    ty_partner_data_t type standard table of ty_partner_data .
  types:
    ty_pa0105_t type standard table of pa0105 .

  class-data PARTNER_DATA type TY_PARTNER_DATA_T .

  class-methods _BUILD_ERROR_HEADER
    importing
      !IS_PARTNER type TY_PARTNER_DATA
    returning
      value(R_ERROR_HEADER) type STRING .
  class-methods _BUILD_RESULT_TABLE
    importing
      !I_CLIENT type MANDT
      !IT_RUNTIME_PARAMETER type TIHTTPNVP
    changing
      !C_CHK_RESULT_TAB type TY_PRE_CONS_CHK_RESULT_TAB .
  class-methods _INITIALIZE
    importing
      !I_CLIENT type MANDT .
  class-methods _BUILD_ERROR_LIST
    importing
      !I_CHECK_SUB_ID type CHAR80
      !I_ERROR_LIST type SALV_WD_T_STRING
    returning
      value(R_CHK_RESULTS) type TY_PRE_CONS_CHK_RESULT_TAB_INT .
  class-methods CHECK_BP001_BUT000_CONSISTENCY
    returning
      value(R_CHK_RESULTS) type TY_PRE_CONS_CHK_RESULT_TAB_INT .
  class-methods CHECK_CONSISTENCY_HR_OFF
    importing
      !I_CLIENT type MANDT
    returning
      value(R_CHK_RESULTS) type TY_PRE_CONS_CHK_RESULT_TAB_INT .
  class-methods CHECK_CONSISTENCY_HR_ON
    importing
      !I_CLIENT type MANDT
    returning
      value(R_CHK_RESULTS) type TY_PRE_CONS_CHK_RESULT_TAB_INT .
  class-methods CHECK_BP001_DUPLICATES
    returning
      value(R_CHK_RESULTS) type TY_PRE_CONS_CHK_RESULT_TAB_INT .
  class-methods CHECK_BP_CATEGORY_PERSON
    returning
      value(R_CHK_RESULTS) type TY_PRE_CONS_CHK_RESULT_TAB_INT.
  class-methods CHECK_ROLE_CATEGORY_BUP003
    importing
      !I_CLIENT type MANDT
    returning
      value(R_CHK_RESULTS) type TY_PRE_CONS_CHK_RESULT_TAB_INT.
  class-methods CHECK_USR21_GUID
    importing
      !I_CLIENT type MANDT
    returning
      value(R_CHK_RESULTS) type TY_PRE_CONS_CHK_RESULT_TAB_INT .
  class-methods _IS_HR_ACTIVE
    importing
      !I_CLIENT type MANDT
    returning
      value(E_HR_ACTIVE) type BOOLE_D .
  class-methods _GET_HR_PLVAR
    importing
      !I_CLIENT type MANDT
    returning
      value(E_PLAN_VERSION) type GSVAL .
  class-methods _VALIDATE_HR_OFF_PARTNERID
    importing
      !IS_PARTNER type TY_PARTNER_DATA
      !IT_BP_TO_CP type HRP1001_T
      !IT_CP_TO_USER type HRP1001_T
    returning
      value(R_ERROR_LIST) type SALV_WD_T_STRING .
  class-methods _VALIDATE_HR_OFF_XUBNAME
    importing
      !IS_PARTNER type TY_PARTNER_DATA
      !IT_USER_TO_CP type HRP1001_T
      !IT_CP_TO_BP type HRP1001_T
    returning
      value(R_ERROR_LIST) type SALV_WD_T_STRING .
  class-methods _VALIDATE_HR_ON_PARTNERID
    importing
      !IS_PARTNER type TY_PARTNER_DATA
      !IT_BP_TO_CP type HRP1001_T
      !IT_CP_TO_PERSEMPL type HRP1001_T
      !IT_PA0105 type TY_PA0105_T
    returning
      value(R_ERROR_LIST) type SALV_WD_T_STRING .
  class-methods _VALIDATE_HR_ON_PERSNR
    importing
      !IS_PARTNER type TY_PARTNER_DATA
      !IT_PERSEMPL_TO_CP type HRP1001_T
      !IT_CP_TO_BP type HRP1001_T
      !IT_PA0105 type TY_PA0105_T
    returning
      value(R_ERROR_LIST) type SALV_WD_T_STRING .
  class-methods _VALIDATE_HR_ON_PERSNR_LENGTH
    importing
      !IS_PARTNER type TY_PARTNER_DATA
    returning
      value(E_ERROR_DESCRIPTION) type STRING .
  class-methods _VALIDATE_HR_ON_XUBNAME
    importing
      !IS_PARTNER type TY_PARTNER_DATA
      !IT_PERSEMPL_TO_CP type HRP1001_T
      !IT_CP_TO_BP type HRP1001_T
      !IT_PA0105 type TY_PA0105_T
    returning
      value(R_ERROR_LIST) type SALV_WD_T_STRING .