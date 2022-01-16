open Yocaml
module Data = Yocaml_yaml
module Markup = Yocaml_markdown
module Tpl = Yocaml_jingoo

open struct
  type strategy =
    | Build
    | Serve of int option
    | Print_usage

  let default_port = 8000

  (* Defines the destination directory *)
  let root = "_site"
  let folder = "angry_cuisine_nerd"
  let target = folder |> into root
  let binary = Sys.argv.(0)

  let get_recipe_url source =
    let filename = basename $ replace_extension source "html" in
    into "recipes" filename
  ;;

  (* An arrow that recompiles a file if the binary, [angry_generator.exe] has
     been updated. An arrow that recompiles a file if the binary,
    [angry_generator.exe] has been updated (recompile after generation) *)
  let track_binary = Build.watch binary

  (* Rule for copying CSS files to the correct destination directory. *)
  let css =
    let open Build in
    process_files [ "css/" ] (with_extension "css")
    $ copy_file ~into:(into target "css")
  ;;

  (* Rule for processing recipes. *)
  let recipes =
    let open Build in
    process_files [ "recipes/" ] (with_extension "md")
    $ fun file ->
    create_file
      (into target $ get_recipe_url file)
      (track_binary
      >>> Data.read_file_with_metadata (module Meta.Recipe) file
      >>> Markup.content_to_html ()
      >>> Tpl.apply_as_template (module Meta.Recipe) "templates/recipe.html"
      >>> Tpl.apply_as_template (module Meta.Recipe) "templates/layout.html"
      >>^ Stdlib.snd)
  ;;

  let get_recipe (module V : Metadata.VALIDABLE) recipe_file =
    let arr =
      Build.read_file_with_metadata
        (module V)
        (module Meta.Recipe)
        recipe_file
    in
    let deps = Build.get_dependencies arr in
    let task = Build.get_task arr in
    let+ meta, _ = task () in
    deps, (meta, get_recipe_url recipe_file)
  ;;

  let get_recipes (module V : Metadata.VALIDABLE) path =
    let* files = read_child_files path (with_extension "md") in
    let+ recipes = Traverse.traverse (get_recipe (module V)) files in
    let deps, effects = List.split recipes in
    Deps.Monoid.reduce deps, effects
  ;;

  let get_recipes_arrowized (module V : Metadata.VALIDABLE) path =
    let+ deps, recipes = get_recipes (module V) path in
    Build.make deps (fun x -> return (x, recipes))
  ;;

  let index =
    let open Build in
    let* recipes = get_recipes_arrowized (module Data) "recipes" in
    create_file
      (into target "index.html")
      (track_binary
      >>> Data.read_file_with_metadata (module Metadata.Page) "index.md"
      >>> Markup.content_to_html ()
      >>> recipes
      >>^ (fun ((_, content), m) -> Meta.Recipes.make m, content)
      >>> Tpl.apply_as_template (module Meta.Recipes) "templates/list.html"
      >>> Tpl.apply_as_template (module Meta.Recipes) "templates/layout.html"
      >>^ Stdlib.snd)
  ;;

  let handle_serve len =
    if len > 2
    then
      Sys.argv.(2)
      |> int_of_string_opt
      |> Option.fold ~none:Print_usage ~some:(fun port -> Serve (Some port))
    else Serve None
  ;;

  let define_strategy () =
    let len = Array.length Sys.argv in
    if len < 2
    then Print_usage
    else (
      let kind = String.lowercase_ascii Sys.argv.(1) in
      match kind with
      | "build" -> Build
      | "serve" -> handle_serve len
      | _ -> Print_usage)
  ;;
end

(* Setup of the logger *)
let () =
  let () = Logs.set_level ~all:true (Some Logs.Info) in
  Logs.set_reporter (Logs_fmt.reporter ())
;;

(* Run the program *)
let () =
  let program =
    let open Yocaml in
    css >> recipes >> index
  in
  match define_strategy () with
  | Print_usage ->
    Logs.warn (fun pp ->
        pp
          "usage: [ %s build ] or [ %s watch *port ], default port is %d"
          binary
          binary
          default_port)
  | Build -> Yocaml_unix.execute program
  | Serve p ->
    let port = Option.value ~default:default_port p in
    let server = Yocaml_unix.serve ~filepath:root ~port program in
    let () =
      Logs.info (fun pp ->
          pp "Website alive on http://localhost:%d/%s/" port folder)
    in
    Lwt_main.run server
;;
