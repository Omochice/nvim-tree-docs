; Function definitions: #let func(params) = body
(let
  pattern: (call
    item: (ident) @function.name)
  value: (_)) @function.definition

; Function parameters
(let
  pattern: (call
    (group
      (ident) @function.parameters.name
      @function.parameters.definition))
  value: (_)) @function.definition

; Variable bindings: #let name = value
(let
  pattern: (ident) @variable.name
  value: (_)) @variable.definition
