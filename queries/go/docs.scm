; Function declarations
(function_declaration
  name: (identifier) @function.name
  body: ((block) @function.end_point
         (#set! function.end_point.position "start"))) @function.definition
