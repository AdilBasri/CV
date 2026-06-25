extends MeshInstance3D

# Adjustable scroll speed from the inspector
@export var scroll_speed: float = 1.5

var road_material: StandardMaterial3D = null

func _ready():
	# Retrieve the active material on surface 0
	var active_mat = get_active_material(0)
	if active_mat and active_mat is StandardMaterial3D:
		# Duplicate the material so we don't modify the source asset file directly on disk
		road_material = active_mat.duplicate()
		set_surface_override_material(0, road_material)
		print("Road material duplicated and prepared for scrolling on: ", name)
	else:
		# Fallback to material_override if surface material is not directly found
		if material_override and material_override is StandardMaterial3D:
			road_material = material_override.duplicate()
			material_override = road_material
			print("Road material override duplicated and prepared for scrolling on: ", name)
		else:
			print("Warning: StandardMaterial3D not found on road node: ", name)

func _process(delta):
	if road_material:
		# Continuously scroll the texture UV offset along the Y (V) axis
		road_material.uv1_offset.y += scroll_speed * delta
