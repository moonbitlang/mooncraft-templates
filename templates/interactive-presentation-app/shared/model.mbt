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
        eyebrow: "Product briefing",
        title: "MoonBit Launch Review",
        body: "An interactive product story with live metrics, scenario planning, and a 3D brand moment.",
        notes: "Open with the business question: where should the team focus next?",
        points: [],
        metrics: [],
      },
      {
        id: 2,
        kind: "agenda",
        layout: "grid",
        eyebrow: "Talk track",
        title: "Today's decision path",
        body: "A concise review flow for evaluating launch health and deciding the next campaign focus.",
        notes: "Use this slide to set expectations before moving into live performance data.",
        points: [
          { label: "Launch pulse", value: 1 },
          { label: "Growth scenario", value: 2 },
          { label: "Channel tradeoffs", value: 3 },
          { label: "Brand moment", value: 4 },
        ],
        metrics: [],
      },
      {
        id: 3,
        kind: "metrics",
        layout: "metrics",
        eyebrow: "Live backend data",
        title: "Metrics without leaving the deck",
        body: "Refresh the latest launch metrics while staying in presentation mode.",
        notes: "Use the refresh button to show that the deck can include operational data.",
        points: [],
        metrics,
      },
      {
        id: 4,
        kind: "chart",
        layout: "chart",
        eyebrow: "Interactive visualization",
        title: "Adjust a scenario live",
        body: "Move the scenario factor to compare how demand generation changes funnel outcomes.",
        notes: "Move the slider while discussing which stage is the strongest lever.",
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
        eyebrow: "Channel tradeoff",
        title: "Static launch plan vs live campaign loop",
        body: "Compare a one-time launch package with an adaptive campaign driven by weekly signals.",
        notes: "Frame the decision as speed versus learning rate.",
        points: [
          { label: "One-time launch", value: 42 },
          { label: "Adaptive loop", value: 86 },
        ],
        metrics: [],
      },
      {
        id: 6,
        kind: "components",
        layout: "grid",
        eyebrow: "Presentation controls",
        title: "Run the briefing from one screen",
        body: "Use keyboard navigation, fullscreen mode, speaker notes, and thumbnails while presenting.",
        notes: "Mention only the controls that the audience will see in this briefing.",
        points: [
          { label: "Keyboard", value: 100 },
          { label: "Fullscreen", value: 100 },
          { label: "Thumbnails", value: 100 },
        ],
        metrics: [],
      },
      {
        id: 7,
        kind: "object3d",
        layout: "object",
        eyebrow: "Brand moment",
        title: "Make the product tangible",
        body: "A draggable pink MoonBit word gives the launch story a tactile product moment.",
        notes: "Invite the audience to interact with the object before closing the discussion.",
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
