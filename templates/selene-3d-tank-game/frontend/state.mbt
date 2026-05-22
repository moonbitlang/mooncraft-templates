///|
const VIEWPORT_WIDTH : Double = 1920.0

///|
const VIEWPORT_HEIGHT : Double = 1080.0

///|
const FPS : UInt = 60

///|
const ARENA_SIZE : Double = 40.0

///|
const TANK_SPEED : Double = 9.0

///|
const TANK_TURN_SPEED : Double = 2.2

///|
const PROJECTILE_SPEED : Double = 35.0

///|
const ENEMY_PROJECTILE_SPEED : Double = 22.0

///|
const PROJECTILE_TTL : Double = 2.0

///|
const ENEMY_PROJECTILE_TTL : Double = 2.5

///|
const RELOAD_SECONDS : Double = 0.25

///|
const ENEMY_HIT_RADIUS : Double = 1.45

///|
const PLAYER_HIT_RADIUS : Double = 1.35

///|
const PROJECTILE_HIT_RADIUS : Double = 0.18

///|
const ENEMY_MOVE_SPEED : Double = 3.5

///|
const ENEMY_BODY_TURN_SPEED : Double = 1.0

///|
const ENEMY_TURRET_TURN_SPEED : Double = 2.0

///|
const ENEMY_MIN_DISTANCE : Double = 12.0

///|
const ENEMY_FIRE_DISTANCE : Double = 30.0

///|
const ENEMY_RELOAD_SECONDS : Double = 1.65

///|
const CAMERA_FOV_Y_DEGREES : Double = 55.0

///|
const CAMERA_DISTANCE : Double = 30.0

///|
const CAMERA_HEIGHT : Double = 14.0

///|
const CAMERA_LOOK_AHEAD : Double = 7.5

///|
const CAMERA_TARGET_HEIGHT : Double = 1.0

///|
const MOUSE_TURN_SENSITIVITY : Double = 0.004

///|
const UI_ZINDEX : Int = 1000

///|
priv struct TankState {
  mut position : @math.Vec3
  mut yaw : Double
  mut turret_yaw : Double
  mut reload : Double
  mut score : Int
  mut hp : Int
  mut status : GameStatus
}

///|
priv struct ProjectileState {
  entity : @entity.Entity
  mut active : Bool
  mut position : @math.Vec3
  yaw : Double
  mut ttl : Double
  from_player : Bool
}

///|
priv struct EnemyState {
  left_track_entity : @entity.Entity
  right_track_entity : @entity.Entity
  body_entity : @entity.Entity
  turret_entity : @entity.Entity
  barrel_entity : @entity.Entity
  mut position : @math.Vec3
  mut yaw : Double
  mut turret_yaw : Double
  mut hp : Int
  mut cooldown : Double
  mut active : Bool
}

///|
priv struct Obstacle {
  position : @math.Vec3
  size : @math.Vec3
}

///|
priv enum GameStatus {
  Playing
  GameOver
  Victory
} derive(Eq)

///|
let tank : TankState = {
  position: @math.Vec3::Vec3(0.0, 0.0, 18.0),
  yaw: 0.0,
  turret_yaw: 0.0,
  reload: 0.0,
  score: 0,
  hp: 100,
  status: Playing,
}

///|
let projectiles : Array[ProjectileState] = []

///|
let enemy_states : Array[EnemyState] = []

///|
let camera_entity : @entity.Entity = @entity.Entity::Entity()

///|
let light_entity : @entity.Entity = @entity.Entity::Entity()

///|
let tank_body_entity : @entity.Entity = @entity.Entity::Entity()

///|
let tank_left_track_entity : @entity.Entity = @entity.Entity::Entity()

///|
let tank_right_track_entity : @entity.Entity = @entity.Entity::Entity()

///|
let tank_turret_entity : @entity.Entity = @entity.Entity::Entity()

///|
let tank_barrel_entity : @entity.Entity = @entity.Entity::Entity()

///|
let hud_entity : @entity.Entity = @entity.Entity::Entity()

///|
let floor_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let wall_long_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let wall_side_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let obstacle_block_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let tank_track_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let tank_body_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let tank_turret_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let tank_barrel_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let projectile_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let floor_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let wall_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let obstacle_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let track_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let tank_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let turret_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let enemy_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let enemy_turret_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let projectile_material : Ref[@render3d.MaterialHandle?] = { val: None }
