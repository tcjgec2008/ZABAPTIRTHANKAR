class-pool MESSAGE-ID S_LMCFG_CORE_TASKS.
*"* class pool for class CL_STCT_ACTIVATE_SICF_SB_APPS

*"* local type definitions
include CL_STCT_ACTIVATE_SICF_SB_APPS=ccdef.

*"* class CL_STCT_ACTIVATE_SICF_SB_APPS definition
*"* public declarations
  include CL_STCT_ACTIVATE_SICF_SB_APPS=cu.
*"* protected declarations
  include CL_STCT_ACTIVATE_SICF_SB_APPS=co.
*"* private declarations
  include CL_STCT_ACTIVATE_SICF_SB_APPS=ci.
endclass. "CL_STCT_ACTIVATE_SICF_SB_APPS definition

*"* macro definitions
include CL_STCT_ACTIVATE_SICF_SB_APPS=ccmac.
*"* local class implementation
include CL_STCT_ACTIVATE_SICF_SB_APPS=ccimp.

*"* test class
include CL_STCT_ACTIVATE_SICF_SB_APPS=ccau.

class CL_STCT_ACTIVATE_SICF_SB_APPS implementation.
*"* method's implementations
  include methods.
endclass. "CL_STCT_ACTIVATE_SICF_SB_APPS implementation
