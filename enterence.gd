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

# Settings state variables
var active_locale = "en"
var current_options_tab = "audio"
var current_faq_tab = "project"
var current_resolution_idx = 4
var current_subtitles_enabled = true
var current_colorblind_mode = 0

# UI Controls references
var play_btn: Button = null
var options_btn: Button = null
var faq_btn: Button = null
var exit_btn: Button = null

var exit_title_label: Label = null
var exit_yes_btn: Button = null
var exit_no_btn: Button = null
var no_btn: Button = null # keep compatibility

# Options Tab Buttons
var tab_audio_btn: Button = null
var tab_video_btn: Button = null
var tab_access_btn: Button = null
var tab_lang_btn: Button = null
var tab_back_btn: Button = null

# Options panels
var audio_panel: Control = null
var video_panel: Control = null
var access_panel: Control = null
var lang_panel: Control = null

# Audio labels & sliders
var master_label: Label = null
var master_slider: HSlider = null
var music_label: Label = null
var music_slider: HSlider = null
var sfx_label: Label = null
var sfx_slider: HSlider = null
var voice_label: Label = null
var voice_slider: HSlider = null

# Video labels & sliders
var fullscreen_btn: Button = null
var resolution_btn: Button = null
var shader_intensity_label: Label = null
var shader_intensity_slider: HSlider = null

# Accessibility labels & sliders
var subtitles_btn: Button = null
var colorblind_btn: Button = null
var mouse_sens_label: Label = null
var mouse_sens_slider: HSlider = null

# FAQ dossier controls
var faq_tab_proj_btn: Button = null
var faq_tab_tech_btn: Button = null
var faq_tab_contact_btn: Button = null
var faq_back_btn: Button = null
var faq_rich_label: RichTextLabel = null

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
	load_settings()
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
	hover_audio_player.bus = &"SFX"
	add_child(hover_audio_player)
	
	click_audio_player = AudioStreamPlayer.new()
	click_audio_player.name = "ClickAudioPlayer"
	click_audio_player.stream = generate_menu_sfx(380.0, 0.12) # mechanical click sound
	click_audio_player.volume_db = -10.0
	click_audio_player.bus = &"SFX"
	add_child(click_audio_player)

	# Procedural vehicle audio
	engine_audio_player = AudioStreamPlayer.new()
	engine_audio_player.name = "EngineAudioPlayer"
	engine_audio_player.stream = generate_engine_sound()
	engine_audio_player.volume_db = -12.0
	engine_audio_player.bus = &"SFX"
	add_child(engine_audio_player)
	engine_audio_player.play()
	
	tire_audio_player = AudioStreamPlayer.new()
	tire_audio_player.name = "TireAudioPlayer"
	tire_audio_player.stream = generate_tire_squeal_sound()
	tire_audio_player.volume_db = -80.0 # start muted
	tire_audio_player.bus = &"SFX"
	add_child(tire_audio_player)
	tire_audio_player.play()
	
	bump_audio_player = AudioStreamPlayer.new()
	bump_audio_player.name = "BumpAudioPlayer"
	bump_audio_player.stream = generate_bump_sound()
	bump_audio_player.volume_db = -10.0
	bump_audio_player.bus = &"SFX"
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
	play_btn = Button.new()
	setup_button(play_btn, "play", _on_play_pressed)
	main_menu_container.add_child(play_btn)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 10)
	main_menu_container.add_child(spacer1)
	
	options_btn = Button.new()
	setup_button(options_btn, "options", _on_options_pressed)
	main_menu_container.add_child(options_btn)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	main_menu_container.add_child(spacer2)
	
	faq_btn = Button.new()
	setup_button(faq_btn, "faq", _on_faq_pressed)
	main_menu_container.add_child(faq_btn)
	
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 10)
	main_menu_container.add_child(spacer3)
	
	exit_btn = Button.new()
	setup_button(exit_btn, "exit", _on_exit_pressed)
	main_menu_container.add_child(exit_btn)
	
	ui_layer.add_child(main_menu_container)
	
	# Submenus setup
	setup_options_panel()
	setup_faq_panel()
	setup_exit_popup()

func setup_button(btn: Button, translation_key: String, pressed_callable: Callable):
	btn.set_meta("translation_key", translation_key)
	btn.flat = true
	btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75)) # light grey
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.91, 0.12)) # retro yellow gold
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.3, 0.3)) # click red
	
	btn.mouse_entered.connect(func():
		var tk = btn.get_meta("translation_key")
		if tk == current_options_tab and options_panel and options_panel.visible: return
		var display_text = menu_locales[active_locale].get(tk, tk)
		btn.text = "> " + display_text
		play_hover_sfx()
	)
	btn.mouse_exited.connect(func():
		var tk = btn.get_meta("translation_key")
		if tk == current_options_tab and options_panel and options_panel.visible: return
		var display_text = menu_locales[active_locale].get(tk, tk)
		btn.text = "  " + display_text
	)
	btn.pressed.connect(pressed_callable)

func create_custom_panel(title_text: String) -> Panel:
	var panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -325
	panel.offset_top = -200
	panel.offset_right = 325
	panel.offset_bottom = 200
	panel.visible = false
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.08, 0.95) # Semi-transparent dark charcoal blue
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.33, 0.35) # Dark grey border
	style.corner_detail = 1
	panel.add_theme_stylebox_override("panel", style)
	
	# Header title Label
	var header = Label.new()
	header.text = title_text
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.position = Vector2(0, 15)
	header.size = Vector2(650, 30)
	
	var font = LabelSettings.new()
	font.font_size = 22
	font.font_color = Color(1.0, 0.91, 0.12) # Gold title
	header.label_settings = font
	panel.add_child(header)
	
	return panel

