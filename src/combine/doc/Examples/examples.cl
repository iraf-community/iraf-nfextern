string	det, obstype, obstype1, seqnum, mjd, exptime
struct	filter

list = "examples.dat"


b1 = YES
for (i=1;
    fscan (list, det, obstype, obstype1, seqnum, mjd, exptime) != EOF;
    i += 1) {
    j = fscan (list, filter)

    printf ("test%02d\n", i) | scan (s1)
    if (imaccess(s1)) {
        next
	#imdel (s1)
    }
    ;
    mkpat (s1, output="", pattern="constant", option="replace", v1=0.,
	v2=1., size=1, title="", pixtype="short", ndim=2, ncols=10,
	nlines=10, n3=1, n4=1, n5=1, n6=1, n7=1, header="")

    hedit (s1, "detector", det, add+, verify-, show-, update+)
    hedit (s1, "obstype", obstype, add+, verify-, show-, update+)
    hedit (s1, "obstype1", obstype1, add+, verify-, show-, update+)
    hedit (s1, "filter", filter, add+, verify-, show-, update+)
    hedit (s1, "seqnum", seqnum, add+, verify-, show-, update+)
    hedit (s1, "mjd-obs", mjd, add+, verify-, show-, update+)
    hedit (s1, "exptime", exptime, add+, verify-, show-, update+)

    if (b1)
	printf ("%6s %8s %8s %6s %11s %7s  %s\n", "FILE", "OBSTYPE",
	    "OBSTYPE1", "SEQNUM", "MJD-OBS", "EXPTIME", "FILTER")
    ;
    printf ("%6s %8s %8s %6s %11s %7s  %s\n", s1, obstype, obstype1,
        seqnum, mjd, exptime, filter)

    for (k=1; k<=2; k+=1) {
        printf ("mef%s[im%d,append]\n", s1, k) | scan (s2)
        imcopy (s1, s2, verb+)
    }

    b1 = NO
}
list = ""

# 1
i = 1
s1 = "example" // i
s2 = s1 // ".lock"
if (access(s2) == NO) {
    delete (s1//"*.list")
    cgroup ("test*", s1, group="", seqval="",
	seqgap=0., extension="", select="")
    touch (s2)
}
;

# 2
i += 1
s1 = "example" // i
s2 = s1 // ".lock"
if (access(s2) == NO) {
    delete (s1//"*.list")
    cgroup ("test*", s1, group="mkid(filter,1,1)", seqval="",
	seqgap=0., extension="", select="")
    touch (s2)
}
;

# 3
i += 1
s1 = "example" // i
s2 = s1 // ".lock"
if (access(s2) == NO) {
    delete (s1//"*.list")
    cgroup ("test*", s1, group="", seqval="",
	seqgap=0., extension="", select="obstype='object'")
    touch (s2)
}
;

# 4
i += 1
s1 = "example" // i
s2 = s1 // ".lock"
if (access(s2) == NO) {
    delete (s1//"*.list")
    cgroup ("test*", s1,
        group="'_'//mkid(filter,1,1)//'_'//obstype//'_'//obstype1",
	seqval="", seqgap=0., extension="", select="obstype='flat'")
    touch (s2)
}
;

# 5
i += 1
s1 = "example" // i
s2 = s1 // ".lock"
if (access(s2) == NO) {
    delete (s1//"*.list")
    cgroup ("test*", s1,
        group="'_'//mkid(filter,1,1)//'_'//exptime",
	seqval="", seqgap=0., extension="",
	select="obstype='flat'&&obstype1='dome'")
    touch (s2)
}
;

# 6
i += 1
s1 = "example" // i
s2 = s1 // ".lock"
if (access(s2) == NO) {
    delete (s1//"*.list")
    cgroup ("test*", s1,
        group="'_'//exptime",
	seqval="seqnum", seqgap=0., extension="",
	select="obstype='dark'")
    touch (s2)
}
;

# 7
i += 1
s1 = "example" // i
s2 = s1 // ".lock"
if (access(s2) == NO) {
    delete (s1//"*.list")
    cgroup ("test*", s1,
        group="'_'//mkid(filter,1,1)",
	seqval="seqnum", seqgap=0., extension="",
	select="obstype='flat'&&obstype1='dome'")
    touch (s2)
}
;

# 8
i += 1
s1 = "example" // i
s2 = s1 // ".lock"
if (access(s2) == NO) {
    delete (s1//"*.list")
    cgroup ("test*", s1,
        group="'_'//mkid(filter,1,1)//'_'//seqnum",
	seqval="", seqgap=0., extension="",
	select="obstype='flat'&&obstype1='dome'")
    touch (s2)
}
;

# 9
i += 1
s1 = "example" // i
s2 = s1 // ".lock"
if (access(s2) == NO) {
    delete (s1//"*.list")
    cgroup ("test*", s1,
        group="'_'//mkid(filter,1,1)",
	seqval="@'mjd-obs'", seqgap=0.005, extension="",
	select="obstype='flat'&&obstype1='dome'")
    touch (s2)
}
;

# 10
i += 1
s1 = "example" // i
s2 = s1 // ".lock"
if (access(s2) == NO) {
    delete (s1//"*.list")
    cgroup ("meftest*", s1,
        group="'_'//mkid(filter,1,1)",
	seqval="", extension="",
	select="obstype='object'")
    touch (s2)
}
;

# 11
i += 1
s1 = "example" // i
s2 = s1 // ".lock"
if (access(s2) == NO) {
    delete (s1//"*.list")
    cgroup ("meftest*", s1,
        group="'_'//mkid(filter,1,1)",
	seqval="", extension="substr(extname,3,100)",
	select="obstype='object'")
    touch (s2)
}
;
