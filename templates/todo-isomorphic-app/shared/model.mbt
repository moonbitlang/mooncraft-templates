///|
pub(all) struct Todo {
  id : Int
  content : String
  completed : Bool
} derive(Debug, Eq, ToJson, @json.FromJson)

///|
pub(all) struct CreateTodo {
  content : String
} derive(Debug, Eq, ToJson, @json.FromJson)

///|
pub(all) struct UpdateTodo {
  completed : Bool
} derive(Debug, Eq, ToJson, @json.FromJson)

///|
pub(all) struct TodosResponse {
  items : Array[Todo]
} derive(Debug, Eq, ToJson, @json.FromJson)

///|
pub(all) struct ErrorResponse {
  error : String
} derive(Debug, Eq, ToJson, @json.FromJson)

///|
pub fn initial_todos() -> Array[Todo] {
  [
    { id: 1, content: "Read the MoonBit multi-target app", completed: true },
    { id: 2, content: "Edit shared types once", completed: false },
  ]
}

///|
pub fn validate_content(content : String) -> Result[String, String] {
  let trimmed = content.trim()
  if trimmed == "" {
    Err("Todo content is required.")
  } else if trimmed.length() > 80 {
    Err("Todo content must be 80 characters or less.")
  } else {
    Ok(trimmed.to_owned())
  }
}

///|
pub fn todos_response_json(items : Array[Todo]) -> String {
  TodosResponse::{ items, }.to_json().stringify()
}
