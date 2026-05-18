///|
fn color_rgba(r : UInt, g : UInt, b : UInt, a : Double) -> @render.Color {
  { r, g, b, a }
}

///|
fn set_entity_visible(entity : @entity.Entity, visible : Bool) -> Unit {
  @visibility.visibilities().set(entity, if visible { Visible } else { Hidden })
}

///|
fn transform_xy(x : Double, y : Double, z : Double) -> @transform.Transform {
  @transform.Transform::from_xyz(x, y, z)
}

///|
fn text_entity(
  entity : @entity.Entity,
  content : String,
  x : Double,
  y : Double,
  size_px : Int,
  color_css : String,
  z : Double,
) -> Unit {
  @ui.texts().set(entity, @ui.Text::new(content))
  @ui.text_fonts().set(
    entity,
    @ui.TextFont::new(family="monospace", size=size_px.to_double()),
  )
  @ui.text_colors().set(entity, @ui.TextColor::from_css(color_css))
  @ui.text_layouts().set(
    entity,
    @ui.TextLayout::new(align=Left, baseline=Top, wrap=WordWrap),
  )
  @text2d.text2ds().set(entity, @text2d.Text2d::new())
  @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2(-0.5, 0.5)))
  @transform.transforms().set(entity, transform_xy(x, y, z))
  set_entity_visible(entity, true)
}

///|
fn set_centered_text_block(
  entity : @entity.Entity,
  width : Double,
  height : Double,
) -> Unit {
  @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2(0.0, 0.0)))
  @text2d.text_bounds().set(entity, @text2d.TextBounds::new(width, height))
  @ui.text_layouts().set(
    entity,
    @ui.TextLayout::new(align=Center, baseline=Center, wrap=WordWrap),
  )
}

///|
fn set_centered_text_block_nowrap(
  entity : @entity.Entity,
  width : Double,
  height : Double,
) -> Unit {
  @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2(0.0, 0.0)))
  @text2d.text_bounds().set(entity, @text2d.TextBounds::new(width, height))
  @ui.text_layouts().set(
    entity,
    @ui.TextLayout::new(align=Center, baseline=Center, wrap=NoWrap),
  )
}

///|
fn centered_text_entity(
  entity : @entity.Entity,
  content : String,
  center_x : Double,
  center_y : Double,
  width : Double,
  height : Double,
  size_px : Int,
  color_css : String,
  z : Double,
) -> Unit {
  text_entity(entity, content, center_x, center_y, size_px, color_css, z)
  set_centered_text_block(entity, width, height)
}

///|
fn centered_text_entity_nowrap(
  entity : @entity.Entity,
  content : String,
  center_x : Double,
  center_y : Double,
  width : Double,
  height : Double,
  size_px : Int,
  color_css : String,
  z : Double,
) -> Unit {
  text_entity(entity, content, center_x, center_y, size_px, color_css, z)
  set_centered_text_block_nowrap(entity, width, height)
}

///|
fn panel_entity(
  entity : @entity.Entity,
  color : @render.Color,
  center_x : Double,
  center_y : Double,
  width : Double,
  height : Double,
  z : Double,
) -> Unit {
  let sprite = @sprite.Sprite::from_color(color, @math.Vec2(width, height))
  sprite.anchor = @sprite.Anchor(@math.Vec2(-0.5, 0.5))
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(
    entity,
    transform_xy(center_x - width * 0.5, center_y - height * 0.5, z),
  )
  set_entity_visible(entity, true)
}
