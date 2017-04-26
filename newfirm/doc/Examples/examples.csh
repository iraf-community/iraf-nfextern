#

@ seqnum = 120
@ mjd1 = 58323
@ mjd2 = 1234

# Darks
foreach det (NEWFIRM)
foreach exptime (5 60)
foreach obstype ("dark")
foreach filter ("Dark")
foreach i (1 2 3)
@ mjd2 = $mjd2 + 1
echo $det $seqnum ${mjd1}.${mjd2} $exptime $obstype
echo $filter
end
@ seqnum++
@ mjd2 = $mjd2 + 40
end
end
end
end

# Dome flats
foreach det (NEWFIRM)
foreach exptime (5)
foreach obstype ("dome flat")
foreach filter ("J" "Ks")
foreach i (1 2 3)
@ mjd2 = $mjd2 + 1
echo $det $seqnum ${mjd1}.${mjd2} $exptime $obstype
echo $filter
end
@ mjd2 = $mjd2 + 40
end
@ seqnum++
end
end
end

# Objects
foreach det (NEWFIRM)
foreach exptime (60)
foreach filter ("J" "Ks")
foreach i (1 2 3)
foreach obstype ("sky" "object" "object" "sky")
@ mjd2 = $mjd2 + 1
echo $det $seqnum ${mjd1}.${mjd2} $exptime $obstype
echo $filter
end
@ seqnum++
@ mjd2 = $mjd2 + 40
end
end
end
end
