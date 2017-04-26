procedure overlay (image, catalog, objmask)

file	image = ""			{prompt="Image"}
file	catalog = ""			{prompt="Catalog"}
file	objmask = ""			{prompt="Object mask"}

begin
	im = ""; cat = ""; obm = ""
	catim = ""; obmim = ""
	imcat = ""; obmcat = ""
	imobm = ""; catobm = ""

	# Set parameter input.
	i = fscan (image, im)
	i = fscan (catalog, cat)
	i = fscan (objmask, obm)

	# Set image input.
	if (im != "") {
	    hedit (im, "CATALOG", ".") | scan (key, dummy, catim)
	    hedit (im, "OBJMASK", ".") | scan (key, dummy, obmim)
	}

	# Set catalog input.
	if (cat != "") {
	    thedit (im, "IMAGE", ".") | scan (key, dummy, imcat)
	    if (key == "Warning")
	        imcat = ""
	    thedit (im, "OBJMASK", ".") | scan (key, dummy, imobm)
	    if (key == "Warning")
	        imobm = ""
	}

	# Set object mask input.
	if (obm != "") {
	    hedit (im, "IMAGE", ".") | scan (key, dummy, imobm)
	    hedit (im, "CATALOG", ".") | scan (key, dummy, catobm)
	}

	# Set image.
	if (im == "")
	    im = imcat
	if (im == "")
	    im = imobm

	# Set catalog.
	if (cat == "")
	    cat = catim
	if (cat == "")
	    cat = catobm

	# Set object mask.
	if (obm == "")
	    obm = obmim
	if (obm == "")
	    obm = obmcat
