extends Node3D

var mask_viewport: SubViewport = null
var mask_camera: Camera3D = null

# Dialogue & interaction state variables
var subtitles_enabled = true
var interact_car_text = "Interact with E for get in the car!"
var chase_warning_text = "Run to car for your life!"
var escape_message_text = "YOU MANAGED TO ESCAPE!"
var narrative_credit_text = ""
var dev_log_slides = []
var dialogue_lines = [
	"Good heavens, you're soaked to the bone! Out in this storm... It's freezing out there.",
	"Forget about that piece of junk for now, son. The roads ahead are flooded... you're not going anywhere tonight.",
	"I could never let a guest of mine stay out in rain like this. Why, it would be a crime.",
	"Come now, step inside. The fire is roaring... Besides, we have so much to talk about."
]
var dialogue_lines_2 = [
	"Ah, the front door is acting up again, is it? Confounded thing... Don't even bother looking for a key, it wouldn't do you any good anyway.",
	"I get locked out of my own home more often than I'd care to admit! Just poke around the back and find another way in. I'm sure you'll figure it out."
]
var first_conversation_done = false
var door_e_pressed = false
var notopen_player: AudioStreamPlayer = null

var is_looking_at_vent = false
var vent_e_pressed = false
var is_inside_house = false

# Teleportation & Fade parameters
var fade_layer: CanvasLayer = null
var fade_rect: ColorRect = null
var fade_alpha = 0.0
var fade_state = 0 # 0 = idle, 1 = fade out, 2 = hold black, 3 = fade in
var fade_timer = 0.0

var ambient_player: AudioStreamPlayer = null
var rain_player: AudioStreamPlayer = null

# Computer interaction state variables
var is_looking_at_comp = false
var is_comp_interacting = false
var interact2_camera: Camera3D = null
var comp_dialogue_lines = [
	"A glowing text document is left open on the screen...",
	"> Current project architecture: Godot.",
	"> Executing entirely via GDScript.",
	"> Note: JavaScript, TypeScript, and Python proficiencies available but unutilized in this instance.",
	"> Previous engine experiences (Unity, GameMaker, UE5) logged and archived."
]
var transition_cam: Camera3D = null
var keyboard_click_player: AudioStreamPlayer = null
var comp_hum_player: AudioStreamPlayer = null

# Painting interaction state variables
var is_looking_at_paint = false
var is_paint_interacting = false
var interact3_camera: Camera3D = null
var paint_dialogue_lines = [
	"You wipe a thin layer of dust off an old, framed photograph. Seven people are smiling in the picture.",
	"Project: subtracker.",
	"A dedicated team of seven, seamlessly led. The initiative dragged two local banks into its wake, and played a pivotal role in the exit of the project that followed.",
	"Beyond the flawless code (JavaScript, Node.js) and the great camaraderie, the true catalyst was its aggressive marketing strategy...",
	"...a strategy driven heavily by the founder, Adil Basri Erdem, and his background in International Trade and Finance."
]

# Wolf figurine interaction state variables
var is_looking_at_wolf = false
var is_wolf_interacting = false
var interact4_camera: Camera3D = null
var wolf_dialogue_lines = [
	"You examine a bizarre collection gathered in the corner: a carved wolf figurine, worn-out playing cards, and heavy metallic tokens.",
	"The archives of Team Husk. Five distinct IPs materialized over two relentless years of development.",
	"The cards belong to 'Soul's Gambit', a dark roguelike deckbuilder. The tokens? Pieces for 'Glad To Feed You!', a macabre game of horror checkers.",
	"Scattered geometric shapes hint at 'SPHENKS', a Tetris-like puzzle shifting between 2D 	and 3D dimensions...",
	"...while a small, pixelated sketch reveals 'Chick: Going to The Chicken Land', a deceptive story-driven platformer.",
	"Different genres, different mechanics. All crafted by the same hands."
]

# Table 2 interaction state variables
var is_looking_at_table2 = false
var is_table2_interacting = false
var interact5_camera: Camera3D = null
var table2_dialogue_lines = [
	"You step closer to the desk. Under the dim light of the lamp, an investigation board dominates the wall.",
	"All the red strings and scattered notes connect to a single face in the center.",
	"Subject: Adil Basri ERDEM.",
	"A mastermind poised to pioneer a new era in the Turkish game industry. Especially in the realm of psychological horror.",
	"The dossier on the desk contains his direct contact protocols. The host's voice echoes in your mind: 'You should reach out to him... before it's too late.'"
]
var table2_links_bbcode = "[center]\n[url=https://www.linkedin.com/in/adil-basri-erdem-189941249/][color=#cc1111]ACCESS LINKEDIN ARCHIVE[/color][/url]\n\n[url=mailto:adilbasri06161@gmail.com][color=#cc1111]INITIATE DIRECT MAIL[/color][/url]\n\n[url=http://www.teamhusk.com.tr][color=#cc1111]INSPECT PORTFOLIO (TEAM HUSK)[/color][/url]\n\n[url=close][color=#777777]EXIT DOSSIER[/color][/url]\n[/center]"
var rich_text_label: RichTextLabel = null

# Poster (INTERRED) interaction state variables
var is_looking_at_poster = false
var is_poster_interacting = false
var interact6_camera: Camera3D = null
var poster_dialogue_lines = [
	"You stare at a large poster hanging exactly where an exit should have been.",
	"INTERRED.",
	"A macabre blend of chess-like tactics and rogue-lite horror.",
	"A playable demo is currently lurking on Steam. It is completely free to experience.",
	"This dark creation is kept alive and evolving solely through the support and feedback of its players. You should seriously consider supporting the team.",
	"If you enjoyed the twisted atmosphere of this little interactive CV... you will feel right at home with INTERRED."
]
var poster_links_bbcode = "[center]\n[url=https://store.steampowered.com/app/4661190/INTERRED/][color=#cc1111]INTERRED[/color][/url]\n\n[url=close][color=#777777]EXIT DOSSIER[/color][/url]\n[/center]"

# Climax sequence and Enemy AI state variables
var interacted_cv_items: Array = []
var is_chase_active = false
var climax_triggered = false
var is_escape_prompt_active = false
var ps2_material: ShaderMaterial = null


var heartbeat_sfx: AudioStreamPlayer = null
var scratch_sfx: AudioStreamPlayer = null
var walkey_sfx: AudioStreamPlayer = null
var horror_sfx: AudioStreamPlayer = null

var warning_label: Label = null




var current_line_idx = -1
var is_interacting = false
var player_node: CharacterBody3D = null
var man_node: Node3D = null
var interact_camera: Camera3D = null

# Dialogue UI nodes
var ui_layer: CanvasLayer = null
var interact_prompt: Label = null
var dialogue_panel: Panel = null
var dialogue_label: Label = null

# Typewriter and voice/click variables
var typewriter_text = ""
var typewriter_char_idx = 0
var typewriter_speed = 0.04 # 40ms per character
var typewriter_timer = 0.0
var typewriter_active = false
var dialogue_cooldown = 0.0

var mumble_player: AudioStreamPlayer = null
var typewriter_sound_player: AudioStreamPlayer = null

func _ready():
	print("World script initialized. Setting up window and environment...")
	
	# 1. Set up Volvo mask viewport first so the screen shader can use it
	print("Setting up Volvo render mask...")
	setup_volvo_mask_viewport()
	
	setup_horror_environment()
	
	print("Setting up collisions and wall materials...")
	setup_collisions_and_wall_materials()
	
	print("Setting up Player...")
	setup_player()
	
	print("Setting up PS2 screen shader...")
	setup_ps2_screen_shader()
	
	print("Setting up Man collision and AnimationPlayer2...")
	setup_man_collision_and_animation()
	
	print("Setting up ambient background audio...")
	setup_ambient_audio()
	
	# Look up interaction target nodes and configure Dialogue UI
	man_node = find_node_by_name(self, "Man")
	if not man_node:
		man_node = find_node_by_name(self, "Character_Male")
	interact_camera = get_node_or_null("Interact1")
	interact2_camera = get_node_or_null("Interact2")
	interact3_camera = get_node_or_null("Interact3")
	interact4_camera = get_node_or_null("Interact4")
	interact5_camera = get_node_or_null("Interact5")
	interact6_camera = get_node_or_null("Interact6")
	setup_tap_material()
	setup_ui()
	setup_climax_elements()
	
	# Apply dynamic configuration and gameplay localization
	apply_settings_from_config()
	apply_gameplay_localization()

func setup_climax_elements():
	# 1. Initialize sfx players
	heartbeat_sfx = AudioStreamPlayer.new()
	heartbeat_sfx.name = "heartbeat_sfx"
	heartbeat_sfx.stream = load("res://heartbeat.mp3")
	heartbeat_sfx.bus = &"SFX"
	add_child(heartbeat_sfx)
	
	scratch_sfx = AudioStreamPlayer.new()
	scratch_sfx.name = "scratch_sfx"
	scratch_sfx.stream = load("res://scratch.mp3")
	scratch_sfx.bus = &"SFX"
	add_child(scratch_sfx)
	
	walkey_sfx = AudioStreamPlayer.new()
	walkey_sfx.name = "walkey_sfx"
	walkey_sfx.stream = load("res://walkey.mp3")
	walkey_sfx.bus = &"SFX"
	add_child(walkey_sfx)
	
	horror_sfx = AudioStreamPlayer.new()
	horror_sfx.name = "horror_sfx"
	horror_sfx.stream = load("res://horror.mp3")
	horror_sfx.bus = &"SFX"
	add_child(horror_sfx)
	
	# 2. Add CV items to group "cv_item" programmatically
	var comp_col = get_node_or_null("homey/comp/StaticBody3D")
	if comp_col: comp_col.add_to_group("cv_item")
	
	var paint_node = find_node_by_name(self, "Paint_12")
	var paint_col = paint_node.get_node_or_null("StaticBody3D") if paint_node else null
	if paint_col: paint_col.add_to_group("cv_item")
	
	var wolf_node = find_node_by_name(self, "wolf")
	var wolf_col = wolf_node.get_node_or_null("StaticBody3D") if wolf_node else null
	if wolf_col: wolf_col.add_to_group("cv_item")
	
	var table2_node = find_node_by_name(self, "table2")
	var table2_col = table2_node.get_node_or_null("StaticBody3D") if table2_node else null
	if table2_col: table2_col.add_to_group("cv_item")
	
	var poster_col = get_node_or_null("homey/MeshInstance3D/StaticBody3D")
	if poster_col: poster_col.add_to_group("cv_item")
	
	# 3. Configure the enemy node
	var enemy_node = get_node_or_null("enemy")
	if enemy_node:
		enemy_node.visible = false
		enemy_node.set_script(load("res://enemy.gd"))
		enemy_node.set_physics_process(true)
		print("Enemy script and physics process set up successfully.")
		print("Enemy tree structure:")
		print_node_hierarchy(enemy_node, "")
		
	# 4. Configure the volvo node
	var volvo_node = get_node_or_null("volvo")
	if volvo_node:
		volvo_node.set_script(load("res://volvo.gd"))
		volvo_node.set_process(true)
		volvo_node.set_process_input(true)
		volvo_node._ready()
		print("Volvo script attached and initialized successfully.")


func setup_tap_material():
	var tap_mesh = get_node_or_null("tap/MeshInstance3D")
	if tap_mesh:
		var mat = ShaderMaterial.new()
		var shader = load("res://macabre_distort.gdshader")
		if shader:
			mat.shader = shader
			var texture = load("res://foto.png")
			if texture:
				mat.set_shader_parameter("albedo_texture", texture)
			tap_mesh.material_override = mat
			print("Tap (Adil Erdem photo) macabre distortion shader material successfully applied.")
		else:
			print("Error: Could not load res://macabre_distort.gdshader")
	else:
		print("Warning: tap/MeshInstance3D not found in scene tree.")

	# Also apply the same shader to Paint_12 photo mesh
	var paint_node = find_node_by_name(self, "Paint_12")
	var paint_mesh = paint_node.get_node_or_null("MeshInstance3D") if paint_node else null
	if paint_mesh:
		var mat = ShaderMaterial.new()
		var shader = load("res://macabre_distort.gdshader")
		if shader:
			mat.shader = shader
			var texture = load("res://sub.png")
			if texture:
				mat.set_shader_parameter("albedo_texture", texture)
			paint_mesh.material_override = mat
			print("Paint_12 macabre distortion shader material successfully applied.")
		else:
			print("Error: Could not load res://macabre_distort.gdshader for Paint_12")
	else:
		print("Warning: Paint_12/MeshInstance3D not found in scene tree.")



func _input(event):
	# Allow toggling fullscreen with F11 or Alt+Enter
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			toggle_fullscreen()
			
		# Close dialogue on E key if links are shown
		if event.keycode == KEY_E and is_interacting:
			if rich_text_label and rich_text_label.visible:
				end_interaction()
				return

	if is_interacting and event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if rich_text_label and rich_text_label.visible:
				# Prevent advancing/closing dialogue when links are active
				return
			advance_dialogue()


