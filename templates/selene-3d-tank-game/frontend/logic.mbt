///|
fn clamp_double(
  value : Double,
  min_value : Double,
  max_value : Double,
) -> Double {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn forward_from_yaw(yaw : Double) -> @math.Vec3 {
  @math.Vec3::Vec3(-@cmath.sin(yaw), 0.0, -@cmath.cos(yaw))
}

///|
fn yaw_to(from : @math.Vec3, to : @math.Vec3) -> Double {
  @cmath.atan2(-(to.x - from.x), -(to.z - from.z))
}

///|
fn mouse_turn_yaw(yaw : Double, movement_x : Double) -> Double {
  yaw - movement_x * MOUSE_TURN_SENSITIVITY
}

///|
fn normalize_angle(angle : Double) -> Double {
  let mut current = angle
  while current > 3.141592653589793 {
    current -= 6.283185307179586
  }
  while current < -3.141592653589793 {
    current += 6.283185307179586
  }
  current
}

///|
fn turn_toward(current : Double, target : Double, max_delta : Double) -> Double {
  let delta = normalize_angle(target - current)
  if delta.abs() <= max_delta {
    target
  } else if delta > 0.0 {
    current + max_delta
  } else {
    current - max_delta
  }
}

///|
fn turret_local_yaw(body_yaw : Double, turret_yaw : Double) -> Double {
  normalize_angle(turret_yaw - body_yaw)
}

///|
fn camera_position_for(position : @math.Vec3, yaw : Double) -> @math.Vec3 {
  position -
  forward_from_yaw(yaw).scalar_mul(CAMERA_DISTANCE) +
  @math.Vec3::Vec3(0.0, CAMERA_HEIGHT, 0.0)
}

///|
fn camera_target_for(position : @math.Vec3, yaw : Double) -> @math.Vec3 {
  position +
  forward_from_yaw(yaw).scalar_mul(CAMERA_LOOK_AHEAD) +
  @math.Vec3::Vec3(0.0, CAMERA_TARGET_HEIGHT, 0.0)
}

///|
fn camera_position() -> @math.Vec3 {
  camera_position_for(tank.position, tank.turret_yaw)
}

///|
fn camera_target() -> @math.Vec3 {
  camera_target_for(tank.position, tank.turret_yaw)
}

///|
fn obstacle_specs() -> Array[Obstacle] {
  [
    {
      position: @math.Vec3::Vec3(-10.0, 1.0, -8.0),
      size: @math.Vec3::Vec3(4.0, 2.0, 4.0),
    },
    {
      position: @math.Vec3::Vec3(12.0, 1.0, -6.0),
      size: @math.Vec3::Vec3(6.0, 2.0, 3.0),
    },
    {
      position: @math.Vec3::Vec3(-14.0, 1.0, 10.0),
      size: @math.Vec3::Vec3(3.0, 2.0, 6.0),
    },
    {
      position: @math.Vec3::Vec3(8.0, 1.0, 12.0),
      size: @math.Vec3::Vec3(5.0, 2.0, 3.0),
    },
    {
      position: @math.Vec3::Vec3(0.0, 1.0, 0.0),
      size: @math.Vec3::Vec3(3.0, 2.0, 3.0),
    },
    {
      position: @math.Vec3::Vec3(-6.0, 1.0, -16.0),
      size: @math.Vec3::Vec3(8.0, 2.0, 2.0),
    },
    {
      position: @math.Vec3::Vec3(16.0, 1.0, 4.0),
      size: @math.Vec3::Vec3(2.0, 2.0, 8.0),
    },
  ]
}

///|
fn rect_collide(
  px : Double,
  pz : Double,
  radius : Double,
  obstacle : Obstacle,
) -> Bool {
  let hx = obstacle.size.x * 0.5
  let hz = obstacle.size.z * 0.5
  px + radius > obstacle.position.x - hx &&
  px - radius < obstacle.position.x + hx &&
  pz + radius > obstacle.position.z - hz &&
  pz - radius < obstacle.position.z + hz
}

///|
fn blocked_by_arena(position : @math.Vec3, radius : Double) -> Bool {
  position.x.abs() > ARENA_SIZE - radius ||
  position.z.abs() > ARENA_SIZE - radius
}

///|
fn blocked_by_obstacles(position : @math.Vec3, radius : Double) -> Bool {
  for obstacle in obstacle_specs() {
    if rect_collide(position.x, position.z, radius, obstacle) {
      return true
    }
  }
  false
}

///|
fn blocked_by_enemies(position : @math.Vec3, radius : Double) -> Bool {
  for enemy in enemy_states {
    if enemy.active &&
      distance_xz_squared(position, enemy.position) <
      (radius + ENEMY_HIT_RADIUS) * (radius + ENEMY_HIT_RADIUS) {
      return true
    }
  }
  false
}

///|
fn blocked(position : @math.Vec3, radius : Double) -> Bool {
  blocked_by_arena(position, radius) ||
  blocked_by_obstacles(position, radius) ||
  blocked_by_enemies(position, radius)
}

///|
fn blocked_for_enemy(
  position : @math.Vec3,
  radius : Double,
  enemy_index : Int,
) -> Bool {
  if blocked_by_arena(position, radius) ||
    blocked_by_obstacles(position, radius) {
    return true
  }
  if distance_xz_squared(position, tank.position) <
    (radius + PLAYER_HIT_RADIUS) * (radius + PLAYER_HIT_RADIUS) {
    return true
  }
  for index in 0..<enemy_states.length() {
    if index != enemy_index &&
      enemy_states[index].active &&
      distance_xz_squared(position, enemy_states[index].position) <
      (radius + ENEMY_HIT_RADIUS) * (radius + ENEMY_HIT_RADIUS) {
      return true
    }
  }
  false
}

///|
fn projectile_blocked(position : @math.Vec3) -> Bool {
  blocked_by_arena(position, PROJECTILE_HIT_RADIUS) ||
  blocked_by_obstacles(position, PROJECTILE_HIT_RADIUS)
}

///|
fn distance_xz_squared(a : @math.Vec3, b : @math.Vec3) -> Double {
  let dx = a.x - b.x
  let dz = a.z - b.z
  dx * dx + dz * dz
}

///|
fn all_enemies_destroyed() -> Bool {
  for enemy in enemy_states {
    if enemy.active {
      return false
    }
  }
  true
}

///|
fn reset_game_state() -> Unit {
  tank.position = @math.Vec3::Vec3(0.0, 0.0, 18.0)
  tank.yaw = 0.0
  tank.turret_yaw = 0.0
  tank.reload = 0.0
  tank.score = 0
  tank.hp = 100
  tank.status = Playing
  for index in 0..<projectiles.length() {
    projectiles[index].active = false
  }
  for index in 0..<enemy_states.length() {
    enemy_states[index].active = true
    enemy_states[index].hp = 2
    enemy_states[index].cooldown = ENEMY_RELOAD_SECONDS +
      index.to_double() * 0.35
  }
}
