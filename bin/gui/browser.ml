open Js_of_ocaml
(** Browser-only code: wait for Run, read the current fields, and submit them.
*)

open Js_of_ocaml_lwt
open Lwt.Syntax

let element = Dom_html.getElementById
let set_text id text = (element id)##.textContent := Js.some (Js.string text)

let input id =
  match Dom_html.getElementById_coerce id Dom_html.CoerceTo.input with
  | Some input -> input
  | None -> failwith ("Missing input: " ^ id)

let read_user_input () =
  List.map
    (fun id -> (id, `String (input id)##.value))
    [
      "dose";
      "drug-smiles";
      "duration";
      "step";
      "patient-heart-rate";
      "patient-height";
      "patient-weight";
      "patient-sex";
    ]

let main () =
  let* _ = Lwt_js_events.onload () in
  let run =
    Option.get (Dom_html.getElementById_coerce "run" Dom_html.CoerceTo.button)
  in
  run##.disabled := Js._false;
  set_text "status" "Ready. Fill in the fields, then click Run.";
  let rec wait_for_run () =
    let* _ = Lwt_js_events.click run in
    run##.disabled := Js._true;
    set_text "status" "Reading your configuration…";
    set_text "submitted-config" "";
    let* () =
      Lwt.catch
        (fun () ->
          let* response =
            XmlHttpRequest.perform_raw_url
              ~headers:[ ("X-PBPK-Run", "1") ]
              ~contents:(`POST_form (read_user_input ()))
              "/run"
          in
          if response.code = 200 then (
            set_text "status"
              "Inputs received. Model simulation is not connected yet.";
            set_text "submitted-config" response.content)
          else if response.code = 0 then
            set_text "status"
              "Cannot reach the app. Check that it is still running in \
               Terminal."
          else set_text "status" response.content;
          Lwt.return_unit)
        (fun _ ->
          set_text "status"
            "Cannot reach the app. Check that it is still running in Terminal.";
          Lwt.return_unit)
    in
    run##.disabled := Js._false;
    wait_for_run ()
  in
  wait_for_run ()

let () = Lwt.async main
