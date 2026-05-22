///|
fn color_rgba(r : UInt, g : UInt, b : UInt, a : Double) -> @render.Color {
  { r, g, b, a }
}

///|
fn ensure_entity_alive(entity : @entity.Entity) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
}

///|
fn set_entity_visibility(entity : @entity.Entity, visible : Bool) -> Unit {
  @visibility.visibilities().set(entity, if visible { Visible } else { Hidden })
}

///|
fn world_transform(
  translation : @math.Vec3,
  rotation : @math.Quat,
  scale : @math.Vec3,
) -> @transform.Transform {
  { translation, rotation, scale }
}

///|
fn yaw_rotation(yaw : Double) -> @math.Quat {
  @math.Quat::from_axis_angle(@math.Vec3::y_axis(), yaw)
}

///|
fn look_rotation(from : @math.Vec3, to : @math.Vec3) -> @math.Quat {
  let forward = (to - from).normalize()
  let mut right = forward.cross(@math.Vec3::y_axis())
  if right.length_squared() < 0.000001 {
    right = @math.Vec3::x_axis()
  }
  right = right.normalize()
  let up = right.cross(forward).normalize()
  @math.Quat::from_basis(
    right,
    up,
    @math.Vec3::Vec3(-forward.x, -forward.y, -forward.z),
  )
}

///|
fn register_assets_once() -> Unit {
  if floor_mesh.val is Some(_) {
    return
  }
  floor_mesh.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cube_mesh(@math.Vec3::Vec3(ARENA_SIZE, 0.16, ARENA_SIZE)),
    ),
  )
  wall_long_mesh.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cube_mesh(@math.Vec3::Vec3(ARENA_SIZE, 1.35, 0.42)),
    ),
  )
  wall_side_mesh.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cube_mesh(@math.Vec3::Vec3(0.42, 1.35, ARENA_SIZE)),
    ),
  )
  obstacle_block_mesh.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cube_mesh(@math.Vec3::Vec3(3.1, 1.45, 2.4)),
    ),
  )
  tank_track_mesh.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cube_mesh(@math.Vec3::Vec3(0.42, 0.52, 1.88)),
    ),
  )
  tank_body_mesh.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cube_mesh(@math.Vec3::Vec3(1.42, 0.58, 1.72)),
    ),
  )
  tank_turret_mesh.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cylinder_mesh(0.42, 0.52, 0.38, slices=16),
    ),
  )
  tank_barrel_mesh.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cube_mesh(@math.Vec3::Vec3(0.16, 0.14, 1.12)),
    ),
  )
  projectile_mesh.val = Some(
    @render3d.register_mesh_asset(@render3d.sphere_mesh(0.16)),
  )

  floor_material.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(72U, 92U, 61U, 1.0),
      roughness: 0.96,
    }),
  )
  wall_material.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(58U, 70U, 45U, 1.0),
      roughness: 0.9,
    }),
  )
  obstacle_material.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(122U, 107U, 80U, 1.0),
      roughness: 0.86,
    }),
  )
  track_material.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(22U, 24U, 27U, 1.0),
      roughness: 0.62,
      metallic: 0.25,
    }),
  )
  tank_material.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(43U, 95U, 168U, 1.0),
      roughness: 0.58,
      metallic: 0.18,
    }),
  )
  turret_material.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(30U, 70U, 128U, 1.0),
      roughness: 0.5,
      metallic: 0.22,
    }),
  )
  enemy_material.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(168U, 58U, 42U, 1.0),
      roughness: 0.58,
      metallic: 0.18,
    }),
  )
  enemy_turret_material.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(122U, 40U, 24U, 1.0),
      roughness: 0.5,
      metallic: 0.22,
    }),
  )
  projectile_material.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(255U, 219U, 92U, 1.0),
      emissive_color: color_rgba(60U, 36U, 4U, 1.0),
      roughness: 0.18,
    }),
  )
}

///|
fn set_mesh_entity(
  entity : @entity.Entity,
  mesh : @render3d.MeshHandle,
  material : @render3d.MaterialHandle,
  translation : @math.Vec3,
  rotation? : @math.Quat = @math.Quat::identity(),
  cast_shadows? : Bool = true,
  receive_shadows? : Bool = true,
) -> Unit {
  ensure_entity_alive(entity)
  @transform.transforms().set(
    entity,
    world_transform(translation, rotation, @math.Vec3::one()),
  )
  @render3d.mesh3d_renderers().set(entity, {
    visible: true,
    mesh,
    material,
    cast_shadows,
    receive_shadows,
  })
  set_entity_visibility(entity, true)
}

///|
fn set_text_entity(entity : @entity.Entity, content : String) -> Unit {
  ensure_entity_alive(entity)
  @ui.texts().set(entity, @ui.Text::Text(content))
  @ui.text_fonts().set(entity, @ui.TextFont::from_css("24px ui-sans-serif"))
  @ui.text_colors().set(entity, @ui.TextColor::from_css("rgb(238,244,252)"))
  @ui.text_layouts().set(
    entity,
    @ui.TextLayout::TextLayout(align=Left, baseline=Top, wrap=WordWrap),
  )
  @text2d.text2ds().set(entity, @text2d.Text2d::Text2d())
  @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2(-0.5, 0.5)))
  @transform.transforms().set(entity, {
    translation: @math.Vec3::Vec3(18.0, 18.0, UI_ZINDEX.to_double()),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  })
  set_entity_visibility(entity, true)
}

