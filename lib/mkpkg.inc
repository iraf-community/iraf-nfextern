# Global MKPKG definitions for the package.

$set XFLAGS	= "$(XFLAGS) -p nfextern"
$set XVFLAGS	= "$(XVFLAGS) -p nfextern"
$set LFLAGS	= "$(LFLAGS) -p nfextern"

# Needed for TABLES used in ACE.

$ifeq (HOSTID, vms) then
$set FITSIO_HOST_DEP = "vms"
$else
$set FITSIO_HOST_DEP = "unix"
$endif
