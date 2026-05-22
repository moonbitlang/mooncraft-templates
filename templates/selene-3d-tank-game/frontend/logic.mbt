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
fn offset_from_yaw(yaw : Double, offset : @math.Vec3) -> @math.Vec3 {
  yaw_rotation(yaw).rotate_vec3(offset)
}

///|
fn mouse_turn_yaw(yaw : Double, movement_x : Double) -> Double {
  yaw - movement_x * MOUSE_TURN_SENSITIVITY
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
fn clamp_to_arena(position : @math.Vec3) -> @math.Vec3 {
  let half = ARENA_SIZE * 0.5 - 0.8
  @math.Vec3::Vec3(
    clamp_double(position.x, -half, half),
    position.y,
    clamp_double(position.z, -half, half),
  )
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
  tank.position = @math.Vec3::Vec3(0.0, 0.0, 3.5)
  tank.yaw = 0.0
  tank.turret_yaw = 0.0
  tank.reload = 0.0
  tank.score = 0
  projectile.active = false
  projectile.ttl = 0.0
  for index in 0..<enemy_states.length() {
    enemy_states[index].active = true
  }
}
