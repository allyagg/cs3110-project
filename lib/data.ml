(* AF: [l] is the time series whose i-th point is the i-th state of [l].
   RI: [l] is non-empty, times are non-decreasing, and every state has the
   same compartment names as the first. *)
type t = State.t list

let of_states l =
  match l with
  | [] -> invalid_arg "Data.of_states: empty series"
  | s0 :: _ ->
      let names = State.names s0 in
      let rec check prev = function
        | [] -> ()
        | s :: rest ->
            if State.names s <> names then
              invalid_arg "Data.of_states: compartments differ";
            if State.time s < prev then
              invalid_arg "Data.of_states: times decrease";
            check (State.time s) rest
      in
      check (State.time s0) l;
      l

let states s = s
let length = List.length
let times s = List.map State.time s
let final s = List.nth s (List.length s - 1)

let amounts_of name s =
  let i = State.index_of name (List.hd s) in
  List.map (fun st -> (State.amounts st).(i)) s

let to_csv s =
  let names = State.names (List.hd s) in
  let f = Printf.sprintf "%g" in
  let floats a = List.map f (Array.to_list a) in
  let header =
    ("time" :: List.map (fun n -> n ^ "_mg") names)
    @ List.map (fun n -> n ^ "_mg_per_l") names
    @ [ "eliminated_mg" ]
  in
  let row st =
    (f (State.time st) :: floats (State.amounts st))
    @ floats (State.concentrations st)
    @ [ f (State.eliminated st) ]
  in
  String.concat "\n" (List.map (String.concat ",") (header :: List.map row s))
  ^ "\n"

let save_csv path s =
  let oc = open_out path in
  Fun.protect
    ~finally:(fun () -> close_out oc)
    (fun () -> output_string oc (to_csv s))
