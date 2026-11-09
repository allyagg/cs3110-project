### run gui

###    After gui recieves user info we have
###               patient_gender 
###               patient_average_heart_rate     
###               patient_weight
###               patient_height      

### model configuration will take 
###               patient_gender 
###               patient_bpm     
###                  patient_gender => stroke volume
###                  patient_bpm * stroke volume = blood flow rate -> variable to pass to engine
###               patient_weight
###                  estimate patient organ volumes -> tissue_data
###               patient_height 
###                  estimate patient vascular lengths -> tissue_data            

### call organ module on gui user infromation, tissue_data to create intial_organ_states
###               estimate logP of DRUG (this could be done in a seperate module)
###               Rodgers–Rowland for drug and each organ => partition_coefficient
###               fill in organ information partitioning information into tissue_data.
###               dynamics will use tissue_data 

### place initial_organ_states into time_series_data.csv 
### call engine "on" time_series_data.csv with current_rates (see below)
### engine could lowk be built into main and call dynamics, engine would be very 
### lightweight and essentially just coordinate between dynamics and time_series_data

### at each time step dynamics should be called on the recent time step data and 
### return an array from j-flow rates for each organ (and blood)
### this rate will be used with the current concentrations state to generate the next time point 

### run analysis and return graphs to user (along with exportable file?)