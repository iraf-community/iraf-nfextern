# This file defines the object parameters for a single catalog.

# The following are the parameter ids which are the offsets into the object
# data structure.  Note that the first group of parameters are those
# determined during detection for potential objects.  The second group
# are parameters added after an object has been accepted.

define  ID_NUM           1 # i "" ""		/ Object number
define  ID_PNUM          2 # i "" ""		/ Parent number
define	ID_XPEAK	 3 # r pixels %10.3f	/ X peak coordinate
define	ID_YPEAK	 4 # r pixels %10.3f	/ Y peak coordinate
define	ID_FLUX		 5 # r counts ""	/ Isophotal flux (I - sky)
define	ID_NPIX		 6 # i pixels ""	/ Number of pixels
define	ID_NDETECT	 7 # i pixels ""	/ Number of detected pixels
define	ID_SIG		 8 # r counts ""	/ Sky sigma
define	ID_ISIGAVG	 9 # r sigma ""		/ Average (I - sky) / sig
define	ID_ISIGMAX	10 # r sigma ""		/ Maximum (I - sky) / sig
define	ID_ISIGAV	11 # r sigma ""		/ *Ref average (I - sky) / sig
define	ID_FLAGS	12 # 8 "" ""		/ Flags

define	ID_SKY		17 # r counts ""	/ Mean sky
define	ID_THRESH	18 # r counts ""	/ Mean threshold above sky
define	ID_PEAK		19 # r counts ""	/ Peak pixel value above sky
define	ID_FCORE	20 # r counts ""	/ Core flux
define	ID_GWFLUX	21 # r counts ""	/ Gaussian weighted flux
define	ID_CAFLUX_0	22 # r counts ""	/ Circular aperture flux
define	ID_CAFLUX_1	23 # r counts ""	/ Circular aperture flux
define	ID_CAFLUX_2	24 # r counts ""	/ Circular aperture flux
define	ID_CAFLUX_3	25 # r counts ""	/ Circular aperture flux
define	ID_CAFLUX_4	26 # r counts ""	/ Circular aperture flux
define	ID_CAFLUX_5	27 # r counts ""	/ Circular aperture flux
define	ID_CAFLUX_6	28 # r counts ""	/ Circular aperture flux
define	ID_CAFLUX_7	29 # r counts ""	/ Circular aperture flux
define	ID_CAFLUX_8	30 # r counts ""	/ Circular aperture flux
define	ID_CAFLUX_9	31 # r counts ""	/ Circular aperture flux
define	ID_FRACFLUX	32 # r counts ""	/ Apportioned flux
define	ID_FRAC		33 # r "" %8.3f		/ Apportioned fraction
define	ID_XMIN		34 # i pixels %10.3f	/ Minimum X
define	ID_XMAX		35 # i pixels %10.3f	/ Maximum X
define	ID_YMIN		36 # i pixels %10.3f	/ Minimum Y
define	ID_YMAX		37 # i pixels %10.3f	/ Maximum Y
define	ID_XAP		38 # r pixels %10.3f	/ X aperture coordinate
define	ID_YAP		39 # r pixels %10.3f	/ Y aperture coordinate
define	ID_X		40 # r pixels %10.3f	/ X centroid
define	ID_Y		41 # r pixels %10.3f	/ Y centroid
define	ID_XX		42 # r pixels ""	/ X 2nd moment
define	ID_YY		43 # r pixels ""	/ Y 2nd moment
define	ID_XY		44 # r pixels ""	/ X 2nd cross moment
define	ID_R		45 # r pixels %8.3f	/ R moment
define	ID_RII		46 # r pixels %8.3f	/ RI2 moment
define	ID_FWHM		47 # r pixels %8.3f	/ FWHM estimate
define	ID_EAELLIP	48 # r "" ""		/ Ellip aperture ellipticity
define	ID_EATHETA	49 # r degrees %8.2f	/ Ellip aperture pos angle
define	ID_EAR_0	50 # r pixels %8.3f	/ Ellip aperture radius
define	ID_EAR_1	51 # r pixels %8.3f	/ Ellip aperture radius
define	ID_EAR_2	52 # r pixels %8.3f	/ Ellip aperture radius
define	ID_EAR_3	53 # r pixels %8.3f	/ Ellip aperture radius
define	ID_EAR_4	54 # r pixels %8.3f	/ Ellip aperture radius
define	ID_EAR_5	55 # r pixels %8.3f	/ Ellip aperture radius
define	ID_EAR_6	56 # r pixels %8.3f	/ Ellip aperture radius
define	ID_EAR_7	57 # r pixels %8.3f	/ Ellip aperture radius
define	ID_EAR_8	58 # r pixels %8.3f	/ Ellip aperture radius
define	ID_EAR_9	59 # r pixels %8.3f	/ Ellip aperture radius
define	ID_EAFLUX_0	60 # r pixels %10.3f	/ Ellip aperture flux
define	ID_EAFLUX_1	61 # r pixels %10.3f	/ Ellip aperture flux
define	ID_EAFLUX_2	62 # r pixels %10.3f	/ Ellip aperture flux
define	ID_EAFLUX_3	63 # r pixels %10.3f	/ Ellip aperture flux
define	ID_EAFLUX_4	64 # r pixels %10.3f	/ Ellip aperture flux
define	ID_EAFLUX_5	65 # r pixels %10.3f	/ Ellip aperture flux
define	ID_EAFLUX_6	66 # r pixels %10.3f	/ Ellip aperture flux
define	ID_EAFLUX_7	67 # r pixels %10.3f	/ Ellip aperture flux
define	ID_EAFLUX_8	68 # r pixels %10.3f	/ Ellip aperture flux
define	ID_EAFLUX_9	69 # r pixels %10.3f	/ Ellip aperture flux

define	ID_FLUXVAR	70 # r counts ""	/ *Variance in the flux
define	ID_XVAR		71 # r pixels ""	/ *Variance in X centroid
define	ID_YVAR		72 # r pixels ""	/ *Variance in Y centroid
define	ID_XYCOV	73 # r pixels ""	/ *Covariance of X and Y

define	ID_ORDER	74 # i "" ""		/ Order

# The following are derived quantities which have ids above 10000.

define	ID_A		10001 # r pixels %8.3f	/ Semimajor axis
define	ID_B		10002 # r pixels %8.3f	/ Semiminor axis
define	ID_THETA	10003 # r degrees %8.2f	/ Position angle
define	ID_ELONG	10004 # r "" ""		/ Elongation = A/B
define	ID_ELLIP	10005 # r "" ""		/ Ellipticity = 1 - B/A
define	ID_RR		10006 # r pixels %8.3f	/ Second moment radius
define	ID_CXX		10007 # r pixels ""	/ Second moment ellipse
define	ID_CYY		10008 # r pixels ""	/ Second moment ellipse
define	ID_CXY		10009 # r pixels ""	/ Second moment ellipse

define	ID_FLUXERR	10011 # r counts ""	/ Error in flux
define	ID_XERR		10012 # r pixels ""	/ Error in X centroid
define	ID_YERR		10013 # r pixels ""	/ Error in Y centroid
define	ID_AERR		10014 # r "" ""		/ Error in A
define	ID_BERR		10015 # r "" ""		/ Error in B
define	ID_THETAERR	10016 # r degrees ""	/ Error in THETA
define	ID_CXXERR	10017 # r pixels ""	/ Error in CXX
define	ID_CYYERR	10018 # r pixels ""	/ Error in CYY
define	ID_CXYERR	10019 # r pixels ""	/ Error in CXY
