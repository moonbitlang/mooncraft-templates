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
  #|     pointerLocked: false,
  #|   };
  #|   g.__mooncraftTankHostInput = state;
  #|   const supported = new Set(["KeyR"]);
  #|   const requestPointerLock = (target) => {
  #|     if (target && target.tagName === "CANVAS" && target.requestPointerLock) {
  #|       const request = target.requestPointerLock();
  #|       if (request && request.catch) {
  #|         request.catch(() => {});
  #|       }
  #|     }
  #|   };
  #|   g.addEventListener("keydown", (event) => {
  #|     const code = event.code || "";
  #|     if (supported.has(code) && !event.repeat) {
  #|       state.justPressed.add(code);
  #|     }
  #|   });
  #|   g.addEventListener("mousedown", (event) => {
  #|     requestPointerLock(event.target);
  #|   });
  #|   g.addEventListener("contextmenu", (event) => {
  #|     if (event.target && event.target.tagName === "CANVAS") {
  #|       event.preventDefault();
  #|     }
  #|   });
  #|   g.document.addEventListener("pointerlockchange", () => {
  #|     state.pointerLocked = g.document.pointerLockElement &&
  #|       g.document.pointerLockElement.tagName === "CANVAS";
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
extern "js" fn host_web_pointer_locked() -> Bool =
  #| () => {
  #|   const state = globalThis.__mooncraftTankHostInput;
  #|   return !!(state && state.pointerLocked);
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

///|
pub fn is_pointer_locked() -> Bool {
  ensure_host_web_input()
  host_web_pointer_locked()
}
