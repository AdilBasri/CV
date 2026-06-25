extends Node3D

var can_escape = false
var player_in_area = false
@onready var world = get_parent()

var escape_label: RichTextLabel = null
var credits_label: RichTextLabel = null
var slide_label: RichTextLabel = null
var typing_audio_player: AudioStreamPlayer = null
var init_done = false

func _ready():
	# Guard against multiple initializations
	if init_done:
		return
	init_done = true
	
	# Ensure processing is enabled
	set_process(true)
	set_process_input(true)
	
	print("Volvo script ready started. Connecting signals...")
	var area = get_node_or_null("Area3D")
	if area:
		# Check if already connected to prevent duplicates
		if not area.body_entered.is_connected(_on_body_entered):
			area.body_entered.connect(_on_body_entered)
		if not area.body_exited.is_connected(_on_body_exited):
			area.body_exited.connect(_on_body_exited)
		print("Volvo Area3D body_entered/exited signals connected.")
	else:
		print("Warning: Area3D node not found under Volvo.")
		
	# UI Setup with absolute positioning to guarantee perfect centering
	if world and world.fade_layer:
		# 1. Escape Label (RichTextLabel for shake horror effect)
		escape_label = RichTextLabel.new()
		escape_label.name = "EscapeLabel"
		escape_label.bbcode_enabled = true
		escape_label.text = "[center][shake rate=25 level=12][font_size=32][color=#ffffff]YOU MANAGED TO ESCAPE![/color][/font_size][/shake][/center]"
		escape_label.visible = false
		
		escape_label.anchor_left = 0.0
		escape_label.anchor_right = 0.0
		escape_label.anchor_top = 0.0
		escape_label.anchor_bottom = 0.0
		escape_label.size = Vector2(640, 100)
		escape_label.position = Vector2(0, 190) # Centered vertically on 480px screen
		world.fade_layer.add_child(escape_label)
		
		# 2. Scrolling narrative Credits label
		credits_label = RichTextLabel.new()
		credits_label.name = "CreditsText"
		credits_label.bbcode_enabled = true
		credits_label.visible = false
		
		credits_label.anchor_left = 0.0
		credits_label.anchor_right = 0.0
		credits_label.anchor_top = 0.0
		credits_label.anchor_bottom = 0.0
		credits_label.size = Vector2(600, 1200)
		credits_label.position = Vector2(20, 490) # Centered horizontally, start off-screen
		
		# Gold/yellow color for the crawl text
		credits_label.add_theme_color_override("default_color", Color(1.0, 0.91, 0.12))
		credits_label.add_theme_font_size_override("normal_font_size", 15)
		credits_label.add_theme_font_size_override("bold_font_size", 15)
		credits_label.add_theme_font_size_override("italics_font_size", 15)
		
		credits_label.meta_clicked.connect(world._on_meta_clicked)
		world.fade_layer.add_child(credits_label)
		
		# 3. Creator/Dev Log Slideshow label (centered slide display)
		slide_label = RichTextLabel.new()
		slide_label.name = "SlideLabel"
		slide_label.bbcode_enabled = true
		slide_label.visible = false
		
		slide_label.anchor_left = 0.0
		slide_label.anchor_right = 0.0
		slide_label.anchor_top = 0.0
		slide_label.anchor_bottom = 0.0
		slide_label.size = Vector2(640, 150)
		slide_label.position = Vector2(0, 165) # Centered vertically on 480px screen
		
		slide_label.add_theme_color_override("default_color", Color(1.0, 0.91, 0.12))
		slide_label.add_theme_font_size_override("normal_font_size", 17)
		slide_label.add_theme_font_size_override("bold_font_size", 17)
		slide_label.add_theme_font_size_override("italics_font_size", 17)
		world.fade_layer.add_child(slide_label)
		
		# 4. Horror typing sound player and custom stream generation
		typing_audio_player = AudioStreamPlayer.new()
		typing_audio_player.name = "TypingAudioPlayer"
		typing_audio_player.stream = generate_horror_click_stream()
		typing_audio_player.volume_db = -10.0 # Loud enough to hear clearly
		add_child(typing_audio_player)
		
		print("Escape Ending UI elements and horror audio player successfully added.")

