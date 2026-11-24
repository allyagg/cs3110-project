open OUnit2
open Cs3110_project

let eps = 1e-9
let cmp_float a b = Float.abs (a -. b) <= eps
let assert_float ?msg expected actual =
  assert_equal ?msg ~cmp:cmp_float ~printer:string_of_float expected actual

let assert_floats expected actual =
  assert_equal ~printer:string_of_int (Array.length expected)
    (Array.length actual);
  Array.iteri (fun i e -> assert_float e actual.(i)) expected

let raises_invalid f =
  match f () with
  | _ -> assert_failure "expected Invalid_argument"
  | exception Invalid_argument _ -> ()

(* Two-compartment fixture used by several tests. *)
let two () =
  State.create ~names:[ "blood"; "liver" ] ~volumes:[ 5.; 2. ] [ 100.; 0. ]

(* ---------- State: construction ---------- *)

let create_tests =
  [
    ( "create starts at time 0 with nothing eliminated" >:: fun _ ->
      let s = two () in
      assert_float 0. (State.time s);
      assert_float 0. (State.eliminated s);
      assert_equal ~printer:string_of_int 2 (State.size s);
      assert_equal [ "blood"; "liver" ] (State.names s);
      assert_floats [| 100.; 0. |] (State.amounts s) );
    ( "create rejects empty lists" >:: fun _ ->
      raises_invalid (fun () -> State.create ~names:[] ~volumes:[] []) );
    ( "create rejects mismatched lengths" >:: fun _ ->
      raises_invalid (fun () ->
          State.create ~names:[ "a"; "b" ] ~volumes:[ 1. ] [ 0.; 0. ]);
      raises_invalid (fun () ->
          State.create ~names:[ "a" ] ~volumes:[ 1. ] [ 0.; 0. ]) );
    ( "create rejects duplicate names" >:: fun _ ->
      raises_invalid (fun () ->
          State.create ~names:[ "a"; "a" ] ~volumes:[ 1.; 1. ] [ 0.; 0. ]) );
    ( "create rejects zero, negative, and non-finite volumes" >:: fun _ ->
      List.iter
        (fun v ->
          raises_invalid (fun () ->
              State.create ~names:[ "a" ] ~volumes:[ v ] [ 1. ]))
        [ 0.; -1.; Float.infinity; Float.nan ] );
    ( "create rejects negative and non-finite amounts" >:: fun _ ->
      List.iter
        (fun a ->
          raises_invalid (fun () ->
              State.create ~names:[ "a" ] ~volumes:[ 1. ] [ a ]))
        [ -1.; Float.infinity; Float.nan ] );
    ( "create accepts a zero amount" >:: fun _ ->
      let s = State.create ~names:[ "a" ] ~volumes:[ 1. ] [ 0. ] in
      assert_float 0. (State.total_in_body s) );
  ]

(* ---------- State: queries ---------- *)

let query_tests =
  [
    ( "index_of finds each compartment" >:: fun _ ->
      let s = two () in
      assert_equal ~printer:string_of_int 0 (State.index_of "blood" s);
      assert_equal ~printer:string_of_int 1 (State.index_of "liver" s) );
    ( "index_of raises Not_found for an unknown name" >:: fun _ ->
      assert_raises Not_found (fun () -> State.index_of "kidney" (two ())) );
    ( "concentrations are amount / volume" >:: fun _ ->
      let s =
        State.create ~names:[ "blood"; "liver" ] ~volumes:[ 5.; 2. ]
          [ 100.; 30. ]
      in
      assert_floats [| 20.; 15. |] (State.concentrations s) );
    ( "total_mass is in-body plus eliminated" >:: fun _ ->
      let s = State.update ~time:1. ~eliminated:10. [| 60.; 30. |] (two ()) in
      assert_float 90. (State.total_in_body s);
      assert_float 100. (State.total_mass s) );
  ]

(* ---------- State: update and immutability ---------- *)

let update_tests =
  [
    ( "update sets time, eliminated, and amounts" >:: fun _ ->
      let s = State.update ~time:0.5 ~eliminated:2. [| 70.; 28. |] (two ()) in
      assert_float 0.5 (State.time s);
      assert_float 2. (State.eliminated s);
      assert_floats [| 70.; 28. |] (State.amounts s);
      assert_equal [ "blood"; "liver" ] (State.names s) );
    ( "update leaves the original state unchanged" >:: fun _ ->
      let s0 = two () in
      let _ = State.update ~time:1. ~eliminated:5. [| 1.; 2. |] s0 in
      assert_float 0. (State.time s0);
      assert_floats [| 100.; 0. |] (State.amounts s0) );
    ( "update rejects a length mismatch" >:: fun _ ->
      raises_invalid (fun () ->
          State.update ~time:1. ~eliminated:0. [| 1. |] (two ())) );
    ( "mutating the array returned by amounts does not change the state"
    >:: fun _ ->
      let s = two () in
      let a = State.amounts s in
      a.(0) <- -999.;
      assert_floats [| 100.; 0. |] (State.amounts s) );
    ( "mutating the array passed to update does not change the state"
    >:: fun _ ->
      let input = [| 50.; 50. |] in
      let s = State.update ~time:1. ~eliminated:0. input (two ()) in
      input.(0) <- -999.;
      assert_floats [| 50.; 50. |] (State.amounts s) );
  ]

