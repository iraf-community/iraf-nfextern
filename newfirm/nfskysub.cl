# NFSKYSUB -- This is a wrapper on NFPROC that does only sky subtractions.

procedure nfskysub (input)

string	input = ""		{prompt="List of input images"}
string	output = "+_ss"		{prompt="List of output images"}
string	outtype = "image"	{prompt="Output type (image|list|<keyword>)"}
string	skies = ""		{prompt="List of skies (empty to use input)"}
string	skymatch = ""		{prompt="Match boolean expression"}
string	skymode = "nearest"	{prompt="Sky subtraction mode"}
string	stype = ""		{prompt="Sky selection expression (boolean)"}
string	obm = "(objmask)"	{prompt="Input mask or keyword reference"}
string	logfiles = "STDOUT,logfile"	{prompt="List of output logfiles"}

struct	*fd

begin
	string	otype, logs, temp, s1, s2, in, sky
	struct	s3

	# Set output.
	if (outtype=="image" || outtype=="list") {
	    otype = outtype
	    logs = logfiles
	} else {
	    otype = "list"
	    logs = mktemp ("tmp$iraf")
	}

	# Sky subtract or list the sky subtraction.
	# Note that we don't want to use the default "order" because of
	# the two pass specification.
	_nfproc (input, output, outtype=otype, logfiles=logs,
	    skysub=yes, order="S", obm=obm, skies=skies, skymatch=skymatch,
	    skymode=skymode, stype=stype, override+, taskname="nfsubsky")

	# Add header keyword if desired.
	if (outtype!="image" && outtype!="list") {
	    fd = logs
	    while (fscan (fd, s1, s2, s3) != EOF) {
		if (s1 == "$S") {
		    sky = s3
		    hedit (in, outtype, sky,
			add+, verify-, show+, update+)
		} else if (strstr ("subtraction", s3) > 0)
		    in = substr (s1, 1, strlen(s1)-1)
	    }
	    fd = ""; delete (logs)
	}
end
