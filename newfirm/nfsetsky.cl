# NFSETSKY -- This is a wrapper on NFPROC that does the sky assignments.

procedure nfsetsky (input)

string	input = ""		{prompt="List of input images"}
string	skies = ""		{prompt="List of skies (empty to use input)"}
string	skymatch = ""		{prompt="Match boolean expression"}
string	skymode = "nearest"	{prompt="Sky subtraction mode"}
string	stype = ""		{prompt="Sky selection expression (boolean)"}
bool	update = yes		{prompt="Update header?"}
string	keyword = "SKY"		{prompt="Keyword for assignment"}

struct	*fd

begin
	string	temp, s1, s2, s3, in, sky, key

	temp = mktemp ("tmp$iraf")
	nfproc (input, output="+LIST", skies=skies, logfiles=temp,
	    skysub=yes, order="S", skymatch=skymatch, skymode=skymode,
	    bpm="", fixpix=no, obm="",
	    intype="", dtype="", ftype="", gtype="", stype=stype,
	    imageid="(imageid)", filter="(filter)", sortval="(@'mjd-obs')",
	    exptime="(exptime)", exprdb="", override=yes, copy=yes,
	    erraction="warn", taskname="nfsetsky")

	fd = temp
	if (update) {
	    while (fscan (fd, s1, s2, s3) != EOF) {
		if (s1 == "$S") {
		    sky = s3
		    hedit (in, keyword, sky,
		        add+, verify-, show+, update=update)
		} else if (s3 == "subtraction")
		    in = substr (s1, 1, strlen(s1)-1)
	    }
	} else {
	    while (fscan (fd, s1, s2, s3) != EOF) {
		if (s1 == "$S") {
		    sky = s3
		    printf ("%s\n", sky)
		} else if (s3 == "subtraction") {
		    in = substr (s1, 1, strlen(s1)-1)
		    #printf ("%s ", in)
		}
	    }
	}
	fd = ""; delete (temp)
end
