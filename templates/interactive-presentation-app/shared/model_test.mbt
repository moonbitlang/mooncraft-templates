///|
test "sample deck is valid" {
  debug_inspect(validate_deck(sample_deck()), content="Ok(())")
}

///|
test "navigation clamps to deck bounds" {
  let deck = sample_deck()
  inspect(previous_slide_index(deck, 0), content="0")
  inspect(next_slide_index(deck, 99), content="8")
}

///|
test "progress is based on clamped slide index" {
  let deck = sample_deck()
  inspect(progress_percent(deck, 0), content="11")
  inspect(progress_percent(deck, 3), content="44")
  inspect(progress_percent(deck, 99), content="100")
}

///|
test "deck response round trips through json" {
  let raw = deck_response_json(sample_deck())
  let parsed : DeckResponse = @json.from_json(@json.parse(raw))
  inspect(parsed.deck.slides.length(), content="9")
  inspect(parsed.deck.slides[2].metrics.length(), content="3")
}

///|
test "last slide index follows deck length" {
  inspect(last_slide_index(sample_deck()), content="8")
}
