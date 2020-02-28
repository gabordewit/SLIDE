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

## Instructions
To get your Fibaro skill up and running head over to the scene section and create yourself  a new scene. Name your scene and use a notepad to list the scene ID. Next head over to the parts of the code that you need to adjust to suit your situation:

```
-- set userdata for SLIDE api including URL.
userName = **"INSERT YOUR OWN EMAIL HERE - YES THE QUOTES NEED TO STAY BEFORE AND AFTER"**
password = **"INSERT YOUR OWN PASSWORD HERE - YES THE QUOTES NEED TO STAY BEFORE AND AFTER"**
slideApiUrl = "https://api.goslide.io/api"
```
When the userdata has been set and you want to  get going, head over to devices and import the example VFIB file to get the basics behind the way in which the virtual device calls the scene and how the device itself is dynamically provisioned. For this to work it's important to do a dry run on the scene (instructions below) and to create three global variables in the panel section of Fibaro. Just create blank ones, they will be filled by the scene.

The following variables need to be created to comply to the scene's storing syntax:
- Slidetoken
- Slides
- Slidehousehold

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