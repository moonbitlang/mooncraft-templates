///|
using @html {
  aside,
  button,
  div,
  footer,
  h1,
  h2,
  h3,
  header,
  input,
  label,
  main_,
  node,
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
  simulation_demand_shift : Int
  simulation_supply_shift : Int
  elapsed_seconds : Int
  busy : Bool
  fullscreen : Bool
  show_notes : Bool
  error : String?
}

///|
enum Msg {
  MetricsLoaded(Result[@shared.MetricsResponse, Error])
  RefreshMetrics
  PollMetrics
  Tick
  Next
  Previous
  First
  Last
  GoTo(Int)
  ZoomIn
  ZoomOut
  FactorChanged(String)
  SimulationDemandChanged(String)
  SimulationSupplyChanged(String)
  ToggleFullscreen
  ToggleNotes
  ClosePanels
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
    simulation_demand_shift: 0,
    simulation_supply_shift: 0,
    elapsed_seconds: 0,
    busy: false,
    fullscreen: false,
    show_notes: false,
    error: None,
  }
}

///|
fn fetch_metrics(emit : @rabbita.Emit[Msg]) -> @rabbita.Cmd {
  @http.get("/api/metrics").expect_json(result => emit(MetricsLoaded(result)))
}

///|
fn clamp_zoom(value : Int) -> Int {
  clamp_int(value, 80, 140)
}

