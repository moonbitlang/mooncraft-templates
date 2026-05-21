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
  eyebrow : String
  title : String
  body : String
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
        eyebrow: "Code-powered deck",
        title: "Interactive Presentation",
        body: "A MoonBit full-stack template for live decks, product demos, and explorable stories.",
        points: [],
        metrics: [],
      },
      {
        id: 2,
        kind: "metrics",
        eyebrow: "Live backend data",
        title: "Metrics without leaving the deck",
        body: "Typed JSON from the native backend flows through shared DTOs before it reaches the slide.",
        points: [],
        metrics,
      },
      {
        id: 3,
        kind: "chart",
        eyebrow: "Interactive visualization",
        title: "Adjust a scenario live",
        body: "The frontend owns browser state while shared logic keeps calculations deterministic.",
        points: [
          { label: "Awareness", value: 38 },
          { label: "Trial", value: 56 },
          { label: "Adoption", value: 72 },
          { label: "Expansion", value: 64 },
        ],
        metrics: [],
      },
      {
        id: 4,
        kind: "components",
        eyebrow: "Composable slides",
        title: "Slides are regular MoonBit UI",
        body: "Use forms, charts, simulations, API-backed numbers, and custom components inside one presentation frame.",
        points: [
          { label: "Keyboard", value: 100 },
          { label: "Fullscreen", value: 100 },
          { label: "Thumbnails", value: 100 },
        ],
        metrics: [],
      },
      {
        id: 5,
        kind: "closing",
        eyebrow: "Ready for agents",
        title: "Copy the architecture, not hidden scaffolds",
        body: "The template is a real MoonBit project with explicit frontend, shared, and backend packages.",
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