func setup_options_panel():
	options_panel = create_custom_panel("OPTIONS")
	
	# Left sidebar tab selector container
	var sidebar = VBoxContainer.new()
	sidebar.position = Vector2(15, 60)
	sidebar.size = Vector2(160, 320)
	options_panel.add_child(sidebar)
	
	tab_audio_btn = Button.new()
	setup_button(tab_audio_btn, "audio", func():
		play_click_sfx()
		select_options_tab("audio")
	)
	sidebar.add_child(tab_audio_btn)
	
	var s1 = Control.new()
	s1.custom_minimum_size = Vector2(0, 5)
	sidebar.add_child(s1)
	
	tab_video_btn = Button.new()
	setup_button(tab_video_btn, "video", func():
		play_click_sfx()
		select_options_tab("video")
	)
	sidebar.add_child(tab_video_btn)
	
	var s2 = Control.new()
	s2.custom_minimum_size = Vector2(0, 5)
	sidebar.add_child(s2)
	
	tab_access_btn = Button.new()
	setup_button(tab_access_btn, "accessibility", func():
		play_click_sfx()
		select_options_tab("accessibility")
	)
	sidebar.add_child(tab_access_btn)
	
	var s3 = Control.new()
	s3.custom_minimum_size = Vector2(0, 5)
	sidebar.add_child(s3)
	
	tab_lang_btn = Button.new()
	setup_button(tab_lang_btn, "language", func():
		play_click_sfx()
		select_options_tab("language")
	)
	sidebar.add_child(tab_lang_btn)
	
	var s4 = Control.new()
	s4.custom_minimum_size = Vector2(0, 20)
	sidebar.add_child(s4)
	
	tab_back_btn = Button.new()
	setup_button(tab_back_btn, "back", func():
		play_click_sfx()
		options_panel.visible = false
		main_menu_container.visible = true
	)
	sidebar.add_child(tab_back_btn)
	
	# Right side tab contents container
	var content_container = Control.new()
	content_container.position = Vector2(190, 60)
	content_container.size = Vector2(440, 320)
	options_panel.add_child(content_container)
	
	# 1. AUDIO PANEL
	audio_panel = Control.new()
	audio_panel.size = Vector2(440, 320)
	content_container.add_child(audio_panel)
	
	master_label = Label.new()
	master_slider = HSlider.new()
	setup_audio_slider(master_label, master_slider, "master_volume", 10, func(val):
		set_menu_bus_volume("Master", val)
		update_audio_labels()
		save_settings()
	)
	audio_panel.add_child(master_label)
	audio_panel.add_child(master_slider)
	
	music_label = Label.new()
	music_slider = HSlider.new()
	setup_audio_slider(music_label, music_slider, "music_volume", 80, func(val):
		set_menu_bus_volume("Music", val)
		update_audio_labels()
		save_settings()
	)
	audio_panel.add_child(music_label)
	audio_panel.add_child(music_slider)
	
	sfx_label = Label.new()
	sfx_slider = HSlider.new()
	setup_audio_slider(sfx_label, sfx_slider, "sfx_volume", 150, func(val):
		set_menu_bus_volume("SFX", val)
		update_audio_labels()
		save_settings()
	)
	audio_panel.add_child(sfx_label)
	audio_panel.add_child(sfx_slider)
	
	voice_label = Label.new()
	voice_slider = HSlider.new()
	setup_audio_slider(voice_label, voice_slider, "voice_volume", 220, func(val):
		set_menu_bus_volume("Voice", val)
		update_audio_labels()
		save_settings()
	)
	audio_panel.add_child(voice_label)
	audio_panel.add_child(voice_slider)
	
	# 2. VIDEO PANEL
	video_panel = Control.new()
	video_panel.size = Vector2(440, 320)
	video_panel.visible = false
	content_container.add_child(video_panel)
	
	fullscreen_btn = Button.new()
	fullscreen_btn.position = Vector2(20, 20)
	fullscreen_btn.size = Vector2(380, 40)
	setup_button(fullscreen_btn, "fullscreen", func():
		play_click_sfx()
		toggle_fullscreen()
		update_video_labels()
		save_settings()
	)
	video_panel.add_child(fullscreen_btn)
	
	resolution_btn = Button.new()
	resolution_btn.position = Vector2(20, 80)
	resolution_btn.size = Vector2(380, 40)
	setup_button(resolution_btn, "resolution", func():
		play_click_sfx()
		current_resolution_idx = (current_resolution_idx + 1) % 5
		var resolutions = [
			Vector2i(640, 480),
			Vector2i(800, 600),
			Vector2i(1024, 768),
			Vector2i(1280, 720),
			Vector2i(1920, 1080)
		]
		var res = resolutions[current_resolution_idx]
		DisplayServer.window_set_size(res)
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN and DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
			var screen_id = DisplayServer.window_get_current_screen()
			var screen_size = DisplayServer.screen_get_size(screen_id)
			DisplayServer.window_set_position((screen_size - res) / 2)
		update_video_labels()
		save_settings()
	)
	video_panel.add_child(resolution_btn)
	
	shader_intensity_label = Label.new()
	shader_intensity_slider = HSlider.new()
	setup_audio_slider(shader_intensity_label, shader_intensity_slider, "shader_intensity", 150, func(val):
		update_video_labels()
		save_settings()
	)
	# Reuse layout helper for shader intensity slider
	shader_intensity_slider.min_value = 0.0
	shader_intensity_slider.max_value = 1.0
	shader_intensity_slider.step = 0.05
	video_panel.add_child(shader_intensity_label)
	video_panel.add_child(shader_intensity_slider)
	
	# 3. ACCESSIBILITY PANEL
	access_panel = Control.new()
	access_panel.size = Vector2(440, 320)
	access_panel.visible = false
	content_container.add_child(access_panel)
	
	subtitles_btn = Button.new()
	subtitles_btn.position = Vector2(20, 20)
	subtitles_btn.size = Vector2(380, 40)
	setup_button(subtitles_btn, "subtitles", func():
		play_click_sfx()
		current_subtitles_enabled = not current_subtitles_enabled
		update_accessibility_labels()
		save_settings()
	)
	access_panel.add_child(subtitles_btn)
	
	colorblind_btn = Button.new()
	colorblind_btn.position = Vector2(20, 80)
	colorblind_btn.size = Vector2(380, 40)
	setup_button(colorblind_btn, "colorblind_mode", func():
		play_click_sfx()
		current_colorblind_mode = (current_colorblind_mode + 1) % 4
		update_accessibility_labels()
		save_settings()
	)
	access_panel.add_child(colorblind_btn)
	
	mouse_sens_label = Label.new()
	mouse_sens_slider = HSlider.new()
	setup_audio_slider(mouse_sens_label, mouse_sens_slider, "mouse_sensitivity", 150, func(val):
		update_accessibility_labels()
		save_settings()
	)
	mouse_sens_slider.min_value = 0.2
	mouse_sens_slider.max_value = 3.0
	mouse_sens_slider.step = 0.1
	access_panel.add_child(mouse_sens_label)
	access_panel.add_child(mouse_sens_slider)
	
	# 4. LANGUAGE PANEL
	lang_panel = Control.new()
	lang_panel.size = Vector2(440, 320)
	lang_panel.visible = false
	content_container.add_child(lang_panel)
	
	var lang_grid = GridContainer.new()
	lang_grid.columns = 2
	lang_grid.position = Vector2(20, 30)
	lang_grid.size = Vector2(380, 240)
	lang_grid.add_theme_constant_override("h_separation", 20)
	lang_grid.add_theme_constant_override("v_separation", 15)
	lang_panel.add_child(lang_grid)
	
	var languages = [
		{"name": "ENGLISH", "code": "en"},
		{"name": "TÜRKÇE", "code": "tr"},
		{"name": "DEUTSCH", "code": "de"},
		{"name": "ITALIANO", "code": "it"},
		{"name": "FRANÇAIS", "code": "fr"},
		{"name": "ESPAÑOL", "code": "es"}
	]
	for l in languages:
		var btn = Button.new()
		setup_language_btn(btn, l.name, l.code)
		lang_grid.add_child(btn)
		
	# Select default tab
	select_options_tab("audio")
	ui_layer.add_child(options_panel)

