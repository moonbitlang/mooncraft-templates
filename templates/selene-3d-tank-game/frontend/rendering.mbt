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
      @render3d.cube_mesh(@math.Vec3::Vec3(ARENA_SIZE, 0.12, ARENA_SIZE)),
    ),
  )
  tank_body_mesh.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cube_mesh(@math.Vec3::Vec3(1.3, 0.45, 1.7)),
    ),
  )
  tank_turret_mesh.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cube_mesh(@math.Vec3::Vec3(0.75, 0.38, 0.75)),
    ),
  )
  tank_barrel_mesh.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cube_mesh(@math.Vec3::Vec3(0.18, 0.16, 0.95)),
    ),
  )
  projectile_mesh.val = Some(
    @render3d.register_mesh_asset(@render3d.sphere_mesh(0.16)),
  )
  target_mesh.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cube_mesh(@math.Vec3::Vec3(0.8, 0.8, 0.8)),
    ),
  )

  floor_material.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(33U, 50U, 64U, 1.0),
      roughness: 0.96,
    }),
  )
  tank_material.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(44U, 164U, 118U, 1.0),
      roughness: 0.72,
    }),
  )
  turret_material.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(27U, 112U, 88U, 1.0),
      roughness: 0.62,
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
  target_material.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(237U, 85U, 101U, 1.0),
      roughness: 0.45,
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
  let camera_position = @math.Vec3::Vec3(0.0, 8.2, 9.5)
  let camera_target = @math.Vec3::Vec3(0.0, 0.0, -0.6)
  @camera3d.cameras3d().set(camera_entity, {
    ..@camera3d.Camera3DComponent::default(),
    fov_y: 55.0,
    near: 0.01,
    far: 100.0,
    clear_color: color_rgba(9U, 15U, 26U, 1.0),
    order: 10,
    enabled: true,
  })
  @transform.transforms().set(
    camera_entity,
    world_transform(
      camera_position,
      look_rotation(camera_position, camera_target),
      @math.Vec3::one(),
    ),
  )

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
fn sync_tank_render() -> Unit {
  let rotation = yaw_rotation(tank.yaw)
  let forward = forward_from_yaw(tank.yaw)
  set_mesh_entity(
    tank_body_entity,
    tank_body_mesh.val.unwrap(),
    tank_material.val.unwrap(),
    tank.position + @math.Vec3::Vec3(0.0, 0.28, 0.0),
    rotation~,
  )
  set_mesh_entity(
    tank_turret_entity,
    tank_turret_mesh.val.unwrap(),
    turret_material.val.unwrap(),
    tank.position + @math.Vec3::Vec3(0.0, 0.65, 0.0),
    rotation~,
  )
  set_mesh_entity(
    tank_barrel_entity,
    tank_barrel_mesh.val.unwrap(),
    turret_material.val.unwrap(),
    tank.position + forward.scalar_mul(0.58) + @math.Vec3::Vec3(0.0, 0.66, 0.0),
    rotation~,
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
fn sync_target_render() -> Unit {
  for target in target_states {
    set_entity_visibility(target.entity, target.active)
  }
}

///|
fn sync_hud() -> Unit {
  let status = if all_targets_destroyed() {
    "All targets down. Press R to reset."
  } else {
    "WASD/Arrows drive · Space fires · R resets"
  }
  set_text_entity(hud_entity, "3D Tank · Score \{tank.score}\n\{status}")
}
