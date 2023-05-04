from ij import IJ, ImagePlus, Prefs
##cf. https://what-alnk.hatenablog.com/entry/2016/11/03/005918
##Prefs.blackBackground = False

imp = IJ.getImage()
IJ.run(imp, "8-bit", "")
IJ.run(imp, "Invert", "")
IJ.run(imp, "Subtract Background...", "rolling=35")
IJ.setAutoThreshold(imp, "Default dark")
Prefs.blackBackground = True  # Prefsをインポートしないと使用できない
IJ.run(imp, "Convert to Mask", "")

IJ.run(imp, "Open", "")
IJ.run(imp, "Fill Holes", "")
IJ.run(imp, "Adjustable Watershed", "tolerance=2.5")
IJ.run(imp, "Set Measurements...", "area mean fit shape feret's integrated redirect=None decimal=3")
IJ.run(imp, "Analyze Particles...", "size=20-Infinity show=Outlines display exclude clear")
