#!/bin/env pipecl
#
# WCSWCS -- Update the WCS.

int	status = 1
int	grpstatus = 1
int	nsets
real    axs, ays, axr, ayr, x1, x2, x3, x4, mjd
string	dataset, lfile, tlfile, procid, cast, s4, glob, globhdr
string	swcdataset, swcdir, swccat, swcmcat, swcwcsdb, swcshort
string  swcwcshdr, shortdir
struct	*list2

# Define the newDataProduct python interface layer
task $newDataProduct = "$!newDataProduct.py $1 $2 $3 -u $4"
task $wcswcs_usnomatch_proc = "$wcswcs_usnomatch_proc.py $1"
task $wcswcs_usnomap_proc = "$wcswcs_usnomap_proc.py $1"
task $wcswcs_ccmap_proc = "$wcswcs_ccmap_proc.py $1"

# Tasks and packages.
utilities
images
imcoords
mario
tables
ttools
servers
dataqual

# Set dataset directory and logfile.
wcsnames( envget ("OSF_DATASET") )
dataset = wcsnames.dataset
set (uparm = wcsnames.uparm)
set (pipedata = wcsnames.pipedata)
lfile = wcsnames.lfile
tlfile = "wcswcs.lfile"
cd( wcsnames.datadir )

# Log start of processing.
printf ("\nWCSWCS (%s): ", dataset) | tee (lfile)
time | tee (lfile)

# TODO: move code below to setup to make it available to all modules if needed

# Create a list of MEF files to process, by selecting all the 
# global header files
files( "*_00.fits", > "wcswcs.tmp" )
list = "wcswcs.tmp"; touch ( "wcswcs1.tmp" )
while( fscan( list, s1 ) != EOF ) {
    # Strip the _00.fits from the end
    s2 = substr( s1, 1, strstr("_00.fits",s1)-1 )
    print( s2, >> "wcswcs1.tmp" )
}
list = ""
delete( "wcswcs.tmp" )

# Check for the existence of any temporary files. These should
# not exist, but these checks have been added during a round
# of thorough and rigorous "let's eliminate all possible potential
# problems" code checking.
if ( access("wcswcscats.tmp") ) {
    delete( "wcswcscats.tmp" )
}
;
if ( access("wcswcsmcats.tmp") ) {
    delete( "wcswcsmcats.tmp" )
}
;
if ( access("wcswcsdb.tmp") ) {
    delete( "wcswcsdb.tmp" )
}
;

# Loop over all MEF files to process
print "TTTTTTTTTTTTTTTTT"
type( "wcswcs1.tmp" )
print "TTTTTTTTTTTTTTTTT"
print "SETTING GROUP STATUS TO 1"
    grpstatus = 1
