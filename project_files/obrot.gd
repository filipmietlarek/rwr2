extends XRController3D

@export var rotation_amount: float = 45.0  
@export var deadzone: float = 0.5    

var xr_origin: XROrigin3D
var can_rotate: bool = true                

func _ready() -> void:
	# Szukamy XROrigin3D (zazwyczaj rodzic kontrolera)
	xr_origin = get_parent() as XROrigin3D
	
	if not xr_origin:
		push_error("Błąd: Skrypt obrotu musi być dzieckiem węzła XROrigin3D!")

func _process(_delta: float) -> void:
	var input := get_vector2("thumbstick")

	if abs(input.x) < deadzone:
		can_rotate = true 
		return

	if can_rotate:
		if input.x > 0:
			xr_origin.rotate_y(deg_to_rad(-rotation_amount))
		else:
			xr_origin.rotate_y(deg_to_rad(rotation_amount))

		can_rotate = false
