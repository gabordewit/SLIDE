# SLIDE
Fibaro SLIDE integration (attempt)

## Introduction
To use this particular slide integration with Fibaro you need:
- A working and connected slide;
- An account for your slide (and your password)
- Some basic fibaro tweaking skills

This skill is intended to work as an internal API (leveraging a scene) that can be used to perform actions on a slide. The main API's used by this skill are the ones to request a token, get the information that is applicable to your slide, and manipulating your actual slide (e.g. closing/opening).

The basic features supported are:
- performing dry-runs to see if your credentials are okay and your household is properly provisioned
- requesting tokens on behalve of your user
- opening/closing your slide
- use a slider to set custom values for open and close (e.g. partially open)

## Quick Instructions (see more detailed step by step approach below)
To get your Fibaro skill up and running head over to the scene section and create yourself  a new scene. Name your scene and use a notepad to list the scene ID. Next head over to the parts of the code that you need to adjust to suit your situation and your credentials.:

```
-- set userdata for SLIDE api including URL.
userName = "INSERT YOUR OWN EMAIL HERE - YES THE QUOTES NEED TO STAY BEFORE AND AFTER"
password = "INSERT YOUR OWN PASSWORD HERE - YES THE QUOTES NEED TO STAY BEFORE AND AFTER"
slideApiUrl = "https://api.goslide.io/api"
```
When the userdata has been set and you want to  get going, head over to devices and import the example VFIB file to get the basics behind the way in which the virtual device calls the scene and how the device itself is dynamically provisioned. For this to work it's important to do a dry run on the scene (instructions below) and to create three global variables in the panel section of Fibaro. Just create blank ones for the first two - they will be filled by the scene- but insert the scene id for the newly create code in the variable for slidescene. So create scene, remember scene id, and then insert that scene id in the value when creating a global variable called Slidescene

The following variables needs to be created to comply to the scene's storing syntax:
- Slidetoken
- Slides
- Slidescene

The variables will hold your slide's information and filled by the Fibaro skill, if you're curious what the data that is in there contains head over to the Scene's Lua code so you can see what's  in there (and which other features are possible).

## Dry runs and debug
Within the scene there are options for debugging and performing a dry run to see if your credential are okay and if I've done a proper job of creating a working scene. Head over to the following section to tweak these settings:
```
--set environment variables that can be used to switch logger on/off.
debug = true                   -- This section will ensure you see debug printed to fibaro's console;
dryrun = true                  -- This section will let you perform a dryrun to get a token retrieve your household info;
testIndividualSlide = true     -- If you know your slide's ID (e.g. you have performed a houshold call) you can try to call one;
slideIdToTest = 1867           -- insert the slideID (the number can be found in the household call)
slideCommandToTest = "close"   -- Insert an option here, for testing insert either "close" / "open" to see if it works

```
When you've done this and have set a dryrun, you can start the dryrun by running the debug. After this it's time for the real stuff and start in Fibaro, the following steps are needed:

Create a global variable:
- Slidetoken
- Slides
- Slidescene

Common steps to take to get started (see detailed step by step further down below):
- set the dryrun in the scene to false (see above) to ensure the scene actually stores information in global variables
- insert the scene id of the slide api into the variable 'Slidescene' in the fibaro panel section;

Option 1 - Creating a household based virtual device for all slides
- import vfib with the name All_slides.vfib in the virtual device section
- adjust the amount of slides in the virtual device to the amount you actually have connected and registered to the cloud api of slide
- Insert the artwork for the individual states of the slide
- start initialization of the virtual device by pressing the associated button name
- wait for 5 seconds (the roundabout time of the login and household call) for the virtual device fields to be filled and the sliders to be filled with the status of the individual slide.

This means you can  import the VFIB and adjust the amount of slides to the slides you have in your house. If you have three devices associated to your home, create three slide labels + open/close buttons. As the example includes two slides validate the syntax they are using to see if you can simply copy one example to the new device (typically this would be a yes). In general the initialization button will loop through all of the slides the SLIDE API will return and create associated labels in the virtual devices so you can actually recognize your slides by their respective friendly names. The global variable in which the Slidescene is referred to will ensure the right api's are called.

