extends CharacterBody3D

@export var walk_range = 5.0

#possible states
enum {
	IDLE,
	ALERT,
	ATTACK,
	HIDING,
	STUNNED
}

#stats
var state = IDLE
var health = 20
const MASS = 4
const SPEED = 20
const ROTATION_SPEED = 2

#misc
var target

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var nav_agent = $NavAgent
@onready var fire_cooldown = $FireCooldown
@onready var fire_lag = $FireLag
@onready var walk_cooldown = $WalkCooldown
@onready var head = $Head
@onready var sight = $Head/Sight
@onready var aim = $Head/Aim
@onready var weapon = $Head/Colt
@onready var hit_sfx = $SFX/Hit

@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	randomize()

func _process(_delta):
	update_target_location()

func _physics_process(delta):
	if !is_on_floor():
		velocity.y -= gravity * delta * MASS
	
	match state:
		ALERT:
			if fire_lag.is_stopped():
				head.look_at(target.global_transform.origin + Vector3(0,1.5,0), Vector3.UP)
				rotate_y(deg_to_rad(head.rotation.y * ROTATION_SPEED))
			
			var next_location = nav_agent.get_next_path_position()
			var new_velocity = (next_location - global_transform.origin).normalized() * SPEED
			velocity = velocity.move_toward(new_velocity, 0.75)
	
	move_and_slide()
	
	#weapon
	if weapon.has_method("aim_from"):
		weapon.aim_from(head.global_position)

func damage(level):
	if state == IDLE:
		state = ALERT
	health -= level
	hit_sfx.play()
	
	if health <= 0:
		queue_free()

func alert(body):
	if !body: #if an enemy is shot at twice in the same frame, the game crashes. This is here to try and prevent that.
		return
	
	if body.is_in_group("player"):
		target = body
		state = ALERT
		fire_cooldown.start()
		walk_cooldown.start()

func _on_fire_cooldown_timeout():
	if aim.is_colliding():
		var collider = aim.get_collider()
		
		if !collider: #if an enemy is shot at twice in the same frame, the game crashes. This is here to try and prevent that.
			return
		
		if collider.is_in_group("player") and collider.has_method("damage"):
			fire_lag.start()

func _on_walk_cooldown_timeout():
	nav_agent.target_location.x = global_position.x + randf_range(-walk_range, walk_range)
	nav_agent.target_location.z = global_position.z + randf_range(-walk_range, walk_range)

func _on_fire_lag_timeout():
	weapon.fire()

func update_target_location():
	sight.target_position = to_local(player.global_position)
	if sight.is_colliding():
		alert(sight.get_collider())