func generate_horror_click_stream() -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 7000 # Lower sample rate for grittier, deeper sound
	stream.stereo = false
	
	var length = 350 # short static burst
	var bytes = PackedByteArray()
	bytes.resize(length)
	for i in range(length):
		var decay = 1.0 - (float(i) / float(length))
		# Distorted scratch sound: 80% noise, 20% low pitch square wave
		var noise = randf_range(-1.0, 1.0)
		var square = 1.0 if (i % 60 < 30) else -1.0
		var sample = int((noise * 0.8 + square * 0.2) * 127.0 * decay)
		
		# Clamp to valid 8-bit limits
		if sample > 127: sample = 127
		elif sample < -128: sample = -128
		
		bytes[i] = sample
		
	stream.data = bytes
	return stream

func _on_body_entered(body):
	if body.name == "Player":
		print("Player entered Volvo Area3D shape.")
		player_in_area = true
		update_escape_state()

func _on_body_exited(body):
	if body.name == "Player":
		print("Player exited Volvo Area3D shape.")
		player_in_area = false
		update_escape_state()

func update_escape_state():
	if world and world.is_chase_active and player_in_area:
		if not can_escape:
			can_escape = true
			world.is_escape_prompt_active = true
			if world.interact_prompt:
				if world.interact_car_text:
					world.interact_prompt.text = world.interact_car_text
				else:
					world.interact_prompt.text = "Interact with E for get in the car!"
				world.interact_prompt.visible = true
			print("Volvo escape prompt shown.")
	else:
		if can_escape:
			can_escape = false
			if world:
				world.is_escape_prompt_active = false
				if world.interact_prompt:
					world.interact_prompt.visible = false
			print("Volvo escape prompt hidden.")

func _process(delta):
	update_escape_state()
	
	# Failsafe check for E input in case _input is not called
	var e_pressed = false
	if Input.is_key_pressed(KEY_E):
		e_pressed = true
	elif InputMap.has_action("interact_action") and Input.is_action_just_pressed("interact_action"):
		e_pressed = true
		
	if can_escape and e_pressed:
		print("Failsafe: Interaction trigger key detected in _process! Starting ending sequence.")
		can_escape = false # Prevent duplicate inputs
		if world and world.interact_prompt:
			world.interact_prompt.visible = false
		trigger_escape_ending()

func _input(event):
	var e_pressed = false
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		e_pressed = true
	elif InputMap.has_action("interact_action") and event.is_action_pressed("interact_action"):
		e_pressed = true
		
	if can_escape and e_pressed:
		print("Interaction trigger key pressed in Volvo area! Starting ending sequence.")
		can_escape = false # Prevent duplicate inputs
		if world and world.interact_prompt:
			world.interact_prompt.visible = false
		trigger_escape_ending()

