class-pool MESSAGE-ID S_LMCFG_CORE_TASKS.
*"* class pool for class CL_STCT_CREATE_SYSALIAS_S4FIN

*"* local type definitions
include CL_STCT_CREATE_SYSALIAS_S4FIN=ccdef.

*"* class CL_STCT_CREATE_SYSALIAS_S4FIN definition
*"* public declarations
  include CL_STCT_CREATE_SYSALIAS_S4FIN=cu.
*"* protected declarations
  include CL_STCT_CREATE_SYSALIAS_S4FIN=co.
*"* private declarations
  include CL_STCT_CREATE_SYSALIAS_S4FIN=ci.
endclass. "CL_STCT_CREATE_SYSALIAS_S4FIN definition

*"* macro definitions
include CL_STCT_CREATE_SYSALIAS_S4FIN=ccmac.
*"* local class implementation
include CL_STCT_CREATE_SYSALIAS_S4FIN=ccimp.

class CL_STCT_CREATE_SYSALIAS_S4FIN implementation.
*"* method's implementations
  include methods.
endclass. "CL_STCT_CREATE_SYSALIAS_S4FIN implementation
