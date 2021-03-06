extends KinematicBody2D

const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")

export var ACCELERATION = 300
export var MAX_SPEED = 50
export var FRICTION = 200

enum { IDLE, WANDER, CHASE }

var velocity = Vector2.ZERO
var knockback = Vector2.ZERO

var state = IDLE

onready var sprite = $AnimatedSprite
onready var stats = $Stats
onready var player_detection_zone = $PlayerDetectionZone
onready var hurtbox = $HurtBox
onready var soft_collision = $SoftCollision
onready var wander_controller = $WanderController
onready var animation_player = $AnimationPlayer

func _physics_process(delta):
	print("Current State : ", state)
	knockback = knockback.move_toward(Vector2.ZERO, FRICTION * delta)
	knockback = move_and_slide(knockback)
	
	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			pick_random_state()
		WANDER:
			accelerate_towards_point(wander_controller.target_position, delta)
			pick_random_state()
			
		CHASE:
			seek_player()
			var player = player_detection_zone.player
			if player != null:
				accelerate_towards_point(player.global_position, delta)
	
	if soft_collision.is_colliding():
		velocity += soft_collision.get_push_vector() * delta * 400
	velocity = move_and_slide(velocity)

func accelerate_towards_point(point, delta):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
	sprite.flip_h = velocity.x < 0

func seek_player():
	if player_detection_zone.can_see_player():
		state = CHASE
		return
	state = IDLE

func _on_HurtBox_area_entered(area):
	stats.health -= area.damage
	knockback = area.knockback_vector * 100
	hurtbox.create_hit_effect()
	hurtbox.start_invincibility(0.4)

func pick_random_state():
	seek_player()
	if state == CHASE : return
	var state_list = [IDLE, WANDER]
	state_list.shuffle()
	self.state = state_list[0]
	if wander_controller.get_time_left() == 0:
		wander_controller.start_wander_timer(rand_range(1,3))
	
func _on_Stats_no_health():
	queue_free()
	var enemy_death_effect = EnemyDeathEffect.instance()
	get_parent().add_child(enemy_death_effect)
	enemy_death_effect.global_position = global_position


func _on_HurtBox_invincibility_started():
	animation_player.play("Start")

func _on_HurtBox_invincibility_ended():
	animation_player.play("Stop")
