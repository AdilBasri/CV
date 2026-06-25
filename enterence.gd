extends Node3D

# Volvo node reference and base positions
@onready var volvo = get_node_or_null("volvo")
var volvo_base_pos = Vector3.ZERO
var volvo_base_rot = Vector3.ZERO

# Lights
var left_headlight: SpotLight3D = null
var right_headlight: SpotLight3D = null

# Shifting CSG material
var csg_material: StandardMaterial3D = null

# Highway spawner variables
var spawned_objects: Array = []
var spawn_timer = 0.0
var road_speed = 40.0 # Speed of moving objects flying past (simulation of car moving forward)
var alternate_side = false

# Car movement state machine
var current_movement_state = 0
var state_timer = 0.0
var state_duration = 3.0
var bump_timer = 0.0

# UI Controls
var ui_layer: CanvasLayer = null
var fade_layer: CanvasLayer = null
var main_menu_container: VBoxContainer = null
var options_panel: Panel = null
var faq_panel: Panel = null
var exit_popup: Panel = null

# Sound effects players
var hover_audio_player: AudioStreamPlayer = null
var click_audio_player: AudioStreamPlayer = null

# Camera movement variables
@onready var camera = get_node_or_null("Camera3D")
var camera_base_pos = Vector3.ZERO
var camera_base_rot = Vector3.ZERO

# Speed lines 3D particles reference
var speed_particles: CPUParticles3D = null

# Vehicle procedural audio players
var engine_audio_player: AudioStreamPlayer = null
var tire_audio_player: AudioStreamPlayer = null
var bump_audio_player: AudioStreamPlayer = null

func _ready():
	print("Entrance Menu scene ready.")
	
	# Store Volvo base transformations
	if volvo:
		volvo_base_pos = volvo.position
		volvo_base_rot = volvo.rotation
		setup_headlights()
		
	# Store Camera base transformations
	if camera:
		camera_base_pos = camera.position
		camera_base_rot = camera.rotation
		
	# Setup night-cycle CSG materials
	setup_csg_materials()
	
	# Setup World Environment and Fog
	setup_world_environment()
	
	# Setup Road Scroller (UV scrolling) script attachment
	setup_road_scroller()
	
	# Audio setup
	setup_audio()
	
	# Setup 3D speed particles
	setup_3d_speed_lines()
	
	# Main UI hierarchy
	setup_ui()
func setup_headlights():
	if not volvo:
		return
		
	# Find and configure all 4 child SpotLight3D nodes added under Volvo in the scene editor
	var spotlights = []
	for spot_name in ["SpotLight3D", "SpotLight3D2", "SpotLight3D3", "SpotLight3D4"]:
		var l = volvo.get_node_or_null(spot_name)
		if l and l is SpotLight3D:
			spotlights.append(l)
			
	# Keep left_headlight and right_headlight references for compatibility
	left_headlight = volvo.get_node_or_null("SpotLight3D")
	right_headlight = volvo.get_node_or_null("SpotLight3D2")
	
	# Configure spotlight properties WITHOUT modifying position, rotation, spot_angle, or spot_range (per user request)
	for l in spotlights:
		l.light_color = Color(1.0, 1.0, 1.0)
		l.light_energy = 35.0
		l.shadow_enabled = true
		l.visible = true
		
	print("Volvo scene headlights (4 spotlights) configured using editor transforms.")


func setup_csg_materials():
	csg_material = StandardMaterial3D.new()
	csg_material.roughness = 0.85 # High roughness (0.8 - 0.9) to scatter headlight glow softly
	csg_material.metallic = 0.0   # No metallic, low reflectivity
	csg_material.albedo_color = Color(0.08, 0.06, 0.12, 1.0)
	
	# Apply dynamically to all CSGBoxes in scene
	var root_box = get_node_or_null("CSGBox3D")
	if root_box:
		root_box.material_override = csg_material
		for child in root_box.get_children():
			if child is CSGBox3D:
				child.material = csg_material
		print("CSGBox materials configured with high roughness and low specular for headlights.")