func setup_audio_slider(label_ref: Label, slider_ref: HSlider, translation_key: String, y_pos: float, changed_callable: Callable):
	label_ref.position = Vector2(20, y_pos)
	label_ref.size = Vector2(400, 30)
	
	var label_settings = LabelSettings.new()
	label_settings.font_size = 16
	label_settings.font_color = Color(0.9, 0.9, 0.9)
	label_ref.label_settings = label_settings
	
	slider_ref.position = Vector2(20, y_pos + 30)
	slider_ref.size = Vector2(380, 20)
	slider_ref.min_value = 0.0
	slider_ref.max_value = 1.0
	slider_ref.step = 0.05
	slider_ref.value = 1.0
	
	slider_ref.value_changed.connect(changed_callable)

func setup_language_btn(btn: Button, lang_name: String, locale: String):
	btn.text = lang_name
	btn.flat = true
	btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.91, 0.12))
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.3, 0.3))
	
	btn.mouse_entered.connect(func():
		btn.text = "> " + lang_name + " <"
		play_hover_sfx()
	)
	btn.mouse_exited.connect(func():
		btn.text = lang_name
	)
	btn.pressed.connect(func():
		play_click_sfx()
		active_locale = locale
		save_settings()
		apply_menu_localization()
		select_options_tab("language")
	)

func select_options_tab(tab_name: String):
	current_options_tab = tab_name
	audio_panel.visible = (tab_name == "audio")
	video_panel.visible = (tab_name == "video")
	access_panel.visible = (tab_name == "accessibility")
	lang_panel.visible = (tab_name == "language")
	
	for btn in [tab_audio_btn, tab_video_btn, tab_access_btn, tab_lang_btn]:
		var tk = btn.get_meta("translation_key")
		var display_text = menu_locales[active_locale].get(tk, tk)
		if tk == tab_name:
			btn.text = "> " + display_text
			btn.add_theme_color_override("font_color", Color(1.0, 0.91, 0.12))
		else:
			btn.text = "  " + display_text
			btn.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))

func setup_faq_panel():
	faq_panel = create_custom_panel("DOSSIER")
	
	# Left sidebar tabs
	var sidebar = VBoxContainer.new()
	sidebar.position = Vector2(15, 60)
	sidebar.size = Vector2(160, 320)
	faq_panel.add_child(sidebar)
	
	faq_tab_proj_btn = Button.new()
	setup_button(faq_tab_proj_btn, "dossier_proj", func():
		play_click_sfx()
		select_faq_tab("project")
	)
	sidebar.add_child(faq_tab_proj_btn)
	
	var s1 = Control.new()
	s1.custom_minimum_size = Vector2(0, 5)
	sidebar.add_child(s1)
	
	faq_tab_tech_btn = Button.new()
	setup_button(faq_tab_tech_btn, "dossier_tech", func():
		play_click_sfx()
		select_faq_tab("tech")
	)
	sidebar.add_child(faq_tab_tech_btn)
	
	var s2 = Control.new()
	s2.custom_minimum_size = Vector2(0, 5)
	sidebar.add_child(s2)
	
	faq_tab_contact_btn = Button.new()
	setup_button(faq_tab_contact_btn, "dossier_contact", func():
		play_click_sfx()
		select_faq_tab("contact")
	)
	sidebar.add_child(faq_tab_contact_btn)
	
	var s3 = Control.new()
	s3.custom_minimum_size = Vector2(0, 40)
	sidebar.add_child(s3)
	
	faq_back_btn = Button.new()
	setup_button(faq_back_btn, "back", func():
		play_click_sfx()
		faq_panel.visible = false
		main_menu_container.visible = true
	)
	sidebar.add_child(faq_back_btn)
	
	# Right side Rich Text Label
	faq_rich_label = RichTextLabel.new()
	faq_rich_label.bbcode_enabled = true
	faq_rich_label.position = Vector2(190, 60)
	faq_rich_label.size = Vector2(440, 240)
	faq_rich_label.meta_clicked.connect(self._on_meta_clicked)
	faq_rich_label.add_theme_font_size_override("normal_font_size", 14)
	faq_rich_label.add_theme_font_size_override("bold_font_size", 14)
	faq_rich_label.add_theme_font_size_override("italics_font_size", 14)
	faq_panel.add_child(faq_rich_label)
	
	# Select default tab
	select_faq_tab("project")
	ui_layer.add_child(faq_panel)

func select_faq_tab(tab_name: String):
	current_faq_tab = tab_name
	update_faq_content()
	
	for btn in [faq_tab_proj_btn, faq_tab_tech_btn, faq_tab_contact_btn]:
		var tk = btn.get_meta("translation_key")
		var display_text = menu_locales[active_locale].get(tk, tk)
		if tk == "dossier_" + tab_name:
			btn.text = "> " + display_text
			btn.add_theme_color_override("font_color", Color(1.0, 0.91, 0.12))
		else:
			btn.text = "  " + display_text
			btn.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))

func setup_exit_popup():
	exit_popup = Panel.new()
	exit_popup.name = "ExitPopup"
	exit_popup.anchor_left = 0.5
	exit_popup.anchor_top = 0.5
	exit_popup.anchor_right = 0.5
	exit_popup.anchor_bottom = 0.5
	exit_popup.offset_left = -200
	exit_popup.offset_top = -100
	exit_popup.offset_right = 200
	exit_popup.offset_bottom = 100
	exit_popup.visible = false
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.04, 0.04, 0.95) # Dark crimson red horror tint
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.85, 0.25, 0.25) # Blood red warning borders
	style.corner_detail = 1
	exit_popup.add_theme_stylebox_override("panel", style)
	
	exit_title_label = Label.new()
	exit_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exit_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	exit_title_label.position = Vector2(0, 40)
	exit_title_label.size = Vector2(400, 30)
	
	var font = LabelSettings.new()
	font.font_size = 18
	font.font_color = Color(1.0, 1.0, 1.0)
	exit_title_label.label_settings = font
	exit_popup.add_child(exit_title_label)
	
	exit_yes_btn = Button.new()
	exit_yes_btn.position = Vector2(60, 110)
	exit_yes_btn.size = Vector2(100, 40)
	setup_btn_centered(exit_yes_btn, "yes")
	exit_yes_btn.pressed.connect(func():
		play_click_sfx()
		print("Exit confirmed.")
		if OS.has_feature("web"):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			if Engine.has_singleton("JavaScriptBridge"):
				var js = Engine.get_singleton("JavaScriptBridge")
				js.eval("window.open('', '_self').close();")
		else:
			get_tree().quit()
	)
	exit_popup.add_child(exit_yes_btn)
	
	exit_no_btn = Button.new()
	exit_no_btn.position = Vector2(240, 110)
	exit_no_btn.size = Vector2(100, 40)
	setup_btn_centered(exit_no_btn, "no")
	no_btn = exit_no_btn # keep compatibility
	exit_no_btn.pressed.connect(func():
		play_click_sfx()
		exit_popup.visible = false
		main_menu_container.visible = true
	)
	exit_popup.add_child(exit_no_btn)
	
	ui_layer.add_child(exit_popup)

