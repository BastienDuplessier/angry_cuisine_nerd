open Yocaml.Util

module Traverse =
  Preface.List.Applicative.Traversable (Yocaml.Validate.Applicative)

module Ingredient = struct
  type t =
    { name : string
    ; quantity : string
    }

  let make name quantity = { name; quantity }

  let fetch obj field =
    (* This function is a clear proof that I have to improve
       the Metadata API. Sorry for the noise. *)
    let open Yocaml.Metadata.Rules in
    let invalid_ingredient =
      Yocaml.Error.(to_validate $ Invalid_metadata "Ingredients")
    in
    match fetch_field obj field with
    | Some (`A result) ->
      List.map
        (fun potential_ingredient ->
          is_object
            potential_ingredient
            (fun x ->
              let open Yocaml.Validate.Applicative in
              make <$> required_string x "name" <*> required_string x "qty")
            invalid_ingredient)
        result
      |> Traverse.sequence
    | _ -> invalid_ingredient
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

  let fetch obj field =
    (* This function is also a clear proof that I have to improve
       the Metadata API. Sorry for the noise. *)
    let open Yocaml.Metadata.Rules in
    let invalid_step =
      Yocaml.Error.(to_validate $ Invalid_metadata "Steps")
    in
    match fetch_field obj field with
    | Some (`A result) ->
      List.map
        (fun potential_step ->
          is_object
            potential_step
            (fun x ->
              let open Yocaml.Validate.Applicative in
              make
              <$> required_string x "name"
              <*> required_string_list x "tasks")
            invalid_step)
        result
      |> Traverse.sequence
    | _ -> invalid_step
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
    let open Yocaml.Metadata.Rules in
    is_object
      yaml
      (fun obj ->
        let open Yocaml.Validate.Applicative in
        make
        <$> required_string obj "name"
        <*> required_string obj "synopsis"
        <*> required_date obj "date"
        <*> Ingredient.fetch obj "ingredients"
        <*> optional_string_list obj "tools"
        <*> Step.fetch obj "steps"
        <*> optional_string_list obj "final_tasks"
        <*> optional_string_list obj "tags")
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