func setup_world_environment():
	# Configure or create WorldEnvironment node programmatically
	var world_env = get_node_or_null("WorldEnvironment")
	if not world_env:
		world_env = WorldEnvironment.new()
		world_env.name = "WorldEnvironment"
		add_child(world_env)
		
	var env = world_env.environment
	if not env:
		env = Environment.new()
		world_env.environment = env
		
	env.background_mode = Environment.BG_CLEAR_COLOR
	
	# Moonlight ambient fill so the car, trees, and details are visible (matches gameplay style)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.18, 0.22, 0.28) # moonlight gray-blue
	env.ambient_light_energy = 1.2
	
	# Optimized depth fog: WebGL2-friendly, softens distant box boundaries
	env.volumetric_fog_enabled = false
	env.fog_enabled = true
	env.fog_light_color = Color(0.04, 0.05, 0.07) # dark blue-black mist
	env.fog_density = 0.038                       # moderate fog density so everything is visible
	env.fog_sky_affect = 0.0
	
	# Restore OmniLight3D to editor energy to keep the scene illuminated
	var omni = get_node_or_null("OmniLight3D")
	if omni:
		omni.light_energy = 16.0
		
	print("WorldEnvironment and Fog configured with moonlight ambient lighting and moderate density.")

func setup_road_scroller():
	# Find node3 (MeshInstance3D representing the road) with fallbacks
	var road_node = find_child("node3", true, false)
	if not road_node:
		# Fallback to Object_3 (actual asphalt surface in Sketchfab road scene)
		road_node = find_child("Object_3", true, false)
		
	if road_node and road_node is MeshInstance3D:
		if not road_node.get_script():
			var scroller_script = load("res://road_scroller.gd")
			if scroller_script:
				road_node.set_script(scroller_script)
		if road_node.mesh:
			var src_mesh = road_node.mesh
			var new_mesh = ArrayMesh.new()
			for i in src_mesh.get_surface_count():
				var st = SurfaceTool.new()
				st.create_from(src_mesh, i) # use mesh and surface index
				st.generate_tangents()
				new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
			road_node.mesh = new_mesh
		# Call ready to initialize material duplication
		road_node._ready()
		print("Attached road_scroller.gd with generated tangents for: ", road_node.name)

func setup_audio():
	# Dynamic WAV generation for clean, dependency-free menu sounds
	hover_audio_player = AudioStreamPlayer.new()
	hover_audio_player.name = "HoverAudioPlayer"
	hover_audio_player.stream = generate_menu_sfx(900.0, 0.06) # short high-pitch blip
	hover_audio_player.volume_db = -18.0
	add_child(hover_audio_player)
	
	click_audio_player = AudioStreamPlayer.new()
	click_audio_player.name = "ClickAudioPlayer"
	click_audio_player.stream = generate_menu_sfx(380.0, 0.12) # mechanical click sound
	click_audio_player.volume_db = -10.0
	add_child(click_audio_player)

	# Procedural vehicle audio
	engine_audio_player = AudioStreamPlayer.new()
	engine_audio_player.name = "EngineAudioPlayer"
	engine_audio_player.stream = generate_engine_sound()
	engine_audio_player.volume_db = -12.0
	add_child(engine_audio_player)
	engine_audio_player.play()
	
	tire_audio_player = AudioStreamPlayer.new()
	tire_audio_player.name = "TireAudioPlayer"
	tire_audio_player.stream = generate_tire_squeal_sound()
	tire_audio_player.volume_db = -80.0 # start muted
	add_child(tire_audio_player)
	tire_audio_player.play()
	
	bump_audio_player = AudioStreamPlayer.new()
	bump_audio_player.name = "BumpAudioPlayer"
	bump_audio_player.stream = generate_bump_sound()
	bump_audio_player.volume_db = -10.0
	add_child(bump_audio_player)

func generate_engine_sound() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 11025
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
	var duration = 0.5
	var length = int(duration * 11025)
	stream.loop_end = length
	var bytes = PackedByteArray()
	bytes.resize(length)
	
	for i in range(length):
		var t = float(i) / 11025.0
		# Combine a low frequency square wave and a sawtooth wave with some noise
		var osc1 = sin(2.0 * PI * 45.0 * t) 
		var osc2 = (fmod(t * 90.0, 1.0) - 0.5) * 2.0
		var osc3 = sign(sin(2.0 * PI * 22.5 * t))
		var noise = randf_range(-0.2, 0.2)
		var sample = int((osc1 + osc2 + osc3 + noise) * 40.0)
		bytes[i] = clamp(sample, -128, 127)
		
	stream.data = bytes
	return stream

