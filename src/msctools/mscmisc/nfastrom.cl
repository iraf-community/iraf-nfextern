# NFASTROM -- Format data for KTM from WCS of NEWFIRM astrometry images.

procedure nfastrom (input)

string	input			{prompt="List of mosaic exposures"}
string	field			{prompt="Astrometry field"}
string	author			{prompt="Author of astrometry solution"}
string	date			{prompt="Date of solution"}

struct	*fd

begin
	int	i, j
	file	in, inlist
	struct	obsid, filter, extname, telescop, value
	string	key, wat

	inlist = mktemp ("tmp$iraf")

	imextensions (input, output="file", index="1-", extname="",
	    extver="", lindex+, lname-, lver-, ikparams="", > inlist)

	fd = inlist
	while (fscan (fd, in) != EOF) {
	    obsid = substr (in, 1, stridx("[",in)-1)
	    filter = "Ks"
	    telescop = "kp4m"
	    #hselect (in, "obsid", yes) | scan (obsid)
	    #hselect (in, "filter", yes) | scan (filter)
	    hselect (in, "extname", yes) | scan (extname)
	    #hselect (in, "imageid", yes) | scan (extname)
	    #extname = "ccd" // extname
	    #telescop = substr (obsid, 1, stridx(".",obsid)-1)
	    print (filter) |
		translit ("STDIN", "^0-9a-zA-Z\n", "_", delete-, collapse-) |
		scan (value)
	    printf ("%s,%s,%s\n", telescop, value, extname) | scan (key)

	    printf ("set WCSASTRM(%s) \\\n          {%s (%s %s) by %s %s}\n",
		key, obsid, field, filter, author, date)
	    hselect (in, "CTYPE1", yes) | scan (value)
	    printf ("set CTYPE1(%s) %s\n", key, value)
	    hselect (in, "CTYPE2", yes) | scan (value)
	    printf ("set CTYPE2(%s) %s\n", key, value)
	    hselect (in, "CRPIX1", yes) | scan (value)
	    printf ("set CRPIX1(%s) %s\n", key, value)
	    hselect (in, "CRPIX2", yes) | scan (value)
	    printf ("set CRPIX2(%s) %s\n", key, value)
	    hselect (in, "CD1_1", yes) | scan (value)
	    printf ("set CD1_1(%s) %s\n", key, value)
	    hselect (in, "CD2_2", yes) | scan (value)
	    printf ("set CD2_2(%s) %s\n", key, value)
	    hselect (in, "CD1_2", yes) | scan (value)
	    printf ("set CD1_2(%s) %s\n", key, value)
	    hselect (in, "CD2_1", yes) | scan (value)
	    printf ("set CD2_1(%s) %s\n", key, value)
	    hselect (in, "WAT0_001", yes) | scan (value)
	    printf ("set WAT01(%s) {%s}\n", key, value)
	    for (j=1; j<=2; j+=1) {
		for (i=1; i<=10; i+=1) {
		    printf ("WAT%d_%03d\n", j, i) | scan (wat)
		    hselect (in, wat, yes) | scan (value)
		    if (value == "")
		        break
		    printf ("WAT%d%d\n", j, i) | scan (wat)
		    printf ("set %s(%s) \\\n          {%-68s}\n",
		        wat, key, value)
		}
	    }
	    printf ("\n")
	}
	fd = ""; delete (inlist, verify-)
end