Option 2 - creating individual slides
- import vfib with the name Single_slide.vfib in the virtual device section
- for the first device you import keep the code of the labels as is
- for the subsequent devices it's important to validate and change the syntax:
```
-- On the On / OFF / Slider buttons  change:
-- list slidenumber here
slideToCheck = 'slide1' -- increment this slidenumber with every slide

```
```
-- On the initialize and main loop change:
-- list slidenumber here
slideToCheck = 'slide1' -- increment this slidenumber with every slide

```
- Insert the artwork for the individual states of the slide
- You can try to initialize a single slide to see if it works, if you have more slides than the subsequent virtual devices should be straightforward to add. 
- wait for 5 seconds (the roundabout time of the login and household call) for the virtual device fields to be filled and the sliders to be filled with the status of the individual slide.

The individual slide option is a little bit more work as you need to adapt N amount of devices (e.g. if you have three slides you need to adopt and adapt three virtual devices).

## Detailed Step by step instructions (Thank you Frank)
1.	Download all files as .zip by pressing on the “clone or download” button and extract them
2.	Make a new scene in Fibaro, the actions in it do not matter. This can be done with graphical blocks if you prefer. Write down the id (can be found in the “general” tab).
3.	Go to the “advanced” tab and switch to lua. 
4.	Copy all the code from slide_scene.lua to the area below “advanced”. Overwrite existing code if it is there
5.	Fill in your Slide emailadress and password in line 39 and 40 in the lua-code
6.	Go to “Panels” and click on “variables”
7.	Click on “add variable” and enter “Slidetoken”. Leave the value at 0.
8.	Do the same for “Slides”.
9.	Do the same for “Slidescene” but enter here as value the nr you wrote down as scene id at step 2.
10.	Go to back to the scene and adjust the code in line 27-30 as mentioned below. Press save.
11.	You are now going to execute a dryrun. This will deliver you with id(‘s) of the Slide(s) in your household. Press “start”.
12.	In the area below the start button white text will appear. All the way to the bottom you will find your Slide id(s), after the text ID found xxxx. 
13.	Now it is time to test if everything works ok. Make sure your Slide is open. Take one of the id’s and enter it in line 29. Change the command in line 28 (testIndividualSlide) to “true”. Save and press start again. The Slide should close now.
14.	If that is working, change the value of testIndividualSlide back to “false” and also change the value of line 27 dryrun to “false”. Press save.
15.	Make sure the scene is “on”.
16.	Go to the Devices tab and click on “add device”. 
17.	In the section “Add virtual device”, click on import file and import the file “single_slide.vfib”.
18.	Fibaro directly should recognize your Slide.
19.	If you want to add more than one Slide, follow the same procedure. However, after importing go the tab “advanced”. Under Label enter the value to Slide 2. (and 3 if you want to add another Slide after this one, and so on) 
20.	In the code under “button”, change slideToCheck = 'slide1'  to slideToCheck = 'slide2'  (and 3 if you want to add another Slide after this one, and so on) 
21.	Do the same at “close” and “curtain rail”
22.	At “Initialize, change slideToCheck = 'slide1' to slideToCheck = 'slide2' (and 3 if you want to add another Slide after this one, and so on) 
23.	Do the same at “main loop”.
24.	Save.
25.	Now you can add the custom icons, per slide. Go to the advanced tab of one of the Slides and click on “change icon” at the “Open” button.
26.	Add the icon you want to use by importing it (bottom of the screen). Then click on the icon in the list. Save.
27.	Do the same for the other buttons.
28.	In case you have more than 2 slides and plan to invoke them from Fibaro at the same time (e.g. multiple virtual devices trying to trigger the scene at the same tiime), please read on.
29. To be able to have more than 2 Slides running from Fibaro at the same time go to "General" in the scene.
30. Set the "Max. running instances:" to the amount of Slides you want to run at the same time.
31. Press "Save" and you're all set.

## Backlog
To simplify the use of the scene/api, this code is under development to include some more features that will follow:
- Update the slider within the virtual device more frequently
- Automate the generation of global variables by the scene itself;
- validate if holiday mode is on/off
- Make a UI for the routines already available on the devices.
- Automate the generation of a virtual device (if Fibaro allows this )
