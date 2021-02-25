class-pool MESSAGE-ID S_LMCFG_CORE_TASKS.
*"* class pool for class CL_STCT_FLP_PLG_DEF_CAI

*"* local type definitions
include CL_STCT_FLP_PLG_DEF_CAI=======ccdef.

*"* class CL_STCT_FLP_PLG_DEF_CAI definition
*"* public declarations
  include CL_STCT_FLP_PLG_DEF_CAI=======cu.
*"* protected declarations
  include CL_STCT_FLP_PLG_DEF_CAI=======co.
*"* private declarations
  include CL_STCT_FLP_PLG_DEF_CAI=======ci.
endclass. "CL_STCT_FLP_PLG_DEF_CAI definition

*"* macro definitions
include CL_STCT_FLP_PLG_DEF_CAI=======ccmac.
*"* local class implementation
include CL_STCT_FLP_PLG_DEF_CAI=======ccimp.

*"* test class
include CL_STCT_FLP_PLG_DEF_CAI=======ccau.

class CL_STCT_FLP_PLG_DEF_CAI implementation.
*"* method's implementations
  include methods.
endclass. "CL_STCT_FLP_PLG_DEF_CAI implementation