func toggle_fullscreen():
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func setup_horror_environment():
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	
	env.background_mode = Environment.BG_CLEAR_COLOR
	
	# Slightly lighter ambient light for better details visibility (moonlight gray-blue)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.18, 0.22, 0.28)
	env.ambient_light_energy = 1.2
	
	# Standard depth fog: highly optimized, WebGL2-friendly
	env.volumetric_fog_enabled = false
	env.fog_enabled = true
	env.fog_light_color = Color(0.04, 0.05, 0.07) # Dark blue-black mist
	env.fog_density = 0.038                       # Slightly lighter fog density (was 0.045)
	
	world_env.environment = env
	add_child(world_env)
	
	# Moonlight source: Brighter moonlight glow to light up the map
	var moon = DirectionalLight3D.new()
	moon.name = "Moonlight"
	moon.light_color = Color(0.60, 0.68, 0.82)
	moon.light_energy = 0.70                    # Raised to illuminate Volvo/world details
	moon.rotation_degrees = Vector3(-40, 50, 0)
	moon.shadow_enabled = true
	moon.shadow_bias = 0.03
	add_child(moon)

func setup_collisions_and_wall_materials():
	var wall_material = ShaderMaterial.new()
	var wall_shader = load("res://wall_sky_shader.gdshader")
	if wall_shader:
		wall_material.shader = wall_shader

	for child in get_children():
		var name_lower = child.name.to_lower()
		# Skip Man/Character_Male to avoid double collision shapes
		if "character" in name_lower or "male" in name_lower or "man" in name_lower:
			continue
			
		var needs_collision = ("wall" in name_lower or 
							   "volvo" in name_lower or 
							   "yol" in name_lower or 
							   "home" in name_lower or 
							   "cooler" in name_lower or
							   "caravan" in name_lower or
							   "car2" in name_lower or
							   "car3" in name_lower or
							   "homey" in name_lower)
		process_node_branch(child, needs_collision, wall_material)

func process_node_branch(node: Node, needs_collision: bool, wall_mat: Material):
	var name_lower = node.name.to_lower()
	if "wolf" in name_lower:
		return
	
	if node is MeshInstance3D:
		if "wall" in name_lower:
			node.material_override = wall_mat
			
		if needs_collision and node.mesh:
			var already_has_collision = false
			for child in node.get_children():
				if child is StaticBody3D:
					already_has_collision = true
					break
			
			if not already_has_collision:
				var static_body = StaticBody3D.new()
				node.add_child(static_body)
				var collision_shape = CollisionShape3D.new()
				
				# Use solid convex hulls for props/furniture/vehicles to prevent player physics sticking.
				# Use trimesh concave shapes only for large static structural meshes (roads, walls, house shell).
				var use_convex = true
				var p = node
				while p:
					var p_name = p.name.to_lower()
					if "wall" in p_name or "yol" in p_name or "home" in p_name:
						if not "homey" in p_name:
							use_convex = false
							break
					p = p.get_parent()
					
				if use_convex:
					collision_shape.shape = node.mesh.create_convex_shape(true, false)
				else:
					collision_shape.shape = node.mesh.create_trimesh_shape()
					
				static_body.add_child(collision_shape)
				
	for child in node.get_children():
		var child_needs_collision = needs_collision or ("wall" in child.name.to_lower() or 
														 "volvo" in child.name.to_lower() or 
														 "yol" in child.name.to_lower() or 
														 "home" in child.name.to_lower() or 
														 "cooler" in child.name.to_lower() or
														 "caravan" in child.name.to_lower() or
														 "car2" in child.name.to_lower() or
														 "car3" in child.name.to_lower() or
														 "homey" in child.name.to_lower())
		process_node_branch(child, child_needs_collision, wall_mat)

func setup_player():
	var player_scene = load("res://Player.tscn")
	if player_scene:
		var player = player_scene.instantiate()
		player.position = Vector3(76.0, 0.5, -19.3)
		add_child(player)
		player_node = player
		
		# Explicitly activate player camera on startup
		var player_camera = player.get_node_or_null("CameraPivot/Camera3D")
		if player_camera:
			player_camera.make_current()

func setup_ps2_screen_shader():
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 2 # PS2 screen shader renders on top
	add_child(canvas_layer)
	
	var color_rect = ColorRect.new()
	color_rect.anchor_left = 0.0
	color_rect.anchor_top = 0.0
	color_rect.anchor_right = 1.0
	color_rect.anchor_bottom = 1.0
	color_rect.offset_left = 0
	color_rect.offset_top = 0
	color_rect.offset_right = 0
	color_rect.offset_bottom = 0
	color_rect.size = Vector2(640, 480)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(color_rect)
	
	var material = ShaderMaterial.new()
	var shader = load("res://ps2_screen_shader.gdshader")
	if shader:
		material.shader = shader
		color_rect.material = material
		ps2_material = material
		
		# Pass the MaskViewport texture to the screen shader to exclude the Volvo
		if mask_viewport:
			material.set_shader_parameter("mask_texture", mask_viewport.get_texture())

func setup_man_collision_and_animation():
	var man_node = find_node_by_name(self, "Man")
	if not man_node:
		man_node = find_node_by_name(self, "Character_Male")
		
	if not man_node:
		print("Warning: Man/Character_Male node not found in scene tree.")
		return
		
	var static_body = StaticBody3D.new()
	static_body.name = "CharacterMaleCollision"
	add_child(static_body)
	static_body.global_position = man_node.global_position
	
	var collision_shape = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.55
	capsule.height = 2.4
	collision_shape.shape = capsule
	collision_shape.position = Vector3(0, 1.2, 0)
	static_body.add_child(collision_shape)
	print("Man solid capsule collision successfully created globally at position: ", static_body.global_position)
	
	var anim_player2 = man_node.get_node_or_null("AnimationPlayer2") as AnimationPlayer
	if anim_player2:
		var anim_list = anim_player2.get_animation_list()
		if anim_list.size() > 0:
			var anim_name = anim_list[0]
			var anim = anim_player2.get_animation(anim_name)
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
			anim_player2.play(anim_name)
			print("Successfully playing assigned editor animation: ", anim_name)
		else:
			var anim_path = ""
			if FileAccess.file_exists("res://oldman.res"):
				anim_path = "res://oldman.res"
			elif FileAccess.file_exists("res://oldman.tres"):
				anim_path = "res://oldman.tres"
				
			if anim_path != "":
				var anim = load(anim_path) as Animation
				if anim:
					anim.loop_mode = Animation.LOOP_LINEAR
					var lib = AnimationLibrary.new()
					anim_player2.add_animation_library("custom", lib)
					lib.add_animation("oldman_loop", anim)
					anim_player2.play("custom/oldman_loop")
					print("Successfully loaded and playing custom animation file: ", anim_path)
				else:
					print("Error: Failed to load animation resource at: ", anim_path)
			else:
				print("Warning: AnimationPlayer2 is empty and no oldman.res/tres file was found.")
	else:
		print("Warning: AnimationPlayer2 node not found under Man.")

func setup_ambient_audio():
	# 1. Load and play night_sound.mp3 in loop
	var stream = load("res://night_sound.mp3")
	if stream:
		if "loop" in stream:
			stream.loop = true
		ambient_player = AudioStreamPlayer.new()
		ambient_player.name = "AmbientAudioPlayer"
		ambient_player.stream = stream
		ambient_player.bus = &"Music"
		add_child(ambient_player)
		ambient_player.play()
		print("Ambient audio 'night_sound.mp3' successfully started in loop.")
		
	# 2. Load and play rain_sound.mp3 in loop
	var rain_stream = load("res://rain_sound.mp3")
	if rain_stream:
		if "loop" in rain_stream:
			rain_stream.loop = true
		rain_player = AudioStreamPlayer.new()
		rain_player.name = "RainAudioPlayer"
		rain_player.stream = rain_stream
		rain_player.volume_db = -19.0 # Slightly increased from -25.0 for better atmospheric balance
		rain_player.bus = &"Music"
		add_child(rain_player)
		rain_player.play()
		print("Rain audio 'rain_sound.mp3' successfully started in loop at -19 dB.")
	else:
		print("Warning: Failed to load res://rain_sound.mp3.")
		
	# 3. Load and configure mumble.mp3 for character voices
	var mumble_stream = load("res://mumble.mp3")
	if mumble_stream:
		mumble_player = AudioStreamPlayer.new()
		mumble_player.name = "MumblePlayer"
		mumble_player.stream = mumble_stream
		mumble_player.volume_db = 4.0
		mumble_player.pitch_scale = 1.25
		mumble_player.bus = &"Voice"
		add_child(mumble_player)
		print("Mumble audio 'mumble.mp3' successfully loaded with speed and volume adjustments.")
		
	# 4. Generate and configure retro typewriter click sound player
	var click_stream = generate_click_stream()
	typewriter_sound_player = AudioStreamPlayer.new()
	typewriter_sound_player.name = "TypewriterSoundPlayer"
	typewriter_sound_player.stream = click_stream
	typewriter_sound_player.volume_db = -16.0
	typewriter_sound_player.bus = &"Voice"
	add_child(typewriter_sound_player)
	
	# 5. Load and configure notopen.mp3
	var notopen_stream = load("res://notopen.mp3")
	if notopen_stream:
		notopen_player = AudioStreamPlayer.new()
		notopen_player.name = "NotOpenPlayer"
		notopen_player.stream = notopen_stream
		if "loop" in notopen_stream:
			notopen_stream.loop = false
		notopen_player.volume_db = -5.0
		notopen_player.bus = &"SFX"
		add_child(notopen_player)
		print("NotOpen audio 'notopen.mp3' successfully loaded.")
		
	# 6. Generate and configure procedural keyboard click sound player
	var kb_stream = generate_keyboard_click_stream()
	keyboard_click_player = AudioStreamPlayer.new()
	keyboard_click_player.name = "KeyboardClickPlayer"
	keyboard_click_player.stream = kb_stream
	keyboard_click_player.volume_db = -12.0
	keyboard_click_player.bus = &"SFX"
	add_child(keyboard_click_player)
	print("Procedural keyboard click audio player successfully loaded.")
	
	# 7. Generate and configure computer hum player
	comp_hum_player = AudioStreamPlayer.new()
	comp_hum_player.name = "CompHumPlayer"
	comp_hum_player.stream = generate_comp_hum_stream()
	comp_hum_player.volume_db = -20.0
	comp_hum_player.bus = &"SFX"
	add_child(comp_hum_player)
	comp_hum_player.play()
	print("Procedural computer hum player successfully started.")

func setup_volvo_mask_viewport():
	# Create SubViewport
	mask_viewport = SubViewport.new()
	mask_viewport.name = "MaskViewport"
	mask_viewport.size = Vector2i(640, 480) # Match 640x480 project viewport resolution
	mask_viewport.transparent_bg = true
	mask_viewport.handle_input_locally = false
	mask_viewport.gui_disable_input = true
	add_child(mask_viewport)
	
	# Create Camera3D inside SubViewport
	mask_camera = Camera3D.new()
	mask_camera.name = "Camera3D"
	mask_camera.cull_mask = 2 # Only render VisualInstance3Ds on Layer 2 (Volvo meshes)
	mask_camera.fov = 75.0   # Match standard FOV
	mask_viewport.add_child(mask_camera)
	
	# Assign Volvo model meshes to Layer 2 recursively
	var volvo = find_node_by_name(self, "volvo")
	if volvo:
		set_layer_recursively(volvo, 2)
		print("Volvo meshes recursively assigned to Layer 2 for post-processing mask.")
	else:
		print("Warning: Volvo node not found, cannot assign mask layers.")

func set_layer_recursively(node: Node, layer_bit: int):
	if node is VisualInstance3D:
		if "wall" in node.name.to_lower():
			node.layers = 1 # Keep walls on Layer 1 so they are affected by the screen shader
		else:
			node.layers = layer_bit
	for child in node.get_children():
		set_layer_recursively(child, layer_bit)

func find_node_by_name(root: Node, target_name: String) -> Node:
	if root.name == target_name:
		return root
	for child in root.get_children():
		var found = find_node_by_name(child, target_name)
		if found:
			return found
	return null

