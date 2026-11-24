(** Immutable snapshot of drug amounts in each compartment at one time.
    Compartment [i] here is compartment [i] in {!Dynamics}. *)

type t

val create : names:string list -> volumes:float list -> float list -> t
(** [create ~names ~volumes amounts] is the state at time 0 with nothing
    eliminated yet. Raises [Invalid_argument] if the lists have different
    lengths or are empty, a name repeats, a volume is not positive, or an
    amount is negative or not finite. *)

val update : time:float -> eliminated:float -> float array -> t -> t
(** [update ~time ~eliminated amounts s] has the same compartments as [s]
    with new values. Raises [Invalid_argument] on a length mismatch. *)

val time : t -> float
val size : t -> int
val names : t -> string list
val index_of : string -> t -> int
(** Raises [Not_found] if no compartment has that name. *)

val amounts : t -> float array
(** A fresh copy of the amounts (mg), so callers cannot change [t]. *)

val concentrations : t -> float array
(** Amount divided by volume for each compartment (mg/L). *)

val eliminated : t -> float
(** Total drug that has left the body so far (mg). *)

val total_in_body : t -> float
val total_mass : t -> float
(** [total_in_body s +. eliminated s]. Constant when mass is conserved. *)
