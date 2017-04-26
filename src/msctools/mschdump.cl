# MSCHDUMP -- Dump a mosaic file header.
# The output can be a file, STDOUT (for the terminal), or an email address
# containing the '@' character.

procedure mschdump (input, output)

file	input			{prompt="Mosaic file"}
file	output			{prompt="File for header listing"}

begin
	file	in, out, tmp

	# Get parameters.
	in = input
	out = output

	# If the output is an email address use a temporary file.
	tmp = out
	if (stridx ("@", out) > 0)
	    out = mktemp ("tmp$iraf")

	# Dump the header.
	if (out != "STDOUT") {
	    imheader (in//"[0]", l+, u+, > out)
	    printf ("\n", >> out)
	    msccmd ("imheader $input l+ u+ >> " // out, in)

	    # Send mail if an email address was specified.
	    if (tmp != out) {
		printf ("!!mail %s < %s\n", tmp, osfn(out)) | cl
		delete (out, verify-)
	    }
	} else {
	    imheader (in//"[0]", l+, u+)
	    printf ("\n")
	    msccmd ("imheader $input l+ u+", in)
	}
end