func generate_tire_squeal_sound() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 11025
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
	var duration = 0.5
	var length = int(duration * 11025)
	stream.loop_end = length
	var bytes = PackedByteArray()
	bytes.resize(length)
	
	for i in range(length):
		var t = float(i) / 11025.0
		var pitch_mod = sin(2.0 * PI * 12.0 * t) * 50.0
		var osc = sin(2.0 * PI * (850.0 + pitch_mod) * t)
		var noise = randf_range(-0.5, 0.5)
		var sample = int((osc * 0.4 + noise * 0.6) * 35.0)
		bytes[i] = clamp(sample, -128, 127)
		
	stream.data = bytes
	return stream

func generate_bump_sound() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 11025
	stream.stereo = false
	
	var duration = 0.25
	var length = int(duration * 11025)
	var bytes = PackedByteArray()
	bytes.resize(length)
	
	for i in range(length):
		var decay = 1.0 - (float(i) / float(length))
		var t = float(i) / 11025.0
		var osc = sin(2.0 * PI * 60.0 * t)
		var noise = randf_range(-0.3, 0.3)
		var sample = int((osc * 0.7 + noise * 0.3) * 60.0 * decay)
		bytes[i] = clamp(sample, -128, 127)
		
	stream.data = bytes
	return stream

func setup_3d_speed_lines():
	speed_particles = CPUParticles3D.new()
	speed_particles.name = "SpeedParticles"
	
	# Create a simple line mesh for the speed streaks
	var line_mesh = BoxMesh.new()
	line_mesh.size = Vector3(0.025, 0.025, 2.8) # thin long streaks
	
	# Create a flat unshaded material for the streaks
	var mat = StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.95, 0.7, 0.18) # semi-transparent golden-white
	mat.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	line_mesh.material = mat
	
	speed_particles.mesh = line_mesh
	speed_particles.amount = 45
	speed_particles.lifetime = 1.0
	speed_particles.preprocess = 1.0
	
	# Emit from a box in front of the car
	speed_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	speed_particles.emission_box_extents = Vector3(10.0, 5.0, 1.0)
	
	# Spawn particles far ahead and let them move towards the camera (+Z)
	speed_particles.position = Vector3(0.0, 2.0, -35.0)
	speed_particles.direction = Vector3(0, 0, 1)
	speed_particles.spread = 0.0 # straight line
	speed_particles.gravity = Vector3.ZERO
	speed_particles.initial_velocity_min = 40.0
	speed_particles.initial_velocity_max = 55.0
	
	add_child(speed_particles)
	print("3D Speed Particles system created and added.")

func generate_menu_sfx(freq: float, duration: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 11025
	stream.stereo = false
	
	var length = int(duration * 11025)
	var bytes = PackedByteArray()
	bytes.resize(length)
	for i in range(length):
		var decay = 1.0 - (float(i) / float(length))
		var angle = float(i) * (2.0 * PI * freq / 11025.0)
		var sample = int(sin(angle) * 127.0 * decay)
		bytes[i] = sample
		
	stream.data = bytes
	return stream

func play_hover_sfx():
	if hover_audio_player:
		hover_audio_player.play()

func play_click_sfx():
	if click_audio_player:
		click_audio_player.play()

func setup_ui():
	# Main canvas
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 1
	add_child(ui_layer)
	
	# Top overlay canvas for PLAY transition
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 10
	add_child(fade_layer)
	
	# Container for vertical button layout on the left side
	main_menu_container = VBoxContainer.new()
	main_menu_container.name = "MainMenuButtons"
	main_menu_container.size = Vector2(250, 240)
	main_menu_container.position = Vector2(24, 140)
	
	# Create a subtle vertical accent sidebar line on the left
	var sidebar_line = ColorRect.new()
	sidebar_line.name = "MenuSidebar"
	sidebar_line.size = Vector2(2, 220)
	sidebar_line.position = Vector2(16, 145)
	sidebar_line.color = Color(1.0, 0.91, 0.12, 0.35) # retro semi-transparent gold
	ui_layer.add_child(sidebar_line)
	
	# Setup the 4 title buttons
	var play_btn = Button.new()
	setup_button(play_btn, "PLAY", _on_play_pressed)
	main_menu_container.add_child(play_btn)
	
	# spacing spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	main_menu_container.add_child(spacer1)
	
	var options_btn = Button.new()
	setup_button(options_btn, "OPTIONS", _on_options_pressed)
	main_menu_container.add_child(options_btn)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	main_menu_container.add_child(spacer2)
	
	var faq_btn = Button.new()
	setup_button(faq_btn, "FAQ", _on_faq_pressed)
	main_menu_container.add_child(faq_btn)
	
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 10)
	main_menu_container.add_child(spacer3)
	
	var exit_btn = Button.new()
	setup_button(exit_btn, "EXIT", _on_exit_pressed)
	main_menu_container.add_child(exit_btn)
	
	ui_layer.add_child(main_menu_container)
	
	# Submenus setup
	setup_options_panel()
	setup_faq_panel()
	setup_exit_popup()

