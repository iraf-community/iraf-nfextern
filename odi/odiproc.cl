# ODIPROC -- Process ODI exposures.

procedure odiproc (input)

begin
	bool	useinnames
	int	n
	string	otype
	string	indir, outdir, lastdir, procdir
	string	inroot, in, out, in1, out1, expnames

	cache	("sections", "average")

	# Query parameters.
	indir = input

	# Set output.
	if (outtype == "ota")
	    outdir = output
	else
	    outdir = ""
	if (outdir == "")
	    outdir = indir
	if (list)
	    otype = "vlist"
	else
	    otype = "image"

	# The input/output are at the exposure level.  Expand the exposure
	# lists and process in a loop.

	expnames = mktemp ("tmp$"//envget("USER"))
	sections (indir, op="fullname", >> expnames+'A') 
	n = sections.nimages
	sections (outdir, op="fullname", >> expnames+'B') 
	if (sections.nimages != 1 && sections.nimages != n) {
	    delete (expnames//"[AB]", verify-)
	    error (1, "Input and output lists do not match")
	}
	if (sections.nimages < n)
	    useinnames = YES
	else
	    useinnames = NO
	joinlines (expnames//'A', expnames//'B', output=expnames,
	    delim=" ", missing='-', shortest-, verbose-)
	delete (expnames//"[AB]", verify-)

	explist = expnames
	while (fscan (explist, indir, outdir) != EOF) {
	    # Handle single output directory when there is an input list.
	    if (outdir == '-')
	        outdir = lastdir
	    lastdir = outdir
	    
	    # Add a little more output.
	    if (verbose)
	        printf ("Processing %s to %s\n", indir, outdir)

	    # Create output directory if necessary.
	    procdir = outdir
	    if (procdir == indir)
		procdir += "/PROC"
	    if (access(procdir) == NO) {
	        mkdir (procdir)
		sleep (1)
	    }

	    # Set the input and output for _odiproc.
	    n = strldx ("/", indir)
	    inroot = substr (indir, n+1, 999)
	    if (useinnames)
		out = inroot
	    else {
		n = strldx ("/", outdir)
		out = substr (outdir, n+1, 999)
	    }

	    printf ("%s/%s.??.fits\n", indir, inroot) | scan (in)
	    printf ("('%s/%s.'//substr(fppos,3,4))\n",
	        procdir, out) | scan (out)

	    # Process or list.
	    _odiproc (in, out, outtype=otype, logfiles=logfiles,
		trim=trim, fixpix=fixpix, biascor=biascor,
		saturation=saturation, zerocor=zerocor, darkcor=darkcor,
		flatcor=flatcor, replace=replace, normalize=no,
		bpm=bpm, obm="(objmask)", trimsec=trimsec,
		biassec=biassec, satexpr=satexpr, satimage=satimage,
		zeros=zeros, darks=darks, flats=flats, repexpr=repexpr,
		repimage=repimage, btype=btype, bfunction=bfunction,
		bsample=bsample, border=border, bnaverage=bnaverage,
		bniterate=bniterate, bhreject=bhreject, blreject=blreject,
		bgrow=bgrow, intype=intype, ztype=ztype, dtype=dtype,
		ftype=ftype, imageid=imageid, filter=filter,
		exptime=exptime, override=override, copy=copy,
		erraction="warn", gdevice=gdevice, gcursor=gcursor,
		gplotfile=gplotfile, taskname=taskname)
	    if (otype == "vlist")
	        next
	    if (normalize) {
		printf ("%s/*.fits\n", procdir) | scan (in1)
		hselect (in1//"[0]", "PROCMEAN", yes) | average (> "dev$null")
		hedit (in1//"[0]", "FLATMEAN", average.mean, add+,
		    verify-, show-, update+)
		printf ("%s/*%%.fits%%.tmp.fits%%\n", procdir) | scan (out1)
		imrename (in1, out1)
		printf ("%s/*.tmp.fits\n", procdir) | scan (in1)
		printf ("%s/*%%.tmp.fits%%.fits%%\n", procdir) | scan (out1)
		_odiproc (in1, out1, outtype=otype, logfiles=logfiles,
		    trim=trim, fixpix=fixpix, biascor=biascor,
		    saturation=saturation, zerocor=zerocor, darkcor=darkcor,
		    flatcor=flatcor, replace=replace, normalize=yes,
		    bpm=bpm, obm="(objmask)", trimsec=trimsec,
		    biassec=biassec, satexpr=satexpr, satimage=satimage,
		    zeros=zeros, darks=darks, flats=flats, repexpr=repexpr,
		    repimage=repimage, btype=btype, bfunction=bfunction,
		    bsample=bsample, border=border, bnaverage=bnaverage,
		    bniterate=bniterate, bhreject=bhreject, blreject=blreject,
		    bgrow=bgrow, intype=intype, ztype=ztype, dtype=dtype,
		    ftype=ftype, imageid=imageid, filter=filter,
		    exptime=exptime, override=override, copy=copy,
		    erraction="warn", gdevice=gdevice, gcursor=gcursor,
		    gplotfile=gplotfile, taskname=taskname)
		imdelete (in1, verify-)
	    }
	    if (merge) {
		printf ("%s/*.fits\n", procdir) | scan (in1)
		printf ("%s/*%%.fits%%.tmp.fits%%\n", procdir) | scan (out1)
		imrename (in1, out1)
		printf ("%s/*.tmp.fits\n", procdir) | scan (in1)
		printf ("%s/%s\n", procdir, inroot) | scan (out1)
		odimerge (in1, out1, bpmask=out1//"_bpm",
		    verbose=no, logfile=logfile)
		imdelete (in1, verify-)
	    }

	    # Handle in-place processing.
	    if (procdir != outdir) {
		files (procdir//"/*") | count | scan (n)
		if (n > 0) {
		    indir += "/ORIG"
		    if (access(indir) == NO) {
			mkdir (indir)
			sleep (1)
		    }
		    move (in, indir, verbose-)
		    move (procdir//"/*", outdir, verbose-)
		}
	    }

	    # Reformat.
	    if (outtype != "ota")
	        odireformat (outdir, output, outtype=outtype,
		    pattern = "*.fits", adjust="none", override=override,
		    verbose=verbose)

	}
	explist = ""; delete (expnames, verify-)

end
