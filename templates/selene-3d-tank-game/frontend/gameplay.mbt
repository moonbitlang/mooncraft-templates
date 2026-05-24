///|
fn enemy_specs() -> Array[(@math.Vec3, Double)] {
  [
    (@math.Vec3::Vec3(-18.0, 0.0, -18.0), -0.55),
    (@math.Vec3::Vec3(0.0, 0.0, -20.0), 0.0),
    (@math.Vec3::Vec3(18.0, 0.0, -18.0), 0.55),
    (@math.Vec3::Vec3(-22.0, 0.0, 3.0), -1.1),
    (@math.Vec3::Vec3(22.0, 0.0, 3.0), 1.1),
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
  let half = ARENA_SIZE
  set_mesh_entity(
    @entity.Entity::Entity(),
    wall_long_mesh.val.unwrap(),
    wall_material.val.unwrap(),
    @math.Vec3::Vec3(0.0, 0.68, -half),
  )
  set_mesh_entity(
    @entity.Entity::Entity(),
    wall_long_mesh.val.unwrap(),
    wall_material.val.unwrap(),
    @math.Vec3::Vec3(0.0, 0.68, half),
  )
  set_mesh_entity(
    @entity.Entity::Entity(),
    wall_side_mesh.val.unwrap(),
    wall_material.val.unwrap(),
    @math.Vec3::Vec3(-half, 0.68, 0.0),
  )
  set_mesh_entity(
    @entity.Entity::Entity(),
    wall_side_mesh.val.unwrap(),
    wall_material.val.unwrap(),
    @math.Vec3::Vec3(half, 0.68, 0.0),
  )
  for obstacle in obstacle_specs() {
    set_mesh_entity(
      @entity.Entity::Entity(),
      obstacle_block_mesh.val.unwrap(),
      obstacle_material.val.unwrap(),
      obstacle.position,
      scale=obstacle.size,
    )
  }
  configure_tank_render_rig(
    tank_player_rig(),
    tank_material.val.unwrap(),
    turret_material.val.unwrap(),
  )
  enemy_states.clear()
  for spec in enemy_specs() {
    let (position, yaw) = spec
    let rig = spawn_tank_render_rig()
    configure_tank_render_rig(
      rig,
      enemy_material.val.unwrap(),
      enemy_turret_material.val.unwrap(),
    )
    enemy_states.push({
      rig,
      position,
      yaw,
      turret_yaw: yaw,
      hp: 2,
      cooldown: ENEMY_RELOAD_SECONDS + enemy_states.length().to_double() * 0.35,
      active: true,
    })
  }
}

///|
fn spawn_projectile(
  position : @math.Vec3,
  yaw : Double,
  from_player : Bool,
  ttl : Double,
) -> Unit {
  projectiles.push({
    entity: @entity.Entity::Entity(),
    active: true,
    position,
    yaw,
    ttl,
    from_player,
  })
}

///|
fn fire_player_projectile() -> Unit {
  if tank.reload > 0.0 || tank.status != Playing {
    return
  }
  let forward = forward_from_yaw(tank.turret_yaw)
  spawn_projectile(
    tank.position + forward.scalar_mul(2.0) + @math.Vec3::Vec3(0.0, 1.45, 0.0),
    tank.turret_yaw,
    true,
    PROJECTILE_TTL,
  )
  tank.reload = RELOAD_SECONDS
}

///|
fn fire_enemy_projectile(enemy : EnemyState) -> Unit {
  let forward = forward_from_yaw(enemy.turret_yaw)
  spawn_projectile(
    enemy.position + forward.scalar_mul(2.0) + @math.Vec3::Vec3(0.0, 1.45, 0.0),
    enemy.turret_yaw,
    false,
    ENEMY_PROJECTILE_TTL,
  )
}

///|
fn update_tank(dt : Double) -> Unit {
  if tank.status != Playing {
    return
  }
  if @inputs.is_pressed(KeyA) || @inputs.is_pressed(ArrowLeft) {
    tank.yaw += TANK_TURN_SPEED * dt
  }
  if @inputs.is_pressed(KeyD) || @inputs.is_pressed(ArrowRight) {
    tank.yaw -= TANK_TURN_SPEED * dt
  }
  let forward = forward_from_yaw(tank.yaw)
  let drive = if @inputs.is_pressed(KeyW) || @inputs.is_pressed(ArrowUp) {
    1.0
  } else if @inputs.is_pressed(KeyS) || @inputs.is_pressed(ArrowDown) {
    -0.62
  } else {
    0.0
  }
  let movement = forward.scalar_mul(drive * TANK_SPEED * dt)
  let next_x = @math.Vec3::Vec3(
    tank.position.x + movement.x,
    tank.position.y,
    tank.position.z,
  )
  if !blocked(next_x, PLAYER_HIT_RADIUS) {
    tank.position = next_x
  }
  let next_z = @math.Vec3::Vec3(
    tank.position.x,
    tank.position.y,
    tank.position.z + movement.z,
  )
  if !blocked(next_z, PLAYER_HIT_RADIUS) {
    tank.position = next_z
  }
  if tank.reload > 0.0 {
    tank.reload = clamp_double(tank.reload - dt, 0.0, RELOAD_SECONDS)
  }
}

///|
fn update_mouse_view() -> Unit {
  if tank.status != Playing {
    return
  }
  let movement = @inputs.mouse_movement.movement
  if movement[X] != 0.0 {
    tank.turret_yaw = mouse_turn_yaw(tank.turret_yaw, movement[X])
  }
}

///|
fn update_enemies(dt : Double) -> Unit {
  if tank.status != Playing {
    return
  }
  for index in 0..<enemy_states.length() {
    if !enemy_states[index].active {
      continue
    }
    let target_yaw = yaw_to(enemy_states[index].position, tank.position)
    enemy_states[index].turret_yaw = turn_toward(
      enemy_states[index].turret_yaw,
      target_yaw,
      ENEMY_TURRET_TURN_SPEED * dt,
    )
    enemy_states[index].yaw = turn_toward(
      enemy_states[index].yaw,
      target_yaw,
      ENEMY_BODY_TURN_SPEED * dt,
    )
    let distance_sq = distance_xz_squared(
      enemy_states[index].position,
      tank.position,
    )
    if distance_sq > ENEMY_MIN_DISTANCE * ENEMY_MIN_DISTANCE {
      let movement = forward_from_yaw(enemy_states[index].yaw).scalar_mul(
        ENEMY_MOVE_SPEED * dt,
      )
      let next_x = @math.Vec3::Vec3(
        enemy_states[index].position.x + movement.x,
        enemy_states[index].position.y,
        enemy_states[index].position.z,
      )
      if !blocked_for_enemy(next_x, ENEMY_HIT_RADIUS, index) {
        enemy_states[index].position = next_x
      }
      let next_z = @math.Vec3::Vec3(
        enemy_states[index].position.x,
        enemy_states[index].position.y,
        enemy_states[index].position.z + movement.z,
      )
      if !blocked_for_enemy(next_z, ENEMY_HIT_RADIUS, index) {
        enemy_states[index].position = next_z
      }
    }
    enemy_states[index].cooldown -= dt
    if enemy_states[index].cooldown <= 0.0 &&
      distance_sq < ENEMY_FIRE_DISTANCE * ENEMY_FIRE_DISTANCE {
      fire_enemy_projectile(enemy_states[index])
      enemy_states[index].cooldown = ENEMY_RELOAD_SECONDS
    }
  }
}

///|
fn update_projectiles(dt : Double) -> Unit {
  for projectile_index in 0..<projectiles.length() {
    if !projectiles[projectile_index].active {
      continue
    }
    let speed = if projectiles[projectile_index].from_player {
      PROJECTILE_SPEED
    } else {
      ENEMY_PROJECTILE_SPEED
    }
    let forward = forward_from_yaw(projectiles[projectile_index].yaw)
    projectiles[projectile_index].position = projectiles[projectile_index].position +
      forward.scalar_mul(speed * dt)
    projectiles[projectile_index].ttl -= dt
    if projectiles[projectile_index].ttl <= 0.0 ||
      projectile_blocked(projectiles[projectile_index].position) {
      projectiles[projectile_index].active = false
      continue
    }
    if projectiles[projectile_index].from_player {
      for enemy_index in 0..<enemy_states.length() {
        if enemy_states[enemy_index].active &&
          distance_xz_squared(
            projectiles[projectile_index].position,
            enemy_states[enemy_index].position,
          ) <=
          ENEMY_HIT_RADIUS * ENEMY_HIT_RADIUS {
          enemy_states[enemy_index].hp -= 1
          if enemy_states[enemy_index].hp <= 0 {
            enemy_states[enemy_index].active = false
            tank.score += 100
          }
          projectiles[projectile_index].active = false
          break
        }
      }
    } else if tank.status == Playing &&
      distance_xz_squared(projectiles[projectile_index].position, tank.position) <=
      PLAYER_HIT_RADIUS * PLAYER_HIT_RADIUS {
      tank.hp -= 10
      if tank.hp <= 0 {
        tank.hp = 0
        tank.status = GameOver
      }
      projectiles[projectile_index].active = false
    }
  }
  if tank.status == Playing && all_enemies_destroyed() {
    tank.status = Victory
  }
}

///|
fn reset_with_input() -> Unit {
  if @host.is_key_pressed("KeyR") {
    reset_game_state()
  }
}

///|
fn fire_with_input() -> Unit {
  if @inputs.is_just_pressed(Space) || @inputs.is_just_pressed(Enter) {
    fire_player_projectile()
    return
  }
  if @inputs.is_mouse_pressed(Left) {
    fire_player_projectile()
  }
}

///|
fn destroy_inactive_projectile_entities() -> Unit {
  if projectiles.length() <= 96 {
    return
  }
  let active : Array[ProjectileState] = []
  for projectile in projectiles {
    if projectile.active {
      active.push(projectile)
    } else {
      projectile.entity.destroy()
    }
  }
  projectiles.clear()
  for projectile in active {
    projectiles.push(projectile)
  }
}

///|
fn update_simulation(dt : Double) -> Unit {
  update_enemies(dt)
  update_projectiles(dt)
  destroy_inactive_projectile_entities()
}

///|
fn handle_runtime_inputs() -> Unit {
  reset_with_input()
  fire_with_input()
}

///|
fn should_exit() -> Bool {
  @inputs.is_just_pressed(Escape)
}

///|
fn exit_if_requested() -> Unit {
  if should_exit() {
    @system.exit()
  }
}

///|
fn run_frame(dt : Double) -> Unit {
  update_tank(dt)
  update_mouse_view()
  handle_runtime_inputs()
  update_simulation(dt)
}

///|
fn sync_render_state() -> Unit {
  sync_camera_transform()
  sync_tank_render()
  sync_projectile_render()
  sync_enemy_render()
  sync_hud()
}

///|
fn prepare_scene() -> Unit {
  register_assets_once()
  setup_camera_and_lighting()
  setup_static_scene()
  reset_game_state()
  sync_render_state()
}

///|
fn startup_system(_world : @ecs.World) -> Unit {
  prepare_scene()
}

///|
fn input_system(_world : @ecs.World) -> Unit {
  exit_if_requested()
}

///|
fn update_system(_world : @ecs.World) -> Unit {
  run_frame(@time.delta())
  sync_render_state()
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