func setup_ui():
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 1 # Under the PS2 shader
	add_child(ui_layer)
	
	# 1. Interact Prompt Label
	interact_prompt = Label.new()
	interact_prompt.name = "InteractPrompt"
	interact_prompt.text = "Interact by pressing the E key"
	interact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var prompt_font = LabelSettings.new()
	prompt_font.font_size = 18
	prompt_font.font_color = Color(0.9, 0.9, 0.9)
	prompt_font.outline_size = 4
	prompt_font.outline_color = Color(0, 0, 0)
	interact_prompt.label_settings = prompt_font
	
	interact_prompt.custom_minimum_size = Vector2(640, 40)
	interact_prompt.size = Vector2(640, 40)
	interact_prompt.position = Vector2(0, 420)
	interact_prompt.visible = false
	ui_layer.add_child(interact_prompt)
	
	# 2. Dialogue Panel
	dialogue_panel = Panel.new()
	dialogue_panel.name = "DialoguePanel"
	dialogue_panel.visible = false
	dialogue_panel.size = Vector2(580, 100)
	dialogue_panel.position = Vector2(30, 350)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.08, 0.85) # Retro semi-transparent dark charcoal blue
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.7, 0.75, 0.8) # Silver-blue frame
	style.corner_detail = 1
	dialogue_panel.add_theme_stylebox_override("panel", style)
	ui_layer.add_child(dialogue_panel)
	
	# 3. Dialogue Label
	dialogue_label = Label.new()
	dialogue_label.name = "DialogueLabel"
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	var diag_font = LabelSettings.new()
	diag_font.font_size = 16
	diag_font.font_color = Color(1, 1, 1)
	diag_font.outline_size = 3
	diag_font.outline_color = Color(0, 0, 0)
	dialogue_label.label_settings = diag_font
	
	dialogue_label.position = Vector2(15, 15)
	dialogue_label.size = Vector2(550, 70)
	dialogue_panel.add_child(dialogue_label)
	
	# 3b. Dialogue RichTextLabel for Links
	rich_text_label = RichTextLabel.new()
	rich_text_label.name = "DialogueRichText"
	rich_text_label.bbcode_enabled = true
	rich_text_label.visible = false
	rich_text_label.custom_minimum_size = Vector2(550, 70)
	rich_text_label.size = Vector2(550, 70)
	rich_text_label.position = Vector2(15, 15)
	rich_text_label.add_theme_font_size_override("normal_font_size", 16)
	rich_text_label.add_theme_font_size_override("bold_font_size", 16)
	rich_text_label.meta_clicked.connect(self._on_meta_clicked)
	dialogue_panel.add_child(rich_text_label)

	# 4. Fade Overlay for Teleportation
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 3 # On top of everything
	add_child(fade_layer)
	
	fade_rect = ColorRect.new()
	fade_rect.name = "FadeOverlay"
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.anchor_left = 0.0
	fade_rect.anchor_top = 0.0
	fade_rect.anchor_right = 1.0
	fade_rect.anchor_bottom = 1.0
	fade_rect.offset_left = 0
	fade_rect.offset_top = 0
	fade_rect.offset_right = 0
	fade_rect.offset_bottom = 0
	fade_rect.size = Vector2(640, 480)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade_rect)
	
	# 5. Warning Label (Climax jumpscare text)
	warning_label = Label.new()
	warning_label.name = "WarningLabel"
	warning_label.text = ""
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var warning_font = LabelSettings.new()
	warning_font.font_size = 28
	warning_font.font_color = Color(0.8, 0.0, 0.0) # Blood red
	warning_font.outline_size = 6
	warning_font.outline_color = Color(0, 0, 0)
	warning_label.label_settings = warning_font
	
	warning_label.custom_minimum_size = Vector2(640, 60)
	warning_label.size = Vector2(640, 60)
	warning_label.position = Vector2(0, 210) # Centered vertically
	warning_label.visible = false
	ui_layer.add_child(warning_label)


func _on_meta_clicked(meta):
	var url = str(meta)
	print("Link clicked: ", url)
	if url == "close":
		end_interaction()
		return
		
	if OS.has_feature("web"):
		if Engine.has_singleton("JavaScriptBridge"):
			var js_bridge = Engine.get_singleton("JavaScriptBridge")
			js_bridge.eval("window.open('" + url + "', '_blank');")
	else:
		var err = OS.shell_open(url)
		if err != OK:
			print("OS.shell_open failed with error code: ", err, ". Attempting OS.execute fallback...")
			var output = []
			var exec_err = OS.execute("open", [url], output)
			if exec_err != OK:
				print("OS.execute fallback failed with error code: ", exec_err)
			else:
				print("OS.execute fallback command successfully executed. Output: ", output)
		else:
			print("OS.shell_open reported success.")





func _physics_process(delta):
	# Distance checking combined with RayCast to target
	if is_interacting or fade_state != 0:
		return
		
	if is_escape_prompt_active:
		return
		
	var is_looking_at_man = false
	var is_looking_at_door = false
	var is_looking_at_vent = false
	var is_looking_at_comp = false
	var is_looking_at_paint = false
	var is_looking_at_wolf = false
	var is_looking_at_table2 = false
	var is_looking_at_poster = false
	
	var paint_node = find_node_by_name(self, "Paint_12")
	var paint_collider = paint_node.get_node_or_null("StaticBody3D") if paint_node else null
	var wolf_node = find_node_by_name(self, "wolf")
	var wolf_collider = wolf_node.get_node_or_null("StaticBody3D") if wolf_node else null
	var table2_node = find_node_by_name(self, "table2")
	var table2_collider = table2_node.get_node_or_null("StaticBody3D") if table2_node else null
	var poster_collider = get_node_or_null("homey/MeshInstance3D/StaticBody3D")
	
	if player_node and is_instance_valid(player_node):
		var player_cam = player_node.get_node_or_null("CameraPivot/Camera3D")
		if player_cam:
			var space_state = get_world_3d().direct_space_state
			var from = player_cam.global_position
			var to = from - player_cam.global_transform.basis.z * 6.0 # Max distance 6.0 meters
			var query = PhysicsRayQueryParameters3D.create(from, to)
			
			# Exclude player self to avoid hitting self capsule
			query.exclude = [player_node.get_rid()]
			
			var result = space_state.intersect_ray(query)
			if result and result.collider:
				if "charactermalecollision" in result.collider.name.to_lower():
					is_looking_at_man = true
				elif not is_inside_house and first_conversation_done and result.collider == get_node_or_null("home/StaticBody3D"):
					is_looking_at_door = true
				elif not is_inside_house and first_conversation_done and result.collider == get_node_or_null("home/StaticBody3D2"):
					is_looking_at_vent = true
				elif is_inside_house and result.collider == get_node_or_null("homey/comp/StaticBody3D"):
					is_looking_at_comp = true
				elif is_inside_house and paint_collider and result.collider == paint_collider:
					is_looking_at_paint = true
				elif is_inside_house and wolf_collider and result.collider == wolf_collider:
					is_looking_at_wolf = true
				elif is_inside_house and table2_collider and result.collider == table2_collider:
					is_looking_at_table2 = true
				elif is_inside_house and poster_collider and result.collider == poster_collider:
					is_looking_at_poster = true
				
	if is_looking_at_man:
		door_e_pressed = false
		vent_e_pressed = false
		if interact_prompt:
			interact_prompt.visible = true
		if Input.is_key_pressed(KEY_E):
			start_interaction()
	elif is_looking_at_door:
		vent_e_pressed = false
		if interact_prompt:
			interact_prompt.visible = true
			
		var e_pressed = Input.is_key_pressed(KEY_E)
		if e_pressed:
			if not door_e_pressed:
				door_e_pressed = true
				play_door_not_open_sound()
		else:
			door_e_pressed = false
	elif is_looking_at_vent:
		door_e_pressed = false
		if interact_prompt:
			interact_prompt.visible = true
			
		var e_pressed = Input.is_key_pressed(KEY_E)
		if e_pressed:
			if not vent_e_pressed:
				vent_e_pressed = true
				start_teleportation()
		else:
			vent_e_pressed = false
	elif is_looking_at_comp:
		door_e_pressed = false
		vent_e_pressed = false
		if interact_prompt:
			interact_prompt.visible = true
		if Input.is_key_pressed(KEY_E):
			start_comp_interaction()
	elif is_looking_at_paint:
		door_e_pressed = false
		vent_e_pressed = false
		if interact_prompt:
			interact_prompt.visible = true
		if Input.is_key_pressed(KEY_E):
			start_paint_interaction()
	elif is_looking_at_wolf:
		door_e_pressed = false
		vent_e_pressed = false
		if interact_prompt:
			interact_prompt.visible = true
		if Input.is_key_pressed(KEY_E):
			start_wolf_interaction()
	elif is_looking_at_table2:
		door_e_pressed = false
		vent_e_pressed = false
		if interact_prompt:
			interact_prompt.visible = true
		if Input.is_key_pressed(KEY_E):
			start_table2_interaction()
	elif is_looking_at_poster:
		door_e_pressed = false
		vent_e_pressed = false
		if interact_prompt:
			interact_prompt.visible = true
		if Input.is_key_pressed(KEY_E):
			start_poster_interaction()
	else:
		door_e_pressed = false
		vent_e_pressed = false
		if interact_prompt:
			interact_prompt.visible = false


func _process(delta):
	# Sync mask camera with the active viewport camera in real-time
	var vp = get_viewport()
	if vp:
		var active_cam = vp.get_camera_3d()
		if active_cam and mask_camera and is_instance_valid(mask_camera):
			mask_camera.global_transform = active_cam.global_transform
			mask_camera.fov = active_cam.fov
			mask_camera.near = active_cam.near
			mask_camera.far = active_cam.far

	# Dialogue cooldown decay
	if dialogue_cooldown > 0.0:
		dialogue_cooldown -= delta
		
	# Typewriter text flow progression
	if typewriter_active:
		typewriter_timer += delta
		if typewriter_timer >= typewriter_speed:
			typewriter_timer = 0.0
			typewriter_char_idx += 1
			if dialogue_label:
				dialogue_label.text = typewriter_text.left(typewriter_char_idx)
			
			# Play click sound
			play_typewriter_sound()
			
			if typewriter_char_idx >= typewriter_text.length():
				typewriter_active = false
				if mumble_player and not is_comp_interacting and not is_paint_interacting and not is_wolf_interacting:
					mumble_player.stream_paused = true
					
	# Handle screen fade transitions
	if fade_state == 1: # Fading out (going to black)
		fade_alpha = min(fade_alpha + delta * 1.5, 1.0)
		if fade_rect:
			fade_rect.color = Color(0, 0, 0, fade_alpha)
		if fade_alpha >= 1.0:
			fade_state = 2
			fade_timer = 1.0 # 1 second of holding black
	elif fade_state == 2: # Holding black
		fade_timer -= delta
		if fade_timer <= 0.0:
			teleport_player_to_house()
			fade_state = 3
	elif fade_state == 3: # Fading in (returning to clear)
		fade_alpha = max(fade_alpha - delta * 1.5, 0.0)
		if fade_rect:
			fade_rect.color = Color(0, 0, 0, fade_alpha)
		if fade_alpha <= 0.0:
			fade_state = 0 # back to idle
			if player_node and is_instance_valid(player_node):
				player_node.is_interacting = false

func start_interaction():
	is_interacting = true
	if interact_prompt:
		interact_prompt.visible = false
	
	# Switch camera to Interact1
	if interact_camera:
		interact_camera.make_current()
		
	# Freeze player
	if player_node:
		player_node.is_interacting = true
		player_node.velocity = Vector3.ZERO
		
	# Start dialogue typewriter flow
	current_line_idx = 0
	var lines = dialogue_lines_2 if first_conversation_done else dialogue_lines
	start_typewriter(lines[current_line_idx])
	
	if dialogue_panel:
		dialogue_panel.visible = true
		
	# Release mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func start_typewriter(text: String):
	typewriter_text = text
	typewriter_char_idx = 0
	typewriter_timer = 0.0
	typewriter_active = true
	if dialogue_label:
		dialogue_label.text = ""
		var is_spoken = not is_comp_interacting and not is_paint_interacting and not is_wolf_interacting and not is_table2_interacting and not is_poster_interacting
		dialogue_label.visible = subtitles_enabled if is_spoken else true
	if rich_text_label:
		rich_text_label.visible = false
		
	if is_table2_interacting or is_poster_interacting:
		dialogue_cooldown = 1.0
		
	if mumble_player and not is_comp_interacting and not is_paint_interacting and not is_wolf_interacting and not is_table2_interacting and not is_poster_interacting:
		mumble_player.stream_paused = false
		if not mumble_player.playing:
			mumble_player.play()


func advance_dialogue():
	if dialogue_cooldown > 0.0:
		return
		
	if is_table2_interacting or is_poster_interacting:
		dialogue_cooldown = 1.0
	else:
		dialogue_cooldown = 0.5 # 0.5 seconds cooldown
	
	var lines = poster_dialogue_lines if is_poster_interacting else (table2_dialogue_lines if is_table2_interacting else (wolf_dialogue_lines if is_wolf_interacting else (paint_dialogue_lines if is_paint_interacting else (comp_dialogue_lines if is_comp_interacting else (dialogue_lines_2 if first_conversation_done else dialogue_lines)))))
	
	if typewriter_active:
		# Fast-forward: instantly reveal whole line
		typewriter_active = false
		if dialogue_label:
			dialogue_label.text = typewriter_text
		if mumble_player and not is_comp_interacting and not is_paint_interacting and not is_wolf_interacting and not is_table2_interacting and not is_poster_interacting:
			mumble_player.stream_paused = true
	else:
		# Move to next line
		current_line_idx += 1
		if current_line_idx < lines.size():
			start_typewriter(lines[current_line_idx])
		elif is_table2_interacting and current_line_idx == lines.size():
			if dialogue_label:
				dialogue_label.visible = false
			if rich_text_label:
				rich_text_label.text = table2_links_bbcode
				rich_text_label.visible = true
			current_line_idx += 1
			dialogue_cooldown = 1.0
		elif is_poster_interacting and current_line_idx == lines.size():
			if dialogue_label:
				dialogue_label.visible = false
			if rich_text_label:
				rich_text_label.text = poster_links_bbcode
				rich_text_label.visible = true
			current_line_idx += 1
			dialogue_cooldown = 1.0
		else:
			end_interaction()



