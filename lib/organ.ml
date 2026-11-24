type clearance =
  | No_Clearance
  | Hepatic
  | Renal

type compartment =
  | Blood
  | Liver
  | Kidneys
  | Remaining_tissues

type lipids = {
  neutral_lipid_fraction : float;
  neutral_phospholipid_fraction : float;
}

type tissue = {
  name : string;
  lipid_mass_percent : float;
  water_fraction : float;
  lipids : lipids;
  lipoprotein_ratio : float;
  clearance : clearance;
}

type neutral_drug = {
  log_p : float;
  plasma_unbound_fraction : float;
}

type tissue_input = {
  data : tissue;
  patient_volume_l : float;
}

type t = {
  tissue : tissue;
  volume_l : float;
  connections : compartment list;
  partition_coefficient : float;
}
(** AF: Record descripes one dissue comparment in a model RI: Tissue data are
    valid, volume_l and partition_coefficient are finite positive *)

type four_compartments = {
  blood_volume_l : float;
  liver : t;
  kidneys : t;
  remaining_tissues : t;
}

let check_range label upper value =
  if (not (Float.is_finite value)) || value < 0. || value > upper then
    invalid_arg
      (Printf.sprintf "Organ: %S is not in the right range of 0 and %g" label
         upper)

let check_positive label value =
  if (not (Float.is_finite value)) || value <= 0. then
    invalid_arg ("Organ: " ^ label ^ " has to be finite and positive")

let check_lipids water_fraction lipids =
  check_range "neutral lipid fraction" 1. lipids.neutral_lipid_fraction;
  check_range "neutral phospholipid fraction" 1.
    lipids.neutral_phospholipid_fraction;
  let total =
    water_fraction +. lipids.neutral_lipid_fraction
    +. lipids.neutral_phospholipid_fraction
  in
  if total > 1. +. 1e-9 then
    invalid_arg "Organ: water and lipid fractions must sum to at most 1"

let check_tissue tissue =
  if String.trim tissue.name = "" then invalid_arg "Organ: empty tissue name";
  check_range "Lipid mass percent" 100. tissue.lipid_mass_percent;
  check_range "water fraction" 1. tissue.water_fraction;
  check_lipids tissue.water_fraction tissue.lipids;
  check_range "lipoprotein ratio" max_float tissue.lipoprotein_ratio

let lipid_partition p lipids =
  (p *. lipids.neutral_lipid_fraction)
  +. (((0.3 *. p) +. 0.7) *. lipids.neutral_phospholipid_fraction)

let partition_predictor plasma_lipids drug =
  check_lipids 0. plasma_lipids;
  let fu = drug.plasma_unbound_fraction in
  check_positive "plasma unbound fraction" fu;
  if fu > 1. then invalid_arg "Organ: plasma unbound fraction must be <=1";
  let p = 10. ** drug.log_p in
  check_positive "OTW partition coefficient" p;
  let plasma_binding =
    max 0. ((1. /. fu) -. 1. -. lipid_partition p plasma_lipids)
  in
  (fun tissue -> check_tissue tissue)
  =
  let kpu =
    tissue.water_fraction
    +. lipid_partition p tissue.lipids
    +. (plasma_binding *. tissue.lipoprotein_ratio)
  in
  let kp = fu *. kpu in
  check_positive "tissue to plasma partition coefficient" kp;
  kp

let predict_partition_coefficients plasma_lipids drug tissues =
  let predict = partition_predictor plasma_lipids drug in
  List.map (fun tissue -> (tissue.name, predict tissue)) tissues

let create_four_compartments plasma_lipids drug blood_volume_l liver kidneys
    remaining_tissues =
  check_positive "blood volume in liters" blood_volume_l;
  let predict = partition_predictor plasma_lipids drug in
  let configure input =
    check_positive "tissue volume in liters" input.patient_volume_l;
    {
      tissue = input.data;
      volume_l = input.patient_volume_l;
      connections = [ Blood ];
      partition_coefficient = predict input.data;
    }
  in
  {
    blood_volume_l;
    liver = configure liver;
    kidneys = configure kidneys;
    remaining_tissues = configure remaining_tissues;
  }

let tissue organ = organ.tissue
let volume_l organ = organ.volume_l
let connections organ = organ.connections
let partition_coefficient organ = organ.partition_coefficient
let compartment_order = [ Blood; Liver; Kidneys; Remaining_tissues ]

let initial_amounts dose_mg =
  check_range "dose in milligrams: " max_float dose_mg;
  compartment_order
  |> List.map (function
    | Blood -> dose_mg
    | _ -> 0.)
  |> Array.of_list
