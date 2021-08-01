open Yocaml.Util

module Traverse =
  Preface.List.Applicative.Traversable (Yocaml.Validate.Applicative)

module Ingredient = struct
  type t =
    { name : string
    ; quantity : string
    }

  let make name quantity = { name; quantity }

  let from (type a) (module V : Yocaml.Metadata.VALIDABLE with type t = a) obj
    =
    let open Yocaml.Validate in
    let open V in
    object_and
      (fun step ->
        let open Applicative in
        let open Alt in
        make
        <$> required_assoc string "name" step
        <*> (required_assoc text "qty" step
            <|> required_assoc text "quantity" step))
      obj
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

  let from (type a) (module V : Yocaml.Metadata.VALIDABLE with type t = a) obj
    =
    let open Yocaml.Validate in
    let open V in
    object_and
      (fun step ->
        let open Applicative in
        make
        <$> required_assoc string "name" step
        <*> required_assoc (list_of string) "tasks" step)
      obj
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

  let from_string (module V : Yocaml.Metadata.VALIDABLE) = function
    | None -> Yocaml.Error.(to_validate $ Required_metadata [ "Recipe" ])
    | Some str ->
      let open Yocaml.Validate in
      let open Monad.Infix in
      let open V in
      V.from_string str
      >>= object_and (fun obj ->
              let open Applicative.Infix in
              make
              <$> required_assoc string "name" obj
              <*> required_assoc string "synopsis" obj
              <*> required_assoc
                    (Yocaml.Metadata.Date.from (module V))
                    "date"
                    obj
              <*> required_assoc
                    (list_of $ Ingredient.from (module V))
                    "ingredients"
                    obj
              <*> optional_assoc_or ~default:[] (list_of string) "tools" obj
              <*> required_assoc (list_of $ Step.from (module V)) "steps" obj
              <*> optional_assoc_or
                    ~default:[]
                    (list_of string)
                    "final_tasks"
                    obj
              <*> optional_assoc_or ~default:[] (list_of string) "tags" obj)
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