func setup_btn_centered(btn: Button, translation_key: String):
	btn.set_meta("translation_key", translation_key)
	btn.flat = true
	btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.91, 0.12))
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.3, 0.3))
	btn.mouse_entered.connect(func():
		var tk = btn.get_meta("translation_key")
		var display_text = menu_locales[active_locale].get(tk, tk)
		btn.text = "> " + display_text + " <"
		play_hover_sfx()
	)
	btn.mouse_exited.connect(func():
		var tk = btn.get_meta("translation_key")
		var display_text = menu_locales[active_locale].get(tk, tk)
		btn.text = display_text
	)

func get_fullscreen_status() -> String:
	var mode = DisplayServer.window_get_mode()
	return "ON" if mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_FULLSCREEN else "OFF"

func toggle_fullscreen():
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

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
	entrance_audio.bus = &"SFX" # Route to SFX bus
	add_child(entrance_audio)
	entrance_audio.play()
	
	# Subtitle label (center-bottom)
	var subtitle = RichTextLabel.new()
	subtitle.bbcode_enabled = true
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
	subtitle.visible_ratio = 1.0
	subtitle.fit_content = true
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
	
	# Dynamic intro subtitles localization from database
	var raw_subs = menu_locales[active_locale].get("intro_subtitles", [])
	var lines = []
	var durations = [6, 3, 2, 2, 4, 5, 3, 7, 4, 4, 6]
	for idx in range(min(raw_subs.size(), durations.size())):
		lines.append({"text": "[center]" + raw_subs[idx] + "[/center]", "duration": durations[idx]})
		
	for entry in lines:
		subtitle.clear()
		if current_subtitles_enabled:
			subtitle.append_text(entry.text)
		await get_tree().create_timer(entry.duration).timeout
		
	# After subtitles, short pause before scene change
	await get_tree().create_timer(1.0).timeout
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

# Settings persistence & Localization functions
func save_settings():
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	
	config.set_value("audio", "master", master_slider.value if master_slider else 1.0)
	config.set_value("audio", "music", music_slider.value if music_slider else 1.0)
	config.set_value("audio", "sfx", sfx_slider.value if sfx_slider else 1.0)
	config.set_value("audio", "voice", voice_slider.value if voice_slider else 1.0)
	
	var is_fs = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	config.set_value("video", "fullscreen", is_fs)
	config.set_value("video", "resolution", current_resolution_idx)
	config.set_value("video", "shader_intensity", shader_intensity_slider.value if shader_intensity_slider else 1.0)
	
	config.set_value("accessibility", "subtitles", current_subtitles_enabled)
	config.set_value("accessibility", "colorblind_mode", current_colorblind_mode)
	config.set_value("accessibility", "mouse_sensitivity", mouse_sens_slider.value if mouse_sens_slider else 1.0)
	
	config.set_value("language", "locale", active_locale)
	
	config.save("user://settings.cfg")
	print("Settings saved to user://settings.cfg")

func load_settings():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		active_locale = config.get_value("language", "locale", "en").to_lower()
		
		var volume_master = config.get_value("audio", "master", 1.0)
		var volume_music = config.get_value("audio", "music", 1.0)
		var volume_sfx = config.get_value("audio", "sfx", 1.0)
		var volume_voice = config.get_value("audio", "voice", 1.0)
		
		if master_slider: master_slider.value = volume_master
		if music_slider: music_slider.value = volume_music
		if sfx_slider: sfx_slider.value = volume_sfx
		if voice_slider: voice_slider.value = volume_voice
		
		set_menu_bus_volume("Master", volume_master)
		set_menu_bus_volume("Music", volume_music)
		set_menu_bus_volume("SFX", volume_sfx)
		set_menu_bus_volume("Voice", volume_voice)
		
		var is_fs = config.get_value("video", "fullscreen", false)
		if is_fs:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			
		current_resolution_idx = config.get_value("video", "resolution", 4)
		var resolutions = [
			Vector2i(640, 480),
			Vector2i(800, 600),
			Vector2i(1024, 768),
			Vector2i(1280, 720),
			Vector2i(1920, 1080)
		]
		if current_resolution_idx >= 0 and current_resolution_idx < resolutions.size():
			var res = resolutions[current_resolution_idx]
			DisplayServer.window_set_size(res)
			if not is_fs:
				var screen_id = DisplayServer.window_get_current_screen()
				var screen_size = DisplayServer.screen_get_size(screen_id)
				DisplayServer.window_set_position((screen_size - res) / 2)
				
		var shader_intensity = config.get_value("video", "shader_intensity", 1.0)
		if shader_intensity_slider: shader_intensity_slider.value = shader_intensity
		
		current_subtitles_enabled = config.get_value("accessibility", "subtitles", true)
		current_colorblind_mode = config.get_value("accessibility", "colorblind_mode", 0)
		
		var sens = config.get_value("accessibility", "mouse_sensitivity", 1.0)
		if mouse_sens_slider: mouse_sens_slider.value = sens
		
		print("Settings loaded successfully from config.")
	else:
		print("No settings file found. Using default UI values.")
		active_locale = "en"
		current_resolution_idx = 4
		current_subtitles_enabled = true
		current_colorblind_mode = 0
		
	apply_menu_localization()

func set_menu_bus_volume(bus_name: String, volume_linear: float):
	ensure_menu_bus_exists("Master")
	ensure_menu_bus_exists(bus_name, "Master")
	var idx = AudioServer.get_bus_index(bus_name)
	if idx != -1:
		var db = linear_to_db(volume_linear) if volume_linear > 0.0 else -80.0
		AudioServer.set_bus_volume_db(idx, db)

