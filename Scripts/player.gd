extends CharacterBody3D


const SPEED = 5.0
const SPRINT_SPEED = 10.0
const JUMP_VELOCITY = 4.5

var gold = 0
var hp = 50
var maxHp = 50
var damage = 10
var target = []
var value = 15

var onCooldown = false
var sensivity = 0.003

var regen_rate = 2.0
var regen_timer = 0.0


@onready var goldLabel = $HUD/GoldLabel
@onready var hpBar = $HUD/HpBar
@onready var camera = $FirstPerson
@onready var animationPlayer = $AnimationPlayer
@onready var cooldown = $AttackCooldown
@onready var damageFlash = $HUD/damageFlash



func _ready():
	hpBar.max_value = 50
	$FirstPerson.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func attack():
	if Input.is_action_just_pressed("attack") and onCooldown == false:
		animationPlayer.play("SwordSwing")
		onCooldown = true
		cooldown.start()

func flash_damage():
	damageFlash.color = Color(1, 0, 0, 0.4)
	await get_tree().create_timer(0.1).timeout
	damageFlash.color = Color(1, 0, 0, 0)

func camera_shake():
	var origin = camera.position
	for i in 10:
		camera.position = origin + Vector3(randf_range(-0.05, 0.05), randf_range(-0.05, 0.05), 0)
		await get_tree().create_timer(0.02).timeout
	camera.position = origin

func deal_damage():
	for enemies in target:
		enemies.hp -= damage

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensivity)
		camera.rotate_x(-event.relative.y * sensivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(70))

func update_HUD():
	hpBar.value = hp
	goldLabel.text = str(gold)

func _switch_view():
	if Input.is_action_just_pressed("switch"):
		if camera == $FirstPerson:
			camera = $Head
			$Head/ThirdPerson.current = true
		else:
			camera = $FirstPerson
			$FirstPerson.current = true


func _process(delta):
	update_HUD()
	attack()
	_switch_view()
	
	if hp < maxHp:
		regen_timer += delta
		if regen_timer >= regen_rate:
			hp += 1
			regen_timer = 0.0
	
	if hp <= 0:
		get_tree().change_scene_to_file("res://Scenes/game_over.tscn")
	if Input.is_action_just_pressed("escape"):
		get_tree().quit()



func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_speed = SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else SPEED
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()


func _on_attack_cooldown_timeout() -> void:
	onCooldown = false


func _on_attack_zone_body_entered(body):
	if body.is_in_group("Enemy"):
		target.append(body)


func _on_attack_zone_body_exited(body):
	if body.is_in_group("Enemy"):
		target.erase(body)
	
