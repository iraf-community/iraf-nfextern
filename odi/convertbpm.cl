# CONVERTBPM -- Convert a BPM derived from a merged OTA image into the
# format suitable for raw exposures.


procedure convertbpm (input, output, reference)

file	input		{prompt="Input BPM in merged OTA format"}
file	output		{prompt="Output BPM in raw MEF format"}
file	reference	{prompt="Reference file in raw MEF format"}

struct	*fd

begin
	int	nc = 480
	int	nl = 494

	string	extname
	file	in, out, ref, tmp, im1, im2
	int	c1, l1, c2, l2

	in = input
	out = output
	ref = reference
	tmp = mktemp ("tmp")

	imextensions (ref, output="file", index="1-", extname="", extver="",
	    lindex=no, lname=yes, lver=no, ikparams="noinherit",
	    > "refextns.tmp")

	imcopy (ref//"[0]", out, verb-)
	hedit (out, "TITLE", "Bad pixel mask", add+, ver-, show-, update+)
	hedit (out, "OBSTYPE", "BPM", add+, ver-, show-, update+)

	fd = "refextns.tmp"
	while (fscan (fd, im1) != EOF) {
	    hselect (im1, "EXTNAME", yes) | scan (extname)
	    imcopy (im1, tmp, verb-)
	    imreplace (tmp, 0)
	    print ("1 1") |
	        wcsctran ("STDIN", "STDOUT", tmp,
		    "logical", "physical", columns="1 2", units="", formats="",
		    min_sigdigit=7, verbose=no) |
		wcsctran ("STDIN", "STDOUT", in,
		    "physical", "logical", columns="1 2", units="", formats="",
		    min_sigdigit=7, verbose=no) |
		scan (c1, l1)
	    c2 = c1 + nc - 1; l2 = l1 + nl - 1
	    printf ("%s[%d:%d,%d:%d]\n", in, c1, c2, l1, l2) | scan (im1)
	    printf ("%s[%d:%d,%d:%d]\n", tmp, 1, nc, 1, nl) | scan (im2)
	    imcopy (im1, im2, verb-)
	    printf ("%s[%s,type=mask,append]\n", out, extname, c1, c2, l1, l2) |
	        scan (im2)
	    imcopy (tmp, im2, verb-)
	    imdelete (tmp, ver-); flpr
	}
	fd = ""; delete ("refextns.tmp", ver-)
end