///|
fn clamp_int(value : Int, min : Int, max : Int) -> Int {
  if value < min {
    min
  } else if value > max {
    max
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
fn number_key(value : String) -> Int? {
  let parsed = @string.parse_int(value) catch { _ => return None }
  if parsed >= 1 && parsed <= 9 {
    Some(parsed - 1)
  } else {
    None
  }
}

///|
fn handle_key(key : @common.Keyboard) -> Msg? {
  match key.key() {
    "ArrowRight" | " " | "PageDown" => Some(Next)
    "ArrowLeft" | "PageUp" => Some(Previous)
    "Home" => Some(First)
    "End" => Some(Last)
    "f" | "F" => Some(ToggleFullscreen)
    "n" | "N" => Some(ToggleNotes)
    "Escape" => Some(ClosePanels)
    key_value =>
      match number_key(key_value) {
        Some(index) => Some(GoTo(index))
        None => None
      }
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
    PollMetrics => (fetch_metrics(emit), model)
    Tick =>
      (@rabbita.none, { ..model, elapsed_seconds: model.elapsed_seconds + 1 })
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
    First => (@rabbita.none, { ..model, current: 0 })
    Last =>
      (
        @rabbita.none,
        { ..model, current: @shared.last_slide_index(model.deck) },
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
    SimulationDemandChanged(value) =>
      (
        @rabbita.none,
        {
          ..model,
          simulation_demand_shift: clamp_int(
            parse_percent(value, model.simulation_demand_shift),
            -30,
            30,
          ),
        },
      )
    SimulationSupplyChanged(value) =>
      (
        @rabbita.none,
        {
          ..model,
          simulation_supply_shift: clamp_int(
            parse_percent(value, model.simulation_supply_shift),
            -30,
            30,
          ),
        },
      )
    ToggleFullscreen => {
      if model.fullscreen {
        exit_presentation_fullscreen()
      } else {
        request_presentation_fullscreen()
      }
      (@rabbita.none, { ..model, fullscreen: !model.fullscreen })
    }
    ToggleNotes => (@rabbita.none, { ..model, show_notes: !model.show_notes })
    ClosePanels => {
      if model.fullscreen {
        exit_presentation_fullscreen()
      }
      (@rabbita.none, { ..model, fullscreen: false, show_notes: false })
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
  @sub.batch([
    @sub.on_key_down(key => emit(KeyPressed(key))),
    @sub.every(1000, emit(Tick)),
    @sub.every(5000, emit(PollMetrics)),
  ])
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
fn two_digits(value : Int) -> String {
  if value < 10 {
    "0\{value}"
  } else {
    "\{value}"
  }
}

///|
fn elapsed_time(seconds : Int) -> String {
  let minutes = seconds / 60
  let remainder = seconds % 60
  "\{minutes}:\{two_digits(remainder)}"
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
fn abs_int(value : Int) -> Int {
  if value < 0 {
    -value
  } else {
    value
  }
}

///|
fn chart_x(quantity : Int) -> Int {
  60 + quantity * 620 / 100
}

///|
fn chart_y(price : Int) -> Int {
  388 - clamp_int(price, 0, 140) * 360 / 140
}

///|
fn demand_price(quantity : Int, shift : Int) -> Int {
  clamp_int(
    122 + shift - quantity * 245 / 100 + quantity * quantity / 100,
    0,
    140,
  )
}

///|
fn supply_price(quantity : Int, shift : Int) -> Int {
  clamp_int(
    15 + shift + quantity * 240 / 100 - quantity * quantity / 62,
    0,
    140,
  )
}

///|
fn equilibrium_quantity(model : Model) -> Int {
  let mut best_quantity = 1
  let mut best_gap = 999
  for quantity in 1..<=100 {
    let gap = abs_int(
      demand_price(quantity, model.simulation_demand_shift) -
      supply_price(quantity, model.simulation_supply_shift),
    )
    if gap < best_gap {
      best_gap = gap
      best_quantity = quantity
    }
  }
  best_quantity
}

///|
fn equilibrium_price(model : Model) -> Int {
  let quantity = equilibrium_quantity(model)
  (
    demand_price(quantity, model.simulation_demand_shift) +
    supply_price(quantity, model.simulation_supply_shift)
  ) /
  2
}

///|
fn total_revenue(model : Model) -> Int {
  equilibrium_price(model) * equilibrium_quantity(model)
}

///|
fn total_cost(model : Model) -> Int {
  total_revenue(model) * 66 / 100
}

///|
fn profit(model : Model) -> Int {
  total_revenue(model) - total_cost(model)
}

///|
fn profit_margin(model : Model) -> Int {
  if total_revenue(model) == 0 {
    0
  } else {
    profit(model) * 100 / total_revenue(model)
  }
}

///|
fn consumer_surplus(model : Model) -> Int {
  let quantity = equilibrium_quantity(model)
  let price = equilibrium_price(model)
  (demand_price(1, model.simulation_demand_shift) - price) * quantity / 2
}

///|
fn producer_surplus(model : Model) -> Int {
  let quantity = equilibrium_quantity(model)
  let price = equilibrium_price(model)
  (price - supply_price(1, model.simulation_supply_shift)) * quantity / 2
}

///|
fn demand_points(model : Model) -> Array[(Int, Int)] {
  let points : Array[(Int, Int)] = []
  for quantity in 0..<=100 {
    points.push(
      (
        chart_x(quantity),
        chart_y(demand_price(quantity, model.simulation_demand_shift)),
      ),
    )
  }
  points
}

///|
fn supply_points(model : Model) -> Array[(Int, Int)] {
  let points : Array[(Int, Int)] = []
  for quantity in 0..<=100 {
    points.push(
      (
        chart_x(quantity),
        chart_y(supply_price(quantity, model.simulation_supply_shift)),
      ),
    )
  }
  points
}

///|
fn grid_lines() -> Array[@svg.Svg] {
  let nodes : Array[@svg.Svg] = []
  for quantity in 0..<=10 {
    let x = chart_x(quantity * 10)
    nodes.push(
      @svg.line(
        x1=x,
        y1=28,
        x2=x,
        y2=388,
        stroke="#e0e8f2",
        stroke_width=1,
        attrs=@svg.Attrs::build().stroke_dasharray("2 4"),
      ),
    )
  }
  for price in [0, 35, 70, 105, 140] {
    let y = chart_y(price)
    nodes.push(
      @svg.line(
        x1=60,
        y1=y,
        x2=680,
        y2=y,
        stroke="#d9e4ef",
        stroke_width=1,
        attrs=@svg.Attrs::build().stroke_dasharray("3 4"),
      ),
    )
    nodes.push(
      @svg.svg_text(
        x=42,
        y=y + 4,
        text="\{price}",
        fill="#708199",
        attrs=@svg.Attrs::build().font_size("10").text_anchor("end"),
      ),
    )
  }
  nodes
}

///|
fn market_chart(model : Model) -> Html {
  let quantity = equilibrium_quantity(model)
  let price = equilibrium_price(model)
  let x = chart_x(quantity)
  let y = chart_y(price)
  let nodes = grid_lines()
  nodes.push(
    @svg.polyline(
      points=demand_points(model),
      fill="none",
      stroke="#4b8cff",
      stroke_width=2,
      stroke_linecap="round",
    ),
  )
  nodes.push(
    @svg.polyline(
      points=supply_points(model),
      fill="none",
      stroke="#12b886",
      stroke_width=2,
      stroke_linecap="round",
    ),
  )
  nodes.push(
    @svg.line(
      x1=60,
      y1=y,
      x2=680,
      y2=y,
      stroke="#f59e0b",
      stroke_width=1,
      attrs=@svg.Attrs::build().stroke_dasharray("5 5"),
    ),
  )
  nodes.push(@svg.circle(cx=x, cy=y, r=5, fill="#f59e0b"))
  nodes.push(
    @svg.svg_text(
      x=370,
      y=438,
      text="Quantity (units)",
      fill="#667085",
      attrs=@svg.Attrs::build().font_size("12").text_anchor("middle"),
    ),
  )
  nodes.push(
    @svg.svg_text(
      x=18,
      y=210,
      text="Price ($)",
      fill="#667085",
      transform="rotate(-90 18 210)",
      attrs=@svg.Attrs::build().font_size("12").text_anchor("middle"),
    ),
  )
  @svg.svg(
    class="market-chart-svg",
    view_box="0 0 720 460",
    attrs=@svg.Attrs::build().preserve_aspect_ratio("xMidYMid meet"),
    nodes,
  )
}

///|
fn view_curve_control(
  emit : @rabbita.Emit[Msg],
  control_label : String,
  value : Int,
  tone : String,
  msg : (String) -> Msg,
  hint : String,
) -> Html {
  div(class="curve-control", [
    label(class="curve-label", [
      span(class="curve-dot \{tone}", ""),
      strong(control_label),
      span(class="curve-value", "\{value}"),
    ]),
    input(
      input_type=Range,
      min=-30,
      max=30,
      value="\{value}",
      on_input=value => emit(msg(value)),
      nothing,
    ),
    small(hint),
  ])
}

///|
fn outcome_row(label : String, value : String, tone? : String = "") -> Html {
  div(class="outcome-row \{tone}", [span(label), strong(value)])
}

///|
fn legend_item(label : String, tone : String) -> Html {
  span(class="legend-item", [span(class="legend-line \{tone}", ""), span(label)])
}

///|
fn view_simulation_slide(
  emit : @rabbita.Emit[Msg],
  model : Model,
  slide : @shared.Slide,
) -> Html {
  let quantity = equilibrium_quantity(model)
  let price = equilibrium_price(model)
  div(class="slide simulation-slide layout-\{slide.layout}", [
    div(class="simulation-heading", [
      h2(slide.title),
      p(class="body-copy", slide.body),
    ]),
    div(class="simulation-dashboard", [
      div(class="market-chart-card", [
        market_chart(model),
        div(class="market-legend", [
          legend_item("Demand", "demand"),
          legend_item("Supply", "supply"),
          legend_item("Equilibrium", "equilibrium"),
        ]),
      ]),
      div(class="simulation-side", [
        div(class="sim-card", [
          h3("Curve controls"),
          view_curve_control(
            emit,
            "Demand Shift",
            model.simulation_demand_shift,
            "demand",
            value => SimulationDemandChanged(value),
            "<- Less demand | More demand ->",
          ),
          view_curve_control(
            emit,
            "Supply Shift",
            model.simulation_supply_shift,
            "supply",
            value => SimulationSupplyChanged(value),
            "<- Lower costs | Higher costs ->",
          ),
        ]),
        div(class="sim-card equilibrium-card", [
          h3("Market equilibrium"),
          div(class="equilibrium-grid", [
            div([small("Price"), strong("$\{price}")]),
            div([small("Quantity"), strong("\{quantity}")]),
          ]),
        ]),
        div(class="sim-card", [
          h3("Financial outcomes"),
          outcome_row("Total Revenue", "$\{total_revenue(model)}", tone="blue"),
          outcome_row("Total Cost", "$\{total_cost(model)}"),
          outcome_row("Profit", "$\{profit(model)}", tone="green"),
          outcome_row("Profit Margin", "\{profit_margin(model)}%", tone="green"),
          small(class="outcome-section-label", "Economic surplus"),
          outcome_row("Consumer", "$\{consumer_surplus(model)}", tone="blue"),
          outcome_row("Producer", "$\{producer_surplus(model)}", tone="green"),
        ]),
      ]),
    ]),
  ])
}

///|
fn view_title_slide(slide : @shared.Slide) -> Html {
  div(class="slide title-slide layout-\{slide.layout}", [
    p(class="eyebrow", slide.eyebrow),
    h1(slide.title),
    p(class="lead", slide.body),
  ])
}

///|
fn view_agenda_slide(slide : @shared.Slide) -> Html {
  div(class="slide content-slide layout-\{slide.layout}", [
    p(class="eyebrow", slide.eyebrow),
    h2(slide.title),
    p(class="body-copy", slide.body),
    div(
      class="agenda-grid",
      slide.points.map(point => {
        div(class="agenda-item", [
          span(class="agenda-number", "\{point.value}"),
          strong(point.label),
        ])
      }),
    ),
  ])
}

///|
fn view_metrics_slide(
  emit : @rabbita.Emit[Msg],
  model : Model,
  slide : @shared.Slide,
) -> Html {
  div(class="slide content-slide layout-\{slide.layout}", [
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
  div(class="slide content-slide layout-\{slide.layout}", [
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
  div(class="slide content-slide layout-\{slide.layout}", [
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
fn view_comparison_slide(slide : @shared.Slide) -> Html {
  div(class="slide content-slide layout-\{slide.layout}", [
    p(class="eyebrow", slide.eyebrow),
    h2(slide.title),
    p(class="body-copy", slide.body),
    div(
      class="comparison-grid",
      slide.points.map(point => {
        div(class="comparison-card", [
          strong(point.label),
          span("\{point.value}%"),
        ])
      }),
    ),
  ])
}

///|
fn view_quote_slide(slide : @shared.Slide) -> Html {
  div(class="slide quote-slide layout-\{slide.layout}", [
    p(class="eyebrow", slide.eyebrow),
    h2(slide.title),
    p(class="lead", slide.body),
  ])
}

///|
fn view_object_slide(slide : @shared.Slide) -> Html {
  let attrs = @html.Attrs::build()
    .class("moonbit-object-viewer")
    .data_set("word", "MoonBit")
  div(class="slide object-slide layout-\{slide.layout}", [
    div(class="object-copy", [
      p(class="eyebrow", slide.eyebrow),
      h2(slide.title),
      p(class="body-copy", slide.body),
    ]),
    node("mooncraft-word-viewer", attrs, nothing),
  ])
}

///|
fn view_closing_slide(slide : @shared.Slide) -> Html {
  div(class="slide closing-slide layout-\{slide.layout}", [
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
    "agenda" => view_agenda_slide(slide)
    "simulation" => view_simulation_slide(emit, model, slide)
    "metrics" => view_metrics_slide(emit, model, slide)
    "chart" => view_chart_slide(emit, model, slide)
    "comparison" => view_comparison_slide(slide)
    "components" => view_components_slide(slide)
    "quote" => view_quote_slide(slide)
    "object3d" => view_object_slide(slide)
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
    button(type_="button", on_click=emit(ToggleNotes), "Notes"),
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
    span(class="timer", elapsed_time(model.elapsed_seconds)),
    button(type_="button", on_click=emit(ToggleFullscreen), "Fullscreen"),
  ])
}

///|
fn view_notes(slide : @shared.Slide, model : Model) -> Html {
  if model.show_notes {
    aside(class="notes-panel", [small("Speaker notes"), p(slide.notes)])
  } else {
    nothing
  }
}

///|
fn view(emit : @rabbita.Emit[Msg], model : Model) -> Html {
  let slide = active_slide(model)
  main_(class="workspace", [
    view_sidebar(emit, model),
    section(class="stage-shell", style=["--stage-zoom: \{model.zoom}"], [
      div(class="stage", [view_slide(emit, model, slide)]),
      view_notes(slide, model),
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
