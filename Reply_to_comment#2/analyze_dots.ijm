macro "analyze_dots" {
originalImageTitle = getTitle();
run("Duplicate...", "title=Mask"); //Duplicate and rename
selectWindow("Mask");
run("Subtract Background...", "rolling=20 disable");
globalmean = getValue("Mean raw");
globalsd = getValue("StdDev raw");

// The intensity threshold is determined as the mean intensity plus 3 times the standard deviation of the image.
threshold = globalmean + 3*globalsd;
setThreshold(threshold, 255, "raw");
setOption("BlackBackground", true);
run("Convert to Mask");
resetThreshold();

// Detection of condensates
run("Set Measurements...", "area mean min centroid shape integrated redirect=None decimal=3"); 
run("Analyze Particles...", "size=0.04-500 circularity=0.1-1.00 show=[Bare Outlines] exclude clear add");

selectWindow(originalImageTitle);
roiManager("Show None");
roiManager("Show All");
roiManager("Measure");
}