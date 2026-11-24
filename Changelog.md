## November 23rd Data Session - Elaine
Added the Data module for time-series results once implemented. Wraps a run's list of States, gives per-compartment amounts over time, and exports to CSV. Added relevant 7 tests to cover x functionality. 

## November 22 ORGAN SESSION - Amanda
Defined types for Organ ML, MLI. Intend to do any val in next update, however wanted to separate the two as to not have any risk of losing data.

## November 22 setup changes - Ally

Reorganized file structure to reflect past assignments. Moved all .ml and .mli files other than main.ml and main.mli into lib/, moved bin/public to project root, created a test folder, and moved data to data folder at project root. Updated file references and dune files to reflect new locations of these files. 

## November 21st State Session - Elaine 
Implemented the State module as an immutable snapshot of each compartment's name, volume, and drug amount, plus current time and total eliminated drug. Concentrations are computed as amount / volume, and total_mass (in body + eliminated) supports mass-conservation checks. Added tests covering State and State + Engine along with hand-checked elimination and mass conservation.

## Novemeber 20th, evening work session – Julia

Implemented a significant portion of main. Created the type for the model configuration and the pattern matching from the user input to the model configuration. Also implemented barebones model parameter asserts and passed the model configuration to that validation function in read user input. next up is implementing the main runner that will open the html file and then wait for the user to click the run button. then run the simulation. 

## November 7-8, mid day work sessions – Julia

Began outlining inputs, parameters, structures that will be passed through the model: 

relevant updates: 

@Amanda (GUI and Organ) the drug should be passed to the user input as a SMILES code. this can be used to turn the chemical structure into information that will be useful for Amanda's organ calculations. We should consider implementing an entire seperate drug.ml file to run these estimations / predictions. There is a C++/python compatible module named RDKit that we could plug into. I am pretty sure Clarkson would be alright with this but we should double check.

@Shannon the dynamics module should be implemented to return the current rate of change for concentration in each organ with a partition coefficient that will be in a column in tissue_data.csv


## November 1, evening work session – Julia


Designed initial proposal and modules. Typed up 1 page project proposal document

The goal of this project is to design a user friendly PBPK model. This package will allow the user to select with organs should be considered, patient body mass, patient blood pressure (?), and other unique parameters.The package will then use a Euler time step implementation acting on a "State" module holding tissue concentrations. The dynamics governing the Euler time steps will be encoded in a "Dynamics" Module that governs how each concentration behaves. 

To simplify, we will hard encode organ specific data and permit the user to select from particular organs. Ideally, we will source an organ tissue parameter database, but otherwise we will make a file encoding this data. 

PBPK modeling additional info: https://pmc.ncbi.nlm.nih.gov/articles/PMC3118302/

I used chat to create a scoping estimate on the project. It estimated 1,200-2,000 lines + 500-900 lines of testing.

## Modules outlined so far: 

A Engine module that advances the simulation doing a Euler time step.

A Model module that connects the user input to the proper set up of equations (this will be a ~configuration, where instances of organs and flows are loaded in according to what the user is interested in.) This will contain the parameters 

A State module that contains the current drug concentrations (all the variables listed in PBPK modeling)

A Dynamics module that contains the equations governing each concentration in State (the matrix of equations in PBPK modeling) and returns the rate to the Engine

An Organ module that pulls data from the data file and contains other information (does it have hepatic clearance, etc)

A testing unit

An Analytics module to graph the concentration trajectories