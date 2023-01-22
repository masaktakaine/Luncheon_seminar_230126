macro "analyze_dots_multi_ROI_userinput_batch" {

#@ String(label="Date of experiments, e.g., 2020-08-22") edate1
#@ File (label="Choose source Folder", style="directory") dirS0
#@ File (label="Choose destination Folder", style="directory") dirD0
#@ String(label="Hide/Show the active image? The Show slows the analysis.", choices={"hide","show"}, style="radioButtonHorizontal") sbm

setBatchMode(sbm); // hides the active image, required ImageJ 1.48h or later
dirS = dirS0 + File.separator; // File.separatorはOSに応じたファイル区切り文字に対応
dirD = dirD0 + File.separator;
File.makeDirectory(dirD);
dirDR = dirD + edate1 + "_Drawings" + File.separator; //Create a folder for mask images and ROI data
File.makeDirectory(dirDR);			//
dirData = dirD + edate1 + "_data" + File.separator;
File.makeDirectory(dirData);
imagefilelist = getFileList(dirS);

for (i = 0; i < imagefilelist.length; i++) {
  currFile = dirS + imagefilelist[i];
    if((endsWith(currFile, ".nd2"))||(endsWith(currFile, ".oib"))||(endsWith(currFile, ".zvi"))) { // process if files ending with .oib or .nd2, or .zvi
		run("Bio-Formats Macro Extensions"); 
		Ext.openImagePlus(currFile)}
	else if ((endsWith(currFile, ".tif"))||(endsWith(currFile, ".tiff"))) {// process if files ending with .tif or .tiff (hyperstack files)
			open(currFile); 
		}
print("\\Clear"); 

originalImageTitle = getTitle();
// Remove the extension from the filename
title_s = replace(originalImageTitle, "\\.tif", "");
//title_s = replace(title_s, "\\.tiff", "");

run("ROI Manager...");
roiManager("Show All");
roiManager("Show All with labels");
roiManager("reset");						// Reset ROI manager
waitForUser("Add ROIs in the ROI manager. Use oval or polygon selection tool");

for(k=0; k<roiManager("count"); k++) {   // Activate and analyse a ROI one by one
redirectImageTitle = "roi_"+ k+1;
maskImageTitle = "mask_" +title_s + "_ROI-"+ k+1;
resultsTitle = "Results_" + title_s + "_ROI-" + k+1;

run("Set Measurements...", "area mean integrated redirect=None decimal=3"); // Reset redirection (otherwise couses error)
selectWindow(originalImageTitle);
slicelabel = getInfo("slice.label");
slicenum = getSliceNumber();
roiManager("Select", k);
roiManager("Rename", redirectImageTitle);
Roi.setStrokeColor(255*random,255*random,255*random);
run("Duplicate...", "title=&redirectImageTitle");

run("Duplicate...", "title=&maskImageTitle");
run("Subtract Background...", "rolling=15");  // Important step to detect fine fluorescent condensates
run("Clear Outside");  // Remove signal outside the cell (ROI)

selectWindow(maskImageTitle);
//raw_globalmean = getValue("Mean raw");
//raw_globalmedian = getValue("Median raw");
//raw_globalmode = getValue("Mode raw");
//raw_globalsd = getValue("StdDev raw");
//run("Subtract Background...", "rolling=20 disable");
globalmean = getValue("Mean raw");
globalmedian = getValue("Median raw");
globalmode = getValue("Mode raw");
globalsd = getValue("StdDev raw");

// The intensity threshold is determined as the mean intensity plus 2 times the standard deviation of the image.
threshold = globalmean + 2*globalsd;

setThreshold(threshold, 65535, "raw");
setOption("BlackBackground", true);
run("Convert to Mask");
//resetThreshold();

run("Set Measurements...", "area mean integrated redirect="+redirectImageTitle+" decimal=3");

selectWindow(maskImageTitle);
run("Analyze Particles...", "size=0.1-500 circularity=0.1-1.00 show=Outlines display exclude clear overlay");
if (nResults !=0) {  // if particles were detected
for(l=0; l<nResults; l++) {
	setResult("GlobalMean",l, globalmean);
	setResult("GlobalSD",l,globalsd);
	setResult("Threshold",l,threshold);
	setResult("file",l,title_s);
	setResult("SliceLabel",l,slicelabel);
	setResult("SliceNumber",l,slicenum);
	setResult("ROI",l,redirectImageTitle);		
}} else{ // if no particels were detected
	setResult("Area", 0, "NaN");
	setResult("Mean", 0, "NaN");
	setResult("IntDen", 0, "NaN");
	setResult("RawIntDen", 0, "NaN");
	setResult("GlobalMean",0, globalmean);
	setResult("GlobalSD",0,globalsd);
	setResult("Threshold",0,threshold);
	setResult("file",0,title_s);
	setResult("SliceLabel",0,slicelabel);
	setResult("SliceNumber",0,slicenum);
 	setResult("ROI",0,redirectImageTitle);	
}

outlineImageTitle = "Drawing of "+maskImageTitle;
selectWindow(outlineImageTitle);
saveAs("Tiff", dirDR +"outline_" + maskImageTitle);
close();
saveAs("Results", dirData + resultsTitle + ".csv");
run("Clear Results");
selectWindow(originalImageTitle);
close("\\Others");
}
selectWindow("Results");
run("Close");
run("Close All");	
    run("Clear Results");						// Reset Results window
	print("\\Clear"); 							// Reset Log window
}
roiManager("reset");						// Reset ROI manager
}