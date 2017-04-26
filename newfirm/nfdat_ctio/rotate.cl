s1 = "../nfdat_kpno/nflincoeffs"
s2 = "nflincoeffs"
imcopy (s1//"[0]", s2)
imcopy (s1//"[im4][-*,-*]", s2//"[im1,append,inherit]")
imcopy (s1//"[im3][-*,-*]", s2//"[im2,append,inherit]")
imcopy (s1//"[im2][-*,-*]", s2//"[im3,append,inherit]")
imcopy (s1//"[im1][-*,-*]", s2//"[im4,append,inherit]")
mscedit (s2, "LTV*,LTM*", del+)
