extends EditorScenePostImport

func new_array_from_typeid(typeid: Variant.Type) -> Variant:
	return type_convert(null, typeid)
	
	
func array_custom_granularity(custom_format: Mesh.ArrayCustomFormat) -> int:
	match custom_format:
		Mesh.ARRAY_CUSTOM_RGBA8_UNORM, Mesh.ARRAY_CUSTOM_RGBA8_SNORM, Mesh.ARRAY_CUSTOM_RG_HALF:
			return 4
		Mesh.ARRAY_CUSTOM_RGBA_HALF:
			return 8
		Mesh.ARRAY_CUSTOM_R_FLOAT:
			return 1
		Mesh.ARRAY_CUSTOM_RG_FLOAT:
			return 2
		Mesh.ARRAY_CUSTOM_RGB_FLOAT:
			return 3
		Mesh.ARRAY_CUSTOM_RGBA_FLOAT:
			return 4
	return 0
	

func array_granularity(arr_id: Mesh.ArrayType, format: Mesh.ArrayFormat) -> int:
	match arr_id:
		Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_COLOR, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2:
			return 1
		Mesh.ARRAY_TANGENT:
			return 4
		Mesh.ARRAY_CUSTOM0:
			return array_custom_granularity((format >> Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) & Mesh.ARRAY_FORMAT_CUSTOM_MASK)
		Mesh.ARRAY_CUSTOM1:
			return array_custom_granularity((format >> Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT) & Mesh.ARRAY_FORMAT_CUSTOM_MASK)
		Mesh.ARRAY_CUSTOM2:
			return array_custom_granularity((format >> Mesh.ARRAY_FORMAT_CUSTOM2_SHIFT) & Mesh.ARRAY_FORMAT_CUSTOM_MASK)
		Mesh.ARRAY_CUSTOM3:
			return array_custom_granularity((format >> Mesh.ARRAY_FORMAT_CUSTOM3_SHIFT) & Mesh.ARRAY_FORMAT_CUSTOM_MASK)
		Mesh.ARRAY_BONES, Mesh.ARRAY_WEIGHTS:
			if (format & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS) != 0:
				return 8
			else:
				return 4	
		# Unhandled:
	# ARRAY_INDEX
	return 0

## "Unroll" array mesh.
## Known limitations: 
## - ignores blend shapes
## - ignores LODs
func duplicate_vertices(input: ArrayMesh) -> ArrayMesh:
	var output := ArrayMesh.new()
	for surf in input.get_surface_count():
		var arrays := input.surface_get_arrays(surf)
		var indices = arrays[Mesh.ARRAY_INDEX]
		var format := input.surface_get_format(surf)
		var new_arrays: Array = []
		new_arrays.resize(Mesh.ARRAY_MAX)
		
		for arr_id in len(arrays):
			if arr_id == Mesh.ARRAY_INDEX: # this is the one we want to eliminate
				continue
			if arrays[arr_id] == null:
				continue
			var arr_in = arrays[arr_id]
			var typeid := typeof(arr_in)
			var new_arr: Variant = new_array_from_typeid(typeid)
			assert(typeof(new_arr) == typeid)
			var granularity := array_granularity(arr_id, format)
			for idx in indices:
				for subidx in granularity:
					new_arr.push_back(arr_in[idx * granularity + subidx])

			print(arr_id, ' ', typeid, ' ', granularity, ' ', len(arr_in), '->', len(new_arr))

			new_arrays[arr_id] = new_arr

		output.add_surface_from_arrays(input.surface_get_primitive_type(surf), new_arrays, [], {}, format & ~Mesh.ARRAY_FORMAT_INDEX)

	return output
