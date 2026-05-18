///|
let todos : Array[@shared.Todo] = @shared.initial_todos()

///|
let next_id : Ref[Int] = { val: 3 }

///|
fn json_headers() -> Map[String, String] {
  { "Content-Type": "application/json; charset=utf-8" }
}

///|
fn text_headers(content_type : String) -> Map[String, String] {
  { "Content-Type": content_type }
}

///|
fn content_type(path : String) -> String {
  match path {
    [.., .. ".html"] => "text/html; charset=utf-8"
    [.., .. ".js"] => "text/javascript; charset=utf-8"
    [.., .. ".css"] => "text/css; charset=utf-8"
    [.., .. ".wasm"] => "application/wasm"
    _ => "application/octet-stream"
  }
}

///|
async fn send_text(
  conn : @http.ServerConnection,
  status : Int,
  reason : String,
  body : String,
  content_type~ : String,
) -> Unit {
  conn
  ..send_response(status, reason, extra_headers=text_headers(content_type))
  ..write(body)
  .end_response()
}

///|
async fn send_json(conn : @http.ServerConnection, body : String) -> Unit {
  conn
  ..send_response(200, "OK", extra_headers=json_headers())
  ..write(body)
  .end_response()
}

///|
async fn send_error(
  conn : @http.ServerConnection,
  status : Int,
  reason : String,
  message : String,
) -> Unit {
  let body = @shared.ErrorResponse::{ error: message }.to_json().stringify()
  conn
  ..send_response(status, reason, extra_headers=json_headers())
  ..write(body)
  .end_response()
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
fn parse_id(path : String, prefix : String) -> Int? {
  match path.strip_prefix(prefix) {
    Some(raw) => Some(@string.parse_int(raw.to_owned())) catch { _ => None }
    None => None
  }
}

///|
async fn handle_todos(
  request : @http.Request,
  body : &@io.Reader,
  conn : @http.ServerConnection,
) -> Unit {
  match (request.meth, request.path) {
    (Get, "/api/todos") => send_json(conn, @shared.todos_response_json(todos))
    (Post, "/api/todos") => {
      let raw = body.read_all().text()
      let payload : @shared.CreateTodo = @json.from_json(@json.parse(raw)) catch {
        _ => {
          send_error(conn, 400, "Bad Request", "Invalid todo JSON.")
          return
        }
      }
      let content = match @shared.validate_content(payload.content) {
        Ok(value) => value
        Err(message) => {
          send_error(conn, 422, "Unprocessable Entity", message)
          return
        }
      }
      let todo : @shared.Todo = { id: next_id.val, content, completed: false }
      next_id.val = next_id.val + 1
      todos.push(todo)
      send_json(conn, todo.to_json().stringify())
    }
    (Patch, path) =>
      match parse_id(path, "/api/todos/") {
        Some(id) =>
          match todo_index(id) {
            Some(index) => {
              let raw = body.read_all().text()
              let payload : @shared.UpdateTodo = @json.from_json(
                @json.parse(raw),
              ) catch {
                _ => {
                  send_error(conn, 400, "Bad Request", "Invalid update JSON.")
                  return
                }
              }
              todos[index] = { ..todos[index], completed: payload.completed }
              send_json(conn, todos[index].to_json().stringify())
            }
            None => send_error(conn, 404, "Not Found", "Todo not found.")
          }
        None => send_error(conn, 404, "Not Found", "Not found.")
      }
    (Delete, path) =>
      match parse_id(path, "/api/todos/") {
        Some(id) =>
          match todo_index(id) {
            Some(index) => {
              ignore(todos.remove(index))
              conn..send_response(204, "No Content").end_response()
            }
            None => send_error(conn, 404, "Not Found", "Todo not found.")
          }
        None => send_error(conn, 404, "Not Found", "Not found.")
      }
    _ => send_error(conn, 404, "Not Found", "Not found.")
  }
}

///|
fn safe_relative_path(path : String) -> String? {
  let target = if path == "/" { "index.html" } else { path[1:].to_owned() }
  if target.contains("..") || target.has_prefix("/") || target == "" {
    None
  } else {
    Some(target)
  }
}

///|
async fn serve_static(
  conn : @http.ServerConnection,
  dist_dir : String,
  path : String,
) -> Unit {
  match safe_relative_path(path) {
    Some(relative) => {
      let full_path = dist_dir + "/" + relative
      if @fs.exists(full_path) {
        let file = @fs.open(full_path, mode=ReadOnly)
        defer file.close()
        conn
        ..send_response(
          200,
          "OK",
          extra_headers=text_headers(content_type(relative)),
        )
        ..write_reader(file)
        .end_response()
      } else {
        send_text(
          conn,
          404,
          "Not Found",
          "Not Found",
          content_type="text/plain; charset=utf-8",
        )
      }
    }
    None =>
      send_text(
        conn,
        404,
        "Not Found",
        "Not Found",
        content_type="text/plain; charset=utf-8",
      )
  }
}

///|
async fn serve(dist_dir : String, port : Int) -> Unit {
  let server = @http.Server::new(
    @socket.Addr::parse("0.0.0.0:\{port}"),
    reuse_addr=true,
  )
  server.run_forever((request, body, conn) => {
    if request.path == "/api/health" {
      send_json(conn, "{\"ok\":true}")
    } else if request.path.has_prefix("/api/todos") {
      handle_todos(request, body, conn)
    } else {
      serve_static(conn, dist_dir, request.path)
    }
  })
}

///|
async fn main {
  let args = @env.args()
  let dist_dir = args.get(1).unwrap_or("preview-dist")
  let port = args
    .get(2)
    .map(fn(raw) { @string.parse_int(raw) catch { _ => 4300 } })
    .unwrap_or(4300)
  serve(dist_dir, port) catch {
    err => println("server stopped: \{err}")
  }
}
