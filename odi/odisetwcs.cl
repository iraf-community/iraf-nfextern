# ODISETWCS -- Set the WCS from a database and RA/Dec header keywords or values.
#
# If no database is specified (a value of "") then only the CRVAL are updated.

procedure odisetwcs (exposures)

string	exposures		{prompt="ODI directories or OTA files"}
file	database = "odidat$wcs120817_g.dat"	{prompt="WCS database"}
string	ra = "ra"		{prompt="Right ascension keyword/value (hours)"}
string	dec = "dec"		{prompt="Declination keyword/value (degrees)"}
string	equinox = "equinox"	{prompt="Epoch keyword/value (years)"}
real	ra_offset = 0.		{prompt="RA offset (arcsec)"}
real	dec_offset = 0.		{prompt="Dec offset (arcsec)"}
file	logfile = ""		{prompt="Logfile"}
bool	verbose	= yes		{prompt="Verbose"}

struct	*readexps, *readims, *readexts

begin
	int	i
	file	explist, imlist, extlist, temp
	file	db, ccsetwcs
	string	exps, exp, im, imext, fppos
	real	raval, decval, eqval
	struct	wcsastrm

	cache mscextensions

	temp = mktemp ("tmp$iraf")
	explist = temp // "1.tmp"
	imlist  = temp // "2.tmp"
	extlist = temp // "3.tmp"
	ccsetwcs = temp // "4.tmp"

	# Set input parameters.
	exps = exposures
	db = database

	# Set WCSASTRM.
	if (db != "") {
	    wcsastrm = ""
	    match ("WCSASTRM", db, stop-) | scan (im, im, im, wcsastrm)
	}

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

	    	# Set OTA identifier.
		fppos = ""
		hselect (im//"[0]", "FPPOS", yes) | scan (fppos)
		if (fppos == "") {
		    printf ("WARNING: FPPOS keyword not found (%s)\n", im)
		    next
		}

		# Set reference coordinate.
		raval = INDEF; decval = INDEF; eqval = 2000.
		if (fscan (ra, raval) != 1)
		    hselect (im//"[0]", ra, yes) |
			translit ("STDIN", '"', delete+, collapse-) |
			scan (raval)
		if (fscan (dec, decval) != 1)
		    hselect (im//"[0]", dec, yes) |
			translit ("STDIN", '"', delete+, collapse-) |
			scan (decval)
		if (fscan (equinox, eqval) != 1)
		    hselect (im//"[0]", equinox, yes) |
			translit ("STDIN", '"', delete+, collapse-) |
			scan (eqval)
		if (isindef(raval) || isindef (decval)) {
		    printf ("WARNING: Invalid reference coordinate \
		        (%s: %s %s)\n", im, ra, dec)
		    next
		}

		# Precess if necessary.
		if (eqval != 2000.)
		    printf ("%g %g\n", raval, decval) |
			precess ("STDIN", eqval, 2000.) | scan (raval, decval)
		decval = decval + dec_offset / 3600.
		raval = raval * 15. + ra_offset / 3600. / dcos (decval) 
		eqval = 2000.

		printf ("ODISETWCS:\n", > ccsetwcs)
		printf ("    Image: %s\n", im, >> ccsetwcs)
		if (db != "") {
		    printf ("    Database: %s\n", db, >> ccsetwcs)
		    printf ("    Solution: %s\n", fppos, >> ccsetwcs)
		    if (wcsastrm != "")
			printf ("    WCSASTRM: %s\n", wcsastrm, >> ccsetwcs)
		}
		printf ("    Reference coordinate:  %.2H %.1h %.1f\n",
		    raval, decval, eqval, >> ccsetwcs)
		if (verbose)
		    concat (ccsetwcs)
		if (logfile != "")
		    concat (ccsetwcs, >> logfile)
		delete (ccsetwcs, verify-)

		# Expand extensions.
		mscextensions (im, output="file", index="0-", extname="",
		    extver="", lindex=no, lname=yes, lver=no, ikparams="",
		    > extlist)

		# Put stuff we want in global header.
		if (wcsastrm != "")
		    hedit (im//"[0]", "WCSASTRM", wcsastrm, add+,
			del-, verify-, show-, update+)

		# For each image add the WCS and set the CRVAL keywords.
		readexts = extlist
		for (i = 1; fscan (readexts, imext) != EOF; i += 1) {
		    if (db != "") {
			#if (wcsastrm != "")
			#    hedit (imext, "WCSASTRM", wcsastrm, add+,
			#	del-, verify-, show-, update+)

			if (i == 1) {
			    ccsetwcs (imext, db, fppos, transpose=no,
				update=yes, verbose=verbose) |
				match ("parameters", stop+) |
				match ("Solution", stop+) |
				match ("Updating", stop+) |
				match ("hours", stop+, > ccsetwcs)
			    if (verbose)
				concat (ccsetwcs)
			    if (logfile != "")
				concat (ccsetwcs, >> logfile)
			    delete (ccsetwcs, verify-)
			} else
			    ccsetwcs (imext, db, fppos, transpose=no,
				update=yes, verbose=no)
		    }
		    hedit (imext, "crval1", raval, add+, del-, update+,
			show-, verify-)
		    hedit (imext, "crval2", decval, add+, del-, update+,
			show-, verify-)
		}
		readexts = ""; delete (extlist, verify=no)
	    }
	    readims = ""; delete (imlist, verify=no)
	}
	readexps = ""; delete (explist, verify=no)
end
