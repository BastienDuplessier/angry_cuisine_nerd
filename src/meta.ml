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

  let inject
      (type a)
      (module D : Yocaml.Key_value.DESCRIBABLE with type t = a)
      { name; quantity }
    =
    [ "name", D.string name; "qty", D.string quantity ]
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

  let inject
      (type a)
      (module D : Yocaml.Key_value.DESCRIBABLE with type t = a)
      { name; tasks }
    =
    [ "name", D.string name; "tasks", D.list $ List.map D.string tasks ]
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

  let is_not_empty
      (type a)
      (module D : Yocaml.Key_value.DESCRIBABLE with type t = a)
    = function
    | [] -> D.boolean false
    | _ -> D.boolean true
  ;;

  let inject
      (type a)
      (module D : Yocaml.Key_value.DESCRIBABLE with type t = a)
      { name; synopsis; date; ingredients; tools; steps; final_tasks; tags }
    =
    [ "name", D.string name
    ; "synopsis", D.string synopsis
    ; "date", D.object_ (Yocaml.Metadata.Date.inject (module D) date)
    ; ( "ingredients"
      , D.list
          (List.map
             (fun x -> D.object_ $ Ingredient.inject (module D) x)
             ingredients) )
    ; "tools", D.list (List.map D.string tools)
    ; ( "steps"
      , D.list
          (List.map (fun x -> D.object_ $ Step.inject (module D) x) steps) )
    ; "final_tasks", D.list (List.map D.string final_tasks)
    ; "tags", D.list (List.map D.string tags)
    ; "has_tools", is_not_empty (module D) tools
    ; "has_tags", is_not_empty (module D) tags
    ; "has_final_tasks", is_not_empty (module D) final_tasks
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

  let inject
      (type a)
      (module D : Yocaml.Key_value.DESCRIBABLE with type t = a)
      recipes
    =
    [ ( "recipes"
      , D.list
          (List.map
             (fun (recipe, link) ->
               D.object_
                 (("link", D.string link) :: Recipe.inject (module D) recipe))
             recipes) )
    ]
  ;;
end
