///|
extern "js" fn start_app(seed_json : String) -> Unit =
  #| (seedJson) => {
  #|   const root = document.getElementById("app");
  #|   const state = { todos: JSON.parse(seedJson).items || [], busy: false };
  #|
  #|   const request = async (url, options = {}) => {
  #|     const response = await fetch(url, {
  #|       headers: { "Content-Type": "application/json" },
  #|       ...options,
  #|     });
  #|     if (!response.ok) {
  #|       const text = await response.text();
  #|       throw new Error(text || `HTTP ${response.status}`);
  #|     }
  #|     return response.status === 204 ? null : response.json();
  #|   };
  #|
  #|   const refresh = async () => {
  #|     state.todos = (await request("/api/todos")).items;
  #|     render();
  #|   };
  #|
  #|   const addTodo = async (event) => {
  #|     event.preventDefault();
  #|     const input = event.currentTarget.elements.content;
  #|     const content = input.value.trim();
  #|     if (!content) return;
  #|     input.value = "";
  #|     await request("/api/todos", {
  #|       method: "POST",
  #|       body: JSON.stringify({ content }),
  #|     });
  #|     await refresh();
  #|   };
  #|
  #|   const toggleTodo = async (todo) => {
  #|     await request(`/api/todos/${todo.id}`, {
  #|       method: "PATCH",
  #|       body: JSON.stringify({ completed: !todo.completed }),
  #|     });
  #|     await refresh();
  #|   };
  #|
  #|   const deleteTodo = async (todo) => {
  #|     await request(`/api/todos/${todo.id}`, { method: "DELETE" });
  #|     await refresh();
  #|   };
  #|
  #|   const button = (label, action) => {
  #|     const node = document.createElement("button");
  #|     node.type = "button";
  #|     node.textContent = label;
  #|     node.addEventListener("click", action);
  #|     return node;
  #|   };
  #|
  #|   const render = () => {
  #|     root.replaceChildren();
  #|     const title = document.createElement("h1");
  #|     title.textContent = "MoonCraft Todo";
  #|     const form = document.createElement("form");
  #|     form.innerHTML = `<input name="content" maxlength="80" placeholder="Add a todo" autocomplete="off"><button>Add</button>`;
  #|     form.addEventListener("submit", addTodo);
  #|     const list = document.createElement("ul");
  #|     for (const todo of state.todos) {
  #|       const item = document.createElement("li");
  #|       item.className = todo.completed ? "done" : "";
  #|       const label = document.createElement("span");
  #|       label.textContent = todo.content;
  #|       item.append(label, button(todo.completed ? "Undo" : "Done", () => toggleTodo(todo)), button("Delete", () => deleteTodo(todo)));
  #|       list.append(item);
  #|     }
  #|     root.append(title, form, list);
  #|   };
  #|
  #|   render();
  #|   refresh().catch((error) => console.error(error));
  #| }

///|
fn main {
  start_app(@shared.todos_response_json(@shared.initial_todos()))
}
