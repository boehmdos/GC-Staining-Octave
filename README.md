# GC Staining and Substance Maps
See your GC data better! Adds color to gas chromatograms according to their mass spectra (GC Staining). Sorts mass spectra by similarity on a plane (Substance Map).

Please remember to cite our publication if you use staining or substance maps in a scientific paper! The DOI is **10.1016/j.talanta.2025.127541** and the paper is here (Open Access, for free!): https://www.sciencedirect.com/science/article/pii/S003991402500027X?via%3Dihub

![A chromatogram with staining stripes, a substance map, a quantitative substance map](/ExampleFiles/GCStaining.png?raw=true "A stained chromatogram, a susbtance map, a quantitative substance map")

Run the script **"GCStaining.m"** to stain a chromatogram. From the output, the chromatogram can be stained again more quickly with the script **"Restaining.m"**. All other functions are called by these two scripts. Please see the comments in the script for the required and optional variables used in the scripts.

# Prerequisites
To work properly, the script needs all the scripts provided and **a map of mass spectra** (a SOM). An extensive SOM can be downloaded at https://doi.org/10.5281/zenodo.13710838. It is built from spectra available from the MassBank of North America (Mona, used under a CC-BY 4.0 license, https://mona.fiehnlab.ucdavis.edu) and covers a wide range of typical GC analytes. We recommend to save this map as hf5 to load faster when the script is executed.

Gas chromatograms with mass spectra must be saved as text before they can be processed by the script. We use OpenChrom to do this - https://www.openchrom.net/ 

The **expected structure** of the csv with GC data is:

		RT(milliseconds),RT(minutes),Retention Index (not used),m/z of detected masses (integer)

Labelling the columns explicitly in the header is not required.

For example, the first lines of an GC input might look like this (Openchrom adds the " - NOT USED BY IMPORT", this does not affect the script):

		RT(milliseconds),RT(minutes) - NOT USED BY IMPORT,RI,50,51,52, ... ,448,449,450
		
		125508,2.0918,0.0,0.0,0.0,0.0, ... ,0.0,0.0,0.0
		
		125787,2.09645,0.0,0.0,36.170532,36.22905, ... ,0.0,0.0,0.0
		
		126067,2.1011166666666665,0.0,245.98819,0.0,21.675735, ... ,0.0,0.0,0.0
  
  		...

		1080512,18.008533333333332,0.0,0.0,0.0,2.4189453, ... ,0.0,0.0,0.0





# Version Info
  
The script file is written on Octave 3.9.0

It uses following packages (tested on 16/02/2025):

- io


# What's up next

- Speed. This is as fast as we could go with Octave. We know that we can be faster in Matlab using pdist2. When there is time.

- A GUI. When there is time.

# What we dream of

- Reading native files from GC manufacturers
