procedure zcombine (input, output)

begin
	int	i
	file	in, out, dir, tmp1, tmp2

	in = input
	out = output
	tmp1 = mktemp ("tmp")
	tmp2 = mktemp ("tmp")

	# Expand directories into files.
	files (in, >> tmp1)
	fd = tmp1; touch (tmp2)
	while (fscan(fd,dir)!=EOF) {
	    if (strldx("/",dir) != strlen(dir))
	        dir += "/"
	    files (dir//"*.fits", >> tmp2)
	}
	fd = ""; delete (tmp1, verify-)

	# Create output directory.
	count (tmp2) | scan (i)
	if (i > 0 && !access(out)) {
	    mkdir (out)
	    sleep (1)
	}

	# Combine.
	if (verbose && logfile != "STDOUT")
	    printf ("ZCOMBINE: %s -> %s\n", in, out)
	combine ("@"//tmp2, out//"/"//out, logfile=logfile, headers=headers,
	    bpmasks=bpmasks, rejmasks=rejmasks, nrejmasks=nrejmasks,
	    expmasks=expmasks, sigmas=sigmas, imcmb=imcmb, select=select,
	    group=group, seqval=seqval, seqgap=seqgap, extension=extension,
	    delete=delete, combine=combine, reject=reject, outtype="real",
	    outlimits=outlimits, offsets=offsets, masktype=masktype,
	    maskvalue=maskvalue, blank=blank, scale=scale, zero=zero,
	    weight=weight, statsec=statsec, lthreshold=lthreshold,
	    hthreshold=hthreshold, nlow=nlow, nhigh=nhigh, nkeep=nkeep,
	    mclip=mclip, lsigma=lsigma, hsigma=hsigma, rdnoise=rdnoise,
	    gain=gain, snoise=snoise, sigscale=sigscale, pclip=pclip,
	    grow=grow)

	# Reformat.
	if (mef)
	    odireformat (out, "", outtype="mef", pattern = "*.fits",
	        adjust="none", override=no, verbose=verbose)

	delete (tmp2, verify-)
end
