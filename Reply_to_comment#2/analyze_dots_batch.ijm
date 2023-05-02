macro "analyze_dots_batch" {
#@ String(label="Date of experiments, e.g., 2020-08-22") edate1
#@ File (label="Choose source Folder", style="directory") dirS0
#@ File (label="Choose destination Folder", style="directory") dirD0
#@ String(label="Hide/Show the active image? The Show slows the analysis.", choices={"hide","show"}, style="radioButtonHorizontal") sbm

setBatchMode(sbm); // hides the active image, required ImageJ 1.48h or later
dirS = dirS0 + File.separator; // File.separatorはOSに応じたファイル区切り文字に対応
dirD = dirD0 + File.separator;
edate = " "+edate1; // Insert a blank to prevent automatic modification on Excel.

dirData = dirD + edate1 + "_data";
File.makeDirectory(dirData);
dirDR = dirD + edate1 + "_Drawings";				//Create a folder for mask images and ROI data
File.makeDirectory(dirDR);			//

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
title_s = replace(originalImageTitle, "\\.nd2", ""); 
title_s = replace(title_s, "\\.tif", "");
title_s = replace(title_s, "\\.tiff", "");

run("Duplicate...", "title=Mask"); //Duplicate and rename
selectWindow("Mask");
run("Subtract Background...", "rolling=20 disable");
globalmean = getValue("Mean raw");
globalsd = getValue("StdDev raw");

// The intensity threshold is determined as the mean intensity plus 3 times the standard deviation of the image.
threshold = globalmean + 3*globalsd;
setThreshold(threshold, 255, "raw");  // for 8-bit image
//setThreshold(threshold, 65535, "raw");  // for 16-bit image
setOption("BlackBackground", true);
run("Convert to Mask");
resetThreshold();

// Detection of condensates
run("Set Measurements...", "area mean min centroid shape integrated redirect=None decimal=3"); 
run("Analyze Particles...", "size=0.04-500 circularity=0.1-1.00 show=[Bare Outlines] exclude clear add");
//waitForUser;
selectWindow(originalImageTitle);
roiManager("Show None");
roiManager("Show All");
roiManager("Measure");

selectWindow("Drawing of Mask");
run("From ROI Manager");
//run("Hide Overlay");
saveAs("Tiff", dirDR + File.separator + "Drawing of " + title_s);
close();

selectWindow("Results");
for(k=0; k<nResults; k++) {   
 setResult("date",k,edate);
 setResult("file",k,title_s);
 setResult("gMean",k, globalmean);
 setResult("gSD",k,globalsd);
 setResult("threshold",k,threshold);				
}
saveAs("Results", dirData + File.separator + title_s + ".csv"); 
run("Close");
	run("Close All");	
    run("Clear Results");						// Reset Results window
	print("\\Clear"); 							// Reset Log window
	roiManager("reset");						// Reset ROI manager
}}
