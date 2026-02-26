; Function declarations
(function_declaration
  (simple_identifier) @function.name) @function.definition

; Function parameters
(function_declaration
  (function_value_parameters
    (parameter
      (simple_identifier) @function.parameters.name) @function.parameters.definition)) @function.definition
