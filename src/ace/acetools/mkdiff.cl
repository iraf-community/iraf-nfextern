procedure mkdiff (input, reference, output)

file	input			{prompt="Input image"}
file	reference		{prompt="Reference image (including input)"}
file	output			{prompt="Output difference image"}

bool	subtract = yes		{prompt="Subtract?"}
bool	display = no		{prompt="Display results?"}

begin
	file	in, ref, out, sec
	real	x1, y1, z1, x2, y2, z2, xoff, yoff
	int	nx, ny, ix1, ix2, iy1, iy2
	bool	subt, disp

	in = input
	ref = reference
	out = output
	subt = subtract
	disp = display

	hselect (in, "crpix1,crpix2,mscscale,naxis1,naxis2", yes) |
	    scan (x1, y1, z1, nx, ny)
	hselect (ref, "crpix1,crpix2,mscscale", yes) |
	    scan (x2, y2, z2)

	xoff = x2 - x1
	yoff = y2 - y1

	i = stridx ("[", in)
	if (i > 0) {
	    sec = substr (in, i, 1000)
	    j = fscanf (sec, "[%d:%d,%d:%d]", ix1, ix2, iy1, iy2)
	} else {
	    ix1 = 1
	    iy1 = 1
	}

	x1 = nint (ix1 + xoff)
	x2 = x1 + nx - 1
	y1 = nint (iy1 + yoff)
	y2 = y1 + ny - 1

	printf ("%s[%d:%d,%d:%d]\n", ref, x1, x2, y1, y2) | scan (sec)

	if (disp) {
	    display (in, 1)
	    display (sec, 2)
	}

	if (subt) {
	    printf ("%s = %.3g * %s - %.3g * %s\n", out, z1, in, z2, sec)
	    imexpr ("c*a-d*b", out, in, sec, z1, z2)
	    if (disp)
		display (out, 3)
	} else
	    printf ("%.3g * %s\n%.3g * %s\n", z1, in, z2, sec)

end
