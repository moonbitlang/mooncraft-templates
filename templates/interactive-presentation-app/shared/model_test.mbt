///|
test "sample deck is valid" {
  debug_inspect(validate_deck(sample_deck()), content="Ok(())")
}

///|
test "navigation clamps to deck bounds" {
  let deck = sample_deck()
  inspect(previous_slide_index(deck, 0), content="0")
  inspect(next_slide_index(deck, 99), content="4")
}

///|
test "progress is based on clamped slide index" {
  let deck = sample_deck()
  inspect(progress_percent(deck, 0), content="20")
  inspect(progress_percent(deck, 2), content="60")
  inspect(progress_percent(deck, 99), content="100")
}

///|
test "deck response round trips through json" {
  let raw = deck_response_json(sample_deck())
  let parsed : DeckResponse = @json.from_json(@json.parse(raw))
  inspect(parsed.deck.slides.length(), content="5")
  inspect(parsed.deck.slides[1].metrics.length(), content="3")
}
