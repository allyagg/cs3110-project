type t = {
  dose_mg : float;
  drug_SMILES : string;
  duration_h : float;
  step_h : float;
  patient_heart_rate_bpm : float;
  patient_height_m : float;
  patient_weight_kg : float;
  patient_sex : string;
}

let of_fields fields =
  let field id label =
    match List.assoc_opt id fields with
    | Some value when String.trim value <> "" -> String.trim value
    | _ -> invalid_arg (label ^ " is required.")
  in
  let number id label =
    match float_of_string_opt (field id label) with
    | Some value when Float.is_finite value -> value
    | _ -> invalid_arg (label ^ " must be a finite number.")
  in
  try
    let c =
      {
        dose_mg = number "dose" "Dose";
        drug_SMILES = field "drug-smiles" "Drug SMILES";
        duration_h = number "duration" "Duration";
        step_h = number "step" "Time step";
        patient_heart_rate_bpm = number "patient-heart-rate" "Heart rate";
        patient_height_m = number "patient-height" "Height";
        patient_weight_kg = number "patient-weight" "Weight";
        patient_sex = String.uppercase_ascii (field "patient-sex" "Patient sex");
      }
    in
    if c.dose_mg < 0. then invalid_arg "Dose must be zero or greater.";
    List.iter
      (fun (value, label) ->
        if value <= 0. then invalid_arg (label ^ " must be positive."))
      [
        (c.duration_h, "Duration");
        (c.step_h, "Time step");
        (c.patient_heart_rate_bpm, "Heart rate");
        (c.patient_height_m, "Height");
        (c.patient_weight_kg, "Weight");
      ];
    if c.step_h > c.duration_h then
      invalid_arg "Time step cannot exceed duration.";
    if c.duration_h /. c.step_h > 100_000. then
      invalid_arg "Choose settings with at most 100,000 steps.";
    if not (List.mem c.patient_sex [ "M"; "F"; "X" ]) then
      invalid_arg "Patient sex must be M, F, or X.";
    Ok c
  with Invalid_argument message -> Error message

let summary c =
  Printf.sprintf
    "Dose: %g mg\n\
     Drug SMILES: %s\n\
     Duration: %g h\n\
     Time step: %g h\n\
     Patient sex: %s\n\
     Weight: %g kg\n\
     Height: %g m\n\
     Heart rate: %g bpm"
    c.dose_mg c.drug_SMILES c.duration_h c.step_h c.patient_sex
    c.patient_weight_kg c.patient_height_m c.patient_heart_rate_bpm
