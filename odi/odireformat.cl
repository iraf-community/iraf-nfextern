# ODIREFORMAT -- Reformat an ODI exposure.

procedure odireformat (input, output)

file	input			{prompt="Input exposure"}
file	output			{prompt="Output OTA directory or file"}
string	outtype = "ota"		{prompt="Output type (ota|image|mef)",
				 enum="ota|image|mef"}
string	pattern = "*.fits"	{prompt="OTA selection pattern"}
string	adjust = "scale"	{prompt="Cell/OTA adjustment (none|zero|scale)",
				 enum="none|zero|scale"}
bool	override = yes		{prompt="Override previous output"}
bool	verbose = yes		{prompt="Verbose?"}


struct	*fd

begin
	bool	merged
	int	i, j, c1, c2, l1, l2, l1o, c1o
	file	in, in1, in2, out, out1, bpm, bpm1, fname, im, tmp
	string	zero, scale, detsec, extname, ota

	# Workaround.
	set use_new_imt = no

	# Get query parameters and define a temporary file root name.
	in = input
	out = output
	tmp = mktemp ("tmp") // "x"

	# Remove the path to the input.
	i = strldx ("$/", in)
	if (i > 0) {
	    in1 = substr(in, i+1, 999)
	    in2 = substr(in, 1, i-1)
	} else {
	    in1 = in
	    in2 = "."
	}

	# Check if the input is a directory or rootname.
	if (access(in) == no)
	    in = in2

	# Set output.
	if (out == "")
	    out = in1

	# Select exposure OTA files to use.
	if (pattern == "")
	    files (in//"/"//in1//"*.fits", > tmp//1)
	else
	    files (in//"/"//in1//pattern, > tmp//1)

	# Setup output.
	if (outtype == "ota" && access (out) == NO)
	    mkdir (out)
	else if (outtype != "ota" && imaccess (out) == YES && !override) {
	    printf ("WARNING: Output file exists (%s)\n", out)
	    return
	}

	# Set scaling adjustment if merging.
	if (adjust == "zero") {
	    zero = "mode"
	    scale = "none"
	} else if (adjust == "scale") {
	    zero = "none"
	    scale = "mode"
	} else {
	    zero = "none"
	    scale = "none"
	}

	fd = tmp//1; c1o = INDEF; l1o = INDEF
	for (i = 1; fscan (fd, fname) != EOF; i += 1) {

	    # Get the OTA.
	    hselect (fname//"[0]", "FPPOS", yes) | scan (extname)
	    j = fscanf (extname, "xy%1d%1d", c1, l1)
	    if (isindef(c1o) || isindef(l1o)) {
	        c1o= c1; l1o = l1
	    } else {
	        c1o = min (c1o, c1); l1o = min (l1o, l1)
	    }
	}
	fd = ""

	# Create images for each OTA.  It proved too slow to create
	# the output in one pass from all the extensions so we make
	# images for each OTA and then put the OTAs together.

	fd = tmp//1
	for (i = 1; fscan (fd, fname) != EOF; i += 1) {

	    # Get the OTA.
	    hselect (fname//"[0]", "FPPOS", yes) | scan (extname)
	    j = fscanf (extname, "xy%1d%1d", c1, l1)
	    printf ("%d%d\n", c1, l1) | scan (ota)
	    c1 -= c1o; l1 -= l1o 

	    # Set the extensions.
	    imextensions (fname, output="file", index="1-", extname="",
	        extver="", lindex+, lname-, lver-, ikparams="", > tmp//5)
	    if (imextensions.nimages > 0)
	        merged = NO
	    else
	        merged = YES

	    if (!merged) {
		hselect ("@"//tmp//5, "$I,DATASEC", yes) |
		    translit ("STDIN", "\t", delete+, > tmp//2)

		# Create merged OTA.
		if (outtype == "ota") {
		    im = out // "/" // out // "." // ota
		    if (verbose)
			printf ("Merge cells in OTA %s to %s\n", fname, im)
		} else {
		    im = tmp // "." // ota
		    if (verbose)
			printf ("Merge cells in OTA %s\n", fname)
		}
		imcombine ("@"//tmp//2, im, headers="", bpmasks="",
		    rejmasks="", nrejmasks="", expmasks="", sigmas="",
		    imcmb="", logfile="", combine="average",
		    reject="none", project=no, outtype="real", outlimits="",
		    offsets="physical", masktype="none", maskvalue="0",
		    blank=0., scale=scale, zero=zero, weight="none",
		    statsec="", expname="", lthreshold=INDEF, hthreshold=INDEF,
		    nlow=1, nhigh=1, nkeep=1, mclip=yes, lsigma=3., hsigma=3.,
		    rdnoise="0.", gain="1.", snoise="0.", sigscale=0.1,
		    pclip=-0.5, grow=0.)
		hedit (im, "NCOMBINE,*SEC", del+, ver-, show-, upd+)
		delete (tmp//2, verify-)
	    } else if (outtype == "ota") {
	        im = out // "/" // out // "." // ota
		if (verbose)
		    printf ("Copy OTA %s to %s\n", fname, im)
		if (override && imaccess(out))
		    imdelete (out, verify-)
		if (!imaccess(out))
		    imcopy (fname, out, verbose-)
	    } else {
	        im = fname
	    }
	    delete (tmp//5, verify-)

	    # Extract the OTA offset.
	    #hselect (fname[1], "CRPIX1,CRPIX2", yes) | scan (c1, l1)
	    #c1 = -c1; l1 = -l1
	    c1 = c1 * 4100 + 1; l1 = l1 * 4100 + 1

	    if (outtype == "image") {
		# Collect lists for creating full image.
		print (im, >> tmp//3)
		print (c1, l1, >> tmp//4)
	    } else {
		# Create DETSEC.
		hselect (im, "NAXIS1,NAXIS2", yes) | scan (c2, l2)
		c2 = c1 + c2 - 1; l2 = l1 + l2 - 1
		printf ("[%d:%d,%d:%d]\n", c1, c2, l1, l2) | scan (detsec)
		hedit (im, "DETSEC", detsec, add+, ver-, show-, upd+)

		# Create MEF if desired.
		if (outtype == "mef") {
		    if (override && imaccess(out) && i == 1)
			imdelete (out, verify-)
		    if (imaccess(out) && i == 1)
		        i -= 1
		    else {
			if (verbose)
			    printf ("Add OTA to MEF %s[%s]\n", out, extname)
			imcopy (im, out//"["//extname//",append]", ver-)
			bpm=""; hselect (im, "BPM", yes) | scan (bpm)
			if (bpm != "") {
			    if (!imaccess(bpm) && strldx("/",im)>0)
			        bpm = substr (im, 1, strldx("/",im)) // bpm
			    if (imaccess(bpm)) {
				bpm1 = out // "_bpm"
				if (verbose)
				    printf ("Add BPM to MEF %s[%s]\n",
					bpm1, extname)
				imcopy (bpm,
				    bpm1//"["//extname//",append,type=mask]",
				    ver-)
				if (strldx("/",bpm1) > 0)
				    bpm1 = substr (bpm1,strldx("/",bpm1)+1,999)
				out1 = out // "[" // extname // "]"
				bpm1 = bpm1 // "[" // extname // "]"
				hedit (out1, "BPM", bpm1,
				    add+, ver-, show-, upd+)
			    }
			}
		    }
		}
	    }
	}
	fd = ""; delete (tmp//1, verify-)

	# Create full image if desired.
	if (outtype == "image") {
	    if (verbose)
		printf ("Merging OTAs for %s to create %s\n", in, out)
	    if (override && imaccess(out))
	        imdelete (out, verify-)
	    if (!imaccess(out)) {
		imcombine ("@"//tmp//3, out, headers="", bpmasks="",
		    rejmasks="", nrejmasks="", expmasks="", sigmas="",
		    imcmb="", logfile="", combine="average",
		    reject="none", project=no, outtype="real", outlimits="",
		    offsets=tmp//4, masktype="none", maskvalue="0",
		    blank=0., scale=scale, zero=zero, weight="none",
		    statsec="", expname="", lthreshold=INDEF, hthreshold=INDEF,
		    nlow=1, nhigh=1, nkeep=1, mclip=yes, lsigma=3., hsigma=3.,
		    rdnoise="0.", gain="1.", snoise="0.", sigscale=0.1,
		    pclip=-0.5, grow=0.)
		hedit (out, "*SEC", del+, verify-, show-, update+)

		if (!merged)
		    imdelete ("@"//tmp//3, verify-)
	    }
	}

	# Clean up.
	delete (tmp//"*", verify-)
end
