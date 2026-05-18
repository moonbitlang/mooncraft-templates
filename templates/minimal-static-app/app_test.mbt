///|
test "page includes stable app content" {
  let html = page()
  assert_true(html.contains("<main>"))
  assert_true(html.contains(title()))
  assert_true(html.contains("rendered by MoonBit"))
}
