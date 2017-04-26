=============================
ODI IRAF Package User's Guide
=============================
-------------------
F. Valdes, May 2012
-------------------

Introduction
============

This document is a quick draft in response to getting the first version
of useful ODI/pODI tools out to the instrument scientists and engineers
and for the instrument verification teams.  It discusses an IRAF
package, called **odi**, which is distributed as part of the **nfextern**
package.  The external package is intented to be added on to V2.16 core
IRAF.

Note that the ODI pipeline is intended to provide the best calibration using
greater compute resources, so use of that data is likely to be more
convenient for users than using the ODI package for personal processing.
However, the scale of pODI does permit one to potentially reduce your own
data outside of the pipeline.

Be aware, that the release of the ODI package and the appearance now, and
in the future, of tasks in that package does not, initially, mean that they
are truly working or have help pages.  So please try and use them, give
feedback as to what is important, and we will try and get new versions out
as quickly as feasible given other priorities such a pipeline development.

There must also evolve since the initial release of "real" data is still
upcoming.  Though the expected formats, keywords, and properties are documented
there are always little details which are not as expected.

Initial Inspection
==================

The first thing most users will want to do is display a raw pODI exposure.
The tool provided for this is **mkpodimef** (a help page is available).
What this does is convert the raw pODI format to an MEF format for which
there are many tools available from the **msctools** package.

Briefly digressing, many of you will already be familiar with the
**mscred** package.  The **msctools** package, which is part of the same
parent **nfextern** package as the prototype ODI package, is an enhanced
version of the non-CCD processing pieces of **mscred**.  The
word "enhanced" means there are a few common things that were not in **mscred**
that now have explicit commands.  The key ones are::

    mscstat, mscselect, and mscedit

which are MEF versions of the standard **imstat**, **hselect**, and **hedit**.

So, the first time **mkpodimef** is run it produces an MEF version.
Subsequent executions with the same input exposure name will simply use this
version unless the ``override`` option is selected.

The other thing **mkpodimef** provides you is to call **mscdisplay** to
load the OTAs in their tiled positions in a display server.  As with other
data, this is based on the header keywords ``DETSEC``.  One specialized
feature is that loading the entire ODI field of view with the sparse pODI
focal plane is often not what you want to look at.  So there is a parameter
to allows selecting the filled part of the pODI focal plane.  This is the
default.

A word about frame buffer sizes.  In IRAF you need to define the frame
buffer size.  **Mscdisplay** will use whatever frame size you have by binning
to the smallest factor that fits the size.  Users can set up buffers as
needed but the IRAF distribution needs to provide one soon.  Note there
is already a 12K frame buffer defined (see **gdevices**) ``imt57``.  However,
the central field is just slightly larger than 12K and so it doesn't actually
give you pixel resolution.

Once the image is displayed you can run **imexam** if you are using the
XIMTOOL display server.  This does not work with DS9 though loading the display
does work.  What **mscdisplay** does is define a separate coordinate system
for each OTA which is stored in the display server (only XIMTOOL).  Then
**imexam** can determine which OTA is referenced during a cursor read and to
the correct calculation to find the pixel data.

PPA Tools
=========

This is a specific section for the PPA portal developers.  The need here is
to make a simple, large, flat FITS image of the full field which can then
be converted to the display form used by the portal.  The tool to use
to make this simple FITS image is **odireformat** (a help page is available).

OTA Processing
==============

The various processing commands have been exercised with simulated data.
They have been written to be relatively easy to use by hiding a lot of
parameters.
