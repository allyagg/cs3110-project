(* ## organ.ml should pull hard coded information from tissue_data.ml and ## it
   should calculate the partition coefficient of the user specified ## drug into
   the organ.

   ## use the Rodgers–Rowland model for estimating the partition coefficient ##
   I have notes on this from a drug delivery course that I can send!

   ## look at tissue_data.csv for preliminary information on what that info
   struct looks like

   let coefficients = predict_partition_coefficients drug_properties
   tissue_table

   from readme: our scope goal is to at least have a configuration that will
   include blood, liver, kidneys, and a remaining-tissues compartment. These
   organs are the most dominant factors on clearance. *)

(** TODO FOR ORGAN:
    - calculate organ partition coeffifient of user specific drug in the organ
      using Rodgers-Rowland estimation model
    - lipid storing stuff based on tissue_data *)

(** Words to know / defs to understand are in descriptions. I just copied
    definitons from Google as I know nothing about biological pathways, so I
    hope this can help everyone understand what terms in organ do and are! *)

(** What category of clearance an organ has, including no clearance. *)
type clearance =
  | No_clearance
  | Hepatic
  (* Hepatic Clearance: the volume of blood perfusing the liver that is
     completely cleared of a drug or substance per unit of time*)
  | Renal
(* Renal Clearance: the volume of blood plasma from which a substance is
   completely removed by the kidneys and excreted into urine per unit of time*)

(** What compartment is having test ran *)
type compartment =
  | Blood
  | Liver
  | Kidneys
  | Remaining_tissues

type lipids = {
  neutral_lipid_fraction : float;
  neutral_phospholipid_fraction : float;
}
(** Tissue or plasma lipid volume, should be fractions on a 0 - 1 scale basis.
*)

(** A row in the tissue table in tissue_data.csv. Lipid_mass_percent is on a 0 -
    100 scale. water_fraction combines cellular water. lipoprotein_ratio is the
    cellular lipoprotein cocentration in tissue over plasma concentrations *)
type tissue = {
  name : string;
  lipid_mass_percent : float;
  water_fraction : float;
  lipids : lipids;
  lipoprotein_ratio : float;
  clearance : clearance;
}
(** IMPORTANT:: I do not have actual tissue_data information, so this is an
    assumption of possible data that I could recieve BUT!!! totally possibler to
    adjust after meeting based on the actual tissue_data!*)

type neutral_drug = {
  log_p : float;
  plasma_unbound_fraction : float;
}
(** Properties of a non-ionizing drug, or in other words a neutral_drug. log_p
    is the base-10 log of the OTW partition coefficient. The unbound fraction is
    0<f<1 *)

type tissue_input = {
  data : tissue;
  patient_volume_l : float;
}
(** When users input patient data on a tissue *)

type t
(** Abstract type for tissue made for the simulation *)

type four_compartments = {
  blood_volume_l : float;
  liver : t;
  kidneys : t;
  remaining_tissues : t;
}
(** !!! IMPORTANT!!! Added this after looking at main / GUI. Unsure if needed /
    necessary but talk in meeting about this!!!*)

val predict_partition_coefficients :
  lipids -> neutral_drug -> tissue list -> (string * float) list
(** Returns the tissue names and tissue to total plasma KP values in input order
*)

val create_four_compartments :
  lipids ->
  neutral_drug ->
  float ->
  tissue_input ->
  tissue_input ->
  tissue_input ->
  four_compartments
(** Calculates each tissue KP value and configures it for blood exchanges *)

val tissue : t -> tissue
val volume_l : t -> float
val connections : t -> compartment list
val partition_coefficient : t -> float

val compartment_order : compartment list
(** Input order used for simulation array *)

val initial_amounts : float -> float array
(** Amounts in mg in compartment order with full dose of blood *)
