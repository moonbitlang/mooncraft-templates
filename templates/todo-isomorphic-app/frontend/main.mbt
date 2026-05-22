///|
using @html {div, h1, form, input, button, ul, li, span, p, nothing, type Html}

///|
struct Model {
  todos : Array[@shared.Todo]
  draft : String
  busy : Bool
  error : String?
}

///|
enum Msg {
  DraftChanged(String)
  Submit
  Toggle(@shared.Todo)
  Delete(Int)
  TodoCreated(Result[@shared.Todo, Error])
  TodoUpdated(Result[@shared.Todo, Error])
  TodoDeleted(Int, Error?)
}

///|
fn initial_model() -> Model {
  { todos: @shared.initial_todos(), draft: "", busy: false, error: None }
}

///|
fn request_error() -> String {
  "Request failed."
}

///|
fn remove_todo(todos : Array[@shared.Todo], id : Int) -> Array[@shared.Todo] {
  todos.filter(todo => todo.id != id)
}

///|
fn replace_todo(
  todos : Array[@shared.Todo],
  updated : @shared.Todo,
) -> Array[@shared.Todo] {
  todos.map(todo => if todo.id == updated.id { updated } else { todo })
}

///|
fn update(
  emit : @rabbita.Emit[Msg],
  msg : Msg,
  model : Model,
) -> (@rabbita.Cmd, Model) {
  match msg {
    DraftChanged(value) =>
      (@rabbita.none, { ..model, draft: value, error: None })
    Submit =>
      match @shared.validate_content(model.draft) {
        Ok(content) =>
          (
            @http.post("api/todos")
            .with_json(@shared.CreateTodo::{ content, })
            .expect_json(result => emit(TodoCreated(result))),
            { ..model, draft: "", busy: true, error: None },
          )
        Err(message) =>
          (@rabbita.none, { ..model, error: Some(message), busy: false })
      }
    Toggle(todo) =>
      (
        @http.patch("api/todos/\{todo.id}")
        .with_json(@shared.UpdateTodo::{ completed: !todo.completed })
        .expect_json(result => emit(TodoUpdated(result))),
        { ..model, busy: true, error: None },
      )
    Delete(id) =>
      (
        @http.delete("api/todos/\{id}").expect_empty(result => {
          emit(TodoDeleted(id, result))
        }),
        { ..model, busy: true, error: None },
      )
    TodoCreated(Ok(todo)) =>
      (@rabbita.none, { ..model, todos: model.todos..push(todo), busy: false })
    TodoCreated(Err(_)) =>
      (@rabbita.none, { ..model, busy: false, error: Some(request_error()) })
    TodoUpdated(Ok(todo)) =>
      (
        @rabbita.none,
        { ..model, todos: replace_todo(model.todos, todo), busy: false },
      )
    TodoUpdated(Err(_)) =>
      (@rabbita.none, { ..model, busy: false, error: Some(request_error()) })
    TodoDeleted(id, None) =>
      (
        @rabbita.none,
        { ..model, todos: remove_todo(model.todos, id), busy: false },
      )
    TodoDeleted(_, Some(_)) =>
      (@rabbita.none, { ..model, busy: false, error: Some(request_error()) })
  }
}

///|
fn view_todo(emit : @rabbita.Emit[Msg], todo : @shared.Todo) -> Html {
  li(class=if todo.completed { "done" } else { "" }, [
    span(todo.content),
    button(
      type_="button",
      on_click=emit(Toggle(todo)),
      if todo.completed {
        "Undo"
      } else {
        "Done"
      },
    ),
    button(type_="button", on_click=emit(Delete(todo.id)), "Delete"),
  ])
}

///|
fn view(emit : @rabbita.Emit[Msg], model : Model) -> Html {
  div([
    h1("MoonCraft Todo"),
    form(on_submit=emit(Submit), [
      input(
        input_type=Text,
        name="content",
        value=model.draft,
        maxlength=80,
        placeholder="Add a todo",
        auto_complete=Off,
        on_input=value => emit(DraftChanged(value)),
        nothing,
      ),
      button(type_="submit", disabled=model.busy, "Add"),
    ]),
    match model.error {
      Some(message) => p(style=["color: #9b1c1c"], message)
      None => nothing
    },
    ul(model.todos.map(todo => view_todo(emit, todo))),
  ])
}

///|
fn main {
  let app = @rabbita.cell(model=initial_model(), update~, view~)
  @rabbita.new(app).mount("app")
}