func end_interaction():
	is_interacting = false
	typewriter_active = false
	if dialogue_panel:
		dialogue_panel.visible = false
	if interact_prompt:
		interact_prompt.visible = false
		
	if rich_text_label:
		rich_text_label.visible = false
	if dialogue_label:
		dialogue_label.visible = true
		
	if mumble_player:
		mumble_player.stop()
		
	if comp_hum_player:
		comp_hum_player.stop()
	
	# Switch camera back to player camera
	if is_comp_interacting:
		end_camera_transition(0.8)
		is_comp_interacting = false
	elif is_paint_interacting:
		end_camera_transition(0.8)
		is_paint_interacting = false
	elif is_wolf_interacting:
		end_camera_transition(0.8)
		is_wolf_interacting = false
	elif is_table2_interacting:
		end_camera_transition(0.8)
		is_table2_interacting = false
	elif is_poster_interacting:
		end_camera_transition(0.8)
		is_poster_interacting = false
	else:
		if player_node:
			player_node.is_interacting = false
			var player_camera = player_node.get_node_or_null("CameraPivot/Camera3D")
			if player_camera:
				player_camera.make_current()
			
	# Re-capture mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	
	if not first_conversation_done:
		first_conversation_done = true
		print("First conversation finished. Door is now interactable.")

	if interacted_cv_items.size() == 5 and not climax_triggered:
		climax_triggered = true
		print("5 unique CV items interacted! Triggering climax sequence in 0.85 seconds...")
		var trigger_timer = get_tree().create_timer(0.85)
		trigger_timer.timeout.connect(func():
			start_climax_sequence()
		)

func generate_click_stream() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 11025
	stream.stereo = false
	
	var length = 300 # short blip
	var bytes = PackedByteArray()
	bytes.resize(length)
	for i in range(length):
		var decay = 1.0 - (float(i) / float(length))
		# Sine wave click: 1200Hz wave decaying over time
		var angle = float(i) * 0.8
		var sample = int(sin(angle) * 127.0 * decay)
		bytes[i] = sample
		
	stream.data = bytes
	return stream

func play_typewriter_sound():
	# Typewriter sound disabled per user request for old man and photograph, but active for computer
	if is_comp_interacting and keyboard_click_player:
		keyboard_click_player.play()

func play_door_not_open_sound():
	if notopen_player and is_instance_valid(notopen_player):
		notopen_player.play()

func start_teleportation():
	fade_state = 1
	fade_alpha = 0.0
	if interact_prompt:
		interact_prompt.visible = false
	if player_node and is_instance_valid(player_node):
		player_node.is_interacting = true
		player_node.velocity = Vector3.ZERO
	print("Teleportation started. Screen fading to black...")

func teleport_player_to_house():
	is_inside_house = true
	
	# Teleport player
	if player_node and is_instance_valid(player_node):
		player_node.global_position = Vector3(-4.9, 0.5, -23.0)
		print("Player successfully teleported to house interior at global position: ", player_node.global_position)
		
		# Stop rain particles
		var rain_particles = player_node.get_node_or_null("RainParticles")
		if rain_particles:
			rain_particles.visible = false
			if "emitting" in rain_particles:
				rain_particles.emitting = false
			print("RainParticles disabled inside house.")
		
	# Stop/mute outside sounds
	if ambient_player and is_instance_valid(ambient_player):
		ambient_player.stop()
	if rain_player and is_instance_valid(rain_player):
		rain_player.stop()
	print("Outside weather and night audio stopped.")

func start_paint_interaction():
	var paint = find_node_by_name(self, "Paint_12")
	var col = paint.get_node_or_null("StaticBody3D") if paint else null
	register_cv_item(col)

	is_interacting = true
	is_paint_interacting = true
	if interact_prompt:
		interact_prompt.visible = false
		
	# Setup Interact3 camera dynamically if needed
	if not interact3_camera:
		paint = find_node_by_name(self, "Paint_12")
		if paint:
			interact3_camera = Camera3D.new()
			interact3_camera.name = "Interact3"
			add_child(interact3_camera)
			
			# Position 1.2m offset in front of painting
			var paint_global_pos = paint.global_position
			var offset = paint.global_transform.basis.z * 1.2
			interact3_camera.global_position = paint_global_pos + offset
			interact3_camera.look_at(paint_global_pos)
			print("Interact3 camera dynamically created in front of Paint_12.")
			
	# Switch camera to Interact3 using smooth tween transition
	if interact3_camera:
		start_camera_transition(interact3_camera, 0.8)
		
	# Freeze player
	if player_node:
		player_node.is_interacting = true
		player_node.velocity = Vector3.ZERO
		
	# Start dialogue typewriter flow
	current_line_idx = 0
	start_typewriter(paint_dialogue_lines[current_line_idx])
	
	if dialogue_panel:
		dialogue_panel.visible = true
		
	# Release mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func start_comp_interaction():
	var col = get_node_or_null("homey/comp/StaticBody3D")
	register_cv_item(col)

	is_interacting = true
	is_comp_interacting = true
	if interact_prompt:
		interact_prompt.visible = false
		
	# Switch camera to Interact2 using smooth tween transition
	if interact2_camera:
		start_camera_transition(interact2_camera, 0.8)
		
	# Freeze player
	if player_node:
		player_node.is_interacting = true
		player_node.velocity = Vector3.ZERO
		
	# Start dialogue typewriter flow
	current_line_idx = 0
	start_typewriter(comp_dialogue_lines[current_line_idx])
	
	if dialogue_panel:
		dialogue_panel.visible = true
		
	# Play computer background hum
	if comp_hum_player:
		comp_hum_player.play()
		
	# Release mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func start_camera_transition(target_camera: Camera3D, duration: float):
	if transition_cam:
		transition_cam.queue_free()
		
	var vp = get_viewport()
	var current_cam = vp.get_camera_3d() if vp else null
	if not current_cam or not target_camera:
		return
		
	transition_cam = Camera3D.new()
	transition_cam.name = "TransitionCamera"
	add_child(transition_cam)
	
	transition_cam.global_position = current_cam.global_position
	transition_cam.quaternion = current_cam.global_transform.basis.get_rotation_quaternion()
	transition_cam.fov = current_cam.fov
	transition_cam.make_current()
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(transition_cam, "global_position", target_camera.global_position, duration)
	tween.tween_property(transition_cam, "quaternion", target_camera.global_transform.basis.get_rotation_quaternion(), duration)
	tween.tween_property(transition_cam, "fov", target_camera.fov, duration)

func end_camera_transition(duration: float):
	if not transition_cam or not player_node:
		return
		
	var player_cam = player_node.get_node_or_null("CameraPivot/Camera3D") as Camera3D
	if not player_cam:
		return
		
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(transition_cam, "global_position", player_cam.global_position, duration)
	tween.tween_property(transition_cam, "quaternion", player_cam.global_transform.basis.get_rotation_quaternion(), duration)
	tween.tween_property(transition_cam, "fov", player_cam.fov, duration)
	
	# Once finished, make player camera current and cleanup
	tween.chain().set_parallel(false)
	tween.tween_callback(func():
		if player_cam and is_instance_valid(player_cam):
			player_cam.make_current()
		if transition_cam and is_instance_valid(transition_cam):
			transition_cam.queue_free()
			transition_cam = null
		if player_node and is_instance_valid(player_node):
			player_node.is_interacting = false
	)

func generate_keyboard_click_stream() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	
	var length = 1200 # ~50ms
	var bytes = PackedByteArray()
	bytes.resize(length)
	for i in range(length):
		var t = float(i) / float(length)
		var decay = exp(-t * 8.0) # fast decay
		
		# Noise burst mixed with sine resonant blip
		var noise = ((randi() % 256) - 128) * 0.4
		var sine = sin(float(i) * 0.25) * 127.0 * 0.6
		
		var sample = int((noise + sine) * decay)
		sample = clamp(sample, -128, 127)
		bytes[i] = sample
		
	stream.data = bytes
	return stream

func generate_comp_hum_stream() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 11025
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
	var length = 22050 # 2 seconds of hum/crackle
	stream.loop_end = length
	var bytes = PackedByteArray()
	bytes.resize(length)
	
	for i in range(length):
		# 60Hz mains hum + 120Hz harmonics
		var angle_60 = float(i) * 0.034
		var angle_120 = float(i) * 0.068
		var hum = sin(angle_60) * 15.0 + sin(angle_120) * 8.0
		
		# CPU Seek Seek crackling blips
		var crackle = 0.0
		if randf() < 0.0006:
			crackle = ((randi() % 256) - 128) * 0.6
			
		var sample = int(hum + crackle)
		sample = clamp(sample, -128, 127)
		bytes[i] = sample
		
	stream.data = bytes
	return stream

func start_wolf_interaction():
	var wolf = find_node_by_name(self, "wolf")
	var col = wolf.get_node_or_null("StaticBody3D") if wolf else null
	register_cv_item(col)

	is_interacting = true
	is_wolf_interacting = true
	if interact_prompt:
		interact_prompt.visible = false
		
	# Switch camera to Interact4 using smooth tween transition
	if interact4_camera:
		start_camera_transition(interact4_camera, 0.8)
		
	# Freeze player
	if player_node:
		player_node.is_interacting = true
		player_node.velocity = Vector3.ZERO
		
	# Start dialogue typewriter flow
	current_line_idx = 0
	start_typewriter(wolf_dialogue_lines[current_line_idx])
	
	if dialogue_panel:
		dialogue_panel.visible = true
		
	# Release mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func start_table2_interaction():
	var table2 = find_node_by_name(self, "table2")
	var col = table2.get_node_or_null("StaticBody3D") if table2 else null
	register_cv_item(col)

	is_interacting = true
	is_table2_interacting = true
	if interact_prompt:
		interact_prompt.visible = false
		
	# Switch camera to Interact5 using smooth tween transition
	if interact5_camera:
		start_camera_transition(interact5_camera, 0.8)
		
	# Freeze player
	if player_node:
		player_node.is_interacting = true
		player_node.velocity = Vector3.ZERO
		
	# Start dialogue typewriter flow
	current_line_idx = 0
	start_typewriter(table2_dialogue_lines[current_line_idx])
	
	if dialogue_panel:
		dialogue_panel.visible = true
		
	# Release mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func start_poster_interaction():
	var col = get_node_or_null("homey/MeshInstance3D/StaticBody3D")
	register_cv_item(col)

	is_interacting = true
	is_poster_interacting = true
	if interact_prompt:
		interact_prompt.visible = false
		
	# Switch camera to Interact6 using smooth tween transition
	if interact6_camera:
		start_camera_transition(interact6_camera, 0.8)
		
	# Freeze player
	if player_node:
		player_node.is_interacting = true
		player_node.velocity = Vector3.ZERO
		
	# Start dialogue typewriter flow
	current_line_idx = 0
	start_typewriter(poster_dialogue_lines[current_line_idx])
	
	if dialogue_panel:
		dialogue_panel.visible = true
		
	# Release mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func register_cv_item(item_node: Node):
	if item_node and item_node.is_in_group("cv_item"):
		if not interacted_cv_items.has(item_node):
			interacted_cv_items.append(item_node)
			var debug_name = item_node.get_parent().name if item_node.get_parent() else item_node.name
			print("CV item registered: ", debug_name, " (Total: ", interacted_cv_items.size(), "/5)")