func ensure_menu_bus_exists(bus_name: String, send_to: String = ""):
	var idx = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, bus_name)
	if send_to != "":
		var send_idx = AudioServer.get_bus_index(send_to)
		if send_idx != -1:
			AudioServer.set_bus_send(idx, send_to)

func apply_menu_localization():
	var data = menu_locales[active_locale]
	
	for btn in [play_btn, options_btn, faq_btn, exit_btn, tab_audio_btn, tab_video_btn, tab_access_btn, tab_lang_btn, tab_back_btn, faq_tab_proj_btn, faq_tab_tech_btn, faq_tab_contact_btn, faq_back_btn]:
		if btn and btn.has_meta("translation_key"):
			var tk = btn.get_meta("translation_key")
			var display_text = menu_locales[active_locale].get(tk, tk)
			if tk == current_options_tab and options_panel and options_panel.visible:
				btn.text = "> " + display_text
			elif tk == "dossier_" + current_faq_tab and faq_panel and faq_panel.visible:
				btn.text = "> " + display_text
			else:
				btn.text = "  " + display_text
				
	if exit_title_label: exit_title_label.text = data["are_you_sure"]
	for btn in [exit_yes_btn, exit_no_btn]:
		if btn and btn.has_meta("translation_key"):
			var tk = btn.get_meta("translation_key")
			var display_text = menu_locales[active_locale].get(tk, tk)
			btn.text = display_text
			
	update_audio_labels()
	update_video_labels()
	update_accessibility_labels()
	update_faq_content()

func update_audio_labels():
	var data = menu_locales[active_locale]
	if master_label and master_slider:
		master_label.text = data["master_volume"] % int(master_slider.value * 100)
	if music_label and music_slider:
		music_label.text = data["music_volume"] % int(music_slider.value * 100)
	if sfx_label and sfx_slider:
		sfx_label.text = data["sfx_volume"] % int(sfx_slider.value * 100)
	if voice_label and voice_slider:
		voice_label.text = data["voice_volume"] % int(voice_slider.value * 100)

func update_video_labels():
	var data = menu_locales[active_locale]
	if fullscreen_btn:
		var fs_str = data["on"] if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else data["off"]
		fullscreen_btn.text = "  " + (data["fullscreen"] % fs_str)
	if resolution_btn:
		var resolutions = ["640x480", "800x600", "1024x768", "1280x720", "1920x1080"]
		var res_str = resolutions[clamp(current_resolution_idx, 0, resolutions.size() - 1)]
		resolution_btn.text = "  " + (data["resolution"] % res_str)
	if shader_intensity_label and shader_intensity_slider:
		shader_intensity_label.text = data["shader_intensity"] % int(shader_intensity_slider.value * 100)

func update_accessibility_labels():
	var data = menu_locales[active_locale]
	if subtitles_btn:
		var sub_str = data["on"] if current_subtitles_enabled else data["off"]
		subtitles_btn.text = "  " + (data["subtitles"] % sub_str)
	if colorblind_btn:
		var cb_modes = [data["cb_none"], data["cb_protanopia"], data["cb_deuteranopia"], data["cb_tritanopia"]]
		var cb_str = cb_modes[clamp(current_colorblind_mode, 0, cb_modes.size() - 1)]
		colorblind_btn.text = "  " + (data["colorblind_mode"] % cb_str)
	if mouse_sens_label and mouse_sens_slider:
		mouse_sens_label.text = data["mouse_sensitivity"] % mouse_sens_slider.value

func update_faq_content():
	var data = menu_locales[active_locale]
	if faq_rich_label:
		if current_faq_tab == "project":
			faq_rich_label.text = data["dossier_proj_text"]
		elif current_faq_tab == "tech":
			faq_rich_label.text = data["dossier_tech_text"]
		elif current_faq_tab == "contact":
			faq_rich_label.text = data["dossier_contact_text"]

