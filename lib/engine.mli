val rates : Dynamics.t -> float array -> float array
(** [rates dynamics amounts] computes the rate of change for each compartment. *)

val step : Dynamics.t -> float array -> float -> float array
(** [step dynamics amounts dt] advances [amounts] by one Euler step of size
    [dt]. *)

val run :
  Dynamics.t ->
  float array ->
  float ->
  float ->
  (float * float array) list
(** [run dynamics initial_amounts duration step_size] returns the initial state
    and each subsequent state in the simulation trajectory. *)