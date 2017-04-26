# MSCSTACK -- Stack dithered images.

procedure mscstack

begin
	combine (input, output, logfile=logfile,  headers=headers,
	    bpmasks=bpmasks, rejmasks=rejmasks, nrejmasks=nrejmasks,
	    expmasks=expmasks, sigmas=sigmas, combine=combine,
	    reject=reject, masktype=masktype, maskvalue=maskvalue,
	    blank=blank, scale=scale, zero=zero, weight=weight,
	    statsec=statsec, lthreshold=lthreshold, hthreshold=hthreshold,
	    nlow=nlow, nhigh=nhigh, nkeep=nkeep, mclip=mclip, lsigma=lsigma,
	    hsigma=hsigma, rdnoise=rdnoise, gain=gain, snoise=snoise,
	    sigscale=sigscale, pclip=pclip, grow=grow)

end
