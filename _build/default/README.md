# cs3110-project

Team 58, PBK modeling 

Members: Ally, Amanda, Elaine, Julia, Shannon

### Project Proposal
We propose building a user-friendly physiologically based pharmacokinetic (PBPK) simulator in OCaml. The program will let users explore how a drug moves between blood and organ compartments and how changes to an experiment affect drug exposure over time. Our initial scope is organ-level distribution and elimination, using a small collection of documented parameters and a simplified circulation model. The project will combine a configurable mathematical simulation with saved experiments, result analysis, and clear module interfaces.

A user will begin through a command-line interface by configuring the experiment. They will choose from supported organ configurations, enter body mass, select a supplied drug preset, and specify initial drug amounts, simulation duration, and time-step size. Our scope goal is to at least have a configuration that will include blood, liver, kidneys, and a remaining-tissues compartment. These organs are the most dominant factors on clearance. 

After running an experiment, the user will be able to visually inspect concentration changes in each compartment, peak concentrations, and cumulative exposure via the graphing unit. Saved configurations will make experiments reproducible, while CSV exports will allow users to plot and inspect the full time series. The engine might accept a previously saved state, allowing users to continue a simulation instead of always starting with a new dose.

The implementation will separate biological assumptions from numerical execution. An Organ/Data module will load curated organ and drug records. A Model module will assemble fixed compartment parameters and blood flows. A State module will hold immutable snapshots of drug amounts, with concentrations calculated from compartment volumes. A Dynamics module will encode the exchange and elimination equations as a rate matrix. The Engine will evaluate those rates and advance the state using explicit Euler steps. Analysis and export functions will turn the resulting trajectory into useful summaries. OCaml interfaces will hide internal representations, while private mutation inside the engine will support time stepping and result collection without changing saved snapshots.

To keep the project feasible, we will begin with local data files, fixed parameters during each run, and a single drug preset. Receptor binding, cell signaling, live database integration, and a graphical interface are possible extensions. Tests will cover parameter validation, known small-system behavior, conservation of drug mass with elimination accounted for, and agreement as the time step decreases.

Alternative project

If sourcing defensible biological parameters becomes impractical, we would build an OCaml reaction-network simulator. Users would define chemical species, initial amounts, and reactions with rate constants, then run, save, and compare simulations. This alternative preserves our interest in mechanistic modeling while using self-contained example networks, avoiding dependence on organ databases or external plotting libraries.

### Proposed Architecture
**GUI**: Will make a sketch and summary of GUI coding in OCaml   
**Engine**: A compilation that takes a hand off from State and hand off from Dynamics and returns the State one time step advanced 
**Model**: A compilation unit that takes the hand off from the user interface and constructs the appropriate compartment model. This module should also initialize the t=0 state.   
**Organ**: Component that will take the data.   
**Dynamics**: This component will calculate the rates of change for the Euler engine. The rate of change will be broken down into different terms that will be active or inactive depending on the instance of the model.   
**State**: Create a snapshot of drug amounts in each compartment; design the components of state and coordinate with Engine/Model. First organ implementation (liver, kidney, etc) → what operations / data each organ can possess. Create an organ type in the organ module that has a field for organ specific parameters (which other organs it connects to, partition coefficient). 
**Analysis/Export**: Visualizes the time series data and hands it back off to the GUI 
**Data**: Will hold the time series data  



