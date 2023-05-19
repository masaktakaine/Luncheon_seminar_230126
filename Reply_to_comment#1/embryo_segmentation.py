from ij import IJ, ImagePlus, Prefs
from ij.process import ImageProcessor, ImageConverter
from ij.plugin.filter import BackgroundSubtracter as BS


##cf. https://what-alnk.hatenablog.com/entry/2016/11/03/005918
##Prefs.blackBackground = False
#https://what-alnk.hatenablog.com/entry/2016/06/16/043820
from ij.plugin.filter import ParticleAnalyzer as PA
from ij.measure import ResultsTable

#imp = IJ.getImage()
imp = IJ.openImage("http://imagej.nih.gov/ij/images/embryos.jpg")
cal = imp.getCalibration()
print(cal.pixelWidth)  
ImageConverter(imp).convertToGray8()
imp.getProcessor().invert()

bs = BS()
radius = 35
createBackground = False
lightBackground = False
useParaboloid = False
doPresmooth = False
correctCorners = False
bs.rollingBallBackground(imp.getProcessor(), radius, createBackground, lightBackground, useParaboloid, doPresmooth, correctCorners)



#IJ.run(imp, "Subtract Background...", "rolling=35")
IJ.setAutoThreshold(imp, "Default dark")
Prefs.blackBackground = True  # Prefsをインポートしないと使用できない
IJ.run(imp, "Convert to Mask", "")
#
IJ.run(imp, "Open", "")
IJ.run(imp, "Fill Holes", "")
IJ.run(imp, "Adjustable Watershed", "tolerance=2.5")
#IJ.run(imp, "Set Measurements...", "area mean fit shape feret's integrated redirect=None decimal=3")
#IJ.run(imp, "Analyze Particles...", "size=20-Infinity show=Outlines display exclude clear")


rt = ResultsTable().getResultsTable()
# GUIのAnalyze Particelsのオプション、PAのfieldで指定
options_pa =  PA.CLEAR_WORKSHEET+PA.ADD_TO_MANAGER  +PA.EXCLUDE_EDGE_PARTICLES + PA.SHOW_RESULTS+PA.SHOW_OUTLINES # +PA.SHOW_NONE
MAXSIZE = 100000 # 測定する粒子の最大面積、pixel単位
MINSIZE = 20    # 測定する粒子の最小面積、pixel単位
# Area, Mean, Perimeter, Feret, shape descriptorsを測定する
p = PA(options_pa, PA.AREA + PA.MEAN + PA.PERIMETER + PA.FERET + PA.SHAPE_DESCRIPTORS, rt, MINSIZE, MAXSIZE) 
p.analyze(imp)
