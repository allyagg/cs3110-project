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