; Function declarations
(function_declaration
  (simple_identifier) @function.name) @function.definition

; Property declarations
(property_declaration
  (variable_declaration
    (simple_identifier) @variable.name)) @variable.definition

; Class declarations (also covers interfaces)
(class_declaration
  (type_identifier) @class.name) @class.definition

; Object declarations
(object_declaration
  (type_identifier) @class.name) @class.definition

; Function return type
(function_declaration
  (user_type) @function.return_type) @function.definition

; Function parameters
(function_declaration
  (function_value_parameters
    (parameter
      (simple_identifier) @function.parameters.name) @function.parameters.definition)) @function.definition
