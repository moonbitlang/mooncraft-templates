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
  @math.Vec3::Vec3(@cmath.sin(yaw), 0.0, -@cmath.cos(yaw))
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
fn all_targets_destroyed() -> Bool {
  for target in target_states {
    if target.active {
      return false
    }
  }
  true
}

///|
fn reset_game_state() -> Unit {
  tank.position = @math.Vec3::Vec3(0.0, 0.0, 3.5)
  tank.yaw = 0.0
  tank.reload = 0.0
  tank.score = 0
  projectile.active = false
  projectile.ttl = 0.0
  for index in 0..<target_states.length() {
    target_states[index].active = true
  }
}
