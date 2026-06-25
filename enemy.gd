extends Node3D

var anim_player: AnimationPlayer = null

func _ready():
	# Keep ready check but handle runtime initialization in physics process as well
	anim_player = find_animation_player(self)
	if anim_player:
		var anim = anim_player.get_animation("Move")
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR
	set_physics_process(true)

func find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found = find_animation_player(child)
		if found:
			return found
	return null

func _physics_process(delta):
	# Fail-safe: Initialize if not ready (handles programmatic script attachment)
	if not anim_player:
		anim_player = find_animation_player(self)
		if anim_player:
			var anim = anim_player.get_animation("Move")
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
				print("Lazy-initialized AnimationPlayer and configured Move loop mode.")

	var world = get_parent()
	if world and world.is_chase_active:
		var player = world.player_node
		if player and is_instance_valid(player):
			# Yönelme: Düşman sadece Y ekseninde dönerek oyuncuya baksın (X ve Z rotasyonlarını sıfırda tut)
			var target_pos = player.global_position
			target_pos.y = global_position.y # Keep Y level same for looking direction
			
			if global_position.distance_to(target_pos) > 0.01:
				look_at(target_pos, Vector3.UP)
				rotate_object_local(Vector3.UP, PI) # Rotate Y by 180 degrees to face the player
				# Reset X and Z rotation
				rotation.x = 0.0
				rotation.z = 0.0
				
			# Hareket: Vektör matematiği kullanarak oyuncunun o anki konumuna doğru sürekli ve kararlı bir hızla ilerlesin
			var speed = 3.6
			# Align target Y position to match the initial Y height
			var target_chase_pos = player.global_position
			target_chase_pos.y = global_position.y
			
			global_position = global_position.move_toward(target_chase_pos, speed * delta)
			
			# Ensure Move animation plays during the chase
			if anim_player and (not anim_player.is_playing() or anim_player.current_animation != "Move"):
				anim_player.play("Move")
				
			# Make sure walkey sfx continues playing
			if world.walkey_sfx and not world.walkey_sfx.playing:
				world.walkey_sfx.play()
				
			# Ölüm Durumu: Eğer enemy ile player arasındaki mesafe 1.5 metreden az olursa
			if global_position.distance_to(player.global_position) < 1.5:
				world.trigger_game_over()
