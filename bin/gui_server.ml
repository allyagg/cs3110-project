let decode_form body =
  let decode text =
    let output = Buffer.create (String.length text) in
    let hex c =
      match c with
      | '0' .. '9' -> Char.code c - Char.code '0'
      | 'a' .. 'f' -> Char.code c - Char.code 'a' + 10
      | 'A' .. 'F' -> Char.code c - Char.code 'A' + 10
      | _ -> invalid_arg "Invalid form encoding."
    in
    let rec loop i =
      if i < String.length text then
        match text.[i] with
        | '+' ->
            Buffer.add_char output ' ';
            loop (i + 1)
        | '%' ->
            if i + 2 >= String.length text then
              invalid_arg "Invalid form encoding.";
            Buffer.add_char output
              (Char.chr ((16 * hex text.[i + 1]) + hex text.[i + 2]));
            loop (i + 3)
        | c ->
            Buffer.add_char output c;
            loop (i + 1)
    in
    loop 0;
    Buffer.contents output
  in
  String.split_on_char '&' body
  |> List.map (fun pair ->
      match String.index_opt pair '=' with
      | None -> (decode pair, "")
      | Some i ->
          ( decode (String.sub pair 0 i),
            decode (String.sub pair (i + 1) (String.length pair - i - 1)) ))

let respond output status content_type body =
  Printf.fprintf output
    "HTTP/1.1 %s\r\n\
     Content-Type: %s; charset=utf-8\r\n\
     Content-Length: %d\r\n\
     Connection: close\r\n\
     Cache-Control: no-store\r\n\
     \r\n\
     %s"
    status content_type (String.length body) body;
  flush output

let read_file path =
  let input = open_in_bin path in
  Fun.protect
    ~finally:(fun () -> close_in_noerr input)
    (fun () -> really_input_string input (in_channel_length input))

let handle ~assets ~on_submit input output =
  let request = String.trim (input_line input) in
  let rec headers remaining acc =
    if remaining <= 0 then invalid_arg "Request headers are too large.";
    let line = String.trim (input_line input) in
    if line = "" then acc
    else
      match String.index_opt line ':' with
      | None -> invalid_arg "Invalid request header."
      | Some i ->
          headers
            (remaining - String.length line)
            (( String.lowercase_ascii (String.sub line 0 i),
               String.trim
                 (String.sub line (i + 1) (String.length line - i - 1)) )
            :: acc)
  in
  let headers = headers 16_384 [] in
  match String.split_on_char ' ' request with
  | [ "GET"; path; _ ] -> (
      let asset =
        match path with
        | "/" | "/index.html" -> Some ("index.html", "text/html")
        | "/main.js" -> Some ("main.js", "application/javascript")
        | "/style.css" -> Some ("style.css", "text/css")
        | _ -> None
      in
      match asset with
      | Some (name, mime) ->
          respond output "200 OK" mime (read_file (Filename.concat assets name))
      | None -> respond output "404 Not Found" "text/plain" "Not found.")
  | [ "POST"; "/run"; _ ] -> (
      if
        (* A custom header keeps ordinary cross-origin forms from submitting runs. *)
        List.assoc_opt "x-pbpk-run" headers <> Some "1"
      then
        respond output "403 Forbidden" "text/plain"
          "Submit using the PBPK interface."
      else
        let length =
          match List.assoc_opt "content-length" headers with
          | Some value -> (
              match int_of_string_opt value with
              | Some n when n >= 0 && n <= 16_384 -> n
              | _ -> invalid_arg "Invalid form length.")
          | None -> invalid_arg "Missing form length."
        in
        let fields = decode_form (really_input_string input length) in
        match Model_config.of_fields fields with
        | Error message -> respond output "400 Bad Request" "text/plain" message
        | Ok config ->
            on_submit config;
            respond output "200 OK" "text/plain" (Model_config.summary config))
  | _ ->
      respond output "405 Method Not Allowed" "text/plain"
        "Unsupported request."

let open_browser url =
  if Sys.getenv_opt "PBPK_NO_BROWSER" <> Some "1" then
    try
      let program, args =
        if Sys.os_type = "Win32" then
          ("cmd", [| "cmd"; "/c"; "start"; ""; url |])
        else if Sys.file_exists "/usr/bin/open" then
          ("/usr/bin/open", [| "open"; url |])
        else ("xdg-open", [| "xdg-open"; url |])
      in
      let pid =
        Unix.create_process program args Unix.stdin Unix.stdout Unix.stderr
      in
      match snd (Unix.waitpid [] pid) with
      | Unix.WEXITED 0 -> ()
      | _ -> Printf.eprintf "Open this URL in your browser: %s\n%!" url
    with Unix.Unix_error _ ->
      Printf.eprintf "Open this URL in your browser: %s\n%!" url

let run ~assets ~on_submit =
  let socket = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  Fun.protect
    ~finally:(fun () -> Unix.close socket)
    (fun () ->
      Unix.bind socket (Unix.ADDR_INET (Unix.inet_addr_loopback, 0));
      Unix.listen socket 8;
      let port =
        match Unix.getsockname socket with
        | Unix.ADDR_INET (_, port) -> port
        | _ -> assert false
      in
      let url = Printf.sprintf "http://127.0.0.1:%d/" port in
      Printf.printf
        "PBPK interface: %s\nWaiting for Run. Press Ctrl+C to stop.\n%!" url;
      open_browser url;
      while true do
        let client, _ = Unix.accept socket in
        Unix.setsockopt_float client Unix.SO_RCVTIMEO 5.;
        Unix.setsockopt_float client Unix.SO_SNDTIMEO 5.;
        let input = Unix.in_channel_of_descr client in
        let output = Unix.out_channel_of_descr (Unix.dup client) in
        Fun.protect
          ~finally:(fun () ->
            close_in_noerr input;
            close_out_noerr output)
          (fun () ->
            try handle ~assets ~on_submit input output with
            | Invalid_argument message ->
                respond output "400 Bad Request" "text/plain" message
            | End_of_file | Sys_error _ | Unix.Unix_error _ -> ())
      done)
