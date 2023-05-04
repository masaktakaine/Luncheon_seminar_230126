from ij import IJ, ImagePlus, Prefs
from ij.process import ImageStatistics as IS
options = IS.MEAN | IS.AREA | IS.STD_DEV  # many others
from ij.gui import Roi
from ij.plugin.frame import RoiManager as RM
from ij.measure import ResultsTable
import os
from os import path
from ij.gui import WaitForUserDialog
import random
from java.awt import Color
from ij.plugin.filter import BackgroundSubtracter
radius = 15
createBackground = False
lightBackground = False
useParaboloid = False
doPresmooth = False
correctCorners = False

from ij.plugin.filter import Analyzer
from ij.plugin.filter import ParticleAnalyzer as PA
MAXSIZE = 10000
MINSIZE = 0.05
options_pa = PA.SHOW_OUTLINES + PA.EXCLUDE_EDGE_PARTICLES + PA.CLEAR_WORKSHEET # + PA.SHOW_RESULTS

#from ij.measure.Measurements import *
#options2 = AREA + MEAN + INTEGRATED_DENSITY + CIRCULARITY + FERET + PERIMETER + SHAPE_DESCRIPTORS

#@ String(label="Date of experiments, e.g., 2022-02-05") edate1
#@ File (label="Choose destination folder", style="directory") dirD0

# Result Tableをcsvで保存、関数化
def save_result_table(directory,image,result_table):	# imageは名前だけ利用
	title = image.getTitle().split(".")[0]  			# ピリオドで分割して、画像の名前を取得
	resultfile = os.path.join(directory, title + ".csv")  # 保存するcsvファイルのパスを作成
	result_table.saveAs(resultfile)

# outline画像をpng形式で保存、関数化
def save_outlines_as_PNG(directory, image, outline):
    title = image.getTitle().split(".")[0]
    outputfile = os.path.join(directory, title + "_outline.png")
    IJ.saveAs(outline, "PNG", outputfile) # 保存する画像、png形式、パスを指定

edate = " "+edate1 ## Insert a blank to prevent automatic modification on Excel.
dirData = os.path.join(str(dirD0), edate1+"_data") ## os.path.joinを使うと勝手にseparatorを挟む
if not os.path.exists(dirData):  # dirDataが存在しなければ作成する
	os.mkdir(dirData)								## フォルダdirDataを作成
dirDR = os.path.join(str(dirD0), edate1+"_Drawings")	##Create a folder for mask images and ROI data
if not os.path.exists(dirDR):
	os.mkdir(dirDR)

# Create a ImagePlus object, assign it into imp
imp = IJ.getImage()
# Get its ImageProcessor object
ip = imp.getProcessor()

file = imp.getTitle().replace(".tif", "") # パスを含まないファイル名を取得しさらに拡張子を除く
rm = RM.getRoiManager()
rm.runCommand(imp,"Show None")
rm.runCommand(imp,"Show All with labels")

print("start")
# 使用者に入力を求める
wud = WaitForUserDialog("Wait for User", "Add ROIs in the ROI manager. Use oval or polygon selection tool. \nClick OK if you are done with your manual work")
print("waiting...")
wud.show()
print("done")

nRois = rm.getCount() # ROIの総数を取得
for k in range(0,nRois):
	redirectImageTitle = "roi_"+ str(k+1)
	maskImageTitle = "mask_" + file + "_ROI-"+ str(k+1)
	
	rm.select(imp, k)
	rm.runCommand("Rename",redirectImageTitle)
	cr = imp.getRoi()  # impにアサインされている楕円または不定形のROIを取得、rm.getRoi()にすると外接する長方形のROIを返す
	imp.setRoi(cr)    # impにcrをアサインし直す, ipにアサインしても同じ結果
	#	ip.setRoi(cr)
	
	random_color = Color(random.random(),random.random(),random.random()) # 0〜1の値でRGBを表す
	#	random_color = Color(int(round(255*random.random())),int(round(255*random.random())),int(round(255*random.random()))) # 0〜255の整数でRGBを表す
	cr.setStrokeColor(random_color)
	
	cr_image = ImagePlus(redirectImageTitle, ip.duplicate()) # crごと複製して、同時にオブジェクトを作成
	cr_image.getProcessor().fillOutside(cr)			# Clear Outside
	
	cr_mask = ImagePlus(maskImageTitle, ip.duplicate())
	cr_mask.getProcessor().fillOutside(cr)
	
#	IJ.run(cr_mask, "Subtract Background...", "rolling=15")
	bs = BackgroundSubtracter()
	bs.rollingBallBackground(cr_mask.getProcessor(), radius, createBackground, lightBackground, useParaboloid, doPresmooth, correctCorners)
	cr_mask.setRoi(cr,True)
	
	stats = IS.getStatistics(cr_mask.getProcessor(), options, imp.getCalibration())
#	print stats
	globalmean = stats.mean
	globalsd = stats.stdDev
	thr = globalmean + 3*globalsd
	
	IJ.setRawThreshold(cr_mask, thr, 255)
	Prefs.blackBackground = True
	IJ.run(cr_mask, "Convert to Mask", "")
	
	# Set the "Redirect To" image
	Analyzer.setRedirectImage(cr_image) 
#	Analyzer.setMeasurements(options2)
	
	rt = ResultsTable()
	p = PA(options_pa, PA.AREA + PA.MEAN + PA.INTEGRATED_DENSITY + PA.FERET + PA.SHAPE_DESCRIPTORS, rt, MINSIZE, MAXSIZE)
#	IJ.run(cr_mask, "Analyze Particles...", "size=0.05-Infinity show=Outlines exclude clear")
	p.analyze(cr_mask)
	# Results Tableにパラメータを追加、全ての行に対してiterate
	nResults = rt.size()	# Tableの行数を取得
	for j in range(0, nResults):
		rt.setValue("date", j, edate)
		rt.setValue("file", j, file)
		rt.setValue("gMean", j, globalmean)
		rt.setValue("gSD", j, globalsd)
		rt.setValue("threshold", j, thr)
	save_result_table(str(dirData),cr_image,rt)
#	rt.show("RT")

	IJ.selectWindow("Drawing of "+maskImageTitle)
	ol = IJ.getImage()
	save_outlines_as_PNG(str(dirDR),cr_image,ol)
	ol.close()