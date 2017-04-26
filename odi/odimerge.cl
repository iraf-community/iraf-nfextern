# ODIMERGE -- Merge ODI cells.
#
# This is a preliminary version.

procedure odimerge (input, output)

string	input			{prompt="List of input ODI files"}
file	output			{prompt="Output rootname"}
file	bpmask			{prompt="Output bad pixel mask rootname"}
bool	verbose = yes		{prompt="Verbose?"}
string	logfile = "logfile"	{prompt="Log output"}

struct	*fd

begin
	int	c1, c2, l1, l2
	string	in, out, bpm, detsec
	file	tmplist

	in = input
	out = output
	bpm = bpmask

	files (in) | count | scan (c1)
	if (c1 == 0)
	    return

	if (verbose && logfile != "STDOUT")
	    printf ("Merge %s -> %s\n", in, out)
	combine (in, out, logfile=logfile,
	    headers="", bpmasks=bpm, rejmasks="", nrejmasks="",
	    expmasks="", sigmas="", imcmb="",
	    select="", group="'.'//substr(fppos,3,4)",
	    seqval="", seqgap=INDEF, extension="", delete=no,
	    combine="average", reject="none", outtype="real", outlimits="",
	    offsets="physical", masktype="none", maskvalue="0", blank=0.,
	    scale="none", zero="none", weight="none", statsec="",
	    lthreshold=INDEF, hthreshold=INDEF, nlow=1, nhigh=1, nkeep=1,
	    mclip=yes, lsigma=3., hsigma=3., rdnoise="0.", gain="1.",
	    snoise="0.", sigscale=0.1, pclip=-0.5, grow=0.)

	tmplist = mktemp ("tmp$iraf") // ".list"
	sections (out//".??.fits", option="fullname", > tmplist)
	fd = tmplist
	while (fscan (fd, out) != EOF) {
	    hedit (out, "NCOMBINE,*SEC", del+, verify-, show-, update+)
	    hselect (out, "FPPOS", yes) | scanf ("xy%1d%1d", c1, l1)
	    hselect (out, "NAXIS1,NAXIS2", yes) | scan (c2, l2)
	    bpm = ""; hselect (out, "BPM", yes) | scan (bpm)
	    c1 = c1 * 4100 + 1; l1 = l1 * 4100 + 1
	    c2 = c1 + c2 - 1; l2 = l1 + l2 - 1
	    printf ("[%d:%d,%d:%d]\n", c1, c2, l1, l2) | scan (detsec)
	    hedit (out, "DETSEC", detsec, add+, ver-, show-, upd+)
	    if (strldx("/",bpm) > 0) {
	        bpm = substr (bpm, strldx("/",bpm)+1,999)
		hedit (out, "BPM", bpm, add+, ver-, show-, upd+)
	    }
	}
	fd = ""; delete (tmplist, verify-)

end
