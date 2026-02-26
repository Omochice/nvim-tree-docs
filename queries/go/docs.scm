; Function declarations
(function_declaration
  name: (identifier) @function.name
  body: ((block) @function.end_point
         (#set! function.end_point.position "start"))) @function.definition

; Type declarations (struct, interface, etc.)
(type_declaration
  (type_spec
    name: (type_identifier) @type.name)) @type.definition

; Variable declarations
(var_declaration
  (var_spec
    name: (identifier) @variable.name)) @variable.definition

; Constant declarations
(const_declaration
  (const_spec
    name: (identifier) @variable.name)) @variable.definition

; Method declarations
(method_declaration
  name: (field_identifier) @method.name
  body: ((block) @method.end_point
         (#set! method.end_point.position "start"))) @method.definition
