class-pool .
*"* class pool for class ZCL_MON_MACH

*"* local type definitions
include ZCL_MON_MACH==================ccdef.

*"* class ZCL_MON_MACH definition
*"* public declarations
  include ZCL_MON_MACH==================cu.
*"* protected declarations
  include ZCL_MON_MACH==================co.
*"* private declarations
  include ZCL_MON_MACH==================ci.
endclass. "ZCL_MON_MACH definition

*"* macro definitions
include ZCL_MON_MACH==================ccmac.
*"* local class implementation
include ZCL_MON_MACH==================ccimp.

*"* test class
include ZCL_MON_MACH==================ccau.

class ZCL_MON_MACH implementation.
*"* method's implementations
  include methods.
endclass. "ZCL_MON_MACH implementation
