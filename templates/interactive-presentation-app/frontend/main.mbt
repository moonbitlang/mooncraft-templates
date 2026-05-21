///|
using @html {
  aside,
  button,
  div,
  footer,
  h1,
  h2,
  header,
  input,
  label,
  main_,
  nothing,
  p,
  progress,
  section,
  small,
  span,
  strong,
  type Html,
}

///|
extern "js" fn request_presentation_fullscreen() -> Unit =
  #| () => {
  #|   const el = document.querySelector(".workspace");
  #|   if (el && el.requestFullscreen) {
  #|     el.requestFullscreen().catch(() => {});
  #|   }
  #| }

///|
extern "js" fn exit_presentation_fullscreen() -> Unit =
  #| () => {
  #|   if (document.fullscreenElement && document.exitFullscreen) {
  #|     document.exitFullscreen().catch(() => {});
  #|   }
  #| }

///|
struct Model {
  deck : @shared.Deck
  metrics : Array[@shared.Metric]
  current : Int
  zoom : Int
  factor : Int
  busy : Bool
  fullscreen : Bool
  error : String?
}

///|
enum Msg {
  MetricsLoaded(Result[@shared.MetricsResponse, Error])
  RefreshMetrics
  Next
  Previous
  GoTo(Int)
  ZoomIn
  ZoomOut
  FactorChanged(String)
  ToggleFullscreen
  KeyPressed(@common.Keyboard)
}

///|
fn initial_model() -> Model {
  let deck = @shared.sample_deck()
  {
    deck,
    metrics: @shared.sample_metrics(),
    current: 0,
    zoom: 100,
    factor: 100,
    busy: false,
    fullscreen: false,
    error: None,
  }
}

///|
fn fetch_metrics(emit : @rabbita.Emit[Msg]) -> @rabbita.Cmd {
  @http.get("/api/metrics").expect_json(result => emit(MetricsLoaded(result)))
}

///|
fn clamp_zoom(value : Int) -> Int {
  if value < 80 {
    80
  } else if value > 140 {
    140
  } else {
    value
  }
}

///|
fn clamp_bar(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 100 {
    100
  } else {
    value
  }
}

///|
fn parse_percent(value : String, fallback : Int) -> Int {
  @string.parse_int(value) catch {
    _ => fallback
  }
}

///|
fn handle_key(key : @common.Keyboard) -> Msg? {
  match key.key() {
    "ArrowRight" | " " | "PageDown" => Some(Next)
    "ArrowLeft" | "PageUp" => Some(Previous)
    "Escape" => Some(ToggleFullscreen)
    _ => None
  }
}

///|
fn update(
  emit : @rabbita.Emit[Msg],
  msg : Msg,
  model : Model,
) -> (@rabbita.Cmd, Model) {
  match msg {
    MetricsLoaded(Ok(response)) =>
      (
        @rabbita.none,
        { ..model, metrics: response.metrics, busy: false, error: None },
      )
    MetricsLoaded(Err(_)) =>
      (
        @rabbita.none,
        { ..model, busy: false, error: Some("Could not refresh metrics.") },
      )
    RefreshMetrics =>
      (fetch_metrics(emit), { ..model, busy: true, error: None })
    Next =>
      (
        @rabbita.none,
        {
          ..model,
          current: @shared.next_slide_index(model.deck, model.current),
        },
      )
    Previous =>
      (
        @rabbita.none,
        {
          ..model,
          current: @shared.previous_slide_index(model.deck, model.current),
        },
      )
    GoTo(index) =>
      (
        @rabbita.none,
        { ..model, current: @shared.clamp_slide_index(model.deck, index) },
      )
    ZoomIn => (@rabbita.none, { ..model, zoom: clamp_zoom(model.zoom + 10) })
    ZoomOut => (@rabbita.none, { ..model, zoom: clamp_zoom(model.zoom - 10) })
    FactorChanged(value) =>
      (
        @rabbita.none,
        { ..model, factor: clamp_zoom(parse_percent(value, model.factor)) },
      )
    ToggleFullscreen => {
      if model.fullscreen {
        exit_presentation_fullscreen()
      } else {
        request_presentation_fullscreen()
      }
      (@rabbita.none, { ..model, fullscreen: !model.fullscreen })
    }
    KeyPressed(key) =>
      match handle_key(key) {
        Some(next) => update(emit, next, model)
        None => (@rabbita.none, model)
      }
  }
}

///|
fn subscriptions(emit : @rabbita.Emit[Msg], _model : Model) -> @sub.Sub {
  @sub.on_key_down(key => emit(KeyPressed(key)))
}

///|
fn active_slide(model : Model) -> @shared.Slide {
  let index = @shared.clamp_slide_index(model.deck, model.current)
  model.deck.slides[index]
}

///|
fn slide_position(model : Model) -> String {
  "\{model.current + 1} / \{model.deck.slides.length()}"
}

///|
fn view_metric(metric : @shared.Metric, factor : Int) -> Html {
  div(class="metric", [
    small(metric.label),
    strong("\{@shared.projected_metric(metric, factor)}\{metric.unit}"),
    span(class="trend", metric.trend),
  ])
}

