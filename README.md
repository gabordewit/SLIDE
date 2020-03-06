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

## Instructions
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

Common steps to take to get started:
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
-- use the label value to get the technical id
slideToCommand = decodedInfo["slide1"]["id"] -- increment this slidenumber with every slide

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

## Backlog
To simplify the use of the scene/api, this code is under development to include some more features that will follow:
- Simplify individual devices
- Update the slider within the virtual device more frequently
- Automate the generation of global variables by the scene itself;
- validate if holiday mode is on/off
- Make a UI for the routines already available on the devices.
- Automate the generation of a virtual device (if Fibaro allows this )
