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
test "arena clamp keeps tank inside playable area" {
  let clamped = clamp_to_arena(@math.Vec3::Vec3(100.0, 0.0, -100.0))
  let half = ARENA_SIZE * 0.5 - 0.8
  assert_eq(clamped.x, half)
  assert_eq(clamped.z, -half)
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
test "positive mouse movement turns view to the right" {
  let yaw = mouse_turn_yaw(0.0, 10.0)
  assert_true(yaw < 0.0)
  assert_true(forward_from_yaw(yaw).x > 0.0)
}
