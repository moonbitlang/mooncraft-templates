///|
extern "js" fn set_test_text_queue(codepoints : FixedArray[Int]) -> Unit =
  #| (codepoints) => {
  #|   globalThis.__gamepartyHostInput = {
  #|     justPressed: new Set(),
  #|     textQueue: codepoints.slice(),
  #|   };
  #| }

///|
extern "js" fn clear_test_host_input() -> Unit =
  #| () => { delete globalThis.__gamepartyHostInput; }

///|
test "text queue is empty before host input is initialized" {
  clear_test_host_input()
  assert_eq(take_host_web_text_queue().length(), 0)
}

///|
test "draining text input preserves order and consumes the queue" {
  set_test_text_queue([65, 32, 126])
  let codepoints = drain_text_input_codepoints()
  assert_eq(codepoints, [65, 32, 126])
  assert_eq(drain_text_input_codepoints(), [])
  codepoints.push(66)
  assert_eq(codepoints, [65, 32, 126, 66])
  assert_eq(drain_text_input_codepoints(), [])
  clear_test_host_input()
}

///|
test "an initialized empty text queue can be drained repeatedly" {
  set_test_text_queue([])
  assert_eq(drain_text_input_codepoints(), [])
  assert_eq(drain_text_input_codepoints(), [])
  clear_test_host_input()
}
