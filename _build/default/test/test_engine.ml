open OUnit2
open Cs3110_project

let assert_float_array ?(tol = 1e-9) expected actual =
  assert_equal ~printer:string_of_int (Array.length expected) (Array.length actual);
  Array.iteri
    (fun i expected ->
      assert_bool
        (Printf.sprintf
           "array[%d]: expected %.12g, got %.12g"
           i expected actual.(i))
        (Float.abs (expected -. actual.(i)) <= tol))
    expected

let tests_for_rates =
  "engine rates" >::: [
    ("rates delegates to dynamics" >:: fun _ ->
      let d =
        Dynamics.create 2
        |> Dynamics.add_transfer ~from_:0 ~to_:1 0.5
      in
      assert_float_array [| -5.; 5. |]
        (Engine.rates d [| 10.; 0. |]));

    ("rates preserves dimension mismatch validation" >:: fun _ ->
      let d = Dynamics.create 2 in
      assert_raises
        (Invalid_argument "Dynamics.rates: state dimension mismatch")
        (fun () -> Engine.rates d [| 10. |]))
  ]

let tests_for_step =
  "Euler step" >::: [
    ("step applies an explicit Euler update" >:: fun _ ->
      let d =
        Dynamics.create 2
        |> Dynamics.add_transfer ~from_:0 ~to_:1 0.5
      in
      assert_float_array [| 7.5; 2.5 |]
        (Engine.step d [| 10.; 0. |] 0.5));

    ("step with no dynamics returns the same amounts" >:: fun _ ->
      let d = Dynamics.create 2 in
      assert_float_array [| 10.; 4. |]
        (Engine.step d [| 10.; 4. |] 1.));

    ("step does not mutate its input amounts" >:: fun _ ->
      let d =
        Dynamics.create 1
        |> Dynamics.add_elimination 0 0.25
      in
      let amounts = [| 8. |] in
      let next = Engine.step d amounts 2. in
      assert_float_array [| 4. |] next;
      assert_float_array [| 8. |] amounts);

    ("step rejects invalid timesteps" >:: fun _ ->
      let d = Dynamics.create 1 in
      assert_raises
        (Invalid_argument "Engine.step: timestep must be positive and finite")
        (fun () -> Engine.step d [| 1. |] 0.);
      assert_raises
        (Invalid_argument "Engine.step: timestep must be positive and finite")
        (fun () -> Engine.step d [| 1. |] (-0.1));
      assert_raises
        (Invalid_argument "Engine.step: timestep must be positive and finite")
        (fun () -> Engine.step d [| 1. |] Float.infinity);
      assert_raises
        (Invalid_argument "Engine.step: timestep must be positive and finite")
        (fun () -> Engine.step d [| 1. |] Float.nan))
  ]

let tests_for_run =
  "trajectory run" >::: [
    ("run includes initial and final states" >:: fun _ ->
      let d = Dynamics.create 1 in
      let trajectory = Engine.run d [| 10. |] 1. 0.25 in
      assert_equal 5 (List.length trajectory);
      assert_equal ~printer:string_of_float 0.
        (fst (List.hd trajectory));
      assert_float_array [| 10. |] (snd (List.hd trajectory));
      assert_equal ~printer:string_of_float 1.
        (fst (List.hd (List.rev trajectory)));
      assert_float_array [| 10. |] (snd (List.hd (List.rev trajectory))));

    ("run uses a final partial timestep" >:: fun _ ->
      let d =
        Dynamics.create 1
        |> Dynamics.add_elimination 0 1.
      in
      let trajectory = Engine.run d [| 8. |] 1. 0.3 in
      assert_float_array [| 8. |] (snd (List.hd trajectory));
      assert_equal ~printer:string_of_float 1.
        (fst (List.hd (List.rev trajectory)));
      assert_float_array [| 2.4696 |] (snd (List.hd (List.rev trajectory))));

    ("run does not mutate initial amounts" >:: fun _ ->
      let d =
        Dynamics.create 1
        |> Dynamics.add_elimination 0 0.5
      in
      let initial = [| 6. |] in
      let _ = Engine.run d initial 1. 0.5 in
      assert_float_array [| 6. |] initial);

    ("run rejects an invalid duration" >:: fun _ ->
      let d = Dynamics.create 1 in
      assert_raises
        (Invalid_argument "Engine.run: duration must be nonnegative and finite")
        (fun () -> Engine.run d [| 1. |] (-1.) 0.1);
      assert_raises
        (Invalid_argument "Engine.run: duration must be nonnegative and finite")
        (fun () -> Engine.run d [| 1. |] Float.infinity 0.1);
      assert_raises
        (Invalid_argument "Engine.run: duration must be nonnegative and finite")
        (fun () -> Engine.run d [| 1. |] Float.nan 0.1));

    ("run rejects an invalid timestep" >:: fun _ ->
      let d = Dynamics.create 1 in
      assert_raises
        (Invalid_argument "Engine.run: timestep must be positive and finite")
        (fun () -> Engine.run d [| 1. |] 1. 0.);
      assert_raises
        (Invalid_argument "Engine.run: timestep must be positive and finite")
        (fun () -> Engine.run d [| 1. |] 1. Float.infinity);
      assert_raises
        (Invalid_argument "Engine.run: timestep must be positive and finite")
        (fun () -> Engine.run d [| 1. |] 1. Float.nan));

    ("run rejects too many steps" >:: fun _ ->
      let d = Dynamics.create 1 in
      assert_raises
        (Invalid_argument "Engine.run: too many simulation steps")
        (fun () -> Engine.run d [| 1. |] 100001. 1.))
  ]

let tests = "engine test suite" >::: [
  tests_for_rates;
  tests_for_step;
  tests_for_run
]

let _ = run_test_tt_main tests