var menu_locales = {
	"en": {
		"play": "PLAY",
		"options": "OPTIONS",
		"faq": "DOSSIER",
		"exit": "EXIT",
		"are_you_sure": "Are you sure you want to exit?",
		"yes": "YES",
		"no": "NO",
		"audio": "AUDIO",
		"video": "VIDEO",
		"accessibility": "ACCESSIBILITY",
		"language": "LANGUAGE",
		"back": "BACK",
		"master_volume": "Master Volume: %d%%",
		"music_volume": "Music Volume: %d%%",
		"sfx_volume": "SFX Volume: %d%%",
		"voice_volume": "Voice Volume: %d%%",
		"fullscreen": "Fullscreen: %s",
		"resolution": "Resolution: %s",
		"shader_intensity": "PS2 Shader Intensity: %d%%",
		"subtitles": "Subtitles: %s",
		"colorblind_mode": "Colorblind: %s",
		"mouse_sensitivity": "Mouse Sensitivity: %.1fx",
		"on": "ON",
		"off": "OFF",
		"cb_none": "None",
		"cb_protanopia": "Protanopia",
		"cb_deuteranopia": "Deuteranopia",
		"cb_tritanopia": "Tritanopia",
		"dossier_proj": "PROJECT INFO",
		"dossier_tech": "TECH STACK",
		"dossier_contact": "CONTACTS",
		"dossier_proj_text": "[center][color=#e2e8f0]PROJECT DOSSIER[/color]\n\nThis project is an interactive psychological horror experience serving as a playable developer portfolio.\n\nIt features real-time procedural audio, a nostalgic PS2 screen filter, custom physics-based lighting, and atmospheric soundscapes designed to showcase game programming capabilities.[/center]",
		"dossier_tech_text": "[center][color=#e2e8f0]TECHNOLOGY INVENTORY[/color]\n\n[color=#fbcfe8]Engine:[/color] Godot 4.x\n[color=#fbcfe8]Logic:[/color] 100% pure GDScript\n[color=#fbcfe8]Visuals:[/color] PS2 retro shader with integrated colorblind correction matrix uniforms\n[color=#fbcfe8]Audio:[/color] Procedural sound waves and dynamic sound bus routing[/center]",
		"dossier_contact_text": "[center][color=#e2e8f0]CONTACT CHANNELS[/color]\n\nFeel free to explore the archives and initiate contact:\n\n[url=https://www.linkedin.com/in/adil-basri-erdem-189941249/][color=#60a5fa]LINKEDIN LOGS[/color][/url]\n\n[url=mailto:adilbasri06161@gmail.com][color=#60a5fa]DIRECT MAIL PROTOCOL[/color][/url]\n\n[url=http://www.teamhusk.com.tr][color=#60a5fa]TEAM HUSK ARCHIVES[/color][/url]\n\nPlay INTERRED demo on Steam![/center]",
		"intro_subtitles": [
			"Yeah, I know, I know I'm running late for the interview. I'm really sorry.",
			"Look, my GPS just completely died on me.",
			"I took a wrong turn somewhere off the main highway.",
			"and now I'm stuck on this...",
			"this awful dirt road in the middle of nowhere.",
			"My car is acting up too, engine sounds terrible.",
			"I really can't afford to break down out here.",
			"Wait... hold on. I see some lights up ahead. Looks like an old house.",
			"I'm gonna pull over and see if they can point me to the nearest gas station.",
			"or at least let me use a landline.",
			"I'll call you back as soon as I can. Wish me luck."
		]
	},
	"tr": {
		"play": "OYNA",
		"options": "AYARLAR",
		"faq": "DOSYA",
		"exit": "ÇIKIŞ",
		"are_you_sure": "Çıkmak istediğinize emin misiniz?",
		"yes": "EVET",
		"no": "HAYIR",
		"audio": "SES",
		"video": "GÖRÜNTÜ",
		"accessibility": "ERİŞİLEBİLİRLİK",
		"language": "DİL",
		"back": "GERİ",
		"master_volume": "Ana Ses: %d%%",
		"music_volume": "Müzik Sesi: %d%%",
		"sfx_volume": "Efekt Sesi: %d%%",
		"voice_volume": "Konuşma Sesi: %d%%",
		"fullscreen": "Tam Ekran: %s",
		"resolution": "Çözünürlük: %s",
		"shader_intensity": "PS2 Shader Yoğunluğu: %d%%",
		"subtitles": "Altyazı: %s",
		"colorblind_mode": "Renk Körü: %s",
		"mouse_sensitivity": "Fare Hassasiyeti: %.1fx",
		"on": "AÇIK",
		"off": "KAPALI",
		"cb_none": "Yok",
		"cb_protanopia": "Protanopi",
		"cb_deuteranopia": "Deuteranopi",
		"cb_tritanopia": "Tritanopi",
		"dossier_proj": "PROJE BİLGİSİ",
		"dossier_tech": "TEKNOLOJİLER",
		"dossier_contact": "İLETİŞİM",
		"dossier_proj_text": "[center][color=#e2e8f0]PROJE DOSYASI[/color]\n\nBu proje, oynanabilir bir Geliştirici Portfolyosu olarak hizmet veren interaktif bir psikolojik korku deneyimidir.\n\nOyun programlama yeteneklerini sergilemek amacıyla gerçek zamanlı prosedürel ses sentezi, nostaljik bir PS2 ekran filtresi, fizik tabanlı aydınlatma ve atmosferik ses tasarımları içerir.[/center]",
		"dossier_tech_text": "[center][color=#e2e8f0]TEKNOLOJİ ENVANTERİ[/color]\n\n[color=#fbcfe8]Motor:[/color] Godot 4.x\n[color=#fbcfe8]Mantık:[/color] %100 saf GDScript\n[color=#fbcfe8]Görsel:[/color] Entegre renk körlüğü düzeltme matrislerine sahip PS2 retro shader\n[color=#fbcfe8]Ses:[/color] Prosedürel ses dalgaları ve dinamik ses veri yolu yönlendirmesi[/center]",
		"dossier_contact_text": "[center][color=#e2e8f0]İLETİŞİM KANALLARI[/color]\n\nArşivleri incelemek ve doğrudan iletişime geçmek için:\n\n[url=https://www.linkedin.com/in/adil-basri-erdem-189941249/][color=#60a5fa]LINKEDIN ARŞİVİ[/color][/url]\n\n[url=mailto:adilbasri06161@gmail.com][color=#60a5fa]DOĞRUDAN E-POSTA[/color][/url]\n\n[url=http://www.teamhusk.com.tr][color=#60a5fa]TEAM HUSK ARŞİVLERİ[/color][/url]\n\nSteam'de INTERRED demosunu oynayın![/center]",
		"intro_subtitles": [
			"Evet biliyorum, biliyorum mülakata geç kalıyorum. Gerçekten çok üzgünüm.",
			"Bak, GPS'im tamamen kapandı.",
			"Ana otoyoldan çıkıp bir yerde yanlış yola saptım.",
			"ve şimdi burada sıkışıp kaldım...",
			"hiçliğin ortasındaki bu berbat toprak yolda.",
			"Arabam da sorun çıkarıyor, motor sesi berbat geliyor.",
			"Burada yolda kalmayı gerçekten göze alamam.",
			"Bekle... dur bir saniye. İleride bazı ışıklar görüyorum. Eski bir ev gibi görünüyor.",
			"Kenara çekip bana en yakın benzin istasyonunu gösterebilirler mi bakacağım.",
			"ya da en azından sabit bir telefon kullanmama izin verirler.",
			"En kısa sürede seni tekrar arayacağım. Bana şans dile."
		]
	},
	"de": {
		"play": "SPIELEN",
		"options": "OPTIONEN",
		"faq": "DOSSIER",
		"exit": "BEENDEN",
		"are_you_sure": "Möchten Sie das Spiel wirklich beenden?",
		"yes": "JA",
		"no": "NEIN",
		"audio": "AUDIO",
		"video": "GRAFIK",
		"accessibility": "BARRIEREFREIHEIT",
		"language": "SPRACHE",
		"back": "ZURÜCK",
		"master_volume": "Gesamtlautstärke: %d%%",
		"music_volume": "Musiklautstärke: %d%%",
		"sfx_volume": "Effektlautstärke: %d%%",
		"voice_volume": "Stimmenlautstärke: %d%%",
		"fullscreen": "Vollbild: %s",
		"resolution": "Auflösung: %s",
		"shader_intensity": "PS2-Shaderstärke: %d%%",
		"subtitles": "Untertitel: %s",
		"colorblind_mode": "Farbenblindheit: %s",
		"mouse_sensitivity": "Mausempfindlichkeit: %.1fx",
		"on": "AN",
		"off": "AUS",
		"cb_none": "Keine",
		"cb_protanopia": "Protanopie",
		"cb_deuteranopia": "Deuteranopie",
		"cb_tritanopia": "Tritanopie",
		"dossier_proj": "PROJEKT-INFO",
		"dossier_tech": "TECH-STACK",
		"dossier_contact": "KONTAKTE",
		"dossier_proj_text": "[center][color=#e2e8f0]PROJEKT-DOSSIER[/color]\n\nDieses Projekt ist ein interaktives psychologisches Horror-Erlebnis, das als spielbares Entwickler-Portfolio dient.\n\nEs bietet Echtzeit-prozedurales Audio, einen nostalgischen PS2-Bildschirmfilter, physikbasierte Beleuchtung und atmosphärische Klanglandschaften.[/center]",
		"dossier_tech_text": "[center][color=#e2e8f0]TECHNOLOGIE-INVENTAR[/color]\n\n[color=#fbcfe8]Engine:[/color] Godot 4.x\n[color=#fbcfe8]Logik:[/color] 100% reines GDScript\n[color=#fbcfe8]Grafik:[/color] PS2-Retro-Shader mit integrierten Farbkorrekturmatrizen\n[color=#fbcfe8]Audio:[/color] Prozedurale Soundwellen und dynamisches Bus-Routing[/center]",
		"dossier_contact_text": "[center][color=#e2e8f0]KONTAKTKANÄLE[/color]\n\nFühlen Sie sich frei, die Archive zu erkunden und Kontakt aufzunehmen:\n\n[url=https://www.linkedin.com/in/adil-basri-erdem-189941249/][color=#60a5fa]LINKEDIN-ARCHIV[/color][/url]\n\n[url=mailto:adilbasri06161@gmail.com][color=#60a5fa]DIREKTE E-MAIL[/color][/url]\n\n[url=http://www.teamhusk.com.tr][color=#60a5fa]TEAM HUSK ARCHIV[/color][/url]\n\nSpielen Sie die INTERRED-Demo auf Steam![/center]",
		"intro_subtitles": [
			"Ja, ich weiß, ich weiß, ich komme zu spät zum Vorstellungsgespräch. Es tut mir wirklich leid.",
			"Schau, mein Navi ist einfach komplett ausgefallen.",
			"Ich bin irgendwo von der Hauptstraße falsch abgebogen.",
			"und jetzt stecke ich hier fest...",
			"auf dieser schrecklichen Schotterstraße mitten im Nirgendwo.",
			"Mein Auto macht auch Probleme, der Motor klingt schrecklich.",
			"Ich kann es mir echt nicht leisten, hier liegen zu bleiben.",
			"Warte... halt mal. Ich sehe Lichter da vorne. Sieht aus wie ein altes Haus.",
			"Ich fahre mal ran und frage, ob sie mir den Weg zur nächsten Tankstelle zeigen können.",
			"oder mich zumindest das Festnetz benutzen lassen.",
			"Ich rufe dich zurück, sobald ich kann. Wünsch mir Glück."
		]
	},
	"it": {
		"play": "GIOCA",
		"options": "OPZIONI",
		"faq": "DOSSIER",
		"exit": "ESCI",
		"are_you_sure": "Sei sicuro di voler uscire?",
		"yes": "SÌ",
		"no": "NO",
		"audio": "AUDIO",
		"video": "VIDEO",
		"accessibility": "ACCESSIBILITÀ",
		"language": "LINGUA",
		"back": "INDIETRO",
		"master_volume": "Volume Generale: %d%%",
		"music_volume": "Volume Musica: %d%%",
		"sfx_volume": "Volume Effetti: %d%%",
		"voice_volume": "Volume Voci: %d%%",
		"fullscreen": "Schermo Intero: %s",
		"resolution": "Risoluzione: %s",
		"shader_intensity": "Intensità Shader PS2: %d%%",
		"subtitles": "Sottotitoli: %s",
		"colorblind_mode": "Daltonismo: %s",
		"mouse_sensitivity": "Sensibilità Mouse: %.1fx",
		"on": "SÌ",
		"off": "NO",
		"cb_none": "Nessuno",
		"cb_protanopia": "Protanopia",
		"cb_deuteranopia": "Deuteranopia",
		"cb_tritanopia": "Tritanopia",
		"dossier_proj": "INFO PROGETTO",
		"dossier_tech": "TECNOLOGİE",
		"dossier_contact": "CONTATTI",
		"dossier_proj_text": "[center][color=#e2e8f0]DOSSIER DI PROGETTO[/color]\n\nQuesto progetto è un'esperienza horror psicologica interattiva che funge da portfolio giocabile per lo sviluppatore.\n\nPresenta audio procedurale in tempo reale, un filtro nostalgia PS2, illuminazione fisica e paesaggi sonori atmosferici.[/center]",
		"dossier_tech_text": "[center][color=#e2e8f0]INVENTARIO TECNOLOGICO[/color]\n\n[color=#fbcfe8]Motore:[/color] Godot 4.x\n[color=#fbcfe8]Logica:[/color] 100% puro GDScript\n[color=#fbcfe8]Grafica:[/color] Shader retro PS2 con matrici di correzione daltonismo integrate\n[color=#fbcfe8]Audio:[/color] Onde sonore procedurali e instradamento dinamico dei bus[/center]",
		"dossier_contact_text": "[center][color=#e2e8f0]CANALI DI CONTATTO[/color]\n\nEsplora gli archivi ed entra in contatto diretto:\n\n[url=https://www.linkedin.com/in/adil-basri-erdem-189941249/][color=#60a5fa]ARCHIVIO LINKEDIN[/color][/url]\n\n[url=mailto:adilbasri06161@gmail.com][color=#60a5fa]PROTOCOLLO MAIL DIRETTA[/color][/url]\n\n[url=http://www.teamhusk.com.tr][color=#60a5fa]ARCHIVIO TEAM HUSK[/color][/url]\n\nGioca alla demo di INTERRED su Steam![/center]",
		"intro_subtitles": [
			"Sì lo so, lo so che sono in tardi per il colloquio. Mi dispiace davvero.",
			"Senti, il mio GPS si è completamente spento.",
			"Ho preso una svolta sbagliata da qualche parte fuori dall'autostrada.",
			"e ora sono bloccato su questa...",
			"questa orribile strada sterrata in mezzo al nulla.",
			"Anche la mia macchina fa i capricci, il motore ha un rumore pessimo.",
			"Non posso proprio permettermi di restare a piedi qui fuori.",
			"Aspetta... fermo un attimo. Vedo delle luci davanti. Sembra una vecchia casa.",
			"Accosto per vedere se possono indicarmi la stazione di servizio più vicina.",
			"o almeno lasciarmi usare un telefono fisso.",
			"Ti richiamo appena posso. Augurami buona fortuna."
		]
	},
	"fr": {
		"play": "JOUER",
		"options": "OPTIONS",
		"faq": "DOSSIER",
		"exit": "QUITTER",
		"are_you_sure": "Voulez-vous vraiment quitter?",
		"yes": "OUI",
		"no": "NON",
		"audio": "AUDIO",
		"video": "VIDEO",
		"accessibility": "ACCESSIBILITÉ",
		"language": "LANGUE",
		"back": "RETOUR",
		"master_volume": "Volume Principal: %d%%",
		"music_volume": "Volume Musique: %d%%",
		"sfx_volume": "Volume Effets: %d%%",
		"voice_volume": "Volume Voix: %d%%",
		"fullscreen": "Plein Écran: %s",
		"resolution": "Résolution: %s",
		"shader_intensity": "Intensité Shader PS2: %d%%",
		"subtitles": "Sous-titres: %s",
		"colorblind_mode": "Daltonisme: %s",
		"mouse_sensitivity": "Sensibilité Souris: %.1fx",
		"on": "OUI",
		"off": "NON",
		"cb_none": "Aucun",
		"cb_protanopia": "Protanopie",
		"cb_deuteranopia": "Deuteranopie",
		"cb_tritanopia": "Tritanopie",
		"dossier_proj": "PROJET INFO",
		"dossier_tech": "TECHS",
		"dossier_contact": "CONTACTS",
		"dossier_proj_text": "[center][color=#e2e8f0]DOSSIER DE PROJET[/color]\n\nCe projet est une expérience d'horreur psychologique interactive servant de portfolio de développeur jouable.\n\nIl intègre de l'audio procédural en temps réel, un filtre d'écran rétro PS2, des éclairages physiques et des ambiances sonores travaillées.[/center]",
		"dossier_tech_text": "[center][color=#e2e8f0]INVENTAIRE TECHNIQUE[/color]\n\n[color=#fbcfe8]Moteur:[/color] Godot 4.x\n[color=#fbcfe8]Logique:[/color] 100% GDScript pur\n[color=#fbcfe8]Rendu:[/color] Shader rétro PS2 avec matrices de correction du daltonisme intégrées\n[color=#fbcfe8]Audio:[/color] Synthèse sonore procédurale et routage de bus dynamique[/center]",
		"dossier_contact_text": "[center][color=#e2e8f0]CANAUX DE CONTACT[/color]\n\nN'hésitez pas à explorer les archives et à me contacter:\n\n[url=https://www.linkedin.com/in/adil-basri-erdem-189941249/][color=#60a5fa]ARCHIVES LINKEDIN[/color][/url]\n\n[url=mailto:adilbasri06161@gmail.com][color=#60a5fa]E-MAIL DIRECT[/color][/url]\n\n[url=http://www.teamhusk.com.tr][color=#60a5fa]PORTFOLIO TEAM HUSK[/color][/url]\n\nJouez à la démo d'INTERRED sur Steam ![/center]",
		"intro_subtitles": [
			"Oui je sais, je sais que je suis en retard pour l'entretien. Je suis vraiment désolé.",
			"Écoute, mon GPS vient de s'éteindre complètement.",
			"J'ai pris un mauvais tournant quelque part en quittant l'autoroute.",
			"et maintenant je suis coincé sur ce...",
			"ce terrible chemin de terre au milieu de nulle part.",
			"Ma voiture fait des siennes aussi, le moteur fait un bruit horrible.",
			"Je ne peux vraiment pas me permettre de tomber en panne ici.",
			"Attends... regarde. Je vois des lumières devant. On dirait une vieille maison.",
			"Je vais m'arrêter pour voir s'ils peuvent m'indiquer la station-service la plus proche.",
			"ou au moins me laisser utiliser un téléphone fixe.",
			"Je te rappelle dès que possible. Souhaite-moi bonne chance."
		]
	},
	"es": {
		"play": "JUGAR",
		"options": "OPCIONES",
		"faq": "DOSSIER",
		"exit": "SALIR",
		"are_you_sure": "¿Seguro que quieres salir?",
		"yes": "SÍ",
		"no": "NO",
		"audio": "AUDIO",
		"video": "VIDEO",
		"accessibility": "ACCESIBILIDAD",
		"language": "IDIOMA",
		"back": "VOLVER",
		"master_volume": "Volume General: %d%%",
		"music_volume": "Volume Música: %d%%",
		"sfx_volume": "Volume Efectos: %d%%",
		"voice_volume": "Volume Voces: %d%%",
		"fullscreen": "Pantalla Completa: %s",
		"resolution": "Resolución: %s",
		"shader_intensity": "Intensidad Shader PS2: %d%%",
		"subtitles": "Subtítulos: %s",
		"colorblind_mode": "Daltonismo: %s",
		"mouse_sensitivity": "Sensibilidad Ratón: %.1fx",
		"on": "SÍ",
		"off": "NO",
		"cb_none": "Ninguno",
		"cb_protanopia": "Protanopía",
		"cb_deuteranopia": "Deuteranopía",
		"cb_tritanopia": "Tritanopía",
		"dossier_proj": "INFO PROYECTO",
		"dossier_tech": "TECNOLOGÍAS",
		"dossier_contact": "CONTACTOS",
		"dossier_proj_text": "[center][color=#e2e8f0]DOSSIER DE PROYECTO[/color]\n\nEste proyecto es una experiencia de terror psicológico interactiva que sirve como portafolio jugable de desarrollador.\n\nPresenta audio procedimental en tiempo real, un filtro retro de pantalla PS2, iluminación física y paisajes sonoros atmosféricos.[/center]",
		"dossier_tech_text": "[center][color=#e2e8f0]INVENTARIO TECNOLÓGICO[/color]\n\n[color=#fbcfe8]Motor:[/color] Godot 4.x\n[color=#fbcfe8]Lógica:[/color] 100% GDScript puro\n[color=#fbcfe8]Render:[/color] Shader retro PS2 con matrici de corrección de daltonismo integradas\n[color=#fbcfe8]Audio:[/color] Ondas de sonido procedimentales y enrutamiento de bus dinámico[/center]",
		"dossier_contact_text": "[center][color=#e2e8f0]CANALES DE CONTACTO[/color]\n\nSiéntete libre de explorar los archivos y ponerte en contacto:\n\n[url=https://www.linkedin.com/in/adil-basri-erdem-189941249/][color=#60a5fa]ARCHIVO LINKEDIN[/color][/url]\n\n[url=mailto:adilbasri06161@gmail.com][color=#60a5fa]CORREO DIRECTO[/color][/url]\n\n[url=http://www.teamhusk.com.tr][color=#60a5fa]ARCHIVOS TEAM HUSK[/color][/url]\n\n¡Juega la demo de INTERRED en Steam![/center]",
		"intro_subtitles": [
			"Sí lo sé, sé que llego tarde a la entrevista. Lo siento muchísimo.",
			"Mira, mi GPS acaba de apagarse por completo.",
			"Tomé un desvío equivocado en alguna parte fuera de la autopista.",
			"y ahora estoy atrapado en este...",
			"este horrible camino de tierra en medio de la nada.",
			"Mi coche también está fallando, el motor suena terrible.",
			"De verdad no puedo permitirme averiarme aquí fuera.",
			"Espera... aguanta. Veo unas luces más adelante. Parece una casa vieja.",
			"Voy a parar a ver si me pueden indicar la gasolinera más cercana.",
			"o al menos dejarme usar un teléfono fijo.",
			"Te llamo en cuanto pueda. Deséame suerte."
		]
	}
}
