(** Native entry point: launch the GUI and receive validated model inputs. *)
let main () =
  let assets =
    Filename.concat (Filename.dirname Sys.executable_name) "../public"
  in
  Gui_server.run ~assets ~on_submit:(fun config ->
      (* Model initialization can consume [config] here when it is implemented. *)
      Printf.printf "\nReceived configuration:\n%s\n%!"
        (Model_config.summary config))

let () =
  Sys.catch_break true;
  try main () with Sys.Break -> print_endline "\nPBPK interface stopped."
