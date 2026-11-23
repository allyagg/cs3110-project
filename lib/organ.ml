type clearance =
  | No_Clearance
  | Hepatic
  | Renal

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

type t = {
  tissue : tissue;
  volume_l : float;
  connections : string list;
  partition_coefficient : float;
}
(** AF: Record descripes one dissue comparment in a model RI: Tissue data are
    valid, volume_l and partition_coefficient are finite positive *)
