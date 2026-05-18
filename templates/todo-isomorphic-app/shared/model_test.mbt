///|
test "validation trims content" {
  debug_inspect(
    validate_content("  Ship template  "),
    content="Ok(\"Ship template\")",
  )
}

///|
test "todos response round trips through json" {
  let raw = todos_response_json(initial_todos())
  let parsed : TodosResponse = @json.from_json(@json.parse(raw))
  inspect(parsed.items.length(), content="2")
  inspect(parsed.items[0].completed, content="true")
}
