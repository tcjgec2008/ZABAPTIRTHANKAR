class-pool MESSAGE-ID S_LMCFG_CORE_TASKS.
*"* class pool for class CL_STCT_FLP_PLG_ACT_CAI

*"* local type definitions
include CL_STCT_FLP_PLG_ACT_CAI=======ccdef.

*"* class CL_STCT_FLP_PLG_ACT_CAI definition
*"* public declarations
  include CL_STCT_FLP_PLG_ACT_CAI=======cu.
*"* protected declarations
  include CL_STCT_FLP_PLG_ACT_CAI=======co.
*"* private declarations
  include CL_STCT_FLP_PLG_ACT_CAI=======ci.
endclass. "CL_STCT_FLP_PLG_ACT_CAI definition

*"* macro definitions
include CL_STCT_FLP_PLG_ACT_CAI=======ccmac.
*"* local class implementation
include CL_STCT_FLP_PLG_ACT_CAI=======ccimp.

*"* test class
include CL_STCT_FLP_PLG_ACT_CAI=======ccau.

class CL_STCT_FLP_PLG_ACT_CAI implementation.
*"* method's implementations
  include methods.
endclass. "CL_STCT_FLP_PLG_ACT_CAI implementation
