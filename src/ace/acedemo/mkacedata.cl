# MKACEDATA -- Make ACE demo data.

procedure mkacedata ()

begin
	string	mef, im, mostmp
	int	obs, oseed, nseed
	real	ra, rapix, x1, y1, z1

	# Load packages.
	artdata
	msctools

	# Create mosaic files.
	mostmp = "mostmp.fits"
	nseed = 0
	for (obs=1; obs<=3; obs+=1) {
	    printf ("mos%03d.fits\n", obs) | scan (mef)
	    if (access(mef)) {
	        mscedit (mef, "catalog,objmask", del+, show-)
		next
	    }
	    ;
	    imdel (mef, verify-, >& "dev$null")
	    for (oseed=1; oseed<=2; oseed+=1) {
		nseed += 1
		mkexample ("galfield", mostmp, oseed=oseed, nseed=nseed, ver-)
		rapix = (2 - oseed) * 520 - 10
		mkcwcs (mostmp, ra=1.5, dec=32, scale=0.25, pa=0., left+,
		    proj="tan", rapix=rapix, decpix=256.
		if (obs==1) {
		    for (i=1; i<=3; i+=1) {
			x1 = 100 * i; y1 = x1; z1=i*0.5
			print (x1, y1, z1) |
			    mkobject (mostmp, objects="STDIN", magzero=8.1)
		    }
		}
		;
		printf ("%s[im%d,append]\n", mef, oseed) | scan (im)
		imcopy (mostmp, im, verb-)
		imdel (mostmp, verify-)
	    }
	}
end
