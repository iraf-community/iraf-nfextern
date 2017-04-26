# SETBPM -- Set BPM and CELLMODE keywords.

procedure setbpm (exposures)

string	exposures		{prompt="ODI directories or OTA files"}
file	cellmode = "odidat$cellmode.dat"	{prompt="CELLMODE database"}
file	bpm = "odidat$bpm.dat"	{prompt="BPM database"}
bool	verbose = yes		{prompt="Show progress information"}

struct	*readexps, *readims, *readexts

begin
	int	i, j, k
	real	ltv1, ltv2
	file	explist, imlist, extlist, temp
	string	exps, exp, im, imext, fppos, extname, cmode
	string	c, line, str

	cache mscextensions

	temp = mktemp ("tmp$iraf")
	explist = temp // "1.tmp"
	imlist  = temp // "2.tmp"
	extlist = temp // "3.tmp"

	if (verbose)
	    printf ("SETBPM:\n")

	# Check input parameters.
	if (!access(cellmode) && !access(bpm))
	    error (1, "No cellmode or bpm database found")

	# Set input parameters.
	exps = exposures

	files (exps, > explist)
	readexps = explist
	while (fscan (readexps, exp) != EOF) {
	    # Determine if this is an image or directory.
	    if (imaccess (exp//"[0]"))
		print (exp, > imlist)
	    else
	        files (exp//"/*.fits", > imlist)

	    readims = imlist
	    while (fscan (readims, im) != EOF) {

	        # Print progress information.
		if (verbose)
		    printf ("  Update %s\n", im)

	    	# Set OTA identifier.
		fppos = ""
		hselect (im//"[0]", "FPPOS", yes) | scan (fppos)
		if (fppos == "") {
		    printf ("WARNING: FPPOS keyword not found (%s)\n", im)
		    next
		}

		# Set CELLMODE if defined.  Don't override non-science
		# indicators in the existing header.
		if (access (cellmode)) {
		    match (fppos, cellmode, stop-) | scan (str, str)
		    if (nscan() == 2) {
		        hselect (im//"[0]", "CELLMODE", yes) | scan (cmode)
			line = ""
			for (i=1; i<=64; i+=1) {
			    c = substr (cmode, i, i)
			    if (c != 'S')
			        line += c
			    else
			        line += substr (str, i, i)
			}
		        hedit (im//"[0]", "CELLMODE", line,
			    add+, show-, ver-, upd+)
		    }
		}

		# For each image add the BPM.
		if (access (bpm)) {

#		    # Fix extensions in simulated data.
#		    hselect (im//"[1]", "EXTNAME", yes) | scan (extname)
#		    if (extname == "xy00") {
#			mscextensions (im, output="file", index="0-",
#			    extname="", extver="", lindex=yes, lname=no,
#			    lver=no, ikparams="", > extlist)
#
#			readexts = extlist
#			while (fscan (readexts, imext) != EOF) {
#			    hselect (imext, "EXTNAME", yes) | scan (extname)
#			    if (fscanf (extname, "xy%1d%1d", i, j) != 2)
#				next
#			    j = 7 - j
#			    printf ("xy%1d%1d\n", i, j) | scan (extname)
#			    hedit (imext, "EXTNAME", extname,
#				add+, show-, ver-, upd+)
#			}
#		    }

		    # Expand extensions.
		    mscextensions (im, output="file", index="0-", extname="",
			extver="", lindex=no, lname=yes, lver=no, ikparams="",
			> extlist)

		    readexts = extlist
		    while (fscan (readexts, imext) != EOF) {
		        hselect (imext, "EXTNAME", yes) | scan (extname)
			match (fppos//extname, bpm, stop-) | scan (str, str)
			if (nscan() != 2)
			    next
			hedit (imext, "BPM", str, add+, show-, ver-, upd+)

#			# For simulated data.
#			hselect (str, "LTV1,LTV2,DETSEC", yes) |
#			    scan (ltv1, ltv2, str)
#			hedit (imext, "LTV1", ltv1, add+, show-, ver-, upd+)
#			hedit (imext, "LTV2", ltv2, add+, show-, ver-, upd+)
#			hedit (imext, "DETSEC", str, add+, show-, ver-, upd+)
		    }
		}
		readexts = ""; delete (extlist, verify=no)
	    }
	    readims = ""; delete (imlist, verify=no)
	}
	readexps = ""; delete (explist, verify=no)
end
