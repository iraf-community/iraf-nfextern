i = 0

i += 1
s1 = "example" // i
s2 = s1 // ".lock"
s3 = "nftest*"
if (access(s2) == NO) {
    delete (s1//"*.list")
    printf ("cl> nfgroup %s %s obstype+ seqnum+\n", s3, s1)
    nfgroup (s3, s1, obstype+, seqnum+)
    touch (s2)
}
;

i += 1
s1 = "example" // i
s2 = s1 // ".lock"
s3 = "nftest*"
if (access(s2) == NO) {
    delete (s1//"*.list")
    printf ("cl> nfgroup %s %s filter- seqnum+\n", s3, s1)
    nfgroup (s3, s1, filter-, seqnum+)
    touch (s2)
}
;

i += 1
s1 = "example" // i
s2 = s1 // ".lock"
s3 = "nftest*"
if (access(s2) == NO) {
    delete (s1//"*.list")
    printf ("cl> nfgroup %s %s sel=""obstype='dark'"" filt- exp+\n", s3, s1)
    nfgroup (s3, s1, select="obstype='dark'", filter-, exptime+)
    touch (s2)
}
;

i += 1
s1 = "example" // i
s2 = s1 // ".lock"
s3 = "@example2_128.list"
if (access(s2) == NO) {
    delete (s1//"*.list")
    printf ("cl> nfgroup %s %s mef- obstype+ seqnum+\n", s3, s1)
    nfgroup (s3, s1, mef-, obstype+, seqnum+)
    touch (s2)
}
;

i += 1
s1 = "example" // i
s2 = s1 // ".lock"
s3 = "nftest*[im2]"
if (access(s2) == NO) {
    delete (s1//"*.list")
    printf ("cl> nfgroup %s %s obstype+ seqnum+\n", s3, s1)
    nfgroup (s3, s1, obstype+, seqnum+)
    touch (s2)
}
;
