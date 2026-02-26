; Function declarations
(function_declaration
  name: (identifier) @function.name
  body: ((block) @function.end_point
         (#set! function.end_point.position "start"))) @function.definition

; Method declarations
(method_declaration
  name: (field_identifier) @method.name
  body: ((block) @method.end_point
         (#set! method.end_point.position "start"))) @method.definition
