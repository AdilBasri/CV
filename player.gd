extends CharacterBody3D

const SPEED = 4.5
const JUMP_VELOCITY = 4.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D
@onready var visuals = $Visuals
@onready var torch = $CameraPivot/Camera3D/Torch

var mouse_sensitivity = 0.002
var rot_x = 0.0
var rot_y = 0.0

# Torch 3D rotation offsets for a natural, styled handheld angle
const TORCH_ROTATION = Vector3(-15.0, 205.0, 15.0)
const TORCH_POSITION = Vector3(0.18, -0.18, -0.14)
const TORCH_SCALE = Vector3(1.4, 1.4, 1.4)

# Dynamic container for torch to isolate footstep/jump tweens from mouse look sway
var torch_container: Node3D = null

# Mouse sway dynamics variables
var mouse_input_velocity = Vector2.ZERO
var sway_pos = Vector3.ZERO
var sway_rot = Vector3.ZERO

# Continuous bobbing state variables
var walk_cycle = 0.0
var idle_cycle = 0.0

# Spring/decay offsets for jumps and landing shock
var recoil_y = 0.0
var recoil_rx = 0.0

# Interaction state flag
var is_interacting = false

# Reference to the dynamic mask camera to exclude specific meshes from post-processing
var mask_camera: Camera3D = null

# Walk audio player variables
var walk_audio_player: AudioStreamPlayer = null
var walk_timer = 0.0
var is_walking = false

# Stuck detection variables
var stuck_time = 0.0
var last_position = Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	visuals.visible = false # Hide visuals in first person
	
	# Load mouse sensitivity from settings config
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var sens_factor = config.get_value("accessibility", "mouse_sensitivity", 1.0)
		mouse_sensitivity = 0.002 * sens_factor
		print("Player mouse sensitivity configured from settings: ", mouse_sensitivity)
	
	# Create dynamic container for torch
	torch_container = Node3D.new()
	torch_container.name = "TorchContainer"
	camera.add_child(torch_container)
	
	# Reparent torch to torch_container
	if torch:
		torch.get_parent().remove_child(torch)
		torch_container.add_child(torch)
		
		# Set container base transform
		torch_container.position = TORCH_POSITION
		torch_container.rotation_degrees = TORCH_ROTATION
		torch_container.scale = TORCH_SCALE
		
		# Reset torch local transform (ready for mouse sway offsets)
		torch.position = Vector3.ZERO
		torch.rotation_degrees = Vector3.ZERO
		torch.scale = Vector3.ONE
		
	# Look for the mask camera under the World node
	var world = get_parent()
	if world:
		mask_camera = world.get_node_or_null("MaskViewport/Camera3D")
		
	# Set up the footstep walk audio player
	walk_audio_player = AudioStreamPlayer.new()
	walk_audio_player.name = "WalkAudioPlayer"
	walk_audio_player.stream = load("res://walking.mp3")
	if walk_audio_player.stream and "loop" in walk_audio_player.stream:
		walk_audio_player.stream.loop = false
	walk_audio_player.volume_db = -24.0 # Set walking sound to be the quietest sound
	add_child(walk_audio_player)

