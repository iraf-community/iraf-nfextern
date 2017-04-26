# IRSETSKY -- This is a wrapper on IRPROC that does the sky assignments.

procedure irsetsky (input)

string	input = ""		{prompt="List of input images"}
string	skies = ""		{prompt="List of skies (empty to use input)"}
string	skymatch = ""		{prompt="Match boolean expression"}
string	skymode = "nearest"	{prompt="Sky subtraction mode"}
bool	update = yes		{prompt="Update header?"}
string	keyword = "SKY"		{prompt="Keyword for assignment"}

struct	*fd

begin
	string	temp, s1, s2, s3, in, sky, key

	temp = mktemp ("tmp$iraf")
	irproc (input, "+LIST+", skies=skies, logfiles=temp,
	    skymatch=skymatch, skymode=skymode, inmask=inmask,
	    outmasks="", biascor=no, darkcor=no, lincor=no, satcor=no,
	    flatcor=no, skysub=yes, fixpix=no, trim=no, normalize=no,
	    order="S", intype="", stype="", dtype="", ftype="",
	    override=yes, copy=yes, erraction="warn")

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
