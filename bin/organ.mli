## organ.ml should pull hard coded information from tissue_data.ml and 
## it should calculate the partition coefficient of the user specified 
## drug into the organ. 

## use the Rodgers–Rowland model for estimating the partition coefficient
## I have notes on this from a drug delivery course that I can send!

## look at tissue_data.csv for preliminary information on what that info struct looks like

let coefficients =
  predict_partition_coefficients drug_properties tissue_table

