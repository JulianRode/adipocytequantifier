/* version 0.4
 *  This macro is created by Julian Rodefeld of the University of Cologne, Germany.
 *  It is based based on the Adiposoft plugin by Miguel Galarraga (mgalarraga@unav.es), and Mikel Ariz (mikelariz@unav.es) of the Imaging Unit at the Center for Applied Medical Research (CIMA) of the University of Navarra, in Pamplona (Spain)
 *  1: Boqué N, Campión J, Paternain L, García-Díaz DF, Galarraga M, Portillo MP, Milagro FI, Ortiz de Solórzano C, Martínez JA. Influence of dietary macronutrient composition on adiposity and cellularity of different fat depots in Wistar rats. J Physiol Biochem. 2009 Dec;65(4):387-95. PubMed PMID: 20358352.
 *  
*/


//defining all variables that need to be called within functions as global variables
var r=0.46125, d=10, D=200, do_pre_check = true, OutDir = " ", first = true, compare_height = 0, compare_width = 0, DAB = false, prom = 7, multiple = true, batchmode = true;

macro "adipocytequantifier"{
/*
window_list = getList("window.titles");
if(nImages>0||window_list.length>0){
	exit("Please first close all images and windows, since they might interfere with the analysis");
}
*/

//these are the magnification options in ndp.view2, if a different program was used, a custom pixel size probably needs to be entered
mag_choice = newArray("5x","10x","20x","40x","Custom Pixel Size");

//initial dialogue
Dialog.create("Adipocyte-quantifier");
Dialog.addMessage("Choose parameters");
Dialog.addNumber("Minimum diameter:", d);
Dialog.addNumber("Maximum diameter:", D);
Dialog.addChoice("At which digital magnification was the image exported:", mag_choice, "20x");
Dialog.addNumber("Prominence:", prom);
Dialog.addCheckbox("Would you like to quantify multiple images?", multiple);
Dialog.addCheckbox("Quantify DAB?", DAB);
Dialog.addCheckbox("Check validity of data before quantifying?", do_pre_check);
Dialog.addCheckbox("Hide procedure?", batchmode);
Dialog.show();
d=Dialog.getNumber();
D=Dialog.getNumber();
mag_choice = Dialog.getChoice();
prom=Dialog.getNumber();
multiple=Dialog.getCheckbox();
DAB = Dialog.getCheckbox();
do_pre_check=Dialog.getCheckbox();
batchmode=Dialog.getCheckbox();

//check, if Bio-formats importer is available, since that is needed for the pre-checking function
List.setCommands;
if (List.get("Bio-Formats")!="") {
}
else {
	showMessageWithCancel("Error: Requires Other Plug-ins","This macro uses the Bio-Formats plug-in for pre-checking. Either install the Bio-Formats plug-in and run again, or press \"OK\" and the plug-in will run without pre-checking. Press \"Cancel\" to exit the plug-in");
	do_pre_check=false;
}
//convert the chosen magnification from ndp.view2 into pixel sizes
if(mag_choice=="5x"){
	r=1.8450;
}
if(mag_choice=="10x"){
	r=0.9225;
}
if(mag_choice=="20x"){
	r=0.46125;
}
if(mag_choice=="40x"){
	r=0.230625;
}
if(mag_choice=="Custom Pixel Size"){
	Dialog.create("Pixel size");
	Dialog.addNumber("Pixel size [µm]:", 0.00);
	Dialog.show();
	r=Dialog.getNumber();
}

//letting the program run on multiple images in a directory
if(multiple){
	InDir = getDirectory("Choose Input Directory");
	folders = split(InDir, File.separator);
	l = lengthOf(folders);
	OutDir = "";
	
	image_counter = 0;
	current_image_number = 0;
	
	if (do_pre_check){
		print("Checking compatibility of data");
		setBatchMode(true);
		pre_check(InDir);
		setBatchMode(false);
	}
	
	//creating the two tables that will be used to store the quantification results
	Table.create("Total");
	Table.create("Evaluation");
	
	
	
	//creating an output directory right next to the input directory
	for (i = 0; i < l-1; i++) {
		OutDir = OutDir + folders[i] + "\\";
	}
	if(batchmode){
		setBatchMode(true);
	}
	File.makeDirectory(OutDir + File.getNameWithoutExtension(InDir) + " analyzed");
	OutDir = OutDir + File.getNameWithoutExtension(InDir) + " analyzed\\";
	
	print("Started evaluation, please do not close ImageJ");
	
	//starting the evalutation here, this function goes recursively through the folder structure
	listFiles(InDir, OutDir);

}
else{
	Table.create("Total");
	Table.create("Evaluation");
	if(nImages!=0){
		alreadyopened = true;
		OutDir = getDirectory("Choose output location");
	}
	else{
		alreadyopened = false;
		path = File.openDialog("Choose, which file to analyze");
		open(path);
		OutDir = File.directory;
	}
	//If there is only one file, input and output location are the same
	InDir = OutDir;
	openedImage = getTitle();
	//analysis of images with lossy compression is questionable
	if(endsWith(openedImage,".jpg") && do_pre_check){
		showMessageWithCancel("ERROR","The image is a .jpg images, which are not suitable for quantitative image analysis, because they use lossy compression. Please use .tif or .png instead, press \"Cancel\" to exit the macro. Press \"OK\" to ignore");
	}
	if(batchmode){
		setBatchMode(true);
	}
	
	//creating the two tables that will be used to store the quantification results
	Table.create("Total");
	Table.create("Evaluation");
	IJ.renameResults("Results");
	setResult("Evaluation", 0, "Mean cell area [µm^2]");
	setResult("Evaluation", 1, "Standard deviation");
	setResult("Evaluation", 2, "Median cell area [µm^2]");
	setResult("Evaluation", 3, "Area covered [%]");
	setResult("Evaluation", 4, "Number of Cells");
	
	IJ.renameResults("Evaluation");
	selectWindow(openedImage);
	
	//running the analysis
	quantifier(OutDir);
	
	//close the image if it was opened by this macro
	if(!alreadyopened){
		close(openedImage);
	}
	if(batchmode){
		setBatchMode(false);
	}
}

//saving the composite excel lists
selectWindow("Total");
IJ.renameResults("Results");

if(multiple){
	if(DAB){
		//with the name of the directory
		saveAs("Results", OutDir + File.getNameWithoutExtension(InDir)+" DAB"+".csv");
	}
	
	else{
		saveAs("Results", OutDir + File.getNameWithoutExtension(InDir)+" Area"+".csv");
	}
}

else{
	if(DAB){
		//or of the opened image
		saveAs("Results", OutDir + openedImage+" DAB"+".csv");
	}
	
	else{
		saveAs("Results", OutDir + openedImage+" Area"+".csv");
	}
}

close("Results");
selectWindow("Evaluation");
IJ.renameResults("Results");
//and doing the same thing with the summarization
if(multiple){
	saveAs("Results", OutDir + File.getNameWithoutExtension(InDir)+ " Evaluation"+".xls");
}
else{
	saveAs("Results", OutDir + openedImage+ " Evaluation"+".xls");
}

close("Results");
close("Log");
roiManager("reset");
close("ROI Manager");
if(batchmode){
	setBatchMode(false);
}

showMessage("Processing complete");
//code finished

}

