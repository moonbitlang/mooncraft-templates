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
  #|   if (g.__mooncraftTankHostInput) {
  #|     return;
  #|   }
  #|   const state = {
  #|     justPressed: new Set(),
  #|   };
  #|   g.__mooncraftTankHostInput = state;
  #|   const supported = new Set(["KeyR"]);
  #|   g.addEventListener("keydown", (event) => {
  #|     const code = event.code || "";
  #|     if (supported.has(code) && !event.repeat) {
  #|       state.justPressed.add(code);
  #|     }
  #|   });
  #|   g.addEventListener("blur", () => {
  #|     state.justPressed.clear();
  #|   });
  #| }

///|
extern "js" fn take_host_web_key(code : String) -> Bool =
  #| (code) => {
  #|   const state = globalThis.__mooncraftTankHostInput;
  #|   if (!state) {
  #|     return false;
  #|   }
  #|   const hit = state.justPressed.has(code);
  #|   state.justPressed.delete(code);
  #|   return hit;
  #| }

///|
pub fn prepare_run(_hidden_window : Bool) -> Unit {
  ensure_host_web_input()
}

///|
pub fn is_key_pressed(key : String) -> Bool {
  ensure_host_web_input()
  take_host_web_key(key_code_name(key))
}