func trigger_escape_ending():
	# 1. Lock player movement immediately
	if world and world.player_node:
		world.player_node.is_interacting = true
		world.player_node.set_physics_process(false)
		world.player_node.set_process_input(false)
		print("Player frozen and physics/inputs disabled.")
		
	# 2. Stop and clear chasing enemy
	if world:
		world.is_chase_active = false
		var enemy = world.get_node_or_null("enemy")
		if enemy:
			enemy.queue_free()
			print("Enemy node queue_freed.")
			
		# Stop all climax audio streams
		if world.walkey_sfx:
			world.walkey_sfx.stop()
		if world.heartbeat_sfx:
			world.heartbeat_sfx.stop()
		if world.horror_sfx:
			world.horror_sfx.stop()
		print("All gameplay sfx stopped.")
		
		if world.warning_label:
			world.warning_label.visible = false
			
		# 3. Cut to Black (instant fade rect alpha 1.0)
		if world.fade_rect:
			world.fade_rect.color = Color(0, 0, 0, 1.0)
			print("Screen cut to black instantly.")
			
	# 4. Wait 1.0 seconds
	await get_tree().create_timer(1.0).timeout
	
	# 5. Display escape message (typewriter with violent shake effect)
	if escape_label:
		var esc_text = "YOU MANAGED TO ESCAPE!"
		if world and world.escape_message_text:
			esc_text = world.escape_message_text
		escape_label.text = "[center][shake rate=25 level=12][font_size=32][color=#ffffff]" + esc_text + "[/color][/font_size][/shake][/center]"
		escape_label.visible = true
		escape_label.visible_characters = 0
		var total_escape_chars = escape_label.get_parsed_text().length()
		while escape_label.visible_characters < total_escape_chars:
			escape_label.visible_characters += 1
			play_typing_sfx()
			await get_tree().create_timer(0.04).timeout
		print("Escape message label fully written.")
		
	# 6. Wait 3.0 seconds
	await get_tree().create_timer(3.0).timeout
	if escape_label:
		escape_label.visible = false
		
	# 7. Start slow Credits narrative crawl (Part 1)
	var narrative_text = ""
	if world and world.narrative_credit_text:
		narrative_text = world.narrative_credit_text
	else:
		narrative_text = "Despite his relentless efforts and countless sleepless nights,\nAdil Basri ERDEM has yet to secure his rightful place in the gaming industry.\n\nThe developer is still running from the 'little men' chasing him through small-scale projects.\nHe is willing to endure grueling hours and modest compensation just to grasp something much greater.\n\nBut he is within your reach.\n\nTalent always finds a way to reveal itself.\nForged iron shines brightest in the dark; you will easily spot him among the crowd.\n\nI don't know what the future holds for Adil Basri ERDEM... but I know YOU.\nAnd you wouldn't want to miss a chance like this.\n\n\n[color=#a7f3d0]--- INITIATE CONTACT PROTOCOLS ---[/color]\n\n[url=https://www.linkedin.com/in/adil-basri-erdem-189941249/]ACCESS LINKEDIN ARCHIVE[/url]\n\n[url=http://www.teamhusk.com.tr]TEAM HUSK PORTFOLIO[/url]\n\n[url=mailto:adilbasri06161@gmail.com]DIRECT MAIL COMMUNICATION[/url]"
	
	if credits_label:
		# Add wavy eerie look to the narrative
		credits_label.text = "[center][wave amp=18 freq=2][shake rate=5 level=3]" + narrative_text + "[/shake][/wave][/center]"
		credits_label.visible_characters = 0
		credits_label.visible = true
		
		# Make mouse visible so they can interact with the contact links
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		# Run slow scroll in parallel (from y = 490 to y = -500 over 32 seconds so it finishes crawling faster)
		var tween = create_tween()
		tween.tween_property(credits_label, "position:y", -500.0, 32.0).set_trans(Tween.TRANS_LINEAR)
		
		# Typewrite the text snappily (0.02s per character) so typing finishes at ~15s
		var total_narrative_chars = credits_label.get_parsed_text().length()
		while credits_label.visible_characters < total_narrative_chars:
			credits_label.visible_characters += 1
			play_typing_sfx()
			await get_tree().create_timer(0.02).timeout
			
		# Wait for the slow scroll tween to complete
		await tween.finished
		credits_label.visible = false
		
	# 8. Creator/Dev Log Slide Show transitions (Part 2)
	# Each slide stays on screen for 2.5 seconds before moving to the next.
	var slides = []
	if world and world.dev_log_slides and world.dev_log_slides.size() > 0:
		slides = world.dev_log_slides
	else:
		slides = [
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
	
	if slide_label:
		for slide in slides:
			slide_label.text = slide
			slide_label.visible_characters = 0
			slide_label.visible = true
			
			# Typewrite the slide content snappily (0.025s per character)
			var total_slide_chars = slide_label.get_parsed_text().length()
			while slide_label.visible_characters < total_slide_chars:
				slide_label.visible_characters += 1
				play_typing_sfx()
				await get_tree().create_timer(0.025).timeout
				
			# Stay on screen for 2.5 seconds
			await get_tree().create_timer(2.5).timeout
			
			# Clean transition out
			slide_label.visible = false
			await get_tree().create_timer(0.3).timeout
			
	# 9. Clean quit
	print("Slideshow finished. Quitting game.")
	get_tree().quit()

func play_typing_sfx():
	if typing_audio_player:
		typing_audio_player.pitch_scale = randf_range(0.8, 1.2)
		typing_audio_player.play()