func setup_button(btn: Button, name_str: String, pressed_callable: Callable):
	btn.text = "  " + name_str
	btn.flat = true
	btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75)) # light grey
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.91, 0.12)) # retro yellow gold
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.3, 0.3)) # click red
	
	# Connect hover feedback
	btn.mouse_entered.connect(func():
		btn.text = "> " + name_str # retro selection cursor indicator
		play_hover_sfx()
	)
	btn.mouse_exited.connect(func():
		btn.text = "  " + name_str
	)
	btn.pressed.connect(pressed_callable)

func create_custom_panel(title_text: String) -> Panel:
	var panel = Panel.new()
	panel.size = Vector2(440, 320)
	panel.position = Vector2(100, 80)
	panel.visible = false
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.08, 0.9) # Semi-transparent dark charcoal blue
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.7, 0.75, 0.8) # Silver frame
	style.corner_detail = 1
	panel.add_theme_stylebox_override("panel", style)
	
	# Header title Label
	var header = Label.new()
	header.text = title_text
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.position = Vector2(0, 15)
	header.size = Vector2(440, 30)
	
	var font = LabelSettings.new()
	font.font_size = 20
	font.font_color = Color(1.0, 0.91, 0.12) # Gold title
	header.label_settings = font
	panel.add_child(header)
	
	return panel

func setup_options_panel():
	options_panel = create_custom_panel("OPTIONS")
	
	# Fullscreen toggle button
	var fullscreen_btn = Button.new()
	fullscreen_btn.position = Vector2(40, 70)
	fullscreen_btn.size = Vector2(360, 40)
	setup_button(fullscreen_btn, "FULLSCREEN: " + get_fullscreen_status(), func():
		play_click_sfx()
		toggle_fullscreen()
		fullscreen_btn.text = "FULLSCREEN: " + get_fullscreen_status()
	)
	options_panel.add_child(fullscreen_btn)
	
	# Volume mute/unmute
	var audio_btn = Button.new()
	audio_btn.position = Vector2(40, 125)
	audio_btn.size = Vector2(360, 40)
	setup_button(audio_btn, "MASTER AUDIO: ON", func():
		play_click_sfx()
		var current_bus = AudioServer.get_bus_index("Master")
		var is_muted = AudioServer.is_bus_mute(current_bus)
		AudioServer.set_bus_mute(current_bus, not is_muted)
		audio_btn.text = "MASTER AUDIO: " + ("OFF" if not is_muted else "ON")
	)
	options_panel.add_child(audio_btn)
	
	# Retro PS2 Shader placeholder toggle
	var shader_btn = Button.new()
	shader_btn.position = Vector2(40, 180)
	shader_btn.size = Vector2(360, 40)
	setup_button(shader_btn, "PS2 SCREEN SHADER: ON", func():
		play_click_sfx()
		if "ON" in shader_btn.text:
			shader_btn.text = "PS2 SCREEN SHADER: OFF"
		else:
			shader_btn.text = "PS2 SCREEN SHADER: ON"
	)
	options_panel.add_child(shader_btn)
	
	# BACK button
	var back_btn = Button.new()
	back_btn.position = Vector2(40, 250)
	back_btn.size = Vector2(120, 40)
	setup_button(back_btn, "BACK", func():
		play_click_sfx()
		options_panel.visible = false
		main_menu_container.visible = true
	)
	options_panel.add_child(back_btn)
	
	ui_layer.add_child(options_panel)