func start_climax_sequence():
	print("Climax sequence initiated.")
	
	# Stop active interaction and dialogue
	end_interaction()
	
	# Freeze player and set state
	is_interacting = true
	if player_node:
		player_node.is_interacting = true
		player_node.velocity = Vector3.ZERO
		
	# 1. Kararma (Fade to black)
	var tween = create_tween()
	if fade_rect:
		tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1.0), 2.0)
	if heartbeat_sfx:
		var stream = heartbeat_sfx.stream
		if stream and "loop" in stream:
			stream.loop = true
		heartbeat_sfx.play()
	await tween.finished
	
	# 2. Yer Değiştirme ve Kamera (Cut)
	var player_escape = get_node_or_null("PlayerEscapePoint")
	var enemy_spawn = get_node_or_null("EnemySpawnPoint")
	var cinematic_cam1 = get_node_or_null("CinematicCam1")
	var enemy_node = get_node_or_null("enemy")
	
	if player_node and player_escape:
		player_node.global_position = player_escape.global_position
		var player_cam = player_node.get_node_or_null("CameraPivot/Camera3D")
		if player_cam:
			player_cam.current = false
			
	if cinematic_cam1:
		cinematic_cam1.current = true
		
	if enemy_node:
		enemy_node.visible = true
		
	# 3. Aydınlanma (Fade in)
	var tween_in = create_tween()
	if fade_rect:
		tween_in.tween_property(fade_rect, "color", Color(0, 0, 0, 0.0), 1.0)
	await tween_in.finished
	
	# 4. Animasyonlar
	var anim_player = enemy_node.get_node_or_null("AnimationPlayer") if enemy_node else null
	# Fallback: search recursively if not found directly
	if not anim_player and enemy_node:
		for child in enemy_node.get_children():
			if child is AnimationPlayer:
				anim_player = child
				break
			for subchild in child.get_children():
				if subchild is AnimationPlayer:
					anim_player = subchild
					break
					
	if anim_player:
		anim_player.play("Start")
	if scratch_sfx:
		scratch_sfx.play()
		
	await get_tree().create_timer(5.0).timeout
	
	if anim_player:
		anim_player.play("Idle")
		
	await get_tree().create_timer(6.8).timeout
	
	# 5. Hareket 1
	var start_y = enemy_node.global_position.y if enemy_node else 1.3
	var enemy_dest1 = get_node_or_null("EnemyDestination1")
	var move_speed = 3.5 # speed in m/s
	var duration1 = 3.0
	var target_pos1 = Vector3.ZERO
	if enemy_node and enemy_dest1:
		target_pos1 = enemy_dest1.global_position
		target_pos1.y = start_y
		
		# Align rotation to face destination 1
		if enemy_node.global_position.distance_to(target_pos1) > 0.01:
			enemy_node.look_at(target_pos1, Vector3.UP)
			enemy_node.rotate_object_local(Vector3.UP, PI)
			enemy_node.rotation.x = 0.0
			enemy_node.rotation.z = 0.0
			
		var distance = enemy_node.global_position.distance_to(target_pos1)
		duration1 = distance / move_speed
		print("Climax Move 1 info: distance=", distance, " duration1=", duration1, " start_pos=", enemy_node.global_position, " target_pos1=", target_pos1)
		
	if anim_player:
		anim_player.play("Move")
	if walkey_sfx:
		var stream = walkey_sfx.stream
		if stream and "loop" in stream:
			stream.loop = true
		walkey_sfx.play()
		
	var tween_move1 = create_tween()
	if enemy_node and enemy_dest1:
		tween_move1.tween_property(enemy_node, "global_position", target_pos1, duration1)
	await tween_move1.finished
	
	# 6. Kamera Geçişi (Cut) ve Hareket 2
	var cinematic_cam2 = get_node_or_null("CinematicCam2")
	var enemy_dest2 = get_node_or_null("EnemyDestination2")
	
	if cinematic_cam1:
		cinematic_cam1.current = false
	if cinematic_cam2:
		cinematic_cam2.current = true
		
	var duration2 = 3.0
	var target_pos2 = Vector3.ZERO
	if enemy_node and enemy_dest2:
		target_pos2 = enemy_dest2.global_position
		target_pos2.y = start_y
		
		# Align rotation to face destination 2
		if enemy_node.global_position.distance_to(target_pos2) > 0.01:
			enemy_node.look_at(target_pos2, Vector3.UP)
			enemy_node.rotate_object_local(Vector3.UP, PI)
			enemy_node.rotation.x = 0.0
			enemy_node.rotation.z = 0.0
			
		var distance = enemy_node.global_position.distance_to(target_pos2)
		duration2 = distance / move_speed
		print("Climax Move 2 info: distance=", distance, " duration2=", duration2, " start_pos=", enemy_node.global_position, " target_pos2=", target_pos2)
		
	if anim_player:
		anim_player.play("Move") # Explicitly play Move again to ensure it remains active
		
	var tween_move2 = create_tween()
	if enemy_node and enemy_dest2:
		tween_move2.tween_property(enemy_node, "global_position", target_pos2, duration2)
	await tween_move2.finished
	
	# 7. Kovalamacanın Başlaması
	if walkey_sfx:
		walkey_sfx.stop()
	if heartbeat_sfx:
		heartbeat_sfx.stop()
		
	if cinematic_cam2:
		cinematic_cam2.current = false
	if player_node:
		var player_cam = player_node.get_node_or_null("CameraPivot/Camera3D")
		if player_cam:
			player_cam.current = true
		player_node.is_interacting = false
		
	if warning_label:
		warning_label.text = chase_warning_text
		warning_label.visible = true
		
	if horror_sfx:
		horror_sfx.play()
		
	is_interacting = false
	is_chase_active = true
	print("Chase is active!")

func trigger_game_over():
	is_chase_active = false
	if player_node:
		player_node.is_interacting = true # Freeze player movement
		player_node.velocity = Vector3.ZERO
	if walkey_sfx:
		walkey_sfx.stop()
	if heartbeat_sfx:
		heartbeat_sfx.stop()
		
	print("Game Over triggered. Fading to black...")
	var tween = create_tween()
	if fade_rect:
		tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1.0), 1.5)
	await tween.finished
	
	get_tree().quit()

func print_node_hierarchy(node: Node, indent: String = ""):
	var vis = node.visible if "visible" in node else true
	var scale_val = node.scale if "scale" in node else Vector3.ONE
	var pos = node.position if "position" in node else Vector3.ZERO
	print(indent, "- ", node.name, " (", node.get_class(), ") | vis:", vis, " | scale:", scale_val, " | pos:", pos)
	for child in node.get_children():
		print_node_hierarchy(child, indent + "  ")

func setup_audio_buses():
	ensure_bus_exists("Master")
	ensure_bus_exists("Music", "Master")
	ensure_bus_exists("SFX", "Master")
	ensure_bus_exists("Voice", "Master")

func ensure_bus_exists(bus_name: String, send_to: String = ""):
	var idx = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, bus_name)
	
	if send_to != "":
		var send_idx = AudioServer.get_bus_index(send_to)
		if send_idx != -1:
			AudioServer.set_bus_send(idx, send_to)

func apply_settings_from_config():
	setup_audio_buses()
	
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") != OK:
		print("No settings file found or failed to load. Using defaults.")
		return
	
	# Audio settings
	var volume_master = config.get_value("audio", "master", 1.0)
	var volume_music = config.get_value("audio", "music", 1.0)
	var volume_sfx = config.get_value("audio", "sfx", 1.0)
	var volume_voice = config.get_value("audio", "voice", 1.0)
	
	set_bus_volume("Master", volume_master)
	set_bus_volume("Music", volume_music)
	set_bus_volume("SFX", volume_sfx)
	set_bus_volume("Voice", volume_voice)
	
	# Video settings
	var fullscreen = config.get_value("video", "fullscreen", false)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
	var resolution_idx = config.get_value("video", "resolution", 4) # Default 1920x1080
	var resolutions = [
		Vector2i(640, 480),
		Vector2i(800, 600),
		Vector2i(1024, 768),
		Vector2i(1280, 720),
		Vector2i(1920, 1080)
	]
	if resolution_idx >= 0 and resolution_idx < resolutions.size():
		var res = resolutions[resolution_idx]
		DisplayServer.window_set_size(res)
		if not fullscreen:
			var screen_id = DisplayServer.window_get_current_screen()
			var screen_size = DisplayServer.screen_get_size(screen_id)
			DisplayServer.window_set_position((screen_size - res) / 2)
			
	var shader_intensity = config.get_value("video", "shader_intensity", 1.0)
	if ps2_material:
		ps2_material.set_shader_parameter("shader_intensity", shader_intensity)
		
	# Accessibility settings
	var colorblind_mode = config.get_value("accessibility", "colorblind_mode", 0)
	if ps2_material:
		ps2_material.set_shader_parameter("colorblind_mode", colorblind_mode)
		
	subtitles_enabled = config.get_value("accessibility", "subtitles", true)

func set_bus_volume(bus_name: String, volume_linear: float):
	var idx = AudioServer.get_bus_index(bus_name)
	if idx != -1:
		var db = linear_to_db(volume_linear) if volume_linear > 0.0 else -80.0
		AudioServer.set_bus_volume_db(idx, db)

func apply_gameplay_localization():
	var config = ConfigFile.new()
	var locale = "en"
	if config.load("user://settings.cfg") == OK:
		locale = config.get_value("language", "locale", "en").to_lower()
	
	if not localization_data.has(locale):
		locale = "en"
		
	var data = localization_data[locale]
	dialogue_lines = data["dialogue_lines"]
	dialogue_lines_2 = data["dialogue_lines_2"]
	comp_dialogue_lines = data["comp_dialogue_lines"]
	paint_dialogue_lines = data["paint_dialogue_lines"]
	wolf_dialogue_lines = data["wolf_dialogue_lines"]
	table2_dialogue_lines = data["table2_dialogue_lines"]
	table2_links_bbcode = data["table2_links_bbcode"]
	poster_dialogue_lines = data["poster_dialogue_lines"]
	
	# Chase & Escape Ending localizations
	interact_car_text = data.get("interact_car", "Interact with E for get in the car!")
	chase_warning_text = data.get("chase_warning", "Run to car for your life!")
	escape_message_text = data.get("escape_message", "YOU MANAGED TO ESCAPE!")
	narrative_credit_text = data.get("narrative_credits", "")
	dev_log_slides = data.get("dev_log_slides", [])
	
	if interact_prompt:
		interact_prompt.text = data.get("interact_default", "Interact by pressing the E key")
		
	print("Gameplay localization applied for locale: ", locale)

