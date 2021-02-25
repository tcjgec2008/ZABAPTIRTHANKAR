class-pool MESSAGE-ID S_LMCFG_CORE_TASKS.
*"* class pool for class CL_STCT_ACTIVATE_BR_ODATA_V4

*"* local type definitions
include CL_STCT_ACTIVATE_BR_ODATA_V4==ccdef.

*"* class CL_STCT_ACTIVATE_BR_ODATA_V4 definition
*"* public declarations
  include CL_STCT_ACTIVATE_BR_ODATA_V4==cu.
*"* protected declarations
  include CL_STCT_ACTIVATE_BR_ODATA_V4==co.
*"* private declarations
  include CL_STCT_ACTIVATE_BR_ODATA_V4==ci.
endclass. "CL_STCT_ACTIVATE_BR_ODATA_V4 definition

*"* macro definitions
include CL_STCT_ACTIVATE_BR_ODATA_V4==ccmac.
*"* local class implementation
include CL_STCT_ACTIVATE_BR_ODATA_V4==ccimp.

*"* test class
include CL_STCT_ACTIVATE_BR_ODATA_V4==ccau.

class CL_STCT_ACTIVATE_BR_ODATA_V4 implementation.
*"* method's implementations
  include methods.
endclass. "CL_STCT_ACTIVATE_BR_ODATA_V4 implementation
