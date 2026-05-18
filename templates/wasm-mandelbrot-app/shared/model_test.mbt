///|
test "default params are valid" {
  let params = default_params()
  inspect(params.width > 0 && params.height > 0, content="true")
  inspect(clamp_iter(params.max_iter), content="80")
}

///|
test "mandelbrot center stays inside longer than a far point" {
  let center = iterations(0.0, 0.0, 64)
  let outside = iterations(2.0, 2.0, 64)
  inspect(center > outside, content="true")
}
