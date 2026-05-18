///|
pub fn default_width() -> Int {
  @shared.default_params().width
}

///|
pub fn default_height() -> Int {
  @shared.default_params().height
}

///|
pub fn default_max_iter() -> Int {
  @shared.default_params().max_iter
}

///|
pub fn mandelbrot_color(
  width : Int,
  height : Int,
  px : Int,
  py : Int,
  max_iter : Int,
) -> Int {
  @shared.pixel_color(width, height, px, py, max_iter)
}
