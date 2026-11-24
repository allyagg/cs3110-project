open OUnit2
open Cs3110_project.Organ

let plasma_lipids =
  { neutral_lipid_fraction = 0.01; neutral_phospholipid_fraction = 0.02 }

let drug = { log_p = 1.; plasma_unbound_fraction = 0.5 }

(* Synthetic tissue values so we can calculate the expected Kp by hand. *)
let liver_data =
  {
    name = "liver";
    lipid_mass_percent = 5.;
    water_fraction = 0.6;
    lipids =
      { neutral_lipid_fraction = 0.02; neutral_phospholipid_fraction = 0.03 };
    lipoprotein_ratio = 0.25;
    clearance = Hepatic;
  }

let kidney_data =
  { liver_data with name = "kidneys"; water_fraction = 0.7; clearance = Renal }

let remaining_data =
  { liver_data with name = "remaining tissues"; clearance = No_clearance }

let make_model blood_volume_l liver_volume_l =
  create_four_compartments plasma_lipids drug blood_volume_l
    { data = liver_data; patient_volume_l = liver_volume_l }
    { data = kidney_data; patient_volume_l = 0.3 }
    { data = remaining_data; patient_volume_l = 40. }

let assert_float_equal expected actual =
  assert_equal
    ~cmp:(fun x y -> Float.abs (x -. y) < 1e-10)
    ~printer:string_of_float expected actual

let assert_invalid_argument f =
  match f () with
  | exception Invalid_argument _ -> ()
  | _ -> assert_failure "Expected Invalid_argument"

let tests =
  "Organ"
  >::: [
         ( "partition coefficients match hand calculations and preserve input \
            order"
         >:: fun _ ->
           match
             predict_partition_coefficients plasma_lipids drug
               [ kidney_data; liver_data ]
           with
           | [ ("kidneys", kidney_kp); ("liver", liver_kp) ] ->
               assert_float_equal 0.60875 kidney_kp;
               assert_float_equal 0.55875 liver_kp
           | _ -> assert_failure "Expected kidneys followed by liver" );
         ( "four compartments store the correct tissue data and connections"
         >:: fun _ ->
           let model = make_model 5. 1.5 in
           let organs =
             [ model.liver; model.kidneys; model.remaining_tissues ]
           in
           assert_equal 5. model.blood_volume_l;
           assert_equal [ 1.5; 0.3; 40. ] (List.map volume_l organs);
           assert_equal
             [ liver_data; kidney_data; remaining_data ]
             (List.map tissue organs);
           assert_equal
             [ [ Blood ]; [ Blood ]; [ Blood ] ]
             (List.map connections organs);
           assert_float_equal 0.55875 (partition_coefficient model.liver) );
         ( "the full initial dose starts in blood" >:: fun _ ->
           assert_equal
             [ Blood; Liver; Kidneys; Remaining_tissues ]
             compartment_order;
           assert_equal [| 100.; 0.; 0.; 0. |] (initial_amounts 100.);
           assert_equal [| 0.; 0.; 0.; 0. |] (initial_amounts 0.) );
         ( "rejects zero blood volume" >:: fun _ ->
           assert_invalid_argument (fun () -> make_model 0. 1.5) );
         ( "rejects negative tissue volume" >:: fun _ ->
           assert_invalid_argument (fun () -> make_model 5. (-1.)) );
         ( "rejects a negative dose" >:: fun _ ->
           assert_invalid_argument (fun () -> initial_amounts (-10.)) );
         ( "rejects a zero unbound fraction" >:: fun _ ->
           let invalid_drug = { drug with plasma_unbound_fraction = 0. } in
           assert_invalid_argument (fun () ->
               predict_partition_coefficients plasma_lipids invalid_drug
                 [ liver_data ]) );
         ( "rejects tissue water and lipid fractions that sum above one"
         >:: fun _ ->
           let invalid_tissue = { liver_data with water_fraction = 1. } in
           assert_invalid_argument (fun () ->
               predict_partition_coefficients plasma_lipids drug
                 [ invalid_tissue ]) );
       ]

let () = run_test_tt_main tests