(* ---------- State with Engine ---------- *)

(* Wrap each point of an Engine trajectory as a State. [eliminated] is 0
   because Engine does not yet report drug leaving the body. *)
let states_of_run s0 run =
  List.map (fun (t, a) -> State.update ~time:t ~eliminated:0. a s0) run

let engine_tests =
  [
    ( "hand-checked one-compartment elimination (Case A)" >:: fun _ ->
      (* k = 0.5/h, dt = 0.5 h, so each step multiplies the amount by 0.75. *)
      let s0 = State.create ~names:[ "blood" ] ~volumes:[ 10. ] [ 100. ] in
      let d = Dynamics.create 1 |> Dynamics.add_elimination 0 0.5 in
      let states =
        states_of_run s0 (Engine.run d (State.amounts s0) 2. 0.5)
      in
      let amounts = List.map (fun s -> (State.amounts s).(0)) states in
      let concs = List.map (fun s -> (State.concentrations s).(0)) states in
      let times = List.map State.time states in
      List.iter2 (fun e a -> assert_float e a)
        [ 100.; 75.; 56.25; 42.1875; 31.640625 ] amounts;
      List.iter2 (fun e a -> assert_float e a)
        [ 10.; 7.5; 5.625; 4.21875; 3.1640625 ] concs;
      List.iter2 (fun e a -> assert_float e a) [ 0.; 0.5; 1.; 1.5; 2. ] times );
    ( "transfers alone conserve total mass at every step" >:: fun _ ->
      let s0 =
        State.create
          ~names:[ "blood"; "liver"; "kidney"; "rest" ]
          ~volumes:[ 5.; 1.8; 0.3; 60. ]
          [ 100.; 0.; 0.; 0. ]
      in
      let d =
        Dynamics.create 4
        |> Dynamics.add_transfer ~from_:0 ~to_:1 1.5
        |> Dynamics.add_transfer ~from_:1 ~to_:0 0.8
        |> Dynamics.add_transfer ~from_:0 ~to_:2 2.0
        |> Dynamics.add_transfer ~from_:2 ~to_:0 1.1
        |> Dynamics.add_transfer ~from_:0 ~to_:3 0.4
        |> Dynamics.add_transfer ~from_:3 ~to_:0 0.05
      in
      let states =
        states_of_run s0 (Engine.run d (State.amounts s0) 24. 0.01)
      in
      List.iter
        (fun s ->
          assert_float ~msg:(Printf.sprintf "t = %g" (State.time s)) 100.
            (State.total_mass s))
        states );
  ]

(* ---------- Data ---------- *)

let series () =
  let s0 = two () in
  Data.of_states
    [ s0; State.update ~time:1. ~eliminated:10. [| 60.; 30. |] s0 ]

let data_tests =
  [
    ( "of_states rejects an empty list" >:: fun _ ->
      raises_invalid (fun () -> Data.of_states []) );
    ( "of_states rejects decreasing times" >:: fun _ ->
      let s0 = two () in
      let s1 = State.update ~time:1. ~eliminated:0. [| 1.; 1. |] s0 in
      raises_invalid (fun () -> Data.of_states [ s1; s0 ]) );
    ( "of_states rejects mismatched compartments" >:: fun _ ->
      let other =
        State.create ~names:[ "x"; "y" ] ~volumes:[ 1.; 1. ] [ 0.; 0. ]
      in
      raises_invalid (fun () -> Data.of_states [ two (); other ]) );
    ( "length, times, and final" >:: fun _ ->
      let s = series () in
      assert_equal ~printer:string_of_int 2 (Data.length s);
      assert_equal [ 0.; 1. ] (Data.times s);
      assert_float 1. (State.time (Data.final s)) );
    ( "amounts_of picks one compartment over time" >:: fun _ ->
      assert_equal [ 0.; 30. ] (Data.amounts_of "liver" (series ()));
      assert_raises Not_found (fun () -> Data.amounts_of "kidney" (series ()))
    );
    ( "to_csv has a header and one row per state" >:: fun _ ->
      assert_equal ~printer:(fun s -> s)
        "time,blood_mg,liver_mg,blood_mg_per_l,liver_mg_per_l,eliminated_mg\n\
         0,100,0,20,0,0\n\
         1,60,30,12,15,10\n"
        (Data.to_csv (series ())) );
    ( "save_csv writes to_csv to a file" >:: fun _ ->
      let path = Filename.temp_file "series" ".csv" in
      Data.save_csv path (series ());
      let ic = open_in path in
      let contents = really_input_string ic (in_channel_length ic) in
      close_in ic;
      Sys.remove path;
      assert_equal ~printer:(fun s -> s) (Data.to_csv (series ())) contents );
  ]

let tests =
  "test suite"
  >::: [
         "State.create" >::: create_tests;
         "State queries" >::: query_tests;
         "State.update" >::: update_tests;
         "State with Engine" >::: engine_tests;
         "Data" >::: data_tests;
       ]

let _ = run_test_tt_main tests
