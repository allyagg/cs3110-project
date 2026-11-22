(* AF: [{ transfer; elim }] is the rate matrix K where K(i,j) is
   [transfer.(i).(j)] when i <> j, and K(i,i) is [transfer.(i).(i) -. elim.(i)].

   So [transfer] holds only mass-conserving exchange between compartments, and
   [elim] holds the first-order elimination constant of each compartment.

   RI: [transfer] is square with side [Array.length elim] >= 1; every column of
   [transfer] sums to 0 (up to rounding); off-diagonal entries and [elim] are
   non-negative. Arrays are copied before any change and never exposed. *)
   
type t = {
  transfer : float array array;
  elim : float array;
}

let size d = Array.length d.elim

let rates d amounts =
  let n = size d in
  if Array.length amounts <> n then
    invalid_arg "Dynamics.rates: state dimension mismatch";
  Array.init n (fun i ->
      let transfer_rate =
        Array.fold_left
          ( +. )
          0.
          (Array.mapi
             (fun j amount -> d.transfer.(i).(j) *. amount)
             amounts)
      in
      transfer_rate -. d.elim.(i) *. amounts.(i))

let check_index d i =
  if i < 0 || i >= size d then
    invalid_arg (Printf.sprintf "Dynamics: compartment index %d out of range" i)

let check_rate label k =
  if (not (Float.is_finite k)) || k < 0. then
    invalid_arg ("Dynamics: " ^ label ^ " must be finite and non-negative")

let create n =
  if n <= 0 then invalid_arg "Dynamics.create: need at least one compartment";
  { transfer = Array.make_matrix n n 0.; elim = Array.make n 0. }

let add_transfer ~from_ ~to_ k d =
  check_index d from_;
  check_index d to_;
  if from_ = to_ then invalid_arg "Dynamics.add_transfer: from_ = to_";
  check_rate "transfer rate" k;
  let transfer = Array.map Array.copy d.transfer in
  transfer.(to_).(from_) <- transfer.(to_).(from_) +. k;
  transfer.(from_).(from_) <- transfer.(from_).(from_) -. k;
  { d with transfer }

let add_elimination i k d =
  check_index d i;
  check_rate "elimination rate" k;
  let elim = Array.copy d.elim in
  elim.(i) <- elim.(i) +. k;
  { d with elim }
