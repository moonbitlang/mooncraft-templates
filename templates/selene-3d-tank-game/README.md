# Selene 3D Tank Game

A minimal 3D MoonBit game template for MoonCraft agents.

The frontend is a Selene WebGPU game built for the JavaScript target. It renders a 1920x1080 perspective 3D arena with walls, cover blocks, a player tank, moving enemy tanks, enemy turret tracking, projectile hits, and tank/obstacle collision. Tanks use a parent-child render rig so body, tracks, wheels, armor, turret, hatch, barrel, and muzzle pieces inherit root transforms. The backend is a small native `async/http` server that serves the generated game bundle and static shell.

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
- Click arena: lock the mouse pointer
- Mouse move: turn the tank view and turret while locked
- Mouse left button: fire
- `Space` / `Enter`: fire without mouse
- `R`: reset match
- `Escape`: release the mouse pointer
