(** Rate equations for drug exchange and elimination.

    The model is linear in the drug amounts, so every exchange and elimination
    term can be collected into a single rate matrix [K] (units 1/h):

    {[
    dA / dt = K A
    ]}

    where [A] is the vector of amounts (mg) in each compartment, indexed the
    same way as {!State}.

    - For [i <> j], [K(i,j) >= 0] is the first-order rate constant at which drug
      moves from compartment [j] into compartment [i].
    - [K(i,i) <= 0] is minus the total rate constant at which drug leaves
      compartment [i], whether to other compartments or out of the body.

    Moving drug between compartments conserves mass. Elimination is tracked
    separately so the amount leaving the body can be accumulated in
    {!State.eliminated}.

    A value of type [t] is immutable: the [add_*] functions return a new set of
    dynamics and take [t] last so they can be chained with [|>]:
    {[
    Dynamics.create 4
    |> Dynamics.add_transfer ~from_:0 ~to_:1 18.
    |> Dynamics.add_transfer ~from_:1 ~to_:0 25.
    |> Dynamics.add_elimination 1 0.4
    ]} *)

type t
(** The exchange and elimination rates for a fixed set of compartments. *)

val rates : t -> float array -> float array
(** [rates d amounts] computes the rate of change for each compartment.
    Raises [Invalid_argument] if [amounts] does not have the same dimension
    as [d]. *)

(** {1 Construction} *)

val create : int -> t
(** [create n] is the dynamics for [n] compartments with no exchange and no
    elimination. Raises [Invalid_argument] if [n <= 0]. *)

val add_transfer : from_:int -> to_:int -> float -> t -> t
(** [add_transfer ~from_ ~to_ k d] is [d] plus a first-order transfer from
    compartment [from_] to compartment [to_] with rate constant [k] (1/h).
    Repeated transfers between the same pair add together. Raises
    [Invalid_argument] if an index is out of range, [from_ = to_], or [k] is
    negative or not finite. *)

val add_elimination : int -> float -> t -> t
(** [add_elimination i k d] is [d] plus first-order elimination from compartment
    [i] with rate constant [k] (1/h). For an organ with clearance [cl] (L/h)
    acting on the venous concentration this is
    [k = cl /. (tissue_volume *. kp)]. Raises [Invalid_argument] if [i] is out
    of range or [k] is negative or not finite. *)