///|
fn setup_camera_and_lighting() -> Unit {
  ensure_entity_alive(camera_entity)
  ensure_entity_alive(light_entity)
  @camera3d.cameras3d().set(camera_entity, {
    ..@camera3d.Camera3DComponent::default(),
    fov_y: CAMERA_FOV_Y_DEGREES,
    near: 0.01,
    far: 100.0,
    clear_color: color_rgba(9U, 15U, 26U, 1.0),
    order: 10,
    enabled: true,
  })
  sync_camera_transform()

  @render3d.directional_lights3d().set(light_entity, {
    ..@render3d.default_directional_light3d(),
    direction: @math.Vec3::Vec3(-0.35, -1.0, -0.42),
    color: color_rgba(255U, 246U, 225U, 1.0),
    intensity: 0.95,
    shadows: false,
  })
  @render3d.set_ambient_light3d(
    Some({ color: color_rgba(154U, 184U, 224U, 1.0), intensity: 0.32 }),
  )
}

///|
fn sync_camera_transform() -> Unit {
  ensure_entity_alive(camera_entity)
  @transform.transforms().set(
    camera_entity,
    world_transform(
      camera_position(),
      look_rotation(camera_position(), camera_target()),
      @math.Vec3::one(),
    ),
  )
}

///|
fn sync_tank_render() -> Unit {
  sync_tank_parts(
    tank_left_track_entity,
    tank_right_track_entity,
    tank_body_entity,
    tank_turret_entity,
    tank_barrel_entity,
    tank.position,
    tank.yaw,
    tank.turret_yaw,
    tank_material.val.unwrap(),
    turret_material.val.unwrap(),
  )
}

///|
fn sync_tank_parts(
  left_track : @entity.Entity,
  right_track : @entity.Entity,
  body : @entity.Entity,
  turret : @entity.Entity,
  barrel : @entity.Entity,
  position : @math.Vec3,
  body_yaw : Double,
  turret_yaw : Double,
  body_material : @render3d.MaterialHandle,
  turret_material : @render3d.MaterialHandle,
) -> Unit {
  let body_rotation = yaw_rotation(body_yaw)
  let turret_rotation = yaw_rotation(turret_yaw)
  let track_y = @math.Vec3::Vec3(0.0, 0.32, 0.0)
  let body_y = @math.Vec3::Vec3(0.0, 0.72, 0.0)
  let turret_y = @math.Vec3::Vec3(0.0, 1.15, 0.0)
  set_mesh_entity(
    left_track,
    tank_track_mesh.val.unwrap(),
    track_material.val.unwrap(),
    position +
    offset_from_yaw(body_yaw, @math.Vec3::Vec3(-0.74, 0.0, 0.0)) +
    track_y,
    rotation=body_rotation,
  )
  set_mesh_entity(
    right_track,
    tank_track_mesh.val.unwrap(),
    track_material.val.unwrap(),
    position +
    offset_from_yaw(body_yaw, @math.Vec3::Vec3(0.74, 0.0, 0.0)) +
    track_y,
    rotation=body_rotation,
  )
  set_mesh_entity(
    body,
    tank_body_mesh.val.unwrap(),
    body_material,
    position + body_y,
    rotation=body_rotation,
  )
  set_mesh_entity(
    turret,
    tank_turret_mesh.val.unwrap(),
    turret_material,
    position + turret_y,
    rotation=turret_rotation,
  )
  set_mesh_entity(
    barrel,
    tank_barrel_mesh.val.unwrap(),
    turret_material,
    position +
    offset_from_yaw(turret_yaw, @math.Vec3::Vec3(0.0, 0.0, -0.82)) +
    @math.Vec3::Vec3(0.0, 1.16, 0.0),
    rotation=turret_rotation,
  )
}

///|
fn sync_projectile_render() -> Unit {
  if projectile.active {
    set_mesh_entity(
      projectile_entity,
      projectile_mesh.val.unwrap(),
      projectile_material.val.unwrap(),
      projectile.position,
      cast_shadows=false,
      receive_shadows=false,
    )
  } else {
    set_entity_visibility(projectile_entity, false)
  }
}

///|
fn set_enemy_visibility(enemy : EnemyState, visible : Bool) -> Unit {
  set_entity_visibility(enemy.left_track_entity, visible)
  set_entity_visibility(enemy.right_track_entity, visible)
  set_entity_visibility(enemy.body_entity, visible)
  set_entity_visibility(enemy.turret_entity, visible)
  set_entity_visibility(enemy.barrel_entity, visible)
}

///|
fn sync_enemy_render() -> Unit {
  for enemy in enemy_states {
    if enemy.active {
      let turret_yaw = yaw_to(enemy.position, tank.position)
      sync_tank_parts(
        enemy.left_track_entity,
        enemy.right_track_entity,
        enemy.body_entity,
        enemy.turret_entity,
        enemy.barrel_entity,
        enemy.position,
        enemy.yaw,
        turret_yaw,
        enemy_material.val.unwrap(),
        enemy_turret_material.val.unwrap(),
      )
    } else {
      set_enemy_visibility(enemy, false)
    }
  }
}

///|
fn sync_hud() -> Unit {
  let status = if all_enemies_destroyed() {
    "All enemy tanks down. Press R to reset."
  } else {
    "WASD/Arrows drive · Mouse turns view · Click/Space fires · R resets"
  }
  set_text_entity(hud_entity, "3D Tank · Score \{tank.score}\n\{status}")
}
