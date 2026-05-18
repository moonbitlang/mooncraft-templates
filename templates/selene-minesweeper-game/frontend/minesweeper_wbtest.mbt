///|
fn reset_logic_state_for_test(difficulty : Difficulty) -> Unit {
  reset_run_state(difficulty)
}

///|
fn set_running_board_for_test(difficulty : Difficulty) -> Unit {
  reset_logic_state_for_test(difficulty)
  game_state.phase = Running
  game_state.first_reveal_done = true
}

///|
fn place_mine_for_test(row : Int, col : Int) -> Unit {
  board[board_index(row, col)].has_mine = true
}

///|
fn refresh_counts_for_test() -> Unit {
  recompute_adjacent_mines()
}

///|
fn clear_all_mines_for_test() -> Unit {
  for index in 0..<board.length() {
    board[index].has_mine = false
    board[index].adjacent_mines = 0
    board[index].visibility = Hidden
    board[index].exploded = false
  }
  game_state.revealed_safe_cells = 0
  game_state.flag_count = 0
}

///|
fn mine_count_for_test() -> Int {
  let mut count = 0
  for index in 0..<board.length() {
    if board[index].has_mine {
      count += 1
    }
  }
  count
}

///|
test "mine generation count matches each difficulty" {
  reset_logic_state_for_test(Beginner)
  ignore(reveal_cell(Cell::{ row: 0, col: 0 }))
  assert_eq(mine_count_for_test(), 10)

  reset_logic_state_for_test(Intermediate)
  ignore(reveal_cell(Cell::{ row: 0, col: 0 }))
  assert_eq(mine_count_for_test(), 40)

  reset_logic_state_for_test(Expert)
  ignore(reveal_cell(Cell::{ row: 0, col: 0 }))
  assert_eq(mine_count_for_test(), 99)
}

///|
test "first click is always safe" {
  reset_logic_state_for_test(Expert)
  let first = Cell::{ row: 7, col: 12 }
  ignore(reveal_cell(first))
  let index = board_index_for_cell(first)
  assert_true(!board[index].has_mine)
  assert_true(board[index].visibility == Revealed)
}

///|
test "adjacent mine counts are computed correctly" {
  set_running_board_for_test(Beginner)
  clear_all_mines_for_test()
  place_mine_for_test(1, 1)
  place_mine_for_test(1, 2)
  place_mine_for_test(2, 1)
  refresh_counts_for_test()
  assert_eq(board[board_index(0, 0)].adjacent_mines, 1)
  assert_eq(board[board_index(2, 2)].adjacent_mines, 3)
  assert_eq(board[board_index(0, 2)].adjacent_mines, 2)
}

///|
test "zero flood reveal opens surrounding safe cells" {
  set_running_board_for_test(Beginner)
  clear_all_mines_for_test()
  place_mine_for_test(8, 8)
  refresh_counts_for_test()
  ignore(reveal_cell(Cell::{ row: 0, col: 0 }))
  assert_true(board[board_index(0, 0)].visibility == Revealed)
  assert_true(board[board_index(4, 4)].visibility == Revealed)
  assert_true(board[board_index(8, 7)].visibility == Revealed)
  assert_true(board[board_index(8, 8)].visibility == Hidden)
}

///|
test "flag toggles hidden cell state" {
  set_running_board_for_test(Beginner)
  assert_true(toggle_flag(Cell::{ row: 3, col: 3 }))
  assert_true(board[board_index(3, 3)].visibility == Flagged)
  assert_eq(game_state.flag_count, 1)
  assert_true(toggle_flag(Cell::{ row: 3, col: 3 }))
  assert_true(board[board_index(3, 3)].visibility == Hidden)
  assert_eq(game_state.flag_count, 0)
}

///|
test "chord reveal opens neighbors when flag count matches" {
  set_running_board_for_test(Beginner)
  clear_all_mines_for_test()
  place_mine_for_test(0, 0)
  refresh_counts_for_test()
  ignore(reveal_cell(Cell::{ row: 1, col: 1 }))
  ignore(toggle_flag(Cell::{ row: 0, col: 0 }))
  assert_true(chord_reveal(Cell::{ row: 1, col: 1 }))
  assert_true(board[board_index(1, 2)].visibility == Revealed)
  assert_true(board[board_index(2, 2)].visibility == Revealed)
}

///|
test "win is detected when all safe cells are revealed" {
  set_running_board_for_test(Beginner)
  clear_all_mines_for_test()
  place_mine_for_test(8, 8)
  refresh_counts_for_test()
  ignore(reveal_cell(Cell::{ row: 0, col: 0 }))
  assert_true(game_state.phase == Won)
}

///|
test "revealing a mine loses the game" {
  set_running_board_for_test(Beginner)
  clear_all_mines_for_test()
  place_mine_for_test(0, 0)
  refresh_counts_for_test()
  assert_true(reveal_cell(Cell::{ row: 0, col: 0 }))
  assert_true(game_state.phase == Lost)
  assert_true(board[board_index(0, 0)].exploded)
}
