///|
pub(all) struct ChartPoint {
  label : String
  value : Int
} derive(Debug, Eq, ToJson, @json.FromJson)

///|
pub(all) struct Metric {
  label : String
  value : Int
  unit : String
  trend : String
} derive(Debug, Eq, ToJson, @json.FromJson)

///|
pub(all) struct Slide {
  id : Int
  kind : String
  layout : String
  eyebrow : String
  title : String
  body : String
  notes : String
  points : Array[ChartPoint]
  metrics : Array[Metric]
} derive(Debug, Eq, ToJson, @json.FromJson)

///|
pub(all) struct Deck {
  title : String
  presenter : String
  slides : Array[Slide]
} derive(Debug, Eq, ToJson, @json.FromJson)

///|
pub(all) struct DeckResponse {
  deck : Deck
} derive(Debug, Eq, ToJson, @json.FromJson)

///|
pub(all) struct MetricsResponse {
  metrics : Array[Metric]
} derive(Debug, Eq, ToJson, @json.FromJson)

///|
pub(all) struct ErrorResponse {
  error : String
} derive(Debug, Eq, ToJson, @json.FromJson)

///|
pub fn sample_metrics() -> Array[Metric] {
  [
    { label: "Activation", value: 74, unit: "%", trend: "+12%" },
    { label: "Revenue", value: 128, unit: "k", trend: "+18%" },
    { label: "Retention", value: 91, unit: "%", trend: "+6%" },
  ]
}

///|
pub fn sample_deck() -> Deck {
  let metrics = sample_metrics()
  {
    title: "Interactive Presentation",
    presenter: "MoonCraft",
    slides: [
      {
        id: 1,
        kind: "title",
        layout: "hero",
        eyebrow: "Code-powered deck",
        title: "Interactive Presentation",
        body: "A MoonBit full-stack template for live decks, product demos, and explorable stories.",
        notes: "Open with the idea that a slide deck can behave like an app when it is built with MoonBit.",
        points: [],
        metrics: [],
      },
      {
        id: 2,
        kind: "agenda",
        layout: "grid",
        eyebrow: "Talk track",
        title: "What this template demonstrates",
        body: "A concise deck structure with reusable slide kinds and shared presentation rules.",
        notes: "Use this slide to explain the shape of the template before showing live data.",
        points: [
          { label: "Shared deck model", value: 1 },
          { label: "Backend-fed metrics", value: 2 },
          { label: "Interactive chart", value: 3 },
          { label: "Presenter controls", value: 4 },
        ],
        metrics: [],
      },
      {
        id: 3,
        kind: "metrics",
        layout: "metrics",
        eyebrow: "Live backend data",
        title: "Metrics without leaving the deck",
        body: "Typed JSON from the native backend flows through shared DTOs before it reaches the slide.",
        notes: "The metrics refresh through the native backend route, but the JSON contract is defined once in shared.",
        points: [],
        metrics,
      },
      {
        id: 4,
        kind: "chart",
        layout: "chart",
        eyebrow: "Interactive visualization",
        title: "Adjust a scenario live",
        body: "The frontend owns browser state while shared logic keeps calculations deterministic.",
        notes: "Move the slider to show how slide-local state can drive a visualization.",
        points: [
          { label: "Awareness", value: 38 },
          { label: "Trial", value: 56 },
          { label: "Adoption", value: 72 },
          { label: "Expansion", value: 64 },
        ],
        metrics: [],
      },
      {
        id: 5,
        kind: "comparison",
        layout: "split",
        eyebrow: "Layout preset",
        title: "Static slides vs app slides",
        body: "A lightweight preset shows side-by-side content without building a full editor.",
        notes: "This is intentionally a preset, not a drag-and-drop layout system.",
        points: [
          { label: "Static export", value: 42 },
          { label: "Live MoonBit app", value: 86 },
        ],
        metrics: [],
      },
      {
        id: 6,
        kind: "components",
        layout: "grid",
        eyebrow: "Composable slides",
        title: "Slides are regular MoonBit UI",
        body: "Use forms, charts, simulations, API-backed numbers, and custom components inside one presentation frame.",
        notes: "Point out that each tile is rendered by regular MoonBit frontend code.",
        points: [
          { label: "Keyboard", value: 100 },
          { label: "Fullscreen", value: 100 },
          { label: "Thumbnails", value: 100 },
        ],
        metrics: [],
      },
      {
        id: 7,
        kind: "quote",
        layout: "quote",
        eyebrow: "Narrative slide",
        title: "A template should teach architecture by running",
        body: "Readable examples are more useful to agents than hidden scaffolds.",
        notes: "This slide gives agents a simple editorial pattern for quotation or emphasis slides.",
        points: [],
        metrics: [],
      },
      {
        id: 8,
        kind: "object3d",
        layout: "object",
        eyebrow: "3D object viewer",
        title: "Pink MoonBit word object",
        body: "A lightweight browser component renders a draggable 3D word without pulling in a full model pipeline.",
        notes: "This intentionally uses a simple custom element, not glTF or a large 3D dependency.",
        points: [],
        metrics: [],
      },
      {
        id: 9,
        kind: "closing",
        layout: "hero",
        eyebrow: "Ready for agents",
        title: "Copy the architecture, not hidden scaffolds",
        body: "The template is a real MoonBit project with explicit frontend, shared, and backend packages.",
        notes: "End by reinforcing the MoonCraft rule: templates are examples, not hidden generators.",
        points: [],
        metrics: [],
      },
    ],
  }
}

///|
pub fn validate_deck(deck : Deck) -> Result[Unit, String] {
  if deck.title.trim() == "" {
    Err("Deck title is required.")
  } else if deck.slides.length() == 0 {
    Err("Deck must contain at least one slide.")
  } else {
    for slide in deck.slides {
      if slide.title.trim() == "" {
        return Err("Every slide needs a title.")
      } else if slide.layout.trim() == "" {
        return Err("Every slide needs a layout.")
      }
    }
    Ok(())
  }
}

///|
pub fn clamp_slide_index(deck : Deck, index : Int) -> Int {
  let count = deck.slides.length()
  if count == 0 || index < 0 {
    0
  } else if index >= count {
    count - 1
  } else {
    index
  }
}

///|
pub fn next_slide_index(deck : Deck, index : Int) -> Int {
  clamp_slide_index(deck, index + 1)
}

///|
pub fn previous_slide_index(deck : Deck, index : Int) -> Int {
  clamp_slide_index(deck, index - 1)
}

///|
pub fn progress_percent(deck : Deck, index : Int) -> Int {
  let count = deck.slides.length()
  if count == 0 {
    0
  } else {
    (clamp_slide_index(deck, index) + 1) * 100 / count
  }
}

///|
pub fn slide_count(deck : Deck) -> Int {
  deck.slides.length()
}

///|
pub fn last_slide_index(deck : Deck) -> Int {
  let count = slide_count(deck)
  if count == 0 {
    0
  } else {
    count - 1
  }
}

///|
pub fn projected_metric(metric : Metric, factor : Int) -> Int {
  projected_value(metric.value, factor)
}

///|
pub fn projected_value(value : Int, factor : Int) -> Int {
  value * factor / 100
}

///|
pub fn deck_response_json(deck : Deck) -> String {
  DeckResponse::{ deck, }.to_json().stringify()
}

///|
pub fn metrics_response_json(metrics : Array[Metric]) -> String {
  MetricsResponse::{ metrics, }.to_json().stringify()
}
