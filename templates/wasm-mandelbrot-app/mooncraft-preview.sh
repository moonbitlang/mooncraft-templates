#!/bin/sh
set -eu

port="${1:-4300}"

case "$port" in
  ""|*[!0-9]*)
    echo "port must be numeric" >&2
    exit 2
    ;;
esac

cd "$(dirname "$0")"
rm -rf preview-dist
mkdir -p preview-dist

moon build --target wasm frontend
cp _build/wasm/debug/build/frontend/frontend.wasm preview-dist/frontend.wasm

cat > preview-dist/index.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>MoonCraft Wasm Mandelbrot</title>
  <style>
    body { margin: 0; font-family: system-ui, sans-serif; background: #101820; color: #f7f7f4; }
    main { max-width: 860px; margin: 0 auto; padding: 32px 20px; }
    h1 { margin: 0 0 16px; font-size: 28px; }
    canvas { width: 100%; height: auto; image-rendering: pixelated; background: #101820; border: 1px solid #33434d; }
    label { display: flex; gap: 10px; align-items: center; margin-top: 16px; }
  </style>
</head>
<body>
  <main>
    <h1>Wasm Mandelbrot</h1>
    <canvas id="canvas"></canvas>
    <label>Iterations <input id="iter" type="range" min="24" max="180" value="80"></label>
  </main>
  <script type="module">
    const canvas = document.getElementById("canvas");
    const slider = document.getElementById("iter");
    const { instance } = await WebAssembly.instantiateStreaming(fetch("/frontend.wasm"), {});
    const api = instance.exports;
    const width = api.default_width();
    const height = api.default_height();
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext("2d");
    const image = ctx.createImageData(width, height);

    function render() {
      const maxIter = Number(slider.value);
      for (let y = 0; y < height; y += 1) {
        for (let x = 0; x < width; x += 1) {
          const color = api.mandelbrot_color(width, height, x, y, maxIter);
          const offset = (y * width + x) * 4;
          image.data[offset] = (color >> 16) & 255;
          image.data[offset + 1] = (color >> 8) & 255;
          image.data[offset + 2] = color & 255;
          image.data[offset + 3] = 255;
        }
      }
      ctx.putImageData(image, 0, 0);
    }

    slider.addEventListener("input", render);
    render();
  </script>
</body>
</html>
HTML

exec moon run --target native backend -- preview-dist "$port"
