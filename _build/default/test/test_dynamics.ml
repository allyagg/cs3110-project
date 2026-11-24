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

let tests_for_create_and_rates =
  "create and rates" >::: [
    ("create without compartments" >:: fun _ ->
      assert_raises
        (Invalid_argument "Dynamics.create: need at least one compartment")
        (fun () -> Dynamics.create 0);
      assert_raises
        (Invalid_argument "Dynamics.create: need at least one compartment")
        (fun () -> Dynamics.create (-1)));

    ("zero dynamics leave amounts unchanged" >:: fun _ ->
      let d = Dynamics.create 3 in
      assert_float_array [| 0.; 0.; 0. |]
        (Dynamics.rates d [| 2.; 3.; 5. |]));

    ("rate input dimension mismatch" >:: fun _ ->
      let d = Dynamics.create 2 in
      assert_raises
        (Invalid_argument "Dynamics.rates: state dimension mismatch")
        (fun () -> Dynamics.rates d [| 1. |]);
      assert_raises
        (Invalid_argument "Dynamics.rates: state dimension mismatch")
        (fun () -> Dynamics.rates d [| 1.; 2.; 3. |]));

    ("elimination changes the matching compartment" >:: fun _ ->
      let d =
        Dynamics.create 3
        |> Dynamics.add_elimination 1 0.25
      in
      assert_float_array [| 0.; -1.; 0. |]
        (Dynamics.rates d [| 10.; 4.; 7. |]))
  ]

let tests_for_transfer =
  "transfer" >::: [
    ("transfer moves drug between compartments" >:: fun _ ->
      let d =
        Dynamics.create 2
        |> Dynamics.add_transfer ~from_:0 ~to_:1 0.5
      in
      assert_float_array [| -1.; 1. |]
        (Dynamics.rates d [| 2.; 0. |]));

    ("one-way transfer conserves total amount" >:: fun _ ->
      let d =
        Dynamics.create 3
        |> Dynamics.add_transfer ~from_:0 ~to_:2 0.2
      in
      let rates = Dynamics.rates d [| 10.; 4.; 6. |] in
      assert_float_array [| -2.; 0.; 2. |] rates;
      assert_equal ~printer:string_of_float 0.
        (Array.fold_left ( +. ) 0. rates));

    ("repeated transfers add together" >:: fun _ ->
      let d =
        Dynamics.create 2
        |> Dynamics.add_transfer ~from_:0 ~to_:1 0.2
        |> Dynamics.add_transfer ~from_:0 ~to_:1 0.3
      in
      assert_float_array [| -5.; 5. |]
        (Dynamics.rates d [| 10.; 0. |]));

    ("bidirectional exchange is computed correctly" >:: fun _ ->
      let d =
        Dynamics.create 2
        |> Dynamics.add_transfer ~from_:0 ~to_:1 0.5
        |> Dynamics.add_transfer ~from_:1 ~to_:0 0.25
      in
      assert_float_array [| -3.5; 3.5 |]
        (Dynamics.rates d [| 8.; 2. |]));

    ("elimination is additional to exchange" >:: fun _ ->
      let d =
        Dynamics.create 2
        |> Dynamics.add_transfer ~from_:0 ~to_:1 0.5
        |> Dynamics.add_elimination 0 0.1
      in
      assert_float_array [| -12.; 10. |]
        (Dynamics.rates d [| 20.; 0. |]));

    ("original dynamics remains unchanged" >:: fun _ ->
      let original = Dynamics.create 2 in
      let _ =
        original
        |> Dynamics.add_transfer ~from_:0 ~to_:1 0.5
        |> Dynamics.add_elimination 0 0.1
      in
      assert_float_array [| 0.; 0. |]
        (Dynamics.rates original [| 10.; 4. |]))
  ]

let tests_for_validation =
  "construction validation" >::: [
    ("negative transfer index" >:: fun _ ->
      let d = Dynamics.create 2 in
      assert_raises
        (Invalid_argument "Dynamics: compartment index -1 out of range")
        (fun () -> Dynamics.add_transfer ~from_:(-1) ~to_:1 0.5 d);
      assert_raises
        (Invalid_argument "Dynamics: compartment index 2 out of range")
        (fun () -> Dynamics.add_transfer ~from_:0 ~to_:2 0.5 d));

    ("negative elimination index" >:: fun _ ->
      let d = Dynamics.create 2 in
      assert_raises
        (Invalid_argument "Dynamics: compartment index -1 out of range")
        (fun () -> Dynamics.add_elimination (-1) 0.5 d);
      assert_raises
        (Invalid_argument "Dynamics: compartment index 2 out of range")
        (fun () -> Dynamics.add_elimination 2 0.5 d));

    ("transfer from equals transfer to" >:: fun _ ->
      let d = Dynamics.create 2 in
      assert_raises
        (Invalid_argument "Dynamics.add_transfer: from_ = to_")
        (fun () -> Dynamics.add_transfer ~from_:1 ~to_:1 0.5 d));

    ("invalid transfer rates" >:: fun _ ->
      let d = Dynamics.create 2 in
      assert_raises
        (Invalid_argument "Dynamics: transfer rate must be finite and non-negative")
        (fun () -> Dynamics.add_transfer ~from_:0 ~to_:1 (-0.1) d);
      assert_raises
        (Invalid_argument "Dynamics: transfer rate must be finite and non-negative")
        (fun () -> Dynamics.add_transfer ~from_:0 ~to_:1 Float.nan d);
      assert_raises
        (Invalid_argument "Dynamics: transfer rate must be finite and non-negative")
        (fun () -> Dynamics.add_transfer ~from_:0 ~to_:1 Float.infinity d));

    ("invalid elimination rates" >:: fun _ ->
      let d = Dynamics.create 2 in
      assert_raises
        (Invalid_argument "Dynamics: elimination rate must be finite and non-negative")
        (fun () -> Dynamics.add_elimination 0 (-0.1) d);
      assert_raises
        (Invalid_argument "Dynamics: elimination rate must be finite and non-negative")
        (fun () -> Dynamics.add_elimination 0 Float.nan d);
      assert_raises
        (Invalid_argument "Dynamics: elimination rate must be finite and non-negative")
        (fun () -> Dynamics.add_elimination 0 Float.infinity d))
  ]

let tests = "dynamics test suite" >::: [
  tests_for_create_and_rates;
  tests_for_transfer;
  tests_for_validation
]

let _ = run_test_tt_main tests
