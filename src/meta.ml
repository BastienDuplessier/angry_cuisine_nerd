open Yocaml.Util

module Traverse =
  Preface.List.Applicative.Traversable (Yocaml.Validate.Applicative)

module Ingredient = struct
  type t =
    { name : string
    ; quantity : string
    }

  let make name quantity = { name; quantity }

  let from_yaml field obj =
    let invalid_ingredient =
      Yocaml.Error.(to_validate $ Invalid_metadata field)
    in
    let open Yocaml.Validate in
    Yaml.as_object
      obj
      (fun step ->
        let open Applicative in
        let open Alt in
        make
        <$> Yaml.(required string "name" step)
        <*> Yaml.(
              required as_string "qty" step
              <|> required as_string "quantity" step))
      invalid_ingredient
  ;;

  let to_mustache { name; quantity } =
    `O [ "name", `String name; "qty", `String quantity ]
  ;;
end

module Tool = struct
  type t = string
end

module Step = struct
  type t =
    { name : string
    ; tasks : string list
    }

  let make name tasks = { name; tasks }

  let from_yaml field obj =
    let invalid_step = Yocaml.Error.(to_validate $ Invalid_metadata field) in
    let open Yocaml.Validate in
    Yaml.as_object
      obj
      (fun step ->
        let open Applicative in
        make
        <$> Yaml.(required string "name" step)
        <*> Yaml.(required (list string) "tasks" step))
      invalid_step
  ;;

  let to_mustache { name; tasks } =
    `O
      [ "name", `String name
      ; "tasks", `A (List.map (fun x -> `String x) tasks)
      ]
  ;;
end

module Recipe = struct
  type t =
    { name : string
    ; synopsis : string
    ; date : Yocaml.Metadata.Date.t
    ; ingredients : Ingredient.t list
    ; tools : Tool.t list
    ; steps : Step.t list
    ; final_tasks : string list
    ; tags : string list
    }

  let make name synopsis date ingredients tools steps final_tasks tags =
    { name; synopsis; date; ingredients; tools; steps; final_tasks; tags }
  ;;

  let from_yaml yaml =
    let open Yocaml.Util in
    let open Yocaml.Validate in
    Yaml.as_object
      yaml
      (fun obj ->
        let open Applicative in
        make
        <$> Yaml.(required string "name" obj)
        <*> Yaml.(required string "synopsis" obj)
        <*> Yaml.(required Yocaml.Metadata.Date.from_yaml "date" obj)
        <*> Yaml.(required (list Ingredient.from_yaml) "ingredients" obj)
        <*> Yaml.(with_default ~default:[] (list string) "tools" obj)
        <*> Yaml.(required (list Step.from_yaml) "steps" obj)
        <*> Yaml.(with_default ~default:[] (list string) "final_tasks" obj)
        <*> Yaml.(with_default ~default:[] (list string) "tags" obj))
      Yocaml.Error.(to_validate $ Invalid_metadata "Recipe")
  ;;

  let from_string = function
    | None -> Yocaml.Error.(to_validate $ Invalid_metadata "Recipe")
    | Some str ->
      Result.fold ~ok:from_yaml ~error:(function `Msg e ->
          Yocaml.Error.(to_validate $ Yaml e))
      $ Yaml.of_string str
  ;;

  let is_not_empty = function
    | [] -> `Bool false
    | _ -> `Bool true
  ;;

  let to_mustache
      { name; synopsis; date; ingredients; tools; steps; final_tasks; tags }
    =
    [ "name", `String name
    ; "synopsis", `String synopsis
    ; "date", `O (Yocaml.Metadata.Date.to_mustache date)
    ; "ingredients", `A (List.map Ingredient.to_mustache ingredients)
    ; "tools", `A (List.map (fun x -> `String x) tools)
    ; "steps", `A (List.map Step.to_mustache steps)
    ; "final_tasks", `A (List.map (fun x -> `String x) final_tasks)
    ; "tags", `A (List.map (fun x -> `String x) tags)
    ; "has_tools", is_not_empty tools
    ; "has_tags", is_not_empty tags
    ; "has_final_tasks", is_not_empty final_tasks
    ]
  ;;
end

module Recipes = struct
  type t = (Recipe.t * string) list

  let make ?(decreasing = true) recipes =
    List.sort
      (fun (a, _) (b, _) ->
        let a_date = a.Recipe.date
        and b_date = b.Recipe.date in
        let r = Yocaml.Metadata.Date.compare a_date b_date in
        if decreasing then ~-r else r)
      recipes
  ;;

  let to_mustache recipes =
    [ ( "recipes"
      , `A
          (List.map
             (fun (recipe, link) ->
               `O (("link", `String link) :: Recipe.to_mustache recipe))
             recipes) )
    ]
  ;;
end
