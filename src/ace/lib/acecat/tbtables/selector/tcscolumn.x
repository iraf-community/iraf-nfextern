# Copyright restrictions apply - see tables$copyright.tables 
# 
include "tcs.h"

# TCS_COLUMN -- Get column pointer from column selector

pointer procedure tcs_column (descrip)

pointer	descrip		# i: column descriptor
#--

begin
	return (TCS_COLUMN(descrip))
end
