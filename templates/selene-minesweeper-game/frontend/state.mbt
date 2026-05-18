///|
const VIEWPORT_WIDTH : Double = 1280.0

///|
const VIEWPORT_HEIGHT : Double = 720.0

///|
const FPS : UInt = 60

///|
const MAX_BOARD_ROWS : Int = 16

///|
const MAX_BOARD_COLS : Int = 30

///|
const MAX_CELL_COUNT : Int = MAX_BOARD_ROWS * MAX_BOARD_COLS

///|
const BOARD_TOP : Double = 122.0

///|
const BOARD_BOTTOM_MARGIN : Double = 48.0

///|
const BOARD_SIDE_MARGIN : Double = 36.0

///|
const BOARD_GAP : Double = 4.0

///|
const STATUS_PANEL_WIDTH : Double = 96.0

///|
const STATUS_PANEL_HEIGHT : Double = 48.0

///|
const FACE_BUTTON_SIZE : Double = 66.0

///|
const DIFFICULTY_BUTTON_HEIGHT : Double = 16.0

///|
const DIFFICULTY_BUTTON_GAP : Double = 10.0

///|
const HOVER_FRAME_THICKNESS : Double = 3.0

///|
const HOVER_FRAME_Z : Double = 210.0

///|
enum Difficulty {
  Beginner
  Intermediate
  Expert
} derive(Eq, Hash, Debug)

///|
enum GamePhase {
  Ready
  Running
  Won
  Lost
} derive(Eq, Debug)

///|
enum CellVisibility {
  Hidden
  Revealed
  Flagged
} derive(Eq, Debug)

///|
struct Cell {
  row : Int
  col : Int
} derive(Eq, Hash, Debug)

///|
priv struct DifficultySpec {
  rows : Int
  cols : Int
  mines : Int
}

///|
priv struct CellData {
  mut has_mine : Bool
  mut adjacent_mines : Int
  mut visibility : CellVisibility
  mut exploded : Bool
}

///|
priv struct BoardLayout {
  left : Double
  top : Double
  width : Double
  height : Double
  cell_size : Double
}

///|
priv struct ButtonRect {
  left : Double
  top : Double
  width : Double
  height : Double
}

///|
priv struct GameState {
  mut current_difficulty : Difficulty
  mut phase : GamePhase
  mut rows : Int
  mut cols : Int
  mut mine_count : Int
  mut revealed_safe_cells : Int
  mut flag_count : Int
  mut first_reveal_done : Bool
  mut seconds_elapsed : Double
  mut hovered_cell : Cell?
  mut board_dirty : Bool
  mut layout_dirty : Bool
  mut mine_text_cache : String
  mut timer_text_cache : String
  mut overlay_text_cache : String
  mut face_text_cache : String
}

///|
let difficulties : Array[Difficulty] = [Beginner, Intermediate, Expert]

///|
let rand : @random.Rand = @random.Rand::new()

///|
let game_state : GameState = {
  current_difficulty: Beginner,
  phase: Ready,
  rows: 9,
  cols: 9,
  mine_count: 10,
  revealed_safe_cells: 0,
  flag_count: 0,
  first_reveal_done: false,
  seconds_elapsed: 0.0,
  hovered_cell: None,
  board_dirty: true,
  layout_dirty: true,
  mine_text_cache: "",
  timer_text_cache: "",
  overlay_text_cache: "",
  face_text_cache: "",
}

///|
let board : Array[CellData] = []

///|
let background_entity : @entity.Entity = @entity.Entity::new()

///|
let header_entity : @entity.Entity = @entity.Entity::new()

///|
let title_entity : @entity.Entity = @entity.Entity::new()

///|
let footer_entity : @entity.Entity = @entity.Entity::new()

///|
let mine_panel_entity : @entity.Entity = @entity.Entity::new()

///|
let mine_text_entity : @entity.Entity = @entity.Entity::new()

///|
let timer_panel_entity : @entity.Entity = @entity.Entity::new()

///|
let timer_text_entity : @entity.Entity = @entity.Entity::new()

///|
let face_panel_entity : @entity.Entity = @entity.Entity::new()

///|
let face_text_entity : @entity.Entity = @entity.Entity::new()

///|
let board_panel_entity : @entity.Entity = @entity.Entity::new()

///|
let overlay_panel_entity : @entity.Entity = @entity.Entity::new()

///|
let overlay_text_entity : @entity.Entity = @entity.Entity::new()

///|
let difficulty_panel_entities : Array[@entity.Entity] = [
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
]

///|
let difficulty_text_entities : Array[@entity.Entity] = [
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
]

///|
let hover_frame_top_entity : @entity.Entity = @entity.Entity::new()

///|
let hover_frame_bottom_entity : @entity.Entity = @entity.Entity::new()

///|
let hover_frame_left_entity : @entity.Entity = @entity.Entity::new()

///|
let hover_frame_right_entity : @entity.Entity = @entity.Entity::new()

///|
let cell_background_entities : Array[@entity.Entity] = []

///|
let cell_text_entities : Array[@entity.Entity] = []

///|
fn difficulty_spec(difficulty : Difficulty) -> DifficultySpec {
  match difficulty {
    Beginner => { rows: 9, cols: 9, mines: 10 }
    Intermediate => { rows: 16, cols: 16, mines: 40 }
    Expert => { rows: 16, cols: 30, mines: 99 }
  }
}

///|
fn total_cells() -> Int {
  game_state.rows * game_state.cols
}

///|
fn safe_cell_target() -> Int {
  total_cells() - game_state.mine_count
}

///|
fn board_index(row : Int, col : Int) -> Int {
  row * game_state.cols + col
}

///|
fn board_index_for_cell(cell : Cell) -> Int {
  board_index(cell.row, cell.col)
}

///|
fn in_bounds(row : Int, col : Int) -> Bool {
  row >= 0 && row < game_state.rows && col >= 0 && col < game_state.cols
}

///|
fn clamp_int(value : Int, minimum : Int, maximum : Int) -> Int {
  if value < minimum {
    minimum
  } else if value > maximum {
    maximum
  } else {
    value
  }
}

///|
fn active_layout() -> BoardLayout {
  let cols = game_state.cols.to_double()
  let rows = game_state.rows.to_double()
  let max_width = VIEWPORT_WIDTH - BOARD_SIDE_MARGIN * 2.0
  let max_height = VIEWPORT_HEIGHT - BOARD_TOP - BOARD_BOTTOM_MARGIN
  let width_fit = (max_width - BOARD_GAP * (cols - 1.0)) / cols
  let height_fit = (max_height - BOARD_GAP * (rows - 1.0)) / rows
  let cell_size_raw = if width_fit < height_fit {
    width_fit
  } else {
    height_fit
  }
  let cell_size = @cmath.floor(cell_size_raw).max(18.0)
  let width = cols * cell_size + BOARD_GAP * (cols - 1.0)
  let height = rows * cell_size + BOARD_GAP * (rows - 1.0)
  let left = (VIEWPORT_WIDTH - width) * 0.5
  let top = BOARD_TOP
  { left, top, width, height, cell_size }
}

///|
fn cell_rect(layout : BoardLayout, cell : Cell) -> ButtonRect {
  let left = layout.left + cell.col.to_double() * (layout.cell_size + BOARD_GAP)
  let top = layout.top + cell.row.to_double() * (layout.cell_size + BOARD_GAP)
  { left, top, width: layout.cell_size, height: layout.cell_size }
}
