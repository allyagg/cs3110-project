(lang dune 3.0)
(name PBPK)
(generate_opam_files true)

(package
 (name PBPK)
 (synopsis "PBPK model")
 (allow_empty)
 (depends
  (ocaml (>= 5.0))
  dune
  csv
  batteries
  lwt
  lwt_ppx
  (js_of_ocaml (= 6.2.0))
  (js_of_ocaml-compiler (= 6.2.0))
  (js_of_ocaml-ppx (= 6.2.0))
  (js_of_ocaml-lwt (= 6.2.0))))
