class-pool MESSAGE-ID S_LMCFG_CORE_TASKS.
*"* class pool for class CL_STCT_ADD_HTTP_ALLOWLIST_FLP

*"* local type definitions
include CL_STCT_ADD_HTTP_ALLOWLIST_FLPccdef.

*"* class CL_STCT_ADD_HTTP_ALLOWLIST_FLP definition
*"* public declarations
  include CL_STCT_ADD_HTTP_ALLOWLIST_FLPcu.
*"* protected declarations
  include CL_STCT_ADD_HTTP_ALLOWLIST_FLPco.
*"* private declarations
  include CL_STCT_ADD_HTTP_ALLOWLIST_FLPci.
endclass. "CL_STCT_ADD_HTTP_ALLOWLIST_FLP definition

*"* macro definitions
include CL_STCT_ADD_HTTP_ALLOWLIST_FLPccmac.
*"* local class implementation
include CL_STCT_ADD_HTTP_ALLOWLIST_FLPccimp.

*"* test class
include CL_STCT_ADD_HTTP_ALLOWLIST_FLPccau.

class CL_STCT_ADD_HTTP_ALLOWLIST_FLP implementation.
*"* method's implementations
  include methods.
endclass. "CL_STCT_ADD_HTTP_ALLOWLIST_FLP implementation
