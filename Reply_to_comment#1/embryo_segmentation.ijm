macro "embryo_segmentation" {
run("8-bit");
run("Invert");
run("Subtract Background...", "rolling=35");

setAutoThreshold("Default dark");
//setThreshold(152, 255);
setOption("BlackBackground", true);
run("Convert to Mask");

run("Open");
run("Fill Holes");
run("Adjustable Watershed", "tolerance=2.5");

run("Set Measurements...", "area mean perimeter shape feret's redirect=None decimal=3");
run("Analyze Particles...", "size=20-Infinity show=Outlines display exclude clear");
}