var localization_data = {
	"en": {
		"dialogue_lines": [
			"Good heavens, you're soaked to the bone! Out in this storm... It's freezing out there.",
			"Forget about that piece of junk for now, son. The roads ahead are flooded... you're not going anywhere tonight.",
			"I could never let a guest of mine stay out in rain like this. Why, it would be a crime.",
			"Come now, step inside. The fire is roaring... Besides, we have so much to talk about."
		],
		"dialogue_lines_2": [
			"Ah, the front door is acting up again, is it? Confounded thing... Don't even bother looking for a key, it wouldn't do you any good anyway.",
			"I get locked out of my own home more often than I'd care to admit! Just poke around the back and find another way in. I'm sure you'll figure it out."
		],
		"comp_dialogue_lines": [
			"A glowing text document is left open on the screen...",
			"> Current project architecture: Godot.",
			"> Executing entirely via GDScript.",
			"> Note: JavaScript, TypeScript, and Python proficiencies available but unutilized in this instance.",
			"> Previous engine experiences (Unity, GameMaker, UE5) logged and archived."
		],
		"paint_dialogue_lines": [
			"You wipe a thin layer of dust off an old, framed photograph. Seven people are smiling in the picture.",
			"Project: subtracker.",
			"A dedicated team of seven, seamlessly led. The initiative dragged two local banks into its wake, and played a pivotal role in the exit of the project that followed.",
			"Beyond the flawless code (JavaScript, Node.js) and the great camaraderie, the true catalyst was its aggressive marketing strategy...",
			"...a strategy driven heavily by the founder, Adil Basri Erdem, and his background in International Trade and Finance."
		],
		"wolf_dialogue_lines": [
			"You examine a bizarre collection gathered in the corner: a carved wolf figurine, worn-out playing cards, and heavy metallic tokens.",
			"The archives of Team Husk. Five distinct IPs materialized over two relentless years of development.",
			"The cards belong to 'Soul's Gambit', a dark roguelike deckbuilder. The tokens? Pieces for 'Glad To Feed You!', a macabre game of horror checkers.",
			"Scattered geometric shapes hint at 'SPHENKS', a Tetris-like puzzle shifting between 2D and 3D dimensions...",
			"...while a small, pixelated sketch reveals 'Chick: Going to The Chicken Land', a deceptive story-driven platformer.",
			"Different genres, different mechanics. All crafted by the same hands."
		],
		"table2_dialogue_lines": [
			"You step closer to the desk. Under the dim light of the lamp, an investigation board dominates the wall.",
			"All the red strings and scattered notes connect to a single face in the center.",
			"Subject: Adil Basri ERDEM.",
			"A mastermind poised to pioneer a new era in the Turkish game industry. Especially in the realm of psychological horror.",
			"The dossier on the desk contains his direct contact protocols. The host's voice echoes in your mind: 'You should reach out to him... before it's too late.'"
		],
		"table2_links_bbcode": "[center]\n[url=https://www.linkedin.com/in/adil-basri-erdem-189941249/][color=#cc1111]ACCESS LINKEDIN ARCHIVE[/color][/url]\n\n[url=mailto:adilbasri06161@gmail.com][color=#cc1111]INITIATE DIRECT MAIL[/color][/url]\n\n[url=http://www.teamhusk.com.tr][color=#cc1111]INSPECT PORTFOLIO (TEAM HUSK)[/color][/url]\n\n[url=close][color=#777777]EXIT DOSSIER[/color][/url]\n[/center]",
		"poster_dialogue_lines": [
			"You stare at a large poster hanging exactly where an exit should have been.",
			"INTERRED.",
			"A macabre blend of chess-like tactics and rogue-lite horror.",
			"A playable demo is currently lurking on Steam. It is completely free to experience.",
			"This dark creation is kept alive and evolving solely through the support and feedback of its players. You should seriously consider supporting the team.",
			"If you enjoyed the twisted atmosphere of this little interactive CV... you will feel right at home with INTERRED."
		],
		"interact_default": "Interact by pressing the E key",
		"interact_car": "Interact with E for get in the car!",
		"chase_warning": "Run to car for your life!",
		"escape_message": "YOU MANAGED TO ESCAPE!",
		"narrative_credits": "Despite his relentless efforts and countless sleepless nights,\nAdil Basri ERDEM has yet to secure his rightful place in the gaming industry.\n\nThe developer is still running from the 'little men' chasing him through small-scale projects.\nHe is willing to endure grueling hours and modest compensation just to grasp something much greater.\n\nBut he is within your reach.\n\nTalent always finds a way to reveal itself.\nForged iron shines brightest in the dark; you will easily spot him among the crowd.\n\nI don't know what the future holds for Adil Basri ERDEM... but I know YOU.\nAnd you wouldn't want to miss a chance like this.\n\n\n[color=#a7f3d0]--- INITIATE CONTACT PROTOCOLS ---[/color]\n\n[url=https://www.linkedin.com/in/adil-basri-erdem-189941249/]ACCESS LINKEDIN ARCHIVE[/url]\n\n[url=http://www.teamhusk.com.tr]TEAM HUSK PORTFOLIO[/url]\n\n[url=mailto:adilbasri06161@gmail.com]DIRECT MAIL COMMUNICATION[/url]",
		"dev_log_slides": [
			"[center][wave amp=20 freq=3][shake rate=12 level=5][color=#a7f3d0]--- DEVELOPMENT LOG ---[/color][/shake][/wave][/center]",
			"[center]Creative Director & Game Designer\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Lead Programmer\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Narrative Writer\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]World Building & Level Design\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Voice Acting & Sound Design\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Atmosphere & Shader Engineering\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Enemy AI Architecture\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]QA Testing & Bug Survivor\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center][font_size=32][wave amp=30 freq=3][shake rate=20 level=8][color=#ef4444][i]THANKS TO YOU FOR PLAYING![/i][/color][/shake][/wave][/font_size][/center]"
		]
	},
	"tr": {
		"dialogue_lines": [
			"Aman tanrım, sırılsıklamsın! Bu fırtınada dışarısı... Dışarısı buz kesiyor.",
			"Şimdilik o hurdayı unut evlat. Önündeki yollar sular altında... Bu gece hiçbir yere gidemezsin.",
			"Bir misafirimi böyle bir yağmurda asla dışarıda bırakamam. Bu resmen bir suç olurdu.",
			"Hadi gel, içeri gir. Ateş gürül gürül yanıyor... Hem, konuşacak çok şeyimiz var."
		],
		"dialogue_lines_2": [
			"Ah, ön kapı yine oyun oynuyor demek? Lanet şey... Anahtar aramakla hiç uğraşma, zaten bir işe yaramaz.",
			"Kendi evimde kilitli kaldığım zamanlar itiraf etmek istediğimden çok daha fazladır! Arkadan dolanıp başka bir giriş bul. Eminim bir yolunu bulursun."
		],
		"comp_dialogue_lines": [
			"Ekranda parlayan bir metin belgesi açık bırakılmış...",
			"> Mevcut proje mimarisi: Godot.",
			"> Tamamen GDScript aracılığıyla yürütülüyor.",
			"> Not: JavaScript, TypeScript ve Python yetkinlikleri mevcut ancak bu örnekte kullanılmadı.",
			"> Önceki motor deneyimleri (Unity, GameMaker, UE5) günlüğe kaydedildi ve arşivlendi."
		],
		"paint_dialogue_lines": [
			"Eski, çerçeveli bir fotoğrafın üzerindeki ince toz tabakasını siliyorsun. Resimde yedi kişi gülümsüyor.",
			"Proje: subtracker.",
			"Kusursuz yönetilen yedi kişilik kararlı bir ekip. Girişim, iki yerel bankayı da peşinden sürükledi ve ardından gelen projenin çıkışında çok önemli bir rol oynadı.",
			"Kusursuz kodun (JavaScript, Node.js) ve harika dostluğun ötesinde, gerçek katalizör agresif pazarlama stratejisiydi...",
			"...kurucu Adil Basri Erdem ve onun Uluslararası Ticaret ve Finans geçmişi tarafından güçlü bir şekilde yönlendirilen bir strateji."
		],
		"wolf_dialogue_lines": [
			"Köşede toplanmış tuhaf bir koleksiyonu inceliyorsun: oyulmuş bir kurt heykelciği, yıpranmış oyun kartları ve ağır metal jetonlar.",
			"Team Husk arşivleri. İki amansız geliştirme yılı boyunca ortaya çıkan beş farklı fikri mülkiyet.",
			"Kartlar, karanlık bir roguelike deste oluşturma oyunu olan 'Soul's Gambit'e ait. Jetonlar mı? Korku daması oyunu olan 'Glad To Feed You!' parçaları.",
			"Dağınık geometrik şekiller, 2D ve 3D boyutlar arasında geçiş yapan Tetris benzeri bir bulmaca olan 'SPHENKS'e işaret ediyor...",
			"...küçük, pikselli bir eskiz ise aldatıcı hikaye odaklı platform oyunu 'Chick: Going to The Chicken Land'i ortaya çıkarıyor.",
			"Farklı türler, farklı mekanikler. Hepsi aynı ellerden çıktı."
		],
		"table2_dialogue_lines": [
			"Masaya doğru yaklaşıyorsun. Lambanın loş ışığı altında, duvarda bir soruşturma panosu duruyor.",
			"Tüm kırmızı ipler ve dağınık notlar merkezdeki tek bir yüze bağlanıyor.",
			"Konu: Adil Basri ERDEM.",
			"Türk oyun sektöründe yeni bir döneme öncülük etmeye hazır bir deha. Özellikle psikolojik korku alanında.",
			"Masadaki dosya onun doğrudan iletişim bilgilerini içeriyor. Ev sahibinin sesi zihninde yankılanıyor: 'Çok geç olmadan... ona ulaşmalısın.'"
		],
		"table2_links_bbcode": "[center]\n[url=https://www.linkedin.com/in/adil-basri-erdem-189941249/][color=#cc1111]LİNKEDİN ARŞİVİNE ERİŞ[/color][/url]\n\n[url=mailto:adilbasri06161@gmail.com][color=#cc1111]DOĞRUDAN E-POSTA GÖNDER[/color][/url]\n\n[url=http://www.teamhusk.com.tr][color=#cc1111]PORTFOLYOYU İNCELE (TEAM HUSK)[/color][/url]\n\n[url=close][color=#777777]DOSYADAN ÇIK[/color][/url]\n[/center]",
		"poster_dialogue_lines": [
			"Tam bir çıkış olması gereken yerde asılı duran büyük bir afişe bakıyorsun.",
			"INTERRED.",
			"Satranç benzeri taktiklerin ve rogue-lite korkunun ürpertici bir karışımı.",
			"Oynanabilir bir demo şu anda Steam'de pusuda bekliyor. Deneyimlemesi tamamen ücretsiz.",
			"Bu karanlık yaratım sadece oyuncuların desteği ve geri bildirimleriyle hayatta kalıyor ve gelişiyor. Ekibi desteklemeyi kesinlikle düşünmelisiniz.",
			"Alişılagelmişin dışındaki bu küçük interaktif CV'nin çarpık atmosferinden keyif aldıysanız... INTERRED ile kendinizi evinizde hissedeceksiniz."
		],
		"interact_default": "E tuşuna basarak etkileşime geç",
		"interact_car": "Arabaya binmek için E ile etkileşime geç!",
		"chase_warning": "Hayatın için arabaya koş!",
		"escape_message": "KAÇMAYI BAŞARDIN!",
		"narrative_credits": "Aralıksız çabalarına ve sayısız uykusuz gecesine rağmen,\nAdil Basri ERDEM henüz oyun endüstrisinde hak ettiği yeri bulamadı.\n\nGeliştirici hala küçük projelerle kendisini kovalayan 'küçük adamlardan' kaçıyor.\nDaha büyük bir şeyi yakalamak için yorucu saatlere ve mütevazı ücretlere katlanmaya razı.\n\nAma o sizin erişebileceğiniz bir yerde.\n\nYetenek kendini göstermenin bir yolunu her zaman bulur.\nDövülmüş demir en çok karanlıkta parlar; onu kalabalık arasında kolayca fark edeceksiniz.\n\nAdil Basri ERDEM için geleceğin ne getireceğini bilmiyorum... ama SİZİ biliyorum.\nVe böyle bir fırsatı kaçırmak istemezsiniz.\n\n\n[color=#a7f3d0]--- İLETİŞİM PROTOKOLLERİNİ BAŞLAT ---[/color]\n\n[url=https://www.linkedin.com/in/adil-basri-erdem-189941249/]LINKEDIN ARŞİVİNE ERİŞ[/url]\n\n[url=http://www.teamhusk.com.tr]TEAM HUSK PORTFOLYOSU[/url]\n\n[url=mailto:adilbasri06161@gmail.com]DOĞRUDAN E-POSTA İLETİŞİMİ[/url]",
		"dev_log_slides": [
			"[center][wave amp=20 freq=3][shake rate=12 level=5][color=#a7f3d0]--- GELİŞTİRME GÜNLÜĞÜ ---[/color][/shake][/wave][/center]",
			"[center]Kreatif Direktör & Oyun Tasarımcısı\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Baş Programcı\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Hikaye Yazarı\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Dünya Oluşturma & Seviye Tasarımı\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Seslendirme & Ses Tasarımı\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Atmosfer & Shader Mühendisliği\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Düşman Yapay Zeka Mimarisi\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]QA Testi & Hata Savaşçısı\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center][font_size=32][wave amp=30 freq=3][shake rate=20 level=8][color=#ef4444][i]OYNADIĞINIZ İÇİN TEŞEKKÜRLER![/i][/color][/shake][/wave][/font_size][/center]"
		]
	},
	"de": {
		"dialogue_lines": [
			"Lieber Himmel, du bist bis auf die Knochen durchnässt! Draußen in diesem Sturm... Es ist eiskalt da draußen.",
			"Vergiss das Wrack für Erste, mein Sohn. Die Straßen da vorne sind überschwemmt... du fährst heute nirgendwo mehr hin.",
			"Ich könnte niemals einen Gast von mir bei so einem Regen draußen stehen lassen. Das wäre ein Verbrechen.",
			"Komm schon, geh rein. Das Feuer prasselt... Außerdem haben wir so viel zu besprechen."
		],
		"dialogue_lines_2": [
			"Ah, die Vordertür macht wieder Probleme, was? Verflixtes Ding... Such gar nicht erst nach einem Schlüssel, das würde dir sowieso nichts nützen.",
			"Ich werde öfter aus meinem eigenen Haus ausgesperrt, als ich zugeben möchte! Geh einfach nach hinten und finde einen anderen Weg hinein. Du wirst das schon herausfinden."
		],
		"comp_dialogue_lines": [
			"Ein leuchtendes Textdokument bleibt auf dem Bildschirm geöffnet...",
			"> Aktuelle Projektarchitektur: Godot.",
			"> Ausführung komplett über GDScript.",
			"> Hinweis: JavaScript-, TypeScript- und Python-Kenntnisse vorhanden, aber in diesem Fall ungenutzt.",
			"> Frühere Engine-Erfahrungen (Unity, GameMaker, UE5) protokolliert und archiviert."
		],
		"paint_dialogue_lines": [
			"Du wischst eine dünne Staubschicht von einem alten, gerahmten Foto. Sieben Menschen lächeln auf dem Bild.",
			"Projekt: subtracker.",
			"Ein engagiertes Team von sieben Personen, nahtlos geführt. Die Initiative zog zwei lokale Banken in ihren Bann und spielte eine entscheidende Rolle beim anschließenden Exit des Projekts.",
			"Neben dem fehlerfreien Code (JavaScript, Node.js) und der großartigen Kameradschaft war der wahre Katalysator die aggressive Marketingstrategie...",
			"...eine Strategie, die stark vom Gründer Adil Basri Erdem und seinem Hintergrund in internationalem Handel und Finanzen vorangetrieben wurde."
		],
		"wolf_dialogue_lines": [
			"Du untersuchst eine bizarre Sammlung in der Ecke: eine geschnitzte Wolfsfigur, abgenutzte Spielkarten und schwere Metallmünzen.",
			"Die Archive von Team Husk. Fünf verschiedene IPs entstanden in zwei unerbittlichen Jahren der Entwicklung.",
			"Die Karten gehören zu 'Soul's Gambit', einem düsteren Roguelike-Deckbuilder. Die Münzen? Spielfiguren für 'Glad To Feed You!', einem makabren Horror-Damespiel.",
			"Verstreute geometrische Formen deuten auf 'SPHENKS' hin, ein Tetris-ähnliches Puzzle, das sich zwischen 2D- und 3D-Dimensionen bewegt...",
			"...während eine kleine, verpixelte Skizze 'Chick: Going to The Chicken Land' enthüllt, einen täuschenden, geschichtenbasierten Plattformer.",
			"Verschiedene Genres, verschiedene Mechaniken. Alle von denselben Händen geschaffen."
		],
		"table2_dialogue_lines": [
			"Du trittst näher an den Schreibtisch heran. Unter dem schwachen Licht der Lampe dominiert eine Ermittlungstafel die Wand.",
			"Alle roten Fäden und verstreuten Notizen führen zu einem einzigen Gesicht in der Mitte.",
			"Subjekt: Adil Basri ERDEM.",
			"Ein Mastermind, der bereit ist, eine neue Ära in der türkischen Spielebranche einzuleiten. Besonders im Bereich des psychologischen Horrors.",
			"Das Dossier auf dem Schreibtisch enthält seine direkten Kontaktprotokolle. Die Stimme des Gastgebers hallt in deinem Kopf wider: 'Du solltest dich an ihn wenden... bevor es zu spät ist.'"
		],
		"table2_links_bbcode": "[center]\n[url=https://www.linkedin.com/in/adil-basri-erdem-189941249/][color=#cc1111]LINKEDIN-ARCHIV ÖFFNEN[/color][/url]\n\n[url=mailto:adilbasri06161@gmail.com][color=#cc1111]DIREKTE E-MAIL STARTEN[/color][/url]\n\n[url=http://www.teamhusk.com.tr][color=#cc1111]PORTFOLIO INSPEKTION (TEAM HUSK)[/color][/url]\n\n[url=close][color=#777777]DOSSIER SCHLIESSEN[/color][/url]\n[/center]",
		"poster_dialogue_lines": [
			"Du starrst auf ein großes Poster, das genau dort hängt, wo eigentlich ein Ausgang hätte sein sollen.",
			"INTERRED.",
			"Eine makabre Mischung aus schachähnlicher Taktik und Rogue-lite-Horror.",
			"Eine spielbare Demo lauert derzeit auf Steam. Sie kann völlig kostenlos erlebt werden.",
			"Diese dunkle Kreation wird ausschließlich durch die Unterstützung und das Feedback ihrer Spieler am Leben erhalten und weiterentwickelt. Du solltest ernsthaft überlegen, das Team zu unterstützen.",
			"Wenn dir die düstere Atmosphäre dieses kleinen Lebenslaufs gefallen hat... wirst du dich bei INTERRED wie zu Hause fühlen."
		],
		"interact_default": "Drücke E zur Interaktion",
		"interact_car": "Drücke E, um ins Auto einzusteigen!",
		"chase_warning": "Lauf um dein Leben zum Auto!",
		"escape_message": "DU HAST ES GESCHAFFT ZU ENTKOMMEN!",
		"narrative_credits": "Trotz seiner unermüdlichen Bemühungen und unzähligen schlaflosen Nächte\nhat Adil Basri ERDEM seinen rechtmäßigen Platz in der Spieleindustrie noch nicht gefunden.\n\nDer Entwickler läuft immer noch vor den 'kleinen Männern' weg, die ihn durch kleine Projekte jagen.\nEr ist bereit, zermürbende Stunden und eine bescheidene Vergütung in Kauf zu nehmen, nur um nach etwas viel Größerem zu greifen.\n\nAber er ist in Ihrer Reichweite.\n\nTalent findet immer einen Weg, sich zu offenbaren.\nGeschmiedetes Eisen glänzt im Dunkeln am hellsten; Sie werden ihn leicht in der Menge erkennen.\n\nIch weiß nicht, was die Zukunft für Adil Basri ERDEM bereithält... aber ich kenne SIE.\nUnd Sie würden sich eine solche Gelegenheit nicht entgehen lassen wollen.\n\n\n[color=#a7f3d0]--- KONTAKTAUFNAHME STARTEN ---[/color]\n\n[url=https://www.linkedin.com/in/adil-basri-erdem-189941249/]LINKEDIN-ARCHIV ÖFFNEN[/url]\n\n[url=http://www.teamhusk.com.tr]TEAM HUSK PORTFOLIO[/url]\n\n[url=mailto:adilbasri06161@gmail.com]DIREKTE E-MAIL-KOMMUNIKATION[/url]",
		"dev_log_slides": [
			"[center][wave amp=20 freq=3][shake rate=12 level=5][color=#a7f3d0]--- ENTWICKLUNGSPROTOKOLL ---[/color][/shake][/wave][/center]",
			"[center]Creative Director & Game Designer\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Chefprogrammierer\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Drehbuchautor\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Weltgestaltung & Leveldesign\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Synchronsprecher & Sounddesign\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Atmosphäre & Shader-Entwicklung\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Gegner-KI-Architektur\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]QA-Tests & Bug-Überlebender\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center][font_size=32][wave amp=30 freq=3][shake rate=20 level=8][color=#ef4444][i]DANKE FÜRS SPIELEN![/i][/color][/shake][/wave][/font_size][/center]"
		]
	},
	"it": {
		"dialogue_lines": [
			"Santo cielo, sei bagnato fino alle ossa! Fuori con questa tempesta... Si congela là fuori.",
			"Dimentica quel rottame per ora, figliolo. Le strade davanti sono allagate... stasera non andrai da nessuna parte.",
			"Non potrei mai lasciare un mio ospite fuori con una pioggia simile. Sarebbe un crimine.",
			"Vieni, entra. Il fuoco scoppietta... E poi, abbiamo così tanto di cui parlare."
		],
		"dialogue_lines_2": [
			"Ah, la porta d'ingresso fa di nuovo i capricci, vero? Maledetta cosa... Non perdere tempo a cercare una chiave, non ti servirebbe a nulla comunque.",
			"Rimango chiuso fuori da casa mia più spesso di quanto vorrei ammettere! Fai un giro sul retro e trova un altro modo per entrare. Sono sicuro che ci riuscirai."
		],
		"comp_dialogue_lines": [
			"Un documento di testo luminoso è rimasto aperto sullo schermo...",
			"> Architettura del progetto corrente: Godot.",
			"> Esecuzione interamente tramite GDScript.",
			"> Nota: competenze in JavaScript, TypeScript e Python disponibili ma inutilizzate in questo caso.",
			"> Esperienze precedenti con motori grafici (Unity, GameMaker, UE5) registrate e archiviate."
		],
		"paint_dialogue_lines": [
			"Pulisci un sottile strato di polvere da una vecchia fotografia incorniciata. Sette persone sorridono nella foto.",
			"Progetto: subtracker.",
			"Un team dedicato di sette persone, guidato senza problemi. L'iniziativa ha coinvolto due banche locali e ha svolto un ruolo fondamentale nell'uscita del progetto che è seguito.",
			"Oltre al codice impeccabile (JavaScript, Node.js) e alla grande solidarietà, il vero catalizzatore è stata la sua aggressiva strategia di marketing...",
			"...una strategia fortemente guidata dal fondatore, Adil Basri Erdem, e dal suo background in Commercio Internazionale e Finanza."
		],
		"wolf_dialogue_lines": [
			"Esamini una bizzarra collezione raccolta nell'angolo: una statuina di lupo intagliata, carte da gioco logore e pesanti gettoni metallici.",
			"Gli archivi di Team Husk. Cinque diverse IP materializzate in due implacabili anni di sviluppo.",
			"Le carte appartengono a 'Soul's Gambit', un oscuro deckbuilder roguelike. I gettoni? Pezzi per 'Glad To Feed You!', un macabro gioco di dama horror.",
			"Forme geometriche sparse accennano a 'SPHENKS', un puzzle simile a Tetris che si sposta tra le dimensioni 2D e 3D...",
			"...mentre un piccolo schizzo pixelato rivela 'Chick: Going to The Chicken Land', un ingannevole platform basato sulla storia.",
			"Generi diversi, meccaniche diverse. Tutti creati dalle stesse mani."
		],
		"table2_dialogue_lines": [
			"Ti avvicini alla scrivania. Sotto la luce fioca della lampada, una lavagna investigativa domina la parete.",
			"Tutti i fili rossi e le note sparse si collegano a un unico volto al centro.",
			"Soggetto: Adil Basri ERDEM.",
			"Una mente pronta a fare da apripista a una nuova era nell'industria dei videogiochi turca. Specialmente nel regno dell'horror psicologico.",
			"Il dossier sulla scrivania contiene i suoi protocolli di contatto diretto. La voce dell'ospite risuona nella tua mente: 'Dovresti metterti in contatto con lui... prima che sia troppo tardi.'"
		],
		"table2_links_bbcode": "[center]\n[url=https://www.linkedin.com/in/adil-basri-erdem-189941249/][color=#cc1111]ACCEDI ALL'ARCHIVIO LINKEDIN[/color][/url]\n\n[url=mailto:adilbasri06161@gmail.com][color=#cc1111]INVIA EMAIL DIRETTA[/color][/url]\n\n[url=http://www.teamhusk.com.tr][color=#cc1111]ISPEZIONA IL PORTAFOGLIO (TEAM HUSK)[/color][/url]\n\n[url=close][color=#777777]ESCI DAL DOSSIER[/color][/url]\n[/center]",
		"poster_dialogue_lines": [
			"Fissi un grande poster appeso esattamente dove avrebbe dovuto esserci un'uscita.",
			"INTERRED.",
			"Una macabra miscela di tattiche scacchistiche e horror rogue-lite.",
			"Una demo giocabile si trova attualmente su Steam. L'esperienza é completamente gratuita.",
			"Questa oscura creazione è tenuta in vita e si evolve unicamente grazie al supporto e ai feedback dei suoi giocatori. Dovresti seriamente considerare di supportare il team.",
			"Se ti è piaciuta la cupa atmosfera di questo piccolo CV interattivo... ti sentirai a casa con INTERRED."
		],
		"interact_default": "Interagisci premendo il tasto E",
		"interact_car": "Interagisci con E per salire in macchina!",
		"chase_warning": "Corri alla macchina per salvarti la vita!",
		"escape_message": "SEI RIUSCITO A FUGGIRE!",
		"narrative_credits": "Nonostante i suoi incessanti sforzi e le innumerevoli notti insonni,\nAdil Basri ERDEM non ha ancora assicurato il suo giusto posto nell'industria dei videogiochi.\n\nLo sviluppatore sta ancora fuggendo dai 'piccoli uomini' che lo inseguono attraverso progetti su piccola scala.\nÈ disposto a sopportare ore estenuanti e compensi modesti pur di afferrare qualcosa di molto più grande.\n\nMa è alla vostra portata.\n\nIl talento trova sempre un modo per rivelarsi.\nIl ferro battuto risplende di più nell'oscurità; lo individuerete facilmente tra la folla.\n\nNon so cosa riservi il futuro per Adil Basri ERDEM... ma conosco VOI.\nE non vorrete perdere un'occasione del genere.\n\n\n[color=#a7f3d0]--- INIZIA PROTOCOLLI DI CONTATTO ---[/color]\n\n[url=https://www.linkedin.com/in/adil-basri-erdem-189941249/]ACCEDI ALL'ARCHIVIO LINKEDIN[/url]\n\n[url=http://www.teamhusk.com.tr]PORTFOLIO TEAM HUSK[/url]\n\n[url=mailto:adilbasri06161@gmail.com]COMUNICAZIONE E-POSTA DIRETTA[/url]",
		"dev_log_slides": [
			"[center][wave amp=20 freq=3][shake rate=12 level=5][color=#a7f3d0]--- LOG DI SVILUPPO ---[/color][/shake][/wave][/center]",
			"[center]Direttore Creativo & Game Designer\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Programmatore Capo\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Sceneggiatore\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]World Building & Level Design\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Doppiaggio & Sound Design\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Atmosferica & Ingegneria degli Shader\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Architettura dell'IA Nemica\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Test QA & Sopravvissuto ai Bug\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center][font_size=32][wave amp=30 freq=3][shake rate=20 level=8][color=#ef4444][i]GRAZIE PER AVER GIOCATO![/i][/color][/shake][/wave][/font_size][/center]"
		]
	},
	"fr": {
		"dialogue_lines": [
			"Bon sang, vous êtes trempé jusqu'aux os ! Dehors dans cette tempête... Il fait un froid de canard.",
			"Oublie ce tas de ferraille pour l'instant, mon fils. Les routes devant sont inondées... tu ne vas nulle part ce soir.",
			"Je ne pourrais jamais laisser un de mes invités dehors sous une telle pluie. Ce serait un crime.",
			"Allez, entrez. Le feu crépite... De plus, nous avons tant de choses à nous dire."
		],
		"dialogue_lines_2": [
			"Ah, la porte d'entrée fait encore des siennes, n'est-ce pas ? Sacrée machine... Ne t'embête même pas à chercher une clé, cela ne te servirait à rien de toute façon.",
			"Je me retrouve enfermé dehors de chez moi plus souvent que je ne voudrais l'admettre ! Fais le tour par l'arrière et trouve une autre entrée. Je suis sûr que tu vas trouver."
		],
		"comp_dialogue_lines": [
			"Un document texte lumineux est laissé ouvert sur l'écran...",
			"> Architecture actuelle du projet: Godot.",
			"> Exécution entièrement via GDScript.",
			"> Note: compétences en JavaScript, TypeScript et Python disponibles mais inutilisées dans ce cas.",
			"> Expériences précédentes avec d'autres moteurs (Unity, GameMaker, UE5) enregistrées et archivées."
		],
		"paint_dialogue_lines": [
			"Vous essuyez une fine couche de poussière sur une vieille photo encadrée. Sept personnes sourient sur la photo.",
			"Projet: subtracker.",
			"Une équipe dédiée de sept personnes, dirigée de main de maître. L'initiative a entraîné deux banques locales dans son sillage et a joué un rôle charnière dans la sortie du projet qui a suivi.",
			"Au-delà du code impeccable (JavaScript, Node.js) et de la grande camaraderie, le véritable catalyseur a été son agressive stratégie marketing...",
			"...une stratégie fortement menée par le fondateur, Adil Basri Erdem, et son parcours en commerce international et finance."
		],
		"wolf_dialogue_lines": [
			"Vous examinez une étrange collection rassemblée dans le coin: une figurine de loup sculptée, des cartes à jouer usées et de lourds jetons métalliques.",
			"Les archives de Team Husk. Cinq licences distinctes matérialisées en deux années de développement acharné.",
			"Les cartes appartiennent à 'Soul's Gambit', un deckbuilder roguelike sombre. Les jetons ? Des pièces pour 'Glad To Feed You !', un jeu macabre de dames d'horreur.",
			"Des formes géométriques dispersées font penser à 'SPHENKS', un puzzle de type Tetris alternant entre les dimensions 2D et 3D...",
			"...tandis qu'un petit croquis pixelisé révèle 'Chick: Going to The Chicken Land', un jeu de plateforme trompeur axé sur l'histoire.",
			"Différents genres, différentes mécaniques. Tous créés par les mêmes mains."
		],
		"table2_dialogue_lines": [
			"Vous vous approchez du bureau. Sous la faible lumière de la lampe, un tableau d'investigation domine le mur.",
			"Tous les fils rouges et les notes éparpillées mènent à un seul visage au centre.",
			"Sujet: Adil Basri ERDEM.",
			"Un cerveau prêt à ouvrir une nouvelle ére dans l'industrie du jeu vidéo turque. Particulièrement dans le domaine de l'horreur psychologique.",
			"Le dossier sur le bureau contient ses protocoles de contact direct. La voix de l'hôte résonne dans votre esprit: 'Vous devriez le contacter... avant qu'il ne soit trop tard.'"
		],
		"table2_links_bbcode": "[center]\n[url=https://www.linkedin.com/in/adil-basri-erdem-189941249/][color=#cc1111]ACCÉDER AUX ARCHIVES LINKEDIN[/color][/url]\n\n[url=mailto:adilbasri06161@gmail.com][color=#cc1111]INITIER UN MESSAGE DIRECT[/color][/url]\n\n[url=http://www.teamhusk.com.tr][color=#cc1111]INSPECTER LE PORTFOLIO (TEAM HUSK)[/color][/url]\n\n[url=close][color=#777777]FERMER LE DOSSIER[/color][/url]\n[/center]",
		"poster_dialogue_lines": [
			"Vous fixez un grand poster suspendu exactement là où une sortie aurait dû se trouver.",
			"INTERRED.",
			"Un mélange macabre de tactique inspirée des échecs et d'horreur rogue-lite.",
			"Une démo jouable est actuellement disponible sur Steam. L'expérience est entièrement gratuite.",
			"Cette sombre création est maintenue en vie et évolue uniquement grâce au soutien et aux retours de ses joueurs. Vous devriez sérieusement envisager de soutenir l'équipe.",
			"Si vous avez aimé l'atmosphère tordue de ce petit CV interactif... vous vous sentirez chez vous avec INTERRED."
		],
		"interact_default": "Interagir en appuyant sur la touche E",
		"interact_car": "Interagir avec E pour monter dans la voiture !",
		"chase_warning": "Cours vers la voiture pour sauver ta vie !",
		"escape_message": "TU AS RÉUSSI À T'ÉCHAPPER !",
		"narrative_credits": "Malgré ses efforts incessants et ses innombrables nuits blanches,\nAdil Basri ERDEM n'a pas encore trouvé sa juste place dans l'industrie du jeu vidéo.\n\nLe développeur fuit toujours les 'petits hommes' qui le poursuivent à travers des micro-projets.\nIl est prêt à endurer des heures exténuantes et une rémunération modeste pour saisir quelque chose de bien plus grand.\n\nMais il est à votre portée.\n\nLe talent trouve toujours un moyen de se révéler.\nLe fer forgé brille plus fort dans l'obscurité ; vous le repérerez facilement dans la foule.\n\nJe ne sais pas ce que l'avenir réserve à Adil Basri ERDEM... mais je VOUS connais.\nEt vous ne voudriez pas rater une telle opportunité.\n\n\n[color=#a7f3d0]--- INITIALISER LE PROTOCOLE DE CONTACT ---[/color]\n\n[url=https://www.linkedin.com/in/adil-basri-erdem-189941249/]ACCÉDER AUX ARCHIVES LINKEDIN[/url]\n\n[url=http://www.teamhusk.com.tr]PORTFOLIO TEAM HUSK[/url]\n\n[url=mailto:adilbasri06161@gmail.com]COMMUNICATION E-MAIL DIRECTE[/url]",
		"dev_log_slides": [
			"[center][wave amp=20 freq=3][shake rate=12 level=5][color=#a7f3d0]--- LOG DE DÉVELOPPEMENT ---[/color][/shake][/wave][/center]",
			"[center]Directeur Artistique & Concepteur\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Programmeur Principal\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Scénariste\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]World Building & Level Design\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Doublage & Sound Design\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Atmosphère & Shader Engineering\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Architecture IA Ennemie\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Tests QA & Survivant des Bugs\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center][font_size=32][wave amp=30 freq=3][shake rate=20 level=8][color=#ef4444][i]MERCI D'AVOIR JOUÉ ![/i][/color][/shake][/wave][/font_size][/center]"
		]
	},
	"es": {
		"dialogue_lines": [
			"¡Cielo santo, estás empapado hasta los huesos! Fuera con esta tormenta... Hace un frío glacial.",
			"Olvídate de esa chatarra por ahora, hijo. Los caminos más adelante están inundados... no vas a ir a ningún lado esta noche.",
			"Jamás dejaría que un invitado mío se quedara fuera con una lluvia como esta. Sería un crimen.",
			"Vamos, entra. El fuego está rugiendo... Además, tenemos mucho de qué hablar."
		],
		"dialogue_lines_2": [
			"Ah, ¿la puerta principal vuelve a dar problemas, verdad? Maldita sea... No te molestes en buscar una llave, no te serviría de nada de todos modos.",
			"¡Me quedo fuera de mi propia casa más a menudo de lo que me gustaría admitir! Da una vuelta por detrás y busca otra entrada. Estoy seguro de que lo resolverás."
		],
		"comp_dialogue_lines": [
			"Un documento de texto brillante queda abierto en la pantalla...",
			"> Arquitectura del proyecto actual: Godot.",
			"> Ejecución íntegramente mediante GDScript.",
			"> Nota: conocimientos de JavaScript, TypeScript y Python disponibles pero no utilizados en este caso.",
			"> Experiencias previas con otros motores (Unity, GameMaker, UE5) registradas y archivadas."
		],
		"paint_dialogue_lines": [
			"Limpias una fina capa de polvo de una vieja fotografía enmarcada. Siete personas sonreían en la imagen.",
			"Proyecto: subtracker.",
			"Un equipo dedicado de siete personas, dirigido sin problemas. La iniciativa arrastró a dos bancos locales tras de sí y jugó un papel fundamental en la posterior salida del proyecto.",
			"Más allá del código impecable (JavaScript, Node.js) y el gran compañerismo, el verdadero catalizador fue su agresiva estrategia de marketing...",
			"...una estrategia impulsada principalmente por el fundador, Adil Basri Erdem, y su experiencia en Comercio Internacional y Finanzas."
		],
		"wolf_dialogue_lines": [
			"Examinas una extraña colección reunida en la esquina: una figura de lobo tallada, cartas gastadas y pesadas fichas metálicas.",
			"Los archivos de Team Husk. Cinco propiedades intelectuales distintas materializadas en dos implacables años de desarrollo.",
			"Las cartas pertenecen a 'Soul's Gambit', un oscuro creador de mazos roguelike. ¿Las fichas? Piezas para 'Glad To Feed You!', un macabro juego de damas de terror.",
			"Formas geométricas dispersas sugieren 'SPHENKS', un rompecabezas similar al Tetris que cambia entre dimensiones 2D y 3D...",
			"...mientras que un pequeño boceto pixelado revela 'Chick: Going to The Chicken Land', un engañoso juego de plataformas basado en la historia.",
			"Diferentes géneros, diferentes mecánicas. Todos creados por las mismas manos."
		],
		"table2_dialogue_lines": [
			"Te acercas al escritorio. Bajo la tenue luz de la lámpara, un tablero de investigación domina la pared.",
			"Todos los hilos rojos y las notas dispersas se conectan a un solo rostro en el centro.",
			"Sujeto: Adil Basri ERDEM.",
			"Una mente maestra dispuesta a liderar una nueva era en la industria del videojuego turca. Especialmente en el ámbito del terror psicológico.",
			"El dossier en el escritorio contiene sus protocolos de contacto directo. La voz del anfitrión resuena en tu mente: 'Deberías ponerte en contacto con él... antes de que sea demasiado tarde.'"
		],
		"table2_links_bbcode": "[center]\n[url=https://www.linkedin.com/in/adil-basri-erdem-189941249/][color=#cc1111]ACCEDER AL ARCHIVO DE LINKEDIN[/color][/url]\n\n[url=mailto:adilbasri06161@gmail.com][color=#cc1111]INICIAR CORREO DIRECTO[/color][/url]\n\n[url=http://www.teamhusk.com.tr][color=#cc1111]INSPECCIONAR PORTAFOLIO (TEAM HUSK)[/color][/url]\n\n[url=close][color=#777777]SALIR DEL DOSSIER[/color][/url]\n[/center]",
		"poster_dialogue_lines": [
			"Te quedas mirando un gran cartel colgado exactamente donde debería haber estado una salida.",
			"INTERRED.",
			"Una macabra mezcla de tácticas similares al ajedrez y terror rogue-lite.",
			"Una demostración jugable acecha actualmente en Steam. Es completamente gratis.",
			"Esta oscura creación se mantiene viva y evoluciona únicamente gracias al apoyo y la retroalimentación de sus jugadores. Deberías considerar seriamente apoyar al equipo.",
			"Si disfrutaste de la retorcida atmósfera de este pequeño CV interactivo... te sentirás como en casa con INTERRED."
		],
		"interact_default": "Interactúa presionando la tecla E",
		"interact_car": "¡Interactúa con E para entrar al coche!",
		"chase_warning": "¡Corre al coche para salvar tu vida!",
		"escape_message": "¡LOGRASTE ESCAPAR!",
		"narrative_credits": "A pesar de sus incansables esfuerzos e innumerables noches de insomnio,\nAdil Basri ERDEM aún no ha asegurado el lugar que le corresponde en la industria de los videojuegos.\n\nEl desarrollador sigue huyendo de los 'hombres pequeños' que lo persiguen a través de proyectos a pequeña escala.\nEstá dispuesto a soportar jornadas agotadoras y una compensación modesta solo por alcanzar algo mucho mayor.\n\nMiembro de la comunidad dentro de tu alcance.\n\nEl talento siempre encuentra la manera de revelarse.\nEl hierro forjado brilla con más fuerza en la oscuridad; lo identificarás fácilmente entre la multitud.\n\nNo sé qué depara el futuro para Adil Basri ERDEM... pero te conozco a TI.\nY no querrás perder una oportunidad como esta.\n\n\n[color=#a7f3d0]--- INICIAR PROTOCOLOS DE CONTACTO ---[/color]\n\n[url=https://www.linkedin.com/in/adil-basri-erdem-189941249/]ACCEDER AL ARCHIVO DE LINKEDIN[/url]\n\n[url=http://www.teamhusk.com.tr]PORTAFOLIO TEAM HUSK[/url]\n\n[url=mailto:adilbasri06161@gmail.com]CORREO DIRECTO[/url]",
		"dev_log_slides": [
			"[center][wave amp=20 freq=3][shake rate=12 level=5][color=#a7f3d0]--- REGISTRO DE DESARROLLO ---[/color][/shake][/wave][/center]",
			"[center]Director Creativo y Diseñador\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Programador Principal\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Guionista\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Construcción del Mundo y Diseño de Niveles\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Actuación de Voz y Diseño de Sonido\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Atmósfera e Ingeniería de Shaders\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Arquitectura de la IA Enemiga\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center]Pruebas de Control de Calidad y Sobreviviente de Bugs\n[wave amp=12 freq=2][shake rate=7 level=3][color=#ffffff]Adil Basri ERDEM[/color][/shake][/wave][/center]",
			"[center][font_size=32][wave amp=30 freq=3][shake rate=20 level=8][color=#ef4444][i]¡GRACIAS POR JUGAR![/i][/color][/shake][/wave][/font_size][/center]"
		]
	}
}