func setup_faq_panel():
	faq_panel = create_custom_panel("FAQ & INFORMATION")
	
	var text_info = RichTextLabel.new()
	text_info.bbcode_enabled = true
	text_info.text = "[center]FCCV: Interactive Developer Portfolio\n\nCreated solely by [color=#a7f3d0]Adil Basri ERDEM[/color].\n\nThis project is a playable showcase of atmosphere, shaders, and mechanical AI systems.\n\nWebsite: [url=http://www.teamhusk.com.tr]TEAM HUSK[/url]\nLinkedIn: [url=https://www.linkedin.com/in/adil-basri-erdem-189941249/]LINKEDIN[/url]\nEmail: [url=mailto:adilbasri06161@gmail.com]adilbasri06161@gmail.com[/url]\n\nPlay the demo of INTERRED on Steam![/center]"
	text_info.position = Vector2(20, 60)
	text_info.size = Vector2(400, 175)
	text_info.meta_clicked.connect(self._on_meta_clicked)
	
	text_info.add_theme_font_size_override("normal_font_size", 14)
	text_info.add_theme_font_size_override("bold_font_size", 14)
	text_info.add_theme_font_size_override("italics_font_size", 14)
	faq_panel.add_child(text_info)
	
	var back_btn = Button.new()
	back_btn.position = Vector2(40, 250)
	back_btn.size = Vector2(120, 40)
	setup_button(back_btn, "BACK", func():
		play_click_sfx()
		faq_panel.visible = false
		main_menu_container.visible = true
	)
	faq_panel.add_child(back_btn)
	
	ui_layer.add_child(faq_panel)

func setup_exit_popup():
	exit_popup = Panel.new()
	exit_popup.size = Vector2(320, 180)
	exit_popup.position = Vector2(160, 150) # Centered
	exit_popup.visible = false
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.04, 0.04, 0.95) # Dark crimson red horror tint
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.85, 0.25, 0.25) # Blood red warning borders
	style.corner_detail = 1
	exit_popup.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = "Are u sure about this?"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(0, 30)
	label.size = Vector2(320, 30)
	
	var font = LabelSettings.new()
	font.font_size = 18
	font.font_color = Color(1.0, 1.0, 1.0)
	label.label_settings = font
	exit_popup.add_child(label)
	
	var yes_btn = Button.new()
	yes_btn.position = Vector2(40, 100)
	yes_btn.size = Vector2(100, 40)
	setup_btn_centered(yes_btn, "YES")
	yes_btn.pressed.connect(func():
		play_click_sfx()
		print("Exit confirmed.")
		if OS.has_feature("web"):
			# Exit fullscreen on web before attempt closing
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			if Engine.has_singleton("JavaScriptBridge"):
				var js = Engine.get_singleton("JavaScriptBridge")
				js.eval("window.open('', '_self').close();")
		else:
			get_tree().quit()
	)
	exit_popup.add_child(yes_btn)
	
	var no_btn = Button.new()
	no_btn.position = Vector2(180, 100)
	no_btn.size = Vector2(100, 40)
	setup_btn_centered(no_btn, "NO")
	no_btn.pressed.connect(func():
		play_click_sfx()
		exit_popup.visible = false
		main_menu_container.visible = true
	)
	exit_popup.add_child(no_btn)
	
	ui_layer.add_child(exit_popup)

func setup_btn_centered(btn: Button, name_str: String):
	btn.text = name_str
	btn.flat = true
	btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.91, 0.12))
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.3, 0.3))
	btn.mouse_entered.connect(func():
		btn.text = "> " + name_str + " <"
		play_hover_sfx()
	)
	btn.mouse_exited.connect(func():
		btn.text = name_str
	)

func get_fullscreen_status() -> String:
	return "ON" if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else "OFF"

