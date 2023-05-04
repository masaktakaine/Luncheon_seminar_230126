#@ String(label="Date of experiments, e.g., 2020-08-22") edate1
#@ File (label="Choose source Folder", style="directory") dirS0
#@ File (label="Choose destination Folder", style="directory") dirD0
#@ String(label="Hide/Show the active image? The Show slows the analysis.", choices={"hide","show"}, style="radioButtonHorizontal") sbm

from ij import IJ, ImagePlus, Prefs
from ij.process import ImageStatistics as IS
options = IS.MEAN | IS.AREA | IS.STD_DEV  # many others
from ij.gui import Roi
from ij.plugin.frame import RoiManager
from ij.measure import ResultsTable
import os
from os import path

# ドットの解析を関数化
def analyze_dots(imagefile_path):
	imp = IJ.openImage(imagefile_path) 		# Create a ImagePlus object, assign it into imp
	ip = imp.getProcessor() 				# Get its ImageProcessor object
	stats = IS.getStatistics(ip, options, imp.getCalibration())
	file  = os.path.basename(imagefile_path).replace(".tif", "") # パスを含まないファイル名を取得しさらに拡張子を除く
	
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
	
# Results Tableにパラメータを追加、全ての行に対してiterate
	nResults = rt.size()	# Tableの行数を取得
	for j in range(0, nResults):
		rt.setValue("date", j, edate)
		rt.setValue("file", j, file)
		rt.setValue("gMean", j, globalmean)
		rt.setValue("gSD", j, globalsd)
		rt.setValue("threshold", j, thr)

	return imp,imp2,rt  # imp, imp2, rtを返す、実際はタプルでまとめられている (imp, imp2, rt)

# Result Tableをcsvで保存、関数化
def save_result_table(directory,image,result_table):
	title = image.getTitle().split(".")[0]  # ピリオドで分割して、画像の名前を取得
	resultfile = os.path.join(directory, title + ".csv")  # 保存するcsvファイルのパスを作成
	result_table.saveAs(resultfile)

# マスク画像をtif形式で保存、関数化
def save_mask_as_tif(directory, image, mask):
    title = image.getTitle().split(".")[0]
    outputfile = os.path.join(directory, title + "_mask.tif")
    IJ.saveAs(mask, "TIFF", outputfile) # 保存する画像、tiff形式、パスを指定

# Main code
edate = " "+edate1 ## Insert a blank to prevent automatic modification on Excel.
##dirData = str(dirD0)+ os.sep + edate1 + "_data"  ## dirD0の型は最初、java.io.Fileになっているので変換する必要がある、os.depがOS特有のfile separator
dirData = os.path.join(str(dirD0), edate1+"_data") ## os.path.joinを使うと勝手にseparatorを挟む
os.mkdir(dirData)								## フォルダdirDataを作成
dirDR = os.path.join(str(dirD0), edate1+"_Drawings")				##Create a folder for mask images and ROI data
os.mkdir(dirDR)

# os.listdirでファイルのリストを取得、str型にする必要あり
filelist = os.listdir(str(dirS0))
# リスト内包表記、tifファイルだけを抽出する、split(".")でピリオドの前後２つの単語に分かれる、[-1]は後ろの単語（=拡張子）を表す、[1]にしても同じ
tif_files = [f for f in filelist if f.split(".")[-1] == "tif"]

for tif_file in tif_files:
	current_file_path = os.path.join(str(dirS0), tif_file) # ファイルのパスを取得
	results = analyze_dots(str(current_file_path))		# 上記関数で解析、結果をresultsに代入
	imp = results[0]	# 1番目の要素は元画像
	mask = results[1]	# 2番目の要素はマスク画像
	rt = results[2]		# 3番目の要素は結果のテーブル
	save_result_table(str(dirData),imp,rt)
	save_mask_as_tif(str(dirDR),imp,mask)
	
print "Done. \n"
IJ.run("Clear Results")
rm = RoiManager.getRoiManager()
rm.reset()
IJ.run("Close All")
