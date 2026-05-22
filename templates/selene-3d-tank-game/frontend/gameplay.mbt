///|
fn target_positions() -> Array[@math.Vec3] {
  [
    @math.Vec3::Vec3(-4.6, 0.4, -4.8),
    @math.Vec3::Vec3(0.0, 0.4, -5.6),
    @math.Vec3::Vec3(4.6, 0.4, -4.8),
    @math.Vec3::Vec3(-5.2, 0.4, 0.8),
    @math.Vec3::Vec3(5.2, 0.4, 0.8),
  ]
}

///|
fn setup_static_scene() -> Unit {
  set_mesh_entity(
    @entity.Entity::Entity(),
    floor_mesh.val.unwrap(),
    floor_material.val.unwrap(),
    @math.Vec3::Vec3(0.0, -0.06, 0.0),
    cast_shadows=false,
  )
  target_states.clear()
  for position in target_positions() {
    let entity = @entity.Entity::Entity()
    set_mesh_entity(
      entity,
      target_mesh.val.unwrap(),
      target_material.val.unwrap(),
      position,
    )
    target_states.push({ entity, position, active: true })
  }
}

///|
fn fire_projectile() -> Unit {
  if tank.reload > 0.0 || projectile.active {
    return
  }
  let forward = forward_from_yaw(tank.yaw)
  projectile.active = true
  projectile.position = tank.position +
    forward.scalar_mul(1.05) +
    @math.Vec3::Vec3(0.0, 0.65, 0.0)
  projectile.yaw = tank.yaw
  projectile.ttl = PROJECTILE_TTL
  tank.reload = RELOAD_SECONDS
}

///|
fn update_tank(dt : Double) -> Unit {
  if @inputs.is_pressed(KeyA) || @inputs.is_pressed(ArrowLeft) {
    tank.yaw -= TANK_TURN_SPEED * dt
  }
  if @inputs.is_pressed(KeyD) || @inputs.is_pressed(ArrowRight) {
    tank.yaw += TANK_TURN_SPEED * dt
  }
  let forward = forward_from_yaw(tank.yaw)
  let drive = if @inputs.is_pressed(KeyW) || @inputs.is_pressed(ArrowUp) {
    1.0
  } else if @inputs.is_pressed(KeyS) || @inputs.is_pressed(ArrowDown) {
    -0.62
  } else {
    0.0
  }
  tank.position = clamp_to_arena(
    tank.position + forward.scalar_mul(drive * TANK_SPEED * dt),
  )
  if tank.reload > 0.0 {
    tank.reload = clamp_double(tank.reload - dt, 0.0, RELOAD_SECONDS)
  }
}

///|
fn update_projectile(dt : Double) -> Unit {
  if !projectile.active {
    return
  }
  let forward = forward_from_yaw(projectile.yaw)
  projectile.position = projectile.position +
    forward.scalar_mul(PROJECTILE_SPEED * dt)
  projectile.ttl -= dt
  let half = ARENA_SIZE * 0.5 + 0.5
  if projectile.ttl <= 0.0 ||
    projectile.position.x < -half ||
    projectile.position.x > half ||
    projectile.position.z < -half ||
    projectile.position.z > half {
    projectile.active = false
    return
  }
  for index in 0..<target_states.length() {
    if target_states[index].active &&
      distance_xz_squared(projectile.position, target_states[index].position) <=
      TARGET_HIT_RADIUS * TARGET_HIT_RADIUS {
      target_states[index].active = false
      projectile.active = false
      tank.score += 1
      return
    }
  }
}

///|
fn startup_system(_world : @ecs.World) -> Unit {
  register_assets_once()
  setup_camera_and_lighting()
  setup_static_scene()
  reset_game_state()
  sync_tank_render()
  sync_projectile_render()
  sync_target_render()
  sync_hud()
}

///|
fn input_system(_world : @ecs.World) -> Unit {
  if @inputs.is_just_pressed(Escape) {
    @system.exit()
  }
  if @host.is_key_pressed("KeyR") {
    reset_game_state()
  }
  if @inputs.is_just_pressed(Space) || @inputs.is_just_pressed(Enter) {
    fire_projectile()
  }
}

///|
fn update_system(_world : @ecs.World) -> Unit {
  let dt = @time.delta()
  update_tank(dt)
  update_projectile(dt)
  sync_tank_render()
  sync_projectile_render()
  sync_target_render()
  sync_hud()
}

///|
pub fn run() -> Unit {
  @host.prepare_run(false)
  let app = @app.App::App()
    .with_viewport_width(VIEWPORT_WIDTH)
    .with_viewport_height(VIEWPORT_HEIGHT)
    .with_zoom(1.0)
    .with_fps(FPS)
    .with_image_smooth(true)
    .add_plugin(@plugins.default_3d_plugin)
    .add_system(Startup, startup_system)
    .add_system(Update, input_system)
    .add_system(Update, update_system)
  app.run()
}
