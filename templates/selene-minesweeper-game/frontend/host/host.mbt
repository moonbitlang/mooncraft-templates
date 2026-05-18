///|
pub(all) struct Sound(Int)

///|
fn key_code_name(key : String) -> String {
  match key {
    "Apostrophe" => "Quote"
    _ => key
  }
}

///|
extern "js" fn ensure_host_web_input() -> Unit =
  #| () => {
  #|   const g = globalThis;
  #|   if (g.__gamepartyHostInput) {
  #|     return;
  #|   }
  #|   const state = {
  #|     justPressed: new Set(),
  #|     textQueue: [],
  #|   };
  #|   g.__gamepartyHostInput = state;
  #|   const supported = new Set([
  #|     "F2",
  #|     "F3",
  #|     "Digit1",
  #|     "Digit2",
  #|     "Digit3",
  #|     "Backspace",
  #|     "Quote",
  #|   ]);
  #|   g.addEventListener("keydown", (event) => {
  #|     const code = event.code || "";
  #|     if (supported.has(code) && !event.repeat) {
  #|       state.justPressed.add(code);
  #|       if (code === "Backspace") {
  #|         event.preventDefault();
  #|       }
  #|     }
  #|     if (event.ctrlKey || event.metaKey || event.altKey) {
  #|       return;
  #|     }
  #|     if (typeof event.key !== "string" || event.key.length !== 1) {
  #|       return;
  #|     }
  #|     const cp = event.key.codePointAt(0);
  #|     if (cp >= 32 && cp <= 126) {
  #|       state.textQueue.push(cp);
  #|     }
  #|   });
  #|   g.addEventListener("blur", () => {
  #|     state.justPressed.clear();
  #|     state.textQueue = [];
  #|   });
  #| }

///|
extern "js" fn take_host_web_key(code : String) -> Bool =
  #| (code) => {
  #|   const state = globalThis.__gamepartyHostInput;
  #|   if (!state) {
  #|     return false;
  #|   }
  #|   const hit = state.justPressed.has(code);
  #|   state.justPressed.delete(code);
  #|   return hit;
  #| }

///|
extern "js" fn take_host_web_text_queue() -> Array[Int] =
  #| () => {
  #|   const state = globalThis.__gamepartyHostInput;
  #|   if (!state) {
  #|     return [];
  #|   }
  #|   const out = state.textQueue.slice();
  #|   state.textQueue = [];
  #|   return out;
  #| }

///|
pub fn prepare_run(_hidden_window : Bool) -> Unit {
  ensure_host_web_input()
}

///|
pub fn take_screenshot(_path : String) -> Unit {
  ()
}

///|
pub fn exit_fullscreen_if_needed() -> Unit {
  ()
}

///|
pub fn is_key_pressed(key : String) -> Bool {
  ensure_host_web_input()
  take_host_web_key(key_code_name(key))
}

///|
pub fn drain_text_input_codepoints() -> Array[Int] {
  ensure_host_web_input()
  take_host_web_text_queue()
}

///|
pub fn sound_from_wav_bytes(_wav_bytes : Bytes) -> Sound {
  Sound(0)
}

///|
pub fn play_sound(_sound : Sound) -> Unit {
  ()
}
