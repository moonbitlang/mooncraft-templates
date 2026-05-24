///|
test "forward vector points toward negative z at zero yaw" {
  let forward = forward_from_yaw(0.0)
  assert_true(forward.x.abs() < 0.000001)
  assert_true((forward.z + 1.0).abs() < 0.000001)
}

///|
test "yaw to a point on the right matches Selene rotation direction" {
  let yaw = yaw_to(@math.Vec3::zero(), @math.Vec3::Vec3(1.0, 0.0, 0.0))
  assert_true(yaw < 0.0)
  let forward = forward_from_yaw(yaw)
  assert_true(forward.x > 0.999)
}

///|
test "camera follows behind turret yaw" {
  let position = @math.Vec3::Vec3(0.0, 0.0, 3.5)
  let camera = camera_position_for(position, 0.0)
  let target = camera_target_for(position, 0.0)
  assert_true(camera.z > position.z)
  assert_true(target.z < position.z)
  assert_true(camera.y > target.y)
}

///|
fn active_projectile_count() -> Int {
  let mut count = 0
  for projectile in projectiles {
    if projectile.active {
      count += 1
    }
  }
  count
}

///|
fn enemy_count() -> Int {
  let mut count = 0
  for enemy in enemy_states {
    if enemy.active {
      count += 1
    }
  }
  count
}

///|
fn reset_scene_for_test() -> Unit {
  enemy_states.clear()
  for spec in enemy_specs() {
    let (position, yaw) = spec
    enemy_states.push({
      rig: spawn_tank_render_rig(),
      position,
      yaw,
      turret_yaw: yaw,
      hp: 2,
      cooldown: ENEMY_RELOAD_SECONDS,
      active: true,
    })
  }
  projectiles.clear()
  reset_game_state()
}

///|
test "positive mouse movement turns view to the right" {
  let yaw = mouse_turn_yaw(0.0, 10.0)
  assert_true(yaw < 0.0)
  assert_true(forward_from_yaw(yaw).x > 0.0)
}

///|
test "turret local yaw is relative to tank body yaw" {
  let body_yaw = 0.75
  let turret_yaw = 1.2
  assert_true((turret_local_yaw(body_yaw, turret_yaw) - 0.45).abs() < 0.000001)
}

///|
test "obstacle and arena blockers reject occupied positions" {
  let center_obstacle = @math.Vec3::Vec3(0.0, 0.0, 0.0)
  let outside_arena = @math.Vec3::Vec3(ARENA_SIZE + 1.0, 0.0, 0.0)
  let open_ground = @math.Vec3::Vec3(30.0, 0.0, 30.0)
  assert_true(blocked_by_obstacles(center_obstacle, PLAYER_HIT_RADIUS))
  assert_true(blocked_by_arena(outside_arena, PLAYER_HIT_RADIUS))
  assert_false(blocked_by_obstacles(open_ground, PLAYER_HIT_RADIUS))
  assert_false(blocked_by_arena(open_ground, PLAYER_HIT_RADIUS))
}

///|
test "enemy ai moves, tracks player, and fires projectiles" {
  reset_scene_for_test()
  enemy_states[0].position = @math.Vec3::Vec3(4.0, 0.0, 4.0)
  enemy_states[0].yaw = 0.0
  enemy_states[0].turret_yaw = 0.0
  enemy_states[0].cooldown = 0.0
  let before = enemy_states[0].position
  update_enemies(0.1)
  assert_true(distance_xz_squared(enemy_states[0].position, before) > 0.0)
  assert_true(enemy_states[0].turret_yaw != 0.0)
  assert_eq(active_projectile_count(), 1)
}

///|
test "player projectile damages and destroys enemy tanks" {
  reset_scene_for_test()
  enemy_states[0].position = @math.Vec3::Vec3(0.0, 0.0, 10.0)
  enemy_states[0].hp = 1
  spawn_projectile(@math.Vec3::Vec3(0.0, 1.45, 12.0), 0.0, true, PROJECTILE_TTL)
  update_projectiles(0.08)
  assert_false(enemy_states[0].active)
  assert_eq(enemy_count(), 4)
  assert_eq(tank.score, 100)
}
