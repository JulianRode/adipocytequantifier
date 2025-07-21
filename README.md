# adipocytequantifier
A FIJI macro to quantify adipocytes in H&amp;E images. A modified version of Adiposoft created by Miguel Galarraga (mgalarraga@unav.es), and Mikel Ariz (mikelariz@unav.es) of the Imaging Unit at the Center for Applied Medical Research (CIMA) of the University of Navarra, in Pamplona (Spain).

Original Adiposoft:
Boqué N, Campión J, Paternain L, García-Díaz DF, Galarraga M, Portillo MP, Milagro FI, Ortiz de Solórzano C, Martínez JA. Influence of dietary macronutrient composition on adiposity and cellularity of different fat depots in Wistar rats. J Physiol Biochem. 2009 Dec;65(4):387-95. PubMed PMID: 20358352

---
What is different to Adiposoft:
adipocytequantifier manages folders recursively and retains subfolder structure in output.
Added a file-type check, to ensure usage of images with lossless compression.
Test for equal image size.
Use mean local thresholding after an initial foreground/background differentiation.

---
Running the macro:
Move the macro “Adipocyte quantifier“ from “Z:\Software“ into the into fiji.app>macros>toolsets on your computer. If there is no macro/toolsets folder within fiji.app, you can create one yourself.
Start ImageJ/FIJI. You can now find all macros in the toolset folder when clicking on the two red arrows pointing to the right.
After clicking on the macro in this pop-up menu, it is installed for the current session and can be run from Plugins>Macros in the taskbar.
Or you can ignore all that and drag the file of the macro into ImageJ. The script will open and you can run it with “ctrl + R”.

---
Macro settings:
The diameter restraints of 10 µm-200 µm works well for all my images.
Adjusting the prominence affects, how confidently cells need to be detected for them to be recognized. A prominence of 3 detects almost all cells but might give false positives if the tissue is ambiguous. Choosing a prominence of 7 results in a more conservative cell detection.
Select the pixel size magnification you used when exporting the image (so commonly 20x). If you can’t find your magnification or you did not use ndp.view2 to create your .tif file, first Find out your pixel size!
If you only want to quantify a single image, the macro will check if there currently is an image opened and quantify this. If you do not have open images you can select one upon clicking “OK”.
When quantifying multiple images you will be prompted to select the top directory in which all other images are saved upon clicking “OK”.
Keep “Check validity of data before quantifying?” checked, because it ensures that your images are suitable for a quantitative analysis.
If you check the box “Quantify DAB?” the macro will output the average optical density of the DAB-stain of the cytosol instead of the size of the cells. 
I recommend keeping the box “Hide procedure” checked, except if you want to watch all images being opened and modified. This takes longer & if you work on your computer during this time you might interrupt the macro.
The macro will output the analysed images in a folder structure identical to the input and create two excel files. One has the raw quantification output (cell area or average optical density of DAB) of every detected cell and the one called evaluation has a summary of every image, including the mean cell area and how many cells were detected in each image.

---
Use the R script adipocytequantifier.R to create polished graphs.