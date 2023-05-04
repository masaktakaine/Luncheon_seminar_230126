from ij import IJ, ImagePlus, Prefs
from ij.process import ImageStatistics as IS
options = IS.MEAN | IS.AREA | IS.STD_DEV  # many others
from ij.gui import Roi
from ij.plugin.frame import RoiManager

from ij.measure import ResultsTable

#Prefs.blackBackground = False

imp = IJ.getImage() # Create a ImagePlus object, assign it into imp
ip = imp.getProcessor() # Get its ImageProcessor object
stats = IS.getStatistics(ip, options, imp.getCalibration())

# print statistics on the image
#print "Image statistics for", imp.title
#print "Mean:", stats.mean
#print "Median:", stats.median
#print "Min and max:", stats.min, "-", stats.max
#print "Std. Dev.:", stats.stdDev

imp2 = imp.duplicate()
# imp2 = Duplicator ().run(imp)
imp2.setTitle("mask")
#imp2.show()

IJ.run(imp2, "Subtract Background...", "rolling=20")
#istats = imp2.getStatistics()
ip2 = imp2.getProcessor()
stats2 = IS.getStatistics(ip2, options, imp2.getCalibration())
globalmean = stats2.mean
globalsd = stats2.stdDev
thr = globalmean + 3*globalsd

#print "Image statistics for", imp2.title
#print "Mean", globalmean
#print "SD", globalsd

IJ.setRawThreshold(imp2, thr, 255)
Prefs.blackBackground = True
IJ.run(imp2, "Convert to Mask", "")

IJ.run("Set Measurements...", "area mean perimeter shape feret's redirect=None decimal=3")
IJ.run(imp2, "Analyze Particles...", "size=0.05-Infinity exclude clear add")

rm = RoiManager.getRoiManager()
rm.runCommand(imp,"Show None")
rm.runCommand(imp,"Show All")
rm.runCommand(imp,"Measure")
rt = ResultsTable.getResultsTable()
print(rt.getColumnHeadings())
print(rt.size())
#rt.deleteColumn("Area")
