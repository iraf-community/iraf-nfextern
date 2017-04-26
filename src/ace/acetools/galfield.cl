# GALFIELD - Uniform galaxy field

procedure galfield (output, coords)

file	output			{prompt="Output image"}
file	coords			{prompt="Output coordinates"}

int	ncols	= 512		{prompt="Number of columns"} 
int	nlines	= 512		{prompt="Number of lines"} 
real	ngals	= 0.005		{prompt="Number of objects"}
real	nstars	= 0.0005	{prompt="Number of stars"}

file    header="artdata$stdheader.dat" {prompt="Header"}

real	gain	= 5.		{prompt="Gain"}
real	rdnoise	= 10.		{prompt="Readout noise"}

int	lseed	= 1		{prompt="Object seed"}
int	nseed	= 1		{prompt="Noise seed"}

begin
	int	n
	file	out, dat, tmp

	tmp = mktemp ("tmp")

	out = output
	dat = coords

	if (ngals < 1)
	    n = ngals * ncols * nlines
	else
	    n = ngals

	gallist (tmp, n, interactive=no, spatial="uniform", xmin=1.,
	    xmax=ncols, ymin=1., ymax=nlines, xcenter=INDEF, ycenter=INDEF,
	    core_radius=50., base=0., sseed=lseed+1, luminosity="powlaw",
	    minmag=-7., maxmag=0., mzero=15., power=0.45, alpha=-1.24,
	    mstar=-21.41, lseed=lseed+1, egalmix=0.4, ar=0.7, eradius=10.,
	    sradius=1., absorption=1.2, z=0.05, sfile="", nssample=100,
	    sorder=10, lfile="", nlsample=100, lorder=10, rbinsize=10.,
	    mbinsize=0.5, dbinsize=0.5, ebinsize=0.1, pbinsize=20.,
	    graphics="stdgraph", cursor="")

	if (nstars < 1)
	    n = nstars * ncols * nlines
	else
	    n = nstars

	starlist (tmp, n, "", "", interactive=no, spatial="uniform",
	    xmin=1., xmax=ncols, ymin=1., ymax=nlines, xcenter=INDEF,
	    ycenter=INDEF, core_radius=30., base=0., sseed=lseed,
	    luminosity="powlaw", minmag=-7., maxmag=0., mzero=-4.,
	    power=0.6, alpha=0.74, beta=0.04, delta=0.294, mstar=1.28,
	    lseed=lseed, nssample=100, sorder=10, nlsample=100, lorder=10,
	    rbinsize=10., mbinsize=0.5, graphics="stdgraph", cursor="")

	mkobjects (out, output="", ncols=ncols, nlines=nlines,
	    title="Example artificial galaxy field",
	    header=header, background=400., objects=tmp,
	    xoffset=0., yoffset=0., star="moffat", radius=1.0, beta=2.5,
	    ar=1., pa=0., distance=1., exptime=1., magzero=5.5, gain=gain,
	    rdnoise=rdnoise, poisson=yes, seed=nseed, comments=yes)

	if (dat != "")
	    wcsctran (tmp, dat, out, "logical", "world", columns="1 2",
	        units="", formats="%.2H %.1h", min_sigdigit=9, verbose=no)

	delete (tmp, verify-)
end
