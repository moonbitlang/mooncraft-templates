///|
let todos : Array[@shared.Todo] = @shared.initial_todos()

///|
let next_id : Ref[Int] = { val: 3 }

///|
fn json_headers() -> Map[StringView, StringView] {
  { "Content-Type": "application/json; charset=utf-8" }
}

///|
fn content_headers(content_type : String) -> Map[StringView, StringView] {
  { "Content-Type": content_type }
}

///|
fn json_response(
  status : @mocket.StatusCode,
  body : String,
) -> &@mocket.Responder {
  @mocket.HttpResponse::new(status, headers=json_headers()).body(body)
}

///|
fn error_response(
  status : @mocket.StatusCode,
  message : String,
) -> &@mocket.Responder {
  let body = @shared.ErrorResponse::{ error: message }.to_json().stringify()
  json_response(status, body)
}

///|
async fn asset_response(
  path : String,
  content_type : String,
) -> &@mocket.Responder noraise {
  let body = @fs.read_file(path).text() catch {
    _ => return @mocket.HttpResponse::new(NotFound).body("Not Found")
  }
  @mocket.HttpResponse::new(OK, headers=content_headers(content_type)).body(
    body,
  )
}

///|
fn todo_index(id : Int) -> Int? {
  for index in 0..<todos.length() {
    if todos[index].id == id {
      return Some(index)
    }
  }
  None
}

///|
fn route_id(event : @mocket.MocketEvent) -> Int? {
  match event.params.get("id") {
    Some(raw) => Some(@string.parse_int(raw.to_owned())) catch { _ => None }
    None => None
  }
}

///|
fn create_todo(event : @mocket.MocketEvent) -> &@mocket.Responder {
  let payload : @shared.CreateTodo = event.req.json() catch {
    _ => return error_response(BadRequest, "Invalid todo JSON.")
  }
  let content = match @shared.validate_content(payload.content) {
    Ok(value) => value
    Err(message) => return error_response(UnprocessableEntity, message)
  }
  let todo : @shared.Todo = { id: next_id.val, content, completed: false }
  next_id.val = next_id.val + 1
  todos.push(todo)
  json_response(OK, todo.to_json().stringify())
}

///|
fn update_todo(event : @mocket.MocketEvent) -> &@mocket.Responder {
  let id = match route_id(event) {
    Some(id) => id
    None => return error_response(NotFound, "Not found.")
  }
  let index = match todo_index(id) {
    Some(index) => index
    None => return error_response(NotFound, "Todo not found.")
  }
  let payload : @shared.UpdateTodo = event.req.json() catch {
    _ => return error_response(BadRequest, "Invalid update JSON.")
  }
  todos[index] = { ..todos[index], completed: payload.completed }
  json_response(OK, todos[index].to_json().stringify())
}

///|
fn delete_todo(event : @mocket.MocketEvent) -> &@mocket.Responder {
  let id = match route_id(event) {
    Some(id) => id
    None => return error_response(NotFound, "Not found.")
  }
  match todo_index(id) {
    Some(index) => {
      ignore(todos.remove(index))
      let response : &@mocket.Responder = @mocket.HttpResponse::new(NoContent)
      response
    }
    None => error_response(NotFound, "Todo not found.")
  }
}

///|
async fn serve(dist_dir : String, port : Int) -> Unit {
  let app = @mocket.new()
  app
  ..get("/", _ => {
    asset_response(dist_dir + "/index.html", "text/html; charset=utf-8")
  })
  ..get("/index.html", _ => {
    asset_response(dist_dir + "/index.html", "text/html; charset=utf-8")
  })
  ..get("/frontend.js", _ => {
    asset_response(dist_dir + "/frontend.js", "text/javascript; charset=utf-8")
  })
  ..get("/api/health", _ => json_response(OK, "{\"ok\":true}"))
  ..get("/api/todos", _ => json_response(OK, @shared.todos_response_json(todos)))
  ..post("/api/todos", event => create_todo(event))
  ..patch("/api/todos/:id", event => update_todo(event))
  .delete("/api/todos/:id", event => delete_todo(event))
  app.listen("0.0.0.0:\{port}")
}

///|
async fn main {
  let args = @env.args()
  let dist_dir = args.get(1).unwrap_or("preview-dist")
  let port = args
    .get(2)
    .map(fn(raw) { @string.parse_int(raw) catch { _ => 4300 } })
    .unwrap_or(4300)
  serve(dist_dir, port)
}