func toggle_fullscreen():
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_play_pressed():
	play_click_sfx()
	main_menu_container.visible = false

	# Fade to black over 2 seconds
	var fade = ColorRect.new()
	fade.color = Color(0,0,0,0)
	fade.anchor_left = 0.0
	fade.anchor_top = 0.0
	fade.anchor_right = 1.0
	fade.anchor_bottom = 1.0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade)

	var tween = create_tween()
	tween.tween_property(fade, "color", Color(0,0,0,1), 2.0)
	await tween.finished

	# Play entrance audio
	var entrance_audio = AudioStreamPlayer.new()
	entrance_audio.name = "EntranceAudio"
	entrance_audio.stream = load("res://enterence_sound.mp3")
	add_child(entrance_audio)
	entrance_audio.play()

	# Subtitle label (center-bottom)
	var subtitle = RichTextLabel.new()
	subtitle.bbcode_enabled = true
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
	subtitle.visible_ratio = 1.0
	subtitle.fit_content = true
	subtitle.custom_minimum_size = Vector2(800, 100)
	subtitle.custom_minimum_size = Vector2(900, 120)
	subtitle.anchor_left = 0.5
	subtitle.anchor_top = 1.0
	subtitle.anchor_right = 0.5
	subtitle.anchor_bottom = 1.0
	subtitle.offset_left = -450
	subtitle.offset_right = 450
	subtitle.offset_bottom = -30
	subtitle.offset_top = -130
	subtitle.add_theme_font_size_override("normal_font_size", 14)
	subtitle.add_theme_color_override("default_color", Color(1,1,1))
	fade_layer.add_child(subtitle)

	var lines = [
		{"text":"[center]Yeah, I know, I know I'm running late for the interview. I'm really sorry.[/center]", "duration":6},
		{"text":"[center]Look, my GPS just completely died on me.[/center]", "duration":3},
		{"text":"[center]I took a wrong turn somewhere off the main highway.[/center]", "duration":2},
		{"text":"[center]and now I'm stuck on this...[/center]", "duration":2},
		{"text":"[center]this awful dirt road in the middle of nowhere.[/center]", "duration":4},
		{"text":"[center]My car is acting up too, engine sounds terrible.[/center]", "duration":5},
		{"text":"[center]I really can't afford to break down out here.[/center]", "duration":3},
		{"text":"[center]Wait... hold on. I see some lights up ahead. Looks like an old house.[/center]", "duration":7},
		{"text":"[center]I'm gonna pull over and see if they can point me to the nearest gas station.[/center]", "duration":4},
		{"text":"[center]or at least let me use a landline.[/center]", "duration":4},
		{"text":"[center]I'll call you back as soon as I can. Wish me luck.[/center]", "duration":6}
	]

	var elapsed = 0.0
	for entry in lines:
		subtitle.clear()
		subtitle.append_text(entry.text)
	
		await get_tree().create_timer(entry.duration).timeout
		elapsed += entry.duration

	# After subtitles, short pause before scene change
	await get_tree().create_timer(1.0).timeout
	# Transition to world scene
	get_tree().change_scene_to_file("res://world.tscn")


func _on_options_pressed():
	play_click_sfx()
	main_menu_container.visible = false
	options_panel.visible = true

func _on_faq_pressed():
	play_click_sfx()
	main_menu_container.visible = false
	faq_panel.visible = true

func _on_exit_pressed():
	play_click_sfx()
	main_menu_container.visible = false
	exit_popup.visible = true

func _on_meta_clicked(meta):
	var url = str(meta)
	print("Menu link clicked: ", url)
	if OS.has_feature("web"):
		if Engine.has_singleton("JavaScriptBridge"):
			var js_bridge = Engine.get_singleton("JavaScriptBridge")
			js_bridge.eval("window.open('" + url + "', '_blank');")
	else:
		var err = OS.shell_open(url)
		if err != OK:
			print("OS.shell_open failed, attempting fallback...")
			OS.execute("open", [url])

func _process(delta):
	# 1. Update shifting CSG colors
	var time = Time.get_ticks_msec() / 1000.0
	if csg_material:
		# Slow breathing dark midnight colors (slightly lighter base to reflect headlight cones)
		var r = 0.08 + sin(time * 0.06) * 0.02
		var g = 0.06 + cos(time * 0.08) * 0.015
		var b = 0.12 + sin(time * 0.04) * 0.03
		csg_material.albedo_color = Color(r, g, b, 1.0)
		
	# 2. Highway obstacles/poles spawner (movement illusion)
	spawn_timer += delta
	if spawn_timer >= 0.7:
		spawn_timer = 0.0
		spawn_road_marker()
		
	# Move spawned poles backward along Z
	var markers_to_remove = []
	for marker in spawned_objects:
		if is_instance_valid(marker):
			marker.position.z += road_speed * delta
			if marker.position.z > 25.0:
				markers_to_remove.append(marker)
				marker.queue_free()
	for marker in markers_to_remove:
		spawned_objects.erase(marker)
		
	# 3. Car Shake and Sway engine updates
	update_car_physics(delta)

