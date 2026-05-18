///|
pub(all) struct RenderParams {
  width : Int
  height : Int
  max_iter : Int
  center_x : Double
  center_y : Double
  scale : Double
} derive(Debug, Eq, ToJson, @json.FromJson)

///|
pub fn default_params() -> RenderParams {
  {
    width: 640,
    height: 420,
    max_iter: 80,
    center_x: -0.72,
    center_y: 0.0,
    scale: 3.0,
  }
}

///|
pub fn clamp_iter(value : Int) -> Int {
  if value < 16 {
    16
  } else if value > 512 {
    512
  } else {
    value
  }
}

///|
pub fn iterations(cx : Double, cy : Double, max_iter : Int) -> Int {
  let limit = clamp_iter(max_iter)
  let mut x = 0.0
  let mut y = 0.0
  let mut iter = 0
  while x * x + y * y <= 4.0 && iter < limit {
    let next_x = x * x - y * y + cx
    y = 2.0 * x * y + cy
    x = next_x
    iter = iter + 1
  }
  iter
}

///|
pub fn color(iter : Int, max_iter : Int) -> Int {
  let limit = clamp_iter(max_iter)
  if iter >= limit {
    0x101820
  } else {
    let t = iter * 255 / limit
    let r = 24 + t / 3
    let g = 48 + t * 2 / 3
    let b = 96 + t
    (r << 16) | (g << 8) | b
  }
}

///|
pub fn pixel_color(
  width : Int,
  height : Int,
  px : Int,
  py : Int,
  max_iter : Int,
) -> Int {
  let params = default_params()
  let aspect = width.to_double() / height.to_double()
  let x = params.center_x +
    (px.to_double() / width.to_double() - 0.5) * params.scale * aspect
  let y = params.center_y +
    (py.to_double() / height.to_double() - 0.5) * params.scale
  color(iterations(x, y, max_iter), max_iter)
}