//this function enters a folder and calls itself in all subfolders. If it encounters images, it reads the metadata and compares that all images have the same size; and that they are image formats that use lossless compression
function pre_check(dir) {
	list = getFileList(dir);
	L = lengthOf(list);
	
	for (i=0; i<L; i++) {
    	if (endsWith(list[i], "/")) {
    		pre_check(dir+list[i]);
    	}
       	else {
       		if(endsWith(list[i],".tif")||endsWith(list[i],".png")||endsWith(list[i],".tiff")) {
				fname=dir+list[i];
				image_counter++;
				
				run("Bio-Formats Importer", "open=["+ fname+"] autoscale color_mode=Default open_files display_metadata rois_import=[ROI manager] view=[Metadata only] stack_order=Default");
				
				metadata = getInfo("window.contents");
				metadata =split(metadata, "\n");
				
				width = parseInt(replace(metadata[10], "SizeX", ""));
				height = parseInt(replace(metadata[11], "SizeY", ""));
				
				close("Original Metadata - " + list[i]);
				
				if(first){
					compare_width = width;
					compare_height = height;
					first = false;
				}
				else{
					if (width == compare_width && height == compare_height) {
						
					}

					else{
						showMessageWithCancel("ERROR","Resolutions do not match in data set. Image " + list[i] +" in "+ dir + " is different than the other images. Press \"Cancel\" to exit the macro. Press \"OK\" to ignore");
					}
				}
			}
			if(endsWith(list[i],".jpg")) {
				showMessageWithCancel("ERROR","Image " + list[i] " is a .jpg images, which are not suitable for quantitative image analysis, because they use lossy compression. Please use .tif or .png instead, press \"Cancel\" to exit the macro. Press \"OK\" to ignore");
			}
       	}
    }
}


