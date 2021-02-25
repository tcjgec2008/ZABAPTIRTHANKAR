class-pool MESSAGE-ID S_LMCFG_CORE_TASKS.
*"* class pool for class CL_STCT_SET_SYSALIAS_CLASSICUI

*"* local type definitions
include CL_STCT_SET_SYSALIAS_CLASSICUIccdef.

*"* class CL_STCT_SET_SYSALIAS_CLASSICUI definition
*"* public declarations
  include CL_STCT_SET_SYSALIAS_CLASSICUIcu.
*"* protected declarations
  include CL_STCT_SET_SYSALIAS_CLASSICUIco.
*"* private declarations
  include CL_STCT_SET_SYSALIAS_CLASSICUIci.
endclass. "CL_STCT_SET_SYSALIAS_CLASSICUI definition

*"* macro definitions
include CL_STCT_SET_SYSALIAS_CLASSICUIccmac.
*"* local class implementation
include CL_STCT_SET_SYSALIAS_CLASSICUIccimp.

*"* test class
include CL_STCT_SET_SYSALIAS_CLASSICUIccau.

class CL_STCT_SET_SYSALIAS_CLASSICUI implementation.
*"* method's implementations
  include methods.
endclass. "CL_STCT_SET_SYSALIAS_CLASSICUI implementation
