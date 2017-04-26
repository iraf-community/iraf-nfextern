# NFTWOMASS -- Get 2Mass sources for a NEWFIRM field.

procedure nftwomass (input, output)

string	input			{prompt="List of Mosaic files"}
file	output			{prompt="Output file of sources"}
real	magmin = 0.		{prompt="Minimum magnitude"}
real	magmax = 20.		{prompt="Maximum magnitude"}
string	catalog="twomass@noao"	{prompt="Catalog"}
real	rmin = 21.		{prompt="Minimum radius (arcmin)"}
real	search = 0.		{prompt="Search radius (arcsec)"}

begin
	real	r
	file	inlist

	inlist = mktemp ("tmp$iraf")

	mscextensions (input, output="file", index="0-", extname="",
	    extver="", lindex=no, lname=yes, lver=no, dataless=no,
	    ikparams="", > inlist)

	r = rmin + search / 60.
	getcatalog ("@"//inlist, output=output, catalog=catalog,
	    magmin=magmin, magmax=magmax, rmin=r,
	    radecsys="FK5", equinox=2000.)

	delete (inlist, verify=no)
end
