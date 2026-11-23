(* AF: [{ names; volumes; amounts; time; eliminated }] is the snapshot at
   [time] where compartment [i] is called [names.(i)], has volume
   [volumes.(i)] L and holds [amounts.(i)] mg, and [eliminated] mg have left
   the body.
   RI: the three arrays have the same length >= 1; names are distinct;
   volumes > 0. Arrays are never exposed or mutated after creation. *)
type t = {
  names : string array;
  volumes : float array;
  amounts : float array;
  time : float;
  eliminated : float;
}

let check_amounts a =
  Array.iter
    (fun x ->
      if (not (Float.is_finite x)) || x < 0. then
        invalid_arg "State: amounts must be finite and non-negative")
    a

let create ~names ~volumes amounts =
  let names = Array.of_list names
  and volumes = Array.of_list volumes
  and amounts = Array.of_list amounts in
  let n = Array.length names in
  if n = 0 then invalid_arg "State.create: need at least one compartment";
  if Array.length volumes <> n || Array.length amounts <> n then
    invalid_arg "State.create: length mismatch";
  if List.length (List.sort_uniq compare (Array.to_list names)) <> n then
    invalid_arg "State.create: duplicate compartment name";
  Array.iter
    (fun v ->
      if (not (Float.is_finite v)) || v <= 0. then
        invalid_arg "State.create: volumes must be positive")
    volumes;
  check_amounts amounts;
  { names; volumes; amounts; time = 0.; eliminated = 0. }

let update ~time ~eliminated amounts s =
  if Array.length amounts <> Array.length s.amounts then
    invalid_arg "State.update: length mismatch";
  { s with amounts = Array.copy amounts; time; eliminated }

let time s = s.time
let size s = Array.length s.amounts
let names s = Array.to_list s.names

let index_of name s =
  let rec find i =
    if i >= Array.length s.names then raise Not_found
    else if s.names.(i) = name then i
    else find (i + 1)
  in
  find 0

let amounts s = Array.copy s.amounts
let concentrations s = Array.map2 ( /. ) s.amounts s.volumes
let eliminated s = s.eliminated
let total_in_body s = Array.fold_left ( +. ) 0. s.amounts
let total_mass s = total_in_body s +. s.eliminated
