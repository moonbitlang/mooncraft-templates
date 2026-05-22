///|
test "forward vector points toward negative z at zero yaw" {
  let forward = forward_from_yaw(0.0)
  assert_true(forward.x.abs() < 0.000001)
  assert_true((forward.z + 1.0).abs() < 0.000001)
}

///|
test "arena clamp keeps tank inside playable area" {
  let clamped = clamp_to_arena(@math.Vec3::Vec3(100.0, 0.0, -100.0))
  let half = ARENA_SIZE * 0.5 - 0.8
  assert_eq(clamped.x, half)
  assert_eq(clamped.z, -half)
}
