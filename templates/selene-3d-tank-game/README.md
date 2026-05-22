# Selene 3D Tank Game

A minimal 3D MoonBit game template for MoonCraft agents.

The frontend is a Selene WebGPU game built for the JavaScript target. It renders a perspective 3D arena with walls, cover blocks, a player tank, enemy tank models, and projectile hits. The backend is a small native `async/http` server that serves the generated game bundle and static shell.

## Preview

```sh
./mooncraft-preview.sh 4300
```

The script builds the frontend, copies the browser assets into `preview-dist/`, and runs the native server on `0.0.0.0:<port>`.

## Controls

- `W` / `ArrowUp`: drive forward
- `S` / `ArrowDown`: reverse
- `A` / `ArrowLeft`: turn left
- `D` / `ArrowRight`: turn right
- `Space` / `Enter`: fire
- `R`: reset targets
- `Escape`: exit