///|
fn view_chart(points : Array[@shared.ChartPoint], factor : Int) -> Html {
  div(
    class="chart",
    points.map(point => {
      let value = @shared.projected_value(point.value, factor)
      div(class="bar-row", [
        span(class="bar-label", point.label),
        div(class="bar-track", [
          div(class="bar-fill", style=["width: \{clamp_bar(value)}%"], nothing),
        ]),
        span(class="bar-value", "\{value}%"),
      ])
    }),
  )
}

///|
fn view_title_slide(slide : @shared.Slide) -> Html {
  div(class="title-slide", [
    p(class="eyebrow", slide.eyebrow),
    h1(slide.title),
    p(class="lead", slide.body),
  ])
}

///|
fn view_metrics_slide(
  emit : @rabbita.Emit[Msg],
  model : Model,
  slide : @shared.Slide,
) -> Html {
  div(class="content-slide", [
    p(class="eyebrow", slide.eyebrow),
    h2(slide.title),
    p(class="body-copy", slide.body),
    div(
      class="metrics-grid",
      model.metrics.map(metric => view_metric(metric, model.factor)),
    ),
    button(
      class="secondary",
      type_="button",
      disabled=model.busy,
      on_click=emit(RefreshMetrics),
      "Refresh",
    ),
  ])
}

///|
fn view_chart_slide(
  emit : @rabbita.Emit[Msg],
  model : Model,
  slide : @shared.Slide,
) -> Html {
  div(class="content-slide", [
    p(class="eyebrow", slide.eyebrow),
    h2(slide.title),
    p(class="body-copy", slide.body),
    label(class="slider-label", [
      span("Scenario factor"),
      strong("\{model.factor}%"),
    ]),
    input(
      input_type=Range,
      min=80,
      max=140,
      value="\{model.factor}",
      on_input=value => emit(FactorChanged(value)),
      nothing,
    ),
    view_chart(slide.points, model.factor),
  ])
}

///|
fn view_components_slide(slide : @shared.Slide) -> Html {
  div(class="content-slide", [
    p(class="eyebrow", slide.eyebrow),
    h2(slide.title),
    p(class="body-copy", slide.body),
    div(
      class="component-grid",
      slide.points.map(point => {
        div(class="component-tile", [strong(point.label), span("Ready")])
      }),
    ),
  ])
}

///|
fn view_closing_slide(slide : @shared.Slide) -> Html {
  div(class="closing-slide", [
    p(class="eyebrow", slide.eyebrow),
    h2(slide.title),
    p(class="lead", slide.body),
  ])
}

///|
fn view_slide(
  emit : @rabbita.Emit[Msg],
  model : Model,
  slide : @shared.Slide,
) -> Html {
  match slide.kind {
    "title" => view_title_slide(slide)
    "metrics" => view_metrics_slide(emit, model, slide)
    "chart" => view_chart_slide(emit, model, slide)
    "components" => view_components_slide(slide)
    _ => view_closing_slide(slide)
  }
}

///|
fn view_thumbnail(
  emit : @rabbita.Emit[Msg],
  current : Int,
  index : Int,
  slide : @shared.Slide,
) -> Html {
  button(
    class=if index == current { "thumb active" } else { "thumb" },
    type_="button",
    on_click=emit(GoTo(index)),
    [
      span(class="thumb-number", "\{index + 1}"),
      strong(slide.title),
      small(slide.eyebrow),
    ],
  )
}

///|
fn view_sidebar(emit : @rabbita.Emit[Msg], model : Model) -> Html {
  aside(class="sidebar", [
    header([small(model.deck.presenter), h2(model.deck.title)]),
    div(class="thumb-list", view_thumbnails(emit, model)),
  ])
}

///|
fn view_thumbnails(emit : @rabbita.Emit[Msg], model : Model) -> Array[Html] {
  let items : Array[Html] = []
  for index in 0..<model.deck.slides.length() {
    items.push(
      view_thumbnail(emit, model.current, index, model.deck.slides[index]),
    )
  }
  items
}

///|
fn view_toolbar(emit : @rabbita.Emit[Msg], model : Model) -> Html {
  footer(class="toolbar", [
    button(type_="button", on_click=emit(Previous), "Prev"),
    button(type_="button", on_click=emit(Next), "Next"),
    div(class="progress-readout", [
      span(slide_position(model)),
      progress(
        value=@shared.progress_percent(model.deck, model.current),
        max=100,
        nothing,
      ),
    ]),
    button(type_="button", on_click=emit(ZoomOut), "-"),
    span(class="zoom", "\{model.zoom}%"),
    button(type_="button", on_click=emit(ZoomIn), "+"),
    button(type_="button", on_click=emit(ToggleFullscreen), "Fullscreen"),
  ])
}

///|
fn view(emit : @rabbita.Emit[Msg], model : Model) -> Html {
  let slide = active_slide(model)
  main_(class="workspace", [
    view_sidebar(emit, model),
    section(class="stage-shell", style=["--stage-zoom: \{model.zoom}"], [
      div(class="stage", [view_slide(emit, model, slide)]),
      match model.error {
        Some(message) => p(class="error", message)
        None => nothing
      },
      view_toolbar(emit, model),
    ]),
  ])
}

///|
fn main {
  let app = @rabbita.cell(model=initial_model(), update~, view~, subscriptions~)
  @rabbita.new(app).mount("app")
}
