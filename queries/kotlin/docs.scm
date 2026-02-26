; Function declarations
(function_declaration
  (simple_identifier) @function.name) @function.definition

; Function return statement
(function_declaration
  (function_body
    (statements
      (jump_expression) @function.return_statement))) @function.definition

; Function parameters
(function_declaration
  (function_value_parameters
    (parameter
      (simple_identifier) @function.parameters.name) @function.parameters.definition)) @function.definition
