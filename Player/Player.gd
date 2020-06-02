extends KinematicBody2D

const ACCELERATION = 500
const FRICTION = 500
const MAX_SPEED = 80
const ROLL_SPEED = 125

const PlayerHurtSound = preload("res://Player/PlayerHurtSound.tscn")

enum { MOVE, ROLL, ATTACK }

var state = MOVE
var velocity = Vector2.ZERO 
var roll_vector = Vector2.RIGHT
var stats = PlayerStats

onready var animation_player = $AnimationPlayer
onready var animation_tree = $AnimationTree
onready var animation_state = animation_tree.get("parameters/playback")
onready var collision_shape = $HitboxPivot/SwordHitbox/CollisionShape2D
onready var sword_hitbox = $HitboxPivot/SwordHitbox
onready var hurt_box = $HurtBox
onready var blink_animation_player = $BlinkAnimationPlayer

func _ready():
	stats.connect("no_health", self, "queue_free")
	animation_tree.active = true
	sword_hitbox.knockback_vector = roll_vector

func _physics_process(delta):
	
	match state:
		MOVE:
			move_state(delta)
		ROLL:
			roll_state(delta)
		ATTACK:
			attack_state(delta)
	
	# add another if state and return here
	# if the action wants to be uninterruptable
	# by other keys
	if(state == ROLL): return
	
	if Input.is_action_just_pressed("ui_attack"):
		state = ATTACK
	if Input.is_action_just_pressed("ui_move"):
		collision_shape.disabled = true
		state = MOVE
	if Input.is_action_just_pressed("ui_roll"):
		state = ROLL
	

func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
#	print(input_vector)
	
	if input_vector != Vector2.ZERO:
		roll_vector = input_vector
		sword_hitbox.knockback_vector = input_vector
		animation_tree.set("parameters/Idle/blend_position", input_vector)
		animation_tree.set("parameters/Run/blend_position", input_vector)
		animation_tree.set("parameters/Attack/blend_position", input_vector)
		animation_tree.set("parameters/Roll/blend_position", input_vector)
		animation_state.travel("Run")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
#		print(velocity)
		velocity = move_and_slide(velocity)
		return
	
	animation_state.travel("Idle")	
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
#	print(velocity)
	velocity = move_and_slide(velocity)

func roll_state(delta):
	velocity = roll_vector * ROLL_SPEED
	animation_state.travel("Roll")
	move_and_collide(velocity * delta, false)

func attack_state(delta):
	velocity = Vector2.ZERO
	animation_state.travel("Attack")
	

func roll_animation_finished():
	state = MOVE
	
func attack_animation_finished():
	state = MOVE

func _on_HurtBox_area_entered(area):
	stats.health -= area.damage
	hurt_box.start_invincibility(0.6)
	hurt_box.create_hit_effect()
	var player_hurt_sound = PlayerHurtSound.instance()
	get_tree().current_scene.add_child(player_hurt_sound)


func _on_HurtBox_invincibility_started():
	blink_animation_player.play("Start")


func _on_HurtBox_invincibility_ended():
	blink_animation_player.play("Stop")
