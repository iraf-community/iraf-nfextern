string	det, seqnum, mjd, exptime
struct	obstype, filter

list = "examples.dat"

b1 = YES
for (i=1;
    fscan (list, det, seqnum, mjd, exptime, obstype) != EOF; i += 1) {
    j = fscan (list, filter)

    printf ("test%02d\n", i) | scan (s1)
    printf ("nf%s\n", s1) | scan (s3)
    if (imaccess(s3//"[0]"))
        next

    if (imaccess(s1))
        imdelete (s1, verify-)
    mkpat (s1, output="", pattern="constant", option="replace", v1=0.,
	v2=1., size=1, title="", pixtype="short", ndim=0, ncols=10,
	nlines=10, n3=1, n4=1, n5=1, n6=1, n7=1, header="")

    s2 = s1 // "extn"
    if (imaccess(s2))
        imdelete (s2, verify-)
    mkpat (s2, output="", pattern="constant", option="replace", v1=0.,
	v2=1., size=1, title="", pixtype="short", ndim=2, ncols=10,
	nlines=10, n3=1, n4=1, n5=1, n6=1, n7=1, header="")

    hedit (s1, "detector", det, add+, verify-, show-, update+)
    hedit (s1, "obstype", obstype, add+, verify-, show-, update+)
    hedit (s1, "filter", filter, add+, verify-, show-, update+)
    hedit (s1, "seqnum", seqnum, add+, verify-, show-, update+)
    hedit (s1, "mjd-obs", mjd, add+, verify-, show+, update+)
    hedit (s1, "mjd-obs", mjd, verify-, show+, update+)
    hedit (s1, "exptime", exptime, add+, verify-, show-, update+)
    hedit (s1, "noclamp", "Unknown", add+, verify-, show-, update+)

    if (obstype == "dark")
        hedit (s1, "noctyp", "DARK", add+, verify-, show-, update+)
    else if (obstype == "dome flat") {
        hedit (s1, "noctyp", "DFLATS", add+, verify-, show-, update+)
        hedit (s1, "noclamp", "On", add+, verify-, show-, update+)
    } else if (obstype == "object")
        hedit (s1, "noctyp", "OBJECT", add+, verify-, show-, update+)

    if (b1)
	printf ("%6s %8s %6s %11s %7s  %s\n", "FILE", "OBSTYPE",
	    "SEQNUM", "MJD-OBS", "EXPTIME", "FILTER")
    ;
    printf ("%6s %8s %6s %11s %7s  %s\n", s1, obstype,
        seqnum, mjd, exptime, filter)

    printf ("nf%s\n", s1) | scan (s3)
    imcopy (s1, s3, verb+)
    for (k=1; k<=4; k+=1) {
        printf ("nf%s[im%d,append,inherit]\n", s1, k) | scan (s3)
        imcopy (s2, s3, verb+)
        printf ("nf%s[im%d]\n", s1, k) | scan (s3)
	hedit (s3, "IMAGEID", k, add+, update+, show-, verify-)
	hedit (s3, "BPM", "bpm"//k, add+, update+, show-, verify-)
    }

    imdel (s1//","//s2, verify-)

    b1 = NO
}
list = ""
