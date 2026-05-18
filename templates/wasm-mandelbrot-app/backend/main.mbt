///|
fn headers(content_type : String) -> Map[String, String] {
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
fn safe_relative_path(path : String) -> String? {
  let target = if path == "/" { "index.html" } else { path[1:].to_owned() }
  if target.contains("..") || target.has_prefix("/") || target == "" {
    None
  } else {
    Some(target)
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
  ..send_response(status, reason, extra_headers=headers(content_type))
  ..write(body)
  .end_response()
}

///|
async fn serve_static(
  conn : @http.ServerConnection,
  dist_dir : String,
  path : String,
) -> Unit {
  if path == "/api/health" {
    send_text(
      conn,
      200,
      "OK",
      "{\"ok\":true}",
      content_type="application/json; charset=utf-8",
    )
    return
  }
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
          extra_headers=headers(content_type(relative)),
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
async fn main {
  let args = @env.args()
  let dist_dir = args.get(1).unwrap_or("preview-dist")
  let port = args
    .get(2)
    .map(fn(raw) { @string.parse_int(raw) catch { _ => 4300 } })
    .unwrap_or(4300)
  let server = @http.Server::new(
    @socket.Addr::parse("0.0.0.0:\{port}"),
    reuse_addr=true,
  )
  server.run_forever((request, _, conn) => {
    serve_static(conn, dist_dir, request.path)
  }) catch {
    err => println("server stopped: \{err}")
  }
}