func _input(event):
	if is_interacting:
		return
		
	if event is InputEventMouseMotion:
		rot_y -= event.relative.x * mouse_sensitivity
		rot_x -= event.relative.y * mouse_sensitivity
		rot_x = clamp(rot_x, -1.4, 1.4)
		
		camera_pivot.rotation.x = rot_x
		rotation.y = rot_y
		
		# Accumulate mouse velocity for flashlight sway
		mouse_input_velocity += event.relative * 0.05
		
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	if is_interacting:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity.y = 0.0
		move_and_slide()
		
		# Stop walk audio when interacting
		if is_walking:
			is_walking = false
			walk_timer = 0.0
			if walk_audio_player and walk_audio_player.playing:
				walk_audio_player.stop()
		return

	# Add gravity.
	var was_in_air = not is_on_floor()
	if not is_on_floor():
		velocity.y -= gravity * delta
		
		# Variable jump height: cap upward velocity if space key is released early
		if not Input.is_key_pressed(KEY_SPACE) and velocity.y > 2.5:
			velocity.y = 2.5

	# Handle Jump.
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = JUMP_VELOCITY
		# Jump vertical and rotational recoil shock
		recoil_y = -0.06
		recoil_rx = -10.0

	# Get keyboard input direction relative to player rotation
	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1.0
		
	input_dir = input_dir.normalized()
	
	# Calculate movement direction based on player's local Y rotation
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var current_speed = SPEED
	if Input.is_key_pressed(KEY_SHIFT):
		current_speed = SPEED * 2.0
		
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)


	move_and_slide()
	
	# Dynamic physics stuck detection and rescue (wall/corner stuck solver)
	if not is_interacting:
		var input_moving = (Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or
							Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or
							Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or
							Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))
							
		var colliding = get_slide_collision_count() > 0
		var not_moving_much = global_position.distance_to(last_position) < (SPEED * delta * 0.15)
		
		if input_moving and colliding and not_moving_much:
			stuck_time += delta
			# If stuck for 0.45 seconds or trying to jump while pressed against obstacles
			if stuck_time >= 0.45 or (Input.is_key_pressed(KEY_SPACE) and stuck_time >= 0.20):
				trigger_unstuck()
		else:
			stuck_time = 0.0
			
		last_position = global_position
	
	# Handle walking sound play/stop/restart based on movement and floor state
	var horizontal_vel = Vector3(velocity.x, 0, velocity.z)
	var currently_walking = is_on_floor() and horizontal_vel.length() > 0.1
	
	if currently_walking:
		if not is_walking:
			is_walking = true
			walk_timer = 0.0
			if walk_audio_player:
				walk_audio_player.play()
		else:
			walk_timer += delta
			# 8.45 steps * (4.32s total file duration / 9 steps total) = 4.056 seconds per loop
			if walk_timer >= 4.056:
				walk_timer = 0.0
				if walk_audio_player:
					walk_audio_player.play()
	else:
		if is_walking:
			is_walking = false
			walk_timer = 0.0
			if walk_audio_player and walk_audio_player.playing:
				walk_audio_player.stop()
	
	# Camera landing shock impact
	if was_in_air and is_on_floor():
		recoil_y = -0.14
		recoil_rx = 12.0

	# Sync mask camera handled globally in world.gd

	# Continuous Kinetic Bobbing & Sway Calculations
	var target_camera_y = 0.0
	var target_camera_rz = 0.0
	var target_torch_pos = Vector3.ZERO
	var target_torch_rot = Vector3.ZERO
	if is_on_floor() and horizontal_vel.length() > 0.1:
		# 1. Walking State (Ellipsoid arm sway + head bob)
		walk_cycle += horizontal_vel.length() * delta * 2.2
		
		# Head bobbing (dip on impact)
		target_camera_y = -abs(sin(walk_cycle)) * 0.024
		target_camera_rz = cos(walk_cycle) * 0.005
		
		# Arm/Flashlight swing bobbing (cycles smoothly as a body extension)
		target_torch_pos.x = cos(walk_cycle * 0.5) * 0.016 # left/right swing at half speed
		target_torch_pos.y = -abs(sin(walk_cycle)) * 0.012 # vertical bob with steps
		target_torch_pos.z = sin(walk_cycle * 0.5) * 0.008
		
		target_torch_rot.x = sin(walk_cycle) * 1.5
		target_torch_rot.y = cos(walk_cycle * 0.5) * 4.5
		target_torch_rot.z = sin(walk_cycle * 0.5) * 3.0
	else:
		# 2. Idle State (Independent breathing bob)
		idle_cycle += delta * 1.8
		
		# Camera breathing Y
		target_camera_y = sin(idle_cycle) * 0.006
		
		# Flashlight breathes out of phase from the camera
		target_torch_pos.y = sin(idle_cycle - 1.0) * 0.004
		target_torch_pos.z = cos(idle_cycle - 1.0) * 0.002
		target_torch_rot.x = cos(idle_cycle) * 0.6
		target_torch_rot.y = sin(idle_cycle) * 0.4

	# Smoothly decay recoil impulses over time (spring physics)
	recoil_y = lerp(recoil_y, 0.0, 7.0 * delta)
	recoil_rx = lerp(recoil_rx, 0.0, 7.0 * delta)

	# Combine breathing/walking targets with physics recoil offsets
	var final_camera_y = target_camera_y + recoil_y
	var final_camera_rz = target_camera_rz
	
	var final_torch_pos = TORCH_POSITION + target_torch_pos
	final_torch_pos.y += recoil_y * 0.75 # Flashlight receives a portion of vertical recoil
	
	var final_torch_rot = TORCH_ROTATION + target_torch_rot
	final_torch_rot.x += recoil_rx # Flashlight pitch reacts directly to jump/landing

	# Smoothly interpolate final transforms (guarantees liquid-smooth transitions)
	camera.position.y = lerp(camera.position.y, final_camera_y, 12.0 * delta)
	camera.rotation.z = lerp(camera.rotation.z, final_camera_rz, 12.0 * delta)
	
	if torch_container:
		torch_container.position = torch_container.position.lerp(final_torch_pos, 10.0 * delta)
		torch_container.rotation_degrees = torch_container.rotation_degrees.lerp(final_torch_rot, 10.0 * delta)

	# 3. Mouse Look Sway (applied to the child Torch relative to the animated container)
	var target_sway_pos = Vector3(
		-mouse_input_velocity.x * 0.0015,
		mouse_input_velocity.y * 0.0015,
		0.0
	)
	var target_sway_rot = Vector3(
		mouse_input_velocity.y * 0.6,
		-mouse_input_velocity.x * 0.6,
		-mouse_input_velocity.x * 0.3
	)
	
	# Clamp sway values for safety
	target_sway_pos.x = clamp(target_sway_pos.x, -0.04, 0.04)
	target_sway_pos.y = clamp(target_sway_pos.y, -0.04, 0.04)
	target_sway_rot.x = clamp(target_sway_rot.x, -12.0, 12.0)
	target_sway_rot.y = clamp(target_sway_rot.y, -15.0, 15.0)
	target_sway_rot.z = clamp(target_sway_rot.z, -10.0, 10.0)
	
	# Smoothly interpolate current sway
	sway_pos = sway_pos.lerp(target_sway_pos, 8.0 * delta)
	sway_rot = sway_rot.lerp(target_sway_rot, 8.0 * delta)
	
	if torch:
		torch.position = sway_pos
		torch.rotation_degrees = sway_rot
		
	# Decay mouse velocity input over time
	mouse_input_velocity = mouse_input_velocity.lerp(Vector2.ZERO, 12.0 * delta)

func trigger_unstuck():
	var avg_normal = Vector3.ZERO
	var count = get_slide_collision_count()
	for i in range(count):
		var col = get_slide_collision(i)
		if col:
			avg_normal += col.get_normal()
	
	if count > 0:
		avg_normal = avg_normal.normalized()
		# Nudge player away from wall and slightly up
		var push_vector = avg_normal * 0.3 + Vector3.UP * 0.15
		global_position += push_vector
		velocity = avg_normal * SPEED
		stuck_time = 0.0
		print("Rescued stuck player. Nudge vector: ", push_vector)
	else:
		# Fallback nudge if no collisions registered but timer fired
		var look_dir = -camera.global_transform.basis.z
		look_dir.y = 0.0
		look_dir = look_dir.normalized()
		# Push backward
		var push_vector = -look_dir * 0.3 + Vector3.UP * 0.15
		global_position += push_vector
		stuck_time = 0.0
		print("Fallback stuck rescue. Nudge vector: ", push_vector)