func spawn_road_marker():
	# Vertically oriented thin pole on the side of the road
	var marker = CSGBox3D.new()
	marker.size = Vector3(0.12, 3.0, 0.12)
	
	# Alternate left/right borders of the path
	alternate_side = not alternate_side
	var side_x = -7.5 if alternate_side else 7.5
	marker.position = Vector3(side_x, 1.5, -45.0) # Start far ahead
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.18, 0.18, 1.0)
	mat.roughness = 0.85
	marker.material = mat
	
	# Add a small retroreflective yellow marker at the top
	var reflector = CSGBox3D.new()
	reflector.size = Vector3(0.18, 0.4, 0.18)
	reflector.position = Vector3(0.0, 1.2, 0.0)
	
	var ref_mat = StandardMaterial3D.new()
	ref_mat.albedo_color = Color(1.0, 0.85, 0.1) # golden retro reflector
	ref_mat.emission_enabled = true
	ref_mat.emission = Color(1.0, 0.85, 0.1)
	ref_mat.emission_energy_multiplier = 2.5
	reflector.material = ref_mat
	
	marker.add_child(reflector)
	add_child(marker)
	spawned_objects.append(marker)

func update_car_physics(delta):
	# State machine timers
	state_timer += delta
	if state_timer >= state_duration:
		state_timer = 0.0
		# Randomly pick next behavior state (0 = standard vibe, 1 = swerve left, 2 = swerve right, 3 = rough bumps)
		current_movement_state = randi() % 4
		match current_movement_state:
			0: state_duration = randf_range(2.0, 4.5)
			1: state_duration = 2.0
			2: state_duration = 2.0
			3: state_duration = 3.0
			
	# Behavior calculation variables
	var vibe_y = sin(Time.get_ticks_msec() * 0.085) * 0.005
	var vibe_z = cos(Time.get_ticks_msec() * 0.065) * 0.0035
	
	var target_pos = volvo_base_pos
	var target_rot = volvo_base_rot
	
	var target_cam_pos = camera_base_pos
	var target_cam_rot = camera_base_rot
	
	# Continuous engine rumble shake for camera (adds weight/power feeling)
	target_cam_pos.y += sin(Time.get_ticks_msec() * 0.12) * 0.006
	target_cam_pos.x += cos(Time.get_ticks_msec() * 0.10) * 0.004
	
	# Default target parameters for audio and speed lines
	var target_engine_pitch = 1.0
	var target_engine_volume = -12.0
	var target_tire_volume = -80.0
	var target_particle_speed = 1.0
	var target_particle_alpha = 0.18
	
	match current_movement_state:
		0:
			# Normal engine vibration
			target_pos.y += vibe_y
			target_pos.z += vibe_z
			
			target_engine_pitch = 1.0 + sin(Time.get_ticks_msec() * 0.005) * 0.02
			target_engine_volume = -12.0
			target_tire_volume = -80.0
			target_particle_speed = 0.8
			target_particle_alpha = 0.12
		1:
			# Swerve Left and recover (gentle lateral drift curve)
			var progress = state_timer / state_duration
			var swerve = sin(progress * PI)
			target_pos.x += -swerve * 0.38
			target_rot.y += swerve * 0.06 # yaw tilt
			target_rot.z += swerve * 0.045 # roll tilt body weight
			target_pos.y += vibe_y
			
			# Camera slides opposite to swerve (simulating G-force / inertia)
			target_cam_pos.x += swerve * 0.22
			target_cam_rot.z += swerve * 0.015
			
			# Rev up engine on turn & squeal tires
			target_engine_pitch = 1.0 + swerve * 0.25
			target_engine_volume = -9.0
			target_tire_volume = lerp(-80.0, -18.0, swerve)
			
			# Increase speed lines on hard swerves
			target_particle_speed = lerp(0.8, 1.8, swerve)
			target_particle_alpha = lerp(0.12, 0.28, swerve)
		2:
			# Swerve Right and recover
			var progress = state_timer / state_duration
			var swerve = sin(progress * PI)
			target_pos.x += swerve * 0.38
			target_rot.y += -swerve * 0.06
			target_rot.z += -swerve * 0.045
			target_pos.y += vibe_y
			
			# Camera slides opposite to swerve
			target_cam_pos.x -= swerve * 0.22
			target_cam_rot.z -= swerve * 0.015
			
			# Rev up engine on turn & squeal tires
			target_engine_pitch = 1.0 + swerve * 0.25
			target_engine_volume = -9.0
			target_tire_volume = lerp(-80.0, -18.0, swerve)
			
			# Increase speed lines
			target_particle_speed = lerp(0.8, 1.8, swerve)
			target_particle_alpha = lerp(0.12, 0.28, swerve)
		3:
			# Bumpy road stretches (rapid shock frequencies)
			bump_timer += delta * 18.0
			var decay = 1.0 - (state_timer / state_duration)
			var bump = sin(bump_timer) * 0.065 * decay
			target_pos.y += bump + vibe_y
			target_rot.x += cos(bump_timer) * 0.016 * decay # pitch tilt nose up/down
			
			# High-frequency camera rattle
			var shake_factor = sin(bump_timer * 1.5) * 0.12 * decay
			target_cam_pos.y += shake_factor
			target_cam_pos.x += cos(bump_timer * 2.0) * 0.06 * decay
			target_cam_rot.x += shake_factor * 0.015
			
			# Engine vibrates with the road
			target_engine_pitch = 1.0 + sin(bump_timer) * 0.08 * decay
			target_engine_volume = -12.0 + sin(bump_timer) * 2.0 * decay
			target_tire_volume = -80.0
			
			# Modulate speed lines slightly with bumps
			target_particle_speed = 1.2
			target_particle_alpha = 0.16 + sin(bump_timer * 2.0) * 0.04 * decay
			
			# Play bump thud sound at peak deflection
			if decay > 0.15 and cos(bump_timer) > 0.9:
				if bump_audio_player and not bump_audio_player.playing:
					bump_audio_player.pitch_scale = randf_range(0.85, 1.15)
					bump_audio_player.volume_db = lerp(-25.0, -10.0, decay)
					bump_audio_player.play()
			
	# Smoothly interpolate car transformations
	if volvo:
		volvo.position = volvo.position.lerp(target_pos, delta * 11.0)
		volvo.rotation.x = lerp_angle(volvo.rotation.x, target_rot.x, delta * 8.0)
		volvo.rotation.y = lerp_angle(volvo.rotation.y, target_rot.y, delta * 8.0)
		volvo.rotation.z = lerp_angle(volvo.rotation.z, target_rot.z, delta * 8.0)
		
	# Smoothly interpolate camera transformations
	if camera:
		camera.position = camera.position.lerp(target_cam_pos, delta * 9.0)
		camera.rotation.x = lerp_angle(camera.rotation.x, target_cam_rot.x, delta * 7.0)
		camera.rotation.y = lerp_angle(camera.rotation.y, target_cam_rot.y, delta * 7.0)
		camera.rotation.z = lerp_angle(camera.rotation.z, target_cam_rot.z, delta * 7.0)
		
	# Interpolate vehicle audio
	if engine_audio_player:
		engine_audio_player.pitch_scale = lerp(engine_audio_player.pitch_scale, target_engine_pitch, delta * 5.0)
		engine_audio_player.volume_db = lerp(engine_audio_player.volume_db, target_engine_volume, delta * 5.0)
	if tire_audio_player:
		tire_audio_player.volume_db = lerp(tire_audio_player.volume_db, target_tire_volume, delta * 8.0)
		
	# Interpolate 3D speed particles parameters
	if speed_particles:
		speed_particles.speed_scale = lerp(speed_particles.speed_scale, target_particle_speed, delta * 3.0)
		var mesh = speed_particles.mesh
		if mesh and mesh.material:
			mesh.material.albedo_color.a = lerp(mesh.material.albedo_color.a, target_particle_alpha, delta * 3.0)
