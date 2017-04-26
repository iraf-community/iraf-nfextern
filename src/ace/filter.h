# FILTER definitions

define  FLT_STRLEN      199                     # Length of strings
define  FLT_NUMLEN      39                      # Length of strings
define  FLT_LEN         121                     # Parameters structure length

define  FLT_FILTER      Memc[P2C($1)]           # Filter string
define  FLT_NUM         Memc[P2C($1+100)]       # Catalog field with OM ID
define  FLT_UPDATE      Memi[$1+120]            # Update image header
