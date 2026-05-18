///|
fn ensure_cell_entities_created() -> Unit {
  if !cell_background_entities.is_empty() {
    return
  }
  for _ in 0..<MAX_CELL_COUNT {
    cell_background_entities.push(@entity.Entity::new())
    cell_text_entities.push(@entity.Entity::new())
  }
}

///|
fn setup_hover_frame() -> Unit {
  let frame_color = color_rgba(86U, 180U, 255U, 0.95)
  panel_entity(
    hover_frame_top_entity,
    frame_color,
    0.0,
    0.0,
    12.0,
    4.0,
    HOVER_FRAME_Z,
  )
  panel_entity(
    hover_frame_bottom_entity,
    frame_color,
    0.0,
    0.0,
    12.0,
    4.0,
    HOVER_FRAME_Z,
  )
  panel_entity(
    hover_frame_left_entity,
    frame_color,
    0.0,
    0.0,
    4.0,
    12.0,
    HOVER_FRAME_Z,
  )
  panel_entity(
    hover_frame_right_entity,
    frame_color,
    0.0,
    0.0,
    4.0,
    12.0,
    HOVER_FRAME_Z,
  )
  set_entity_visible(hover_frame_top_entity, false)
  set_entity_visible(hover_frame_bottom_entity, false)
  set_entity_visible(hover_frame_left_entity, false)
  set_entity_visible(hover_frame_right_entity, false)
}

///|
fn setup_overlay_entities() -> Unit {
  panel_entity(
    overlay_panel_entity,
    color_rgba(18U, 24U, 36U, 0.86),
    VIEWPORT_WIDTH * 0.5,
    VIEWPORT_HEIGHT * 0.5,
    VIEWPORT_WIDTH * 0.62,
    180.0,
    300.0,
  )
  centered_text_entity(
    overlay_text_entity,
    "",
    VIEWPORT_WIDTH * 0.5,
    VIEWPORT_HEIGHT * 0.5 - 8.0,
    VIEWPORT_WIDTH * 0.56,
    160.0,
    34,
    "rgb(255,255,255)",
    310.0,
  )
  set_entity_visible(overlay_panel_entity, false)
  set_entity_visible(overlay_text_entity, false)
}

///|
pub fn startup_system(_world : @ecs.World) -> Unit {
  ensure_cell_entities_created()
  setup_hover_frame()
  setup_overlay_entities()
  ensure_sounds_loaded()
  reset_run_state(Beginner)
}
