///|
fn headers(content_type : String) -> Map[String, String] {
  { "Content-Type": content_type }
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
async fn handle_request(conn : @http.ServerConnection, path : String) -> Unit {
  if path == "/" || path == "/index.html" {
    send_text(
      conn,
      200,
      "OK",
      @app.page(),
      content_type="text/html; charset=utf-8",
    )
  } else if path == "/api/health" {
    send_text(
      conn,
      200,
      "OK",
      "{\"status\":\"ok\"}\n",
      content_type="application/json; charset=utf-8",
    )
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

///|
async fn main {
  let args = @env.args()
  let port = args
    .get(1)
    .map(fn(raw) { @string.parse_int(raw) catch { _ => 4300 } })
    .unwrap_or(4300)
  let server = @http.Server::new(
    @socket.Addr::parse("0.0.0.0:\{port}"),
    reuse_addr=true,
  )
  server.run_forever((request, _, conn) => handle_request(conn, request.path)) catch {
    err => println("server stopped: \{err}")
  }
}
