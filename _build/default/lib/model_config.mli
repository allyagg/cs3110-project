(** Validated user-supplied parameters for a PBPK simulation. *)
type t = {
  dose_mg : float;  (** Initial drug dose in milligrams. *)
  drug_SMILES : string;  (** SMILES representation of the drug. *)
  duration_h : float;  (** Total simulation duration in hours. *)
  step_h : float;  (** Simulation timestep in hours. *)
  patient_heart_rate_bpm : float;  (** Patient heart rate in beats per minute. *)
  patient_height_m : float;  (** Patient height in meters. *)
  patient_weight_kg : float;  (** Patient weight in kilograms. *)
  patient_sex : string;  (** Patient sex, normalized to ["M"], ["F"], or ["X"]. *)
}

(** [of_fields fields] parses and validates form fields by their HTML input
    names. Returns [Ok config] when all required values are valid, or
    [Error message] describing the first validation failure. *)
val of_fields :
  (string * string) list -> (t, string) result

(** [summary config] formats the configuration as a human-readable,
    newline-separated summary. *)
val summary : t -> string