///|
fn new_cell_data() -> CellData {
  { has_mine: false, adjacent_mines: 0, visibility: Hidden, exploded: false }
}

///|
fn clear_board_storage() -> Unit {
  board.clear()
  for _ in 0..<total_cells() {
    board.push(new_cell_data())
  }
}

///|
fn reset_run_state(difficulty : Difficulty) -> Unit {
  let spec = difficulty_spec(difficulty)
  game_state.current_difficulty = difficulty
  game_state.phase = Ready
  game_state.rows = spec.rows
  game_state.cols = spec.cols
  game_state.mine_count = spec.mines
  game_state.revealed_safe_cells = 0
  game_state.flag_count = 0
  game_state.first_reveal_done = false
  game_state.seconds_elapsed = 0.0
  game_state.hovered_cell = None
  game_state.board_dirty = true
  game_state.layout_dirty = true
  game_state.mine_text_cache = ""
  game_state.timer_text_cache = ""
  game_state.overlay_text_cache = ""
  game_state.face_text_cache = ""
  clear_board_storage()
}

///|
fn reset_current_run() -> Unit {
  reset_run_state(game_state.current_difficulty)
}

///|
fn count_mines_around(row : Int, col : Int) -> Int {
  let mut count = 0
  for row_offset in 0..<3 {
    for col_offset in 0..<3 {
      let neighbor_row = row + row_offset - 1
      let neighbor_col = col + col_offset - 1
      if (neighbor_row != row || neighbor_col != col) &&
        in_bounds(neighbor_row, neighbor_col) &&
        board[board_index(neighbor_row, neighbor_col)].has_mine {
        count += 1
      }
      ()
    }
    ()
  }
  count
}

///|
fn recompute_adjacent_mines() -> Unit {
  for row in 0..<game_state.rows {
    for col in 0..<game_state.cols {
      let index = board_index(row, col)
      board[index].adjacent_mines = count_mines_around(row, col)
    }
  }
}

///|
fn initialize_mines_avoiding(safe_cell : Cell) -> Unit {
  let candidates : Array[Int] = []
  for row in 0..<game_state.rows {
    for col in 0..<game_state.cols {
      if row != safe_cell.row || col != safe_cell.col {
        candidates.push(board_index(row, col))
      }
    }
  }
  rand.shuffle(candidates.length(), fn(i, j) {
    let tmp = candidates[i]
    candidates[i] = candidates[j]
    candidates[j] = tmp
  })
  for i in 0..<game_state.mine_count {
    board[candidates[i]].has_mine = true
  }
  recompute_adjacent_mines()
  game_state.first_reveal_done = true
  game_state.phase = Running
}

///|
fn reveal_all_mines() -> Unit {
  for index in 0..<board.length() {
    if board[index].has_mine {
      board[index].visibility = Revealed
    }
  }
}

///|
fn finish_if_won() -> Bool {
  if game_state.phase == Running &&
    game_state.revealed_safe_cells >= safe_cell_target() {
    game_state.phase = Won
    game_state.board_dirty = true
    true
  } else {
    false
  }
}

///|
fn flood_reveal_from(start : Cell) -> Int {
  let queue : Array[Cell] = [start]
  let mut head = 0
  let mut revealed = 0
  while head < queue.length() {
    let cell = queue[head]
    head += 1
    if !in_bounds(cell.row, cell.col) {
      continue
    }
    let index = board_index_for_cell(cell)
    if board[index].visibility != Hidden || board[index].has_mine {
      continue
    }
    board[index].visibility = Revealed
    board[index].exploded = false
    game_state.revealed_safe_cells += 1
    revealed += 1
    if board[index].adjacent_mines == 0 {
      for row_offset in 0..<3 {
        for col_offset in 0..<3 {
          let neighbor_row = cell.row + row_offset - 1
          let neighbor_col = cell.col + col_offset - 1
          if (neighbor_row != cell.row || neighbor_col != cell.col) &&
            in_bounds(neighbor_row, neighbor_col) {
            queue.push(Cell::{ row: neighbor_row, col: neighbor_col })
          }
          ()
        }
        ()
      }
    }
    ()
  } nobreak {
    ()
  }
  revealed
}