list = "wcswcs1.tmp"
while( fscan( list, glob ) != EOF ) {
print "============================================"
print "============================================"
print "============================================"
print( glob )
    # Make sure each entry in the list starts with a clean
    # slate, so that previous problems are not passed on to 
    # the next
print "SETTING STATUS TO 1"
    status = 1
    # Append "_" to the contents of glob to avoid matching
    # directory names in the path
    glob = glob//"_"
    if ( access( "wcswcs2.tmp" ) ) {
        delete( "wcswcs2.tmp" )
    }
    ;
    if ( access( "wcswcs.tmp" ) ) {
        delete( "wcswcs.tmp" )
    }
    ;
    # Extract all files matching the current dataset from the 
    # ace return lists ...
    match( glob, "*.ace", print-, > "wcswcs2.tmp" )
    # ... and select the _cat files from the output, which
    # should select one instance of each extension
    match( "_cat", "wcswcs2.tmp", print-, > "wcswcs.tmp" )
    # Loop over all extensions to create input files needed below
print "TKTKTKTKTKTKTKTK"
type( "wcswcs.tmp" )
    list2 = "wcswcs.tmp"
    while( fscan( list2, s2 ) != EOF ) {
	# Strip the _cat from the end
        s3 = substr( s2, 1, strlstr("_cat",s2)-1 )
	# Extract the dataset name
        swcdataset = substr( s3, strlstr("/",s3)+1, 999 )
	# And the path name
        swcdir = substr( s3, 1, strlstr("/",s3) )
	# Set the swc names for this dataset
	swcnames( swcdataset )
        # Create input/output files needed below
        print( s2, >> "wcswcscats.tmp" )
        print( swcnames.mcat, >> "wcswcsmcats.tmp" )
        printf( "%s %s %s %s %s\n", swcdir, swcnames.mcat, swcnames.wcsdb,
            swcnames.shortname, swcnames.wcshdr, >> "wcswcsdb.tmp" )
    }
    list2 = ""
    delete( "wcswcs2.tmp,wcswcs.tmp" )
    if (access("wcswcscats.tmp")==NO)
        next
    ;
print "OOOOOOOOOOOOOOOOOOOOOO1111"
type( "wcswcsmcats.tmp" )
print "OOOOOOOOOOOOOOOOOOOOOO2222"
type( "wcswcsmcats.tmp" )
print "OOOOOOOOOOOOOOOOOOOOOO3333"
type(  "wcswcsdb.tmp" )

    # Construct the file name of the global header as set in wcsgcat.cl
    s3 = substr( s2, strldx("/",s2)+1, strlstr("_im",s2)-1 ) // "_00"

    # Set wcsnames using the global header name
    wcsnames( s3 )
    wcsnames.hdr = s3
print "S3S3S3S3S3"
print( s3 )

    # Insert new data product.
    mjd = INDEF ; hsel( wcsnames.hdr, "mjd-obs", yes ) | scan( mjd )
    newDataProduct( wcsnames.shortname, mjd, "mefobjectimage", "")
    storekeywords( class="mefobjectimage", id=wcsnames.hdr,
        sid=wcsnames.shortname, dm=dm )

    # Match the catalogs produced by swcace.cl against the reference catalog
    # produced by wcsgcat.cl
print "AAA1"
    if (access(wcsnames.mcat)) {
        # Delete the output files
        delete( "@wcswcsmcats.tmp" )
print "LINELINELINELINE"
print( line )
line = "success"
        iferr {
print "USNOMATCH starting"
            usnomatch ("@wcswcscats.tmp", wcsnames.mcat, matchcat="@wcswcsmcats.tmp",
	        imcatdef="@pipedata$catmatch.def", fracmatch=wcs_fracmatch,
	        logfile=tlfile) |& scan (line)
        } then {
            printf( "USNOMATCH failed on %s\n", wcsnames.mcat )
            line = "Warning"
        } else {
            printf( "USNOMATCH completed\n" )
            concatenate (tlfile) | tee (lfile)
        }
    } else {
        printf ("Warning: No reference catalog (%s)\n", wcsnames.mcat) | scan (line)
    }

print "AAA2"
    if (substr (line, 1, 7) == "Warning") {
print "AAA2a"
        sendmsg ("ERROR", substr(line,9,1000), "", "PROC")
        printf ("ERROR: %s\n", substr(line,9,1000), >> lfile)
        status = 2
	grpstatus = 2
    } else {
print "AAA2b"
        # Merge matched catalogs.
        delete (wcsnames.mcat)
        # TODO: determine appropriate value for filter=
        iferr {
            mefmerge( "@wcswcsmcats.tmp", wcsnames.mcat, catdef="",
                filter="G<23.", append+, verbose+ )
        } then {
            print "MEFMERGE FAILED"
            status = 2
        } else { 
            print "MEFMERGE OK"
        }
        delete ("wcswcs_usnomatch_proc.cl")
    }
    delete( tlfile )

print "AAA3"
    # Compute a global correction and add a constraining grid.
    flpr
    if (status == 1) {
        s1 = "none"
        head( "wcswcsmcats.tmp", nl=1 ) | scan( s1 )
        if ( access( s1 ) ) {
            usnomap( "@wcswcsmcats.tmp", logfile=tlfile ) |& scan (line)
            concatenate (tlfile) | tee (lfile)
            if (substr (line, 1, 7) == "Warning") {
                sendmsg ("ERROR", substr(line,9,1000), "", "PROC")
	        printf ("ERROR: %s\n", substr(line,9,1000), >> lfile)
                status = 2
	        grpstatus = 2
            } else {
                wcswcs_usnomap_proc( tlfile )
                cl < wcswcs_usnomap_proc.cl
	        delete ("wcswcs_usnomap_proc.cl")
            }
        } else {
            print "USNOMAP FAILED"
            status = 2
        }
    }
    ;
print "AAA4"
    delete( tlfile )
    delete( "wcswcscats.tmp,wcswcsmcats.tmp" )
    # Do WCS solutions.  Get the shifted tangent point from the logfile.
    if (status == 1) {
        axr = 0
        ayr = 0
        axs = 0
        ays = 0
        nsets = 0
        match ("new tangent point", lfile) | translit ("STDIN", "(,)", del+) |
	    scan (s1, s1, s1, s1, x, y)
        list2 = "wcswcsdb.tmp"
        while (fscan (list2, swcdir, swcmcat, swcwcsdb, swcshort, swcwcshdr) != EOF) {
            if ( access(swcwcsdb) ) {
                delete( swcwcsdb )
            }
            ;
            if (wcs_wcsglobal) {
                # Following should not be needed, but in the interest 
                # of being overly cautious it is included
	        if ( access( "wcswcsgrid.tmp" ) ) {
                    delete ("wcswcsgrid.tmp")
                }
                ;
	        match ("INDEF", swcmcat, > "wcswcsgrid.tmp")
	        ccmap ("wcswcsgrid.tmp", swcwcsdb, solution="wcs",
	            lngref=x, latref=y, > tlfile)
	        delete ("wcswcsgrid.tmp")
	    } else {
	        ccmap (swcmcat, swcwcsdb, solution="wcs",
	            lngref=x, latref=y, > tlfile)
	    }
            concatenate (tlfile) | tee (lfile)
	    # Redirect input parameters for wcswcs_ccmap_proc to file.
	    # wcswcs_ccmap_proc will read the parameters from file.
            # This is a way to avoid escaping the "!" in swcdir.
            if ( access( "wcswcs.inp" ) ) {
                delete( "wcswcs.inp" )
            }
            ;
            printf("%s %s %s\n", tlfile, swcdir, swcshort, >> "wcswcs.inp" )
            wcswcs_ccmap_proc( "wcswcs.inp" )
            delete( "wcswcs.inp" )
            cl < wcswcs_ccmap_proc.cl
	    delete ("wcswcs_ccmap_proc.cl")
	    # Get the scale and the rms from the header to calculate the 
	    # average over all extensions
	    s1 = swcdir // swcshort
	    hselect( s1, "dqwcccxr,dqwcccyr,dqwcccxs,dqwcccys", yes ) |
	        scan( x1, x2, x3, x4 )
	    if (nscan()==4) {
	        axr = axr+x1
	        ayr = ayr+x2
	        axs = axs+x3
	        ays = ays+x4
                nsets = nsets+1
            }
	    ;
            delete( tlfile )
        }
        list2 = ""
        if (nsets>0) {
            axr = axr/nsets
            ayr = ayr/nsets
            axs = axs/nsets
            ays = ays/nsets
    	    printf("%12.5e\n", axr ) | scan( cast )
            setkeyval( class="mefobjectimage", id=wcsnames.shortname, dm=dm,
	        keyword="dqwccaxr", value=cast )
            hedit( wcsnames.hdr, "wcsxrms", axr, add+, update+, verify-, show+, >> lfile)
            printf("%12.5e\n", ayr ) | scan( cast )
            setkeyval( class="mefobjectimage", id=wcsnames.shortname, dm=dm,
                keyword="dqwccayr", value=cast )
            hedit( wcsnames.hdr, "wcsyrms", ayr, add+, update+, verify-, show+, >> lfile)
            printf("%12.5e\n", axs ) | scan( cast )
            setkeyval( class="mefobjectimage", id=wcsnames.shortname, dm=dm,
                keyword="dqwccaxs", value=cast )
            printf("%12.5e\n", ays ) | scan( cast )
            setkeyval( class="mefobjectimage", id=wcsnames.shortname, dm=dm,
                keyword="dqwccays", value=cast )
        } else 
	    sendmsg("WARNING", "Could not determine average WCS info", "", "DQ" )

    }
    ;
print "AAA5"
    # Update headers.
    globhdr = glob // "00.fits" # Note that glob already ends in a _
    if (status == 1) {
        # Trigger results back to SWC pipeline.
        list2 = "wcswcsdb.tmp"
        for (i=1; fscan(list2,swcdir,swcmcat,swcwcsdb,swcshort,swcwcshdr)!=EOF; i+=1) {
            if ( access( swcdir//swcwcshdr ) ) {
                delete( swcdir//swcwcshdr )
            }
            ;
	    x1 = INDEF; thselect (swcmcat, "MAGZERO1", yes) | scan (x1)
	    if (isindef(x1)==NO)
		printf ("MAGZERO1 %g\n", x1, >> swcdir//swcwcshdr)
	    ;
	    x2 = INDEF; thselect (swcmcat, "MAGZSIG1", yes) | scan (x2)
	    if (isindef(x2)==NO)
		printf ("MAGZSIG1 %g\n", x2, >> swcdir//swcwcshdr)
	    ;
	    x3 = INDEF; thselect (swcmcat, "MAGZERR1", yes) | scan (x3)
	    if (isindef(x3)==NO)
		printf ("MAGERR1 %g\n", x3, >> swcdir//swcwcshdr)
	    ;
	    j = INDEF; thselect (swcmcat, "MAGZNAV1", yes) | scan (j)
	    if (isindef(j)==NO)
		printf ("MAGZNAV1 %d\n", j, >> swcdir//swcwcshdr)
	    ;
	    x1 = INDEF; thselect (swcmcat, "MAGZERO", yes) | scan (x1)
	    if (isindef(x1)==NO)
		printf ("MAGZERO %g\n", x1, >> swcdir//swcwcshdr)
	    ;
	    x2 = INDEF; thselect (swcmcat, "MAGZSIG", yes) | scan (x2)
	    if (isindef(x2)==NO)
		printf ("MAGZSIG %g\n", x2, >> swcdir//swcwcshdr)
	    ;
	    x3 = INDEF; thselect (swcmcat, "MAGZERR", yes) | scan (x3)
	    if (isindef(x3)==NO)
		printf ("MAGERR %g\n", x3, >> swcdir//swcwcshdr)
	    ;
	    j = INDEF; thselect (swcmcat, "MAGZNAV", yes) | scan (j)
	    if (isindef(j)==NO)
		printf ("MAGZNAV %d\n", j, >> swcdir//swcwcshdr)
	    ;

	    # Update global header.
	    if (i == 1) {
		if (isindef(x1)==NO)
		    hedit (wcsnames.hdr, "MAGZERO", x1, add+, show+, >> lfile)
		;
		if (isindef(x2)==NO)
		    hedit (wcsnames.hdr, "MAGZSIG", x2, add+, show+, >> lfile)
		;
		if (isindef(x3)==NO)
		    hedit (wcsnames.hdr, "MAGZERR", x3, add+, show+, >> lfile)
		;
		if (isindef(j)==NO)
		    hedit (wcsnames.hdr, "MAGZNAV", j, add+, show+, >> lfile)
		;
		hedit (globhdr, "WCSCAL", "(1==1)", add+, show+, >> lfile)
	    }
	    ;

	    move (swcmcat//","//swcwcsdb, swcdir)
        }
        list2 = ""
    } else
        hedit (globhdr, "WCSCAL", "(1==2)", add+, show+, >> lfile)
    delete( "wcswcsdb.tmp,wcswcscats.tmp,wcswcsmcats.tmp" )
print "AAA6"
}

printf ("EXIT GROUP STATUS IS %d\n", grpstatus)
#logout( grpstatus )
logout 1
