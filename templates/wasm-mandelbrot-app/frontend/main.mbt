///|
pub fn default_width() -> Int {
  default_params().width
}

///|
pub fn default_height() -> Int {
  default_params().height
}

///|
pub fn default_max_iter() -> Int {
  default_params().max_iter
}

///|
pub fn mandelbrot_color(
  width : Int,
  height : Int,
  px : Int,
  py : Int,
  max_iter : Int,
) -> Int {
  pixel_color(width, height, px, py, max_iter)
}