///|
fn reveal_cell(cell : Cell) -> Bool {
  if !in_bounds(cell.row, cell.col) ||
    game_state.phase == Won ||
    game_state.phase == Lost {
    return false
  }
  if !game_state.first_reveal_done {
    initialize_mines_avoiding(cell)
  }
  let index = board_index_for_cell(cell)
  if board[index].visibility != Hidden {
    return false
  }
  if board[index].has_mine {
    board[index].visibility = Revealed
    board[index].exploded = true
    reveal_all_mines()
    game_state.phase = Lost
    game_state.board_dirty = true
    return true
  }
  let revealed = flood_reveal_from(cell)
  if revealed > 0 {
    game_state.board_dirty = true
    ignore(finish_if_won())
    return true
  }
  false
}

///|
fn toggle_flag(cell : Cell) -> Bool {
  if !in_bounds(cell.row, cell.col) ||
    game_state.phase == Won ||
    game_state.phase == Lost {
    return false
  }
  let index = board_index_for_cell(cell)
  match board[index].visibility {
    Hidden => {
      board[index].visibility = Flagged
      game_state.flag_count += 1
      game_state.board_dirty = true
      true
    }
    Flagged => {
      board[index].visibility = Hidden
      game_state.flag_count -= 1
      game_state.board_dirty = true
      true
    }
    Revealed => false
  }
}

///|
fn flagged_neighbors(cell : Cell) -> Int {
  let mut count = 0
  for row_offset in 0..<3 {
    for col_offset in 0..<3 {
      let neighbor_row = cell.row + row_offset - 1
      let neighbor_col = cell.col + col_offset - 1
      if (neighbor_row != cell.row || neighbor_col != cell.col) &&
        in_bounds(neighbor_row, neighbor_col) &&
        board[board_index(neighbor_row, neighbor_col)].visibility == Flagged {
        count += 1
      }
      ()
    }
    ()
  }
  count
}

///|
fn chord_reveal(cell : Cell) -> Bool {
  if !in_bounds(cell.row, cell.col) || game_state.phase != Running {
    return false
  }
  let index = board_index_for_cell(cell)
  if board[index].visibility != Revealed || board[index].adjacent_mines <= 0 {
    return false
  }
  if flagged_neighbors(cell) != board[index].adjacent_mines {
    return false
  }
  let neighbors : Array[Cell] = []
  for row_offset in 0..<3 {
    for col_offset in 0..<3 {
      let neighbor_row = cell.row + row_offset - 1
      let neighbor_col = cell.col + col_offset - 1
      if (neighbor_row != cell.row || neighbor_col != cell.col) &&
        in_bounds(neighbor_row, neighbor_col) {
        let neighbor : Cell = Cell::{ row: neighbor_row, col: neighbor_col }
        let neighbor_index : Int = board_index_for_cell(neighbor)
        if board[neighbor_index].visibility == Hidden {
          neighbors.push(neighbor)
        }
      }
      ()
    }
    ()
  }
  let mut changed : Bool = false
  for neighbor in neighbors {
    let neighbor_index : Int = board_index_for_cell(neighbor)
    if board[neighbor_index].has_mine {
      board[neighbor_index].visibility = Revealed
      board[neighbor_index].exploded = true
      reveal_all_mines()
      game_state.phase = Lost
      game_state.board_dirty = true
      return true
    }
    let revealed : Int = flood_reveal_from(neighbor)
    if revealed > 0 {
      changed = true
    }
    ()
  }
  if changed {
    game_state.board_dirty = true
    ignore(finish_if_won())
  }
  changed
}
