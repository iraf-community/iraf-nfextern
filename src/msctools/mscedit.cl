# MSCEDIT -- Image header editing on multiextension Mosaic files.
# This requires the same values be set on all extensions.

procedure mcsedit (images, fields, value)

string	images			{prompt="images to be edited"}
string	fields			{prompt="fields to be edited"}
string	value			{prompt="value expression"}
bool	add = no		{prompt="add rather than edit fields"}
bool	addonly = no		{prompt="add only if field does not exist"}
bool	delete = no		{prompt="delete rather than edit fields"}
bool	show = yes		{prompt="print record of each edit operation"}
bool	update = yes		{prompt="enable updating of the image header"}
string	extnames = ""		{prompt="extension names"}

begin
	struct	cmd
	string	im, flds, val

	im = images
	flds = fields

	if (delete && !add && !addonly) {
	    printf ('"hedit $input %s \
		add=no addo=no del=YES ver=NO show=%b upd=%b"\n',
		flds, show, update) |
		scan (cmd)
	} else {
	    val = value
	    printf ('"hedit $input %s ''%s'' \
		add=%b addo=%b del=NO ver=NO show=%b upd=%b"\n',
		flds, val, add, addonly, show, update) |
		scan (cmd)
	}
	msccmd (cmd, images, extname=extnames, verbose=no)
end