//this function enters a folder, reads all files and calls itself for all files that are folders themselves. For images it calls the quantifier
//it also duplicates the folder structure in the output directory
function listFiles(dir, odir) {
	list = getFileList(dir);
	L = lengthOf(list);
	
	for (i=0; i<L; i++) {
    	if (endsWith(list[i], "/")) {
    		list[i] = replace(list[i], "/", "\\");
      		File.makeDirectory(odir+ list[i]);
      	    listFiles(dir+list[i],odir + list[i]);
      	}
       	else {
       		if(endsWith(list[i],".tif")||endsWith(list[i],".jpg")||endsWith(list[i],".tiff")||endsWith(list[i],".png")) {
				fname=dir+list[i];
				
				
				open(fname);
				openedImage = getTitle();
				quantifier(odir);
				current_image_number++;
				close(openedImage);
				print("Processed image " + current_image_number + "/" + image_counter + ": " + openedImage);
			}
       	}
    }
}


//this is the actual quantifier
function quantifier(output) {

	run("Clear Results");
	roiManager("reset");
	Overlay.remove;
	getDimensions(width, height, channels, slices, frames);
	MyTitle=getTitle();
	
	/*
	else{
		run("Colour Deconvolution", "vectors=[H&E] hide");
		selectWindow(MyTitle + "-(Colour_3)");
		close();
		selectWindow(MyTitle + "-(Colour_1)");
		rename("H");
		selectWindow(MyTitle + "-(Colour_2)");
		close();
	}
	*/
	
	selectWindow(MyTitle);
	run("Duplicate...", "title=luminance");
	
	run("8-bit");
	run("Subtract Background...", "rolling=50 light");
	//run("Enhance Contrast", "saturated=1 normalize"); //This leads to the appearance of microscope artifacts, if the images were taken slightly out of focus. Still works reasonibly well without
	run("Gaussian Blur...", "sigma = 1");
	
	
	//detect the area, where there definitely is tissue, so the local thresholder doesn't try to find local maxima in big white spaces
	run("Duplicate...","title=foreground");
	setAutoThreshold("Percentile dark");
	getThreshold(lower, upper);
	setThreshold(lower*89/90, 255);
	run("Convert to Mask");
	run("Invert");
	//removing small particles
	run("Analyze Particles...", "size=8000-Infinity pixel circularity=0-0.30 show=Masks");
	close("foreground");
	selectWindow("luminance");
	run("Invert");
	//now only apply the local threshold to the spaces where the percentile method also allowed signal
	imageCalculator("and", "luminance", "Mask of foreground");
	close("Mask of foreground");
	selectWindow("luminance");
	
	run("Auto Local Threshold", "method=Mean radius=15 parameter_1=0 parameter_2=0"); //no c-value modification neccessary
	
	run("Invert");
	
	run("Median...", "radius=3");
	run("Options...", "iterations=2 count=1 pad edm=Overwrite do=Nothing");
	run("Open");
	
	//removing small stuff again
	run("Invert");
	run("Analyze Particles...", "size=800-Infinity pixel circularity=0-0.30 show=Masks");
	close("luminance");
	
	selectWindow("Mask of luminance");
	run("Invert");
	
	//seeded watershed algorithm
	run("Duplicate...", "title=ws");
	run("Distance Map");
	run("Find Maxima...", "noise="+prom+" output=[Segmented Particles] light");
	close("ws");
	imageCalculator("AND", "Mask of luminance", "ws Segmented");
	
	//setting the output measurements & converting pixels into microns
	run("Set Measurements...", "area mean median display redirect=None decimal=2");
	selectWindow("Mask of luminance");
	run("Properties...", "channels=1 slices=1 frames=1 unit=um pixel_width="+r+" pixel_height="+r+" voxel_depth="+r+" frame=[0 sec] origin=0,0");
	
		m=PI*pow(d/2,2);
		M=PI*pow(D/2,2);
	
	//this is where the particle recognition happens
	run("Analyze Particles...", "size="+m+"-"+M+" circularity=0.27-1.00 display exclude clear add show=Masks");
	run("Duplicate...", " ");
	//collect measurements of the detected cells
	selectWindow("Results");
	cell_number = nResults;
	areas = Table.getColumn("Area");
	Array.getStatistics(areas, min, max, mean, stdDev);
	areamedian = median(areas);
	areamean = mean;
	area_stdDev = stdDev;
	
	//create a list of the current subfolders inside of the chosen directory
	prev_folders = split(OutDir, File.separator);
	now_folders = split(output, File.separator);
	for (i = 0; i < lengthOf(prev_folders); i++) {
		now_folders=Array.deleteValue(now_folders, prev_folders[i]);
	}
	
	//selectWindow("Mask of luminance");
	//run("Duplicate...", " ");
	
	
	//now creating a mask of all the area surrounding selected cells
	
	//This creates the space around all particles, not just the detected ones
	selectWindow("Mask of luminance");
	run("Duplicate...", "title=borders");
	run("Invert");
	
	//creating an image that only has the space around all individual particles with separating lines between the border spaces
	selectWindow("ws Segmented");
	run("Duplicate...", "title=rim");
	run("Invert");
	run("Dilate");
	imageCalculator("or", "borders", "rim");
	close("rim");
	imageCalculator("and", "borders", "ws Segmented");
	close("ws Segmented");
	
	//this makes an image of all particles that were not picked
	imageCalculator("xor", "Mask of Mask of luminance", "Mask of luminance");
	
	//filling all holes that were not recognized as cells in the border image
	imageCalculator("or", "borders", "Mask of Mask of luminance");
	close("Mask of Mask of luminance");
	
	
	//creating an image with the borders of all particles being assigned the number of the ROI they will have later
	selectWindow("borders");
	run("Analyze Particles...", "size=0-Inf circularity=0-1.00 show=[Count Masks] include");
	rename("count masks");
	max = getValue("Max");
	//makes an image with only the ID's of the particles left that were recognized as cells
	
	selectWindow("Mask of Mask of luminance-1");
	run("Divide...", "value=255");
	run("16-bit");
	imageCalculator("multiply", "count masks", "Mask of Mask of luminance-1");
	close("Mask of Mask of luminance-1");
	selectWindow("count masks");
	//all IDs that are not here are added to the list of ROIs that will be deleted later (so we only collect the stain values of cells and not of junk)
	delete_ROIs = newArray();	
	getHistogram(values, counts, max, 0, max);
	for (i = 1; i < lengthOf(values); i++) {
		if (counts[i]==0){
			delete_ROIs = Array.concat(delete_ROIs,i-1);
		}
	}
	close("count masks");
	selectWindow("borders");
	//creating the corresponding ROIs over the cell membranes (borders) (they need to include holes because otherwise the labeling order is different from the count mask command
	run("Analyze Particles...", "size=0-Inf circularity=0-1.00 show=Nothing display clear add include");
	//deleting all ROIs not belonging to cells
	roiManager("select", delete_ROIs);
	roiManager("delete");
	//all cells left are drawn onto a new image
	newImage("x", "8-bit", width, height, slices);
	
	roiManager("show all");
	roiManager("fill");
	run("Invert");
	run("Divide...", "value=255");
	//and we only use the cell membranes
	imageCalculator("multiply", "x", "borders");
	close("borders");
	run("Invert");
	//now the ROIs of only the cell membranes are created
	run("Analyze Particles...", "size=0-Inf circularity=0-1.00 clear add composite");
	close("Results");
	
	
	//Check the area covered by the analysis
	run("Analyze Particles...", "include summarize");
	coverage = Table.get("%Area", 0);
	close("Summary");
	close("x");
	
	//putting all the general information of this image into the summary spreadsheet
	selectWindow("Evaluation");
	IJ.renameResults("Results");
	y = nResults;
	setResult("Image Name", y, MyTitle);
	setResult("Folders", y, String.join(now_folders));
	setResult("Area mean [µm^2]", y, areamean);
	setResult("Standard deviation", y, area_stdDev);
	setResult("Area median [µm^2]", y, areamedian);
	setResult("Coverage [%]", y, coverage);
	setResult("Cell number", y, cell_number);
	IJ.renameResults("Evaluation");
	
	
	if(DAB){
		
		selectWindow(MyTitle);
		//create an 8-bit image of those colours that belong to the DAB stain
		run("Colour Deconvolution", "vectors=[H DAB] hide");
		close(MyTitle + "-(Colour_3)");
		close(MyTitle + "-(Colour_1)");
		selectWindow(MyTitle + "-(Colour_2)");
		run("Invert");
		
		rename("DAB");
		//loads the ROIs of the membranes onto the image
		roiManager("Show All with labels");
		roiManager("Show All");
		
		//checks how brown the membranes are
		roiManager("measure");
		results = Table.getColumn("Mean");
		close("Results");
		close("DAB");
		
		//adds a column to the detailed spreadsheet with the brownness of every individual detection
		selectWindow("Total");
		IJ.renameResults("Results");
		Table.setColumn(MyTitle + " " + String.join(now_folders) , results);
		IJ.renameResults("Total");
	}
	
	if(!DAB){
		//for just area analysis it adds the area of all detections to the growing list of areas, with the saved location and the image title
		selectWindow("Total");
		IJ.renameResults("Results");
		n=nResults;
		
		for (i = 0; i < lengthOf(areas); i++) {
			setResult("Label", n + i, MyTitle);
			setResult("Folders", n + i, String.join(now_folders));
			setResult("Area", n + i, areas[i]);		
		}
	
		
		IJ.renameResults("Total");
		selectWindow("Mask of luminance");
		
		run("Analyze Particles...", "size="+m+"-"+M+" circularity=0.27-1.00 exclude clear add");
	}
	close("Mask of luminance");
	//saves a .jpg of an overlay of the ROIs on the original image
	selectWindow(MyTitle);
	
	run("Duplicate...", "title=v");
	roiManager("Show All without labels");
	run("From ROI Manager");
	run("Flatten");
	saveAs("Jpeg",output + "\\" + MyTitle + "analyzed");
	
	close("v");
	close("v-1");
}

//function to calculate the median of an array (Volko Straub on image.sc)
function median(x){
	x=Array.sort(x);
	if (x.length%2>0.5) {
		m=x[floor(x.length/2)];
	}else{
		m=(x[x.length/2]+x[x.length/2-1])/2;
	};
	return m
}