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
async fn serve(dist_dir : String, port : Int) -> Unit {
  let deck = @shared.sample_deck()
  let metrics = @shared.sample_metrics()
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
  ..get("/object-viewer.js", _ => {
    asset_response(
      dist_dir + "/object-viewer.js",
      "text/javascript; charset=utf-8",
    )
  })
  ..get("/favicon.ico", _ => @mocket.HttpResponse::new(NoContent))
  ..get("/api/health", _ => json_response(OK, "{\"ok\":true}"))
  ..get("/api/deck", _ => json_response(OK, @shared.deck_response_json(deck)))
  .get("/api/metrics", _ => {
    json_response(OK, @shared.metrics_response_json(metrics))
  })
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
