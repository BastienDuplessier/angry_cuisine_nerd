open Yocaml

open struct
  (* Defines the destination directory *)
  let target = "_site"

  let get_recipe_url source =
    let filename = basename $ replace_extension source "html" in
    into "recipes" filename
  ;;

  (* An arrow that recompiles a file if the binary, [angry_generator.exe] has
     been updated. An arrow that recompiles a file if the binary,
    [angry_generator.exe] has been updated (recompile after generation) *)
  let track_binary = Build.watch Sys.argv.(0)

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
      >>> read_file_with_metadata (module Meta.Recipe) file
      >>> snd process_markdown
      >>> apply_as_template (module Meta.Recipe) "templates/recipe.html"
      >>> apply_as_template (module Meta.Recipe) "templates/layout.html"
      >>^ Stdlib.snd)
  ;;

  let index =
    let open Build in
    let* recipes =
      collection
        (read_child_files "recipes/" (with_extension "md"))
        (fun source ->
          track_binary
          >>> read_file_with_metadata (module Meta.Recipe) source
          >>^ fun (x, _) -> x, get_recipe_url source)
        (fun x _ content -> x |> Meta.Recipes.make |> fun x -> x, content)
    in
    create_file
      (into target "index.html")
      (track_binary
      >>> read_file_with_metadata (module Metadata.Page) "index.md"
      >>> snd process_markdown
      >>> recipes
      >>> apply_as_template (module Meta.Recipes) "templates/list.html"
      >>> apply_as_template (module Meta.Recipes) "templates/layout.html"
      >>^ Stdlib.snd)
  ;;
end

let () =
  let open Yocaml in
  Yocaml_unix.execute (css >> recipes >> index)
;;
