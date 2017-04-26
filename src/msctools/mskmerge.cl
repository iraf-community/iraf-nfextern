# MSKMERGE -- Merge masks.

procdure mskmerge (input, output)

string	input			{prompt="List of masks to merge"}
string	output			{prompt="Output mask"}
string	method = "map"		{prompt="Merging method",
				enum="map|min|max|add"}
string	mapto = "1,2,3,4,5,6"	{prompt="Mapping values"}

begin
	cache	sections, aimexpr

	# Get query parameters.
	in = input
	out = output
	mthd = method
	m2 = mapto

	# Temporary files.
	tmp = mktemp ("tmp$iraf")

	# Expand input lists.
	sections (in, option="fullname", > tmp//"1.tmp")
	sections (m2, option="fullname", > tmp//"2.tmp")
	n = sections.nimages
	if (n < 1)
	    error (1, "No input images")

	# Create the merging expression.
	expr = "msk"//mthd
	if (mthd == "map") {
	} else {
	    fd = temp//"1.tmp"; i = 0
	    if (i<nfscan(fd,im)!=EOF) {
	        expr += "($A,n"
		aimexpr.A = im
	        
	    for (i=1; fscan(fd,im)!=EOF; i+=1) {
	        op = substr(ops,i,i)
	        if (i == 1)
		    expr += "($" // op
		else
		    expr += "," // im
		aimexpr.
	    }
	    fd = ""; delete (temp//"1.tmp")
	        

	expr += "("

	if (mthd
	sections (in, option="fullname", > temp//"1.tmp")
