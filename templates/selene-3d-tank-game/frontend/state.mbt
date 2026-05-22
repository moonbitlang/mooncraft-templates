///|
const VIEWPORT_WIDTH : Double = 960.0

///|
const VIEWPORT_HEIGHT : Double = 640.0

///|
const FPS : UInt = 60

///|
const ARENA_SIZE : Double = 14.0

///|
const TANK_SPEED : Double = 4.2

///|
const TANK_TURN_SPEED : Double = 2.4

///|
const PROJECTILE_SPEED : Double = 9.0

///|
const PROJECTILE_TTL : Double = 1.8

///|
const RELOAD_SECONDS : Double = 0.35

///|
const TARGET_HIT_RADIUS : Double = 0.85

///|
const UI_ZINDEX : Int = 1000

///|
priv struct TankState {
  mut position : @math.Vec3
  mut yaw : Double
  mut reload : Double
  mut score : Int
}

///|
priv struct ProjectileState {
  mut active : Bool
  mut position : @math.Vec3
  mut yaw : Double
  mut ttl : Double
}

///|
priv struct TargetState {
  entity : @entity.Entity
  position : @math.Vec3
  mut active : Bool
}

///|
let tank : TankState = {
  position: @math.Vec3::Vec3(0.0, 0.0, 3.5),
  yaw: 0.0,
  reload: 0.0,
  score: 0,
}

///|
let projectile : ProjectileState = {
  active: false,
  position: @math.Vec3::zero(),
  yaw: 0.0,
  ttl: 0.0,
}

///|
let target_states : Array[TargetState] = []

///|
let camera_entity : @entity.Entity = @entity.Entity::Entity()

///|
let light_entity : @entity.Entity = @entity.Entity::Entity()

///|
let tank_body_entity : @entity.Entity = @entity.Entity::Entity()

///|
let tank_turret_entity : @entity.Entity = @entity.Entity::Entity()

///|
let tank_barrel_entity : @entity.Entity = @entity.Entity::Entity()

///|
let projectile_entity : @entity.Entity = @entity.Entity::Entity()

///|
let hud_entity : @entity.Entity = @entity.Entity::Entity()

///|
let floor_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let tank_body_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let tank_turret_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let tank_barrel_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let projectile_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let target_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let floor_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let tank_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let turret_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let projectile_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let target_material : Ref[@render3d.MaterialHandle?] = { val: None }
