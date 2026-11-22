
(* engine.ml *)

(* Calculate the rate of change of drug amounts. *)
let rates (dynamics : Dynamics.t) (amounts : float array) =
  Dynamics.rates dynamics amounts


(* Advance the simulation by one Euler timestep. *)
let step dynamics amounts dt =
  if not (Float.is_finite dt) || dt <= 0. then
    invalid_arg "Engine.step: timestep must be positive and finite";

  let change = rates dynamics amounts in

  Array.mapi
    (fun i amount -> amount +. dt *. change.(i))
    amounts


(* Run the simulation and return the full trajectory. *)
let run dynamics initial_amounts duration step_size =

  if not (Float.is_finite duration) || duration < 0. then
    invalid_arg "Engine.run: duration must be nonnegative and finite";

  if not (Float.is_finite step_size) || step_size <= 0. then
    invalid_arg "Engine.run: timestep must be positive and finite";

  if float_of_int (int_of_float (ceil (duration /. step_size))) > 100_000. then
    invalid_arg "Engine.run: too many simulation steps";

  let rec simulate time amounts results =

    if time >= duration then
      List.rev results

    else
      let dt = min step_size (duration -. time) in

      let next_amounts = step dynamics amounts dt in
      let next_time = time +. dt in

      simulate next_time next_amounts
        ((next_time, next_amounts) :: results)

  in

  simulate 0. (Array.copy initial_amounts)
    [ (0., Array.copy initial_amounts) ]
