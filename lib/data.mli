(** Time series of simulation results: one {!State.t} per time step. *)

type t
(** A run's states in time order, all with the same compartments. *)

val of_states : State.t list -> t
(** [of_states l] is the series of [l]. Raises [Invalid_argument] if [l] is
    empty, the times decrease, or the states have different compartment names. *)

val states : t -> State.t list
val length : t -> int
val times : t -> float list

val final : t -> State.t
(** The last state in the series. *)

val amounts_of : string -> t -> float list
(** [amounts_of name s] is the amount (mg) in compartment [name] at each step.
    Raises [Not_found] if there is no such compartment. *)

val to_csv : t -> string
(** Header [time,<name>_mg...,<name>_mg_per_l...,eliminated_mg], then one row
    per state. *)

val save_csv : string -> t -> unit
(** [save_csv path s] writes [to_csv s] to [path], replacing any existing file. *)
