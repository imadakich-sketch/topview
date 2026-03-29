extends Camera2D

# --- CONFIGURATION ---
@export var vitesse_zoom = 0.1
var est_en_train_de_glisser = false

func _unhandled_input(event):
	# 1. GESTION DU GLISSEMENT (Clic droit)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			est_en_train_de_glisser = event.pressed
		
		# 2. GESTION DU ZOOM (Molette)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoomer(1) # Rapproche
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoomer(-1) # Recule

	# 3. MOUVEMENT DE LA CAMERA
	if event is InputEventMouseMotion and est_en_train_de_glisser:
		position -= event.relative * zoom

# --- FONCTION POUR CALCULER LE ZOOM ---
func zoomer(sens):
	var nouveau_zoom_x = zoom.x + (sens * vitesse_zoom)
	
	# On empêche de trop zoomer ou dézoomer (clamp)
	nouveau_zoom_x = clamp(nouveau_zoom_x, 0.5, 2.0)
	
	# On applique le zoom !
	zoom = Vector2(nouveau_zoom_x, nouveau_zoom_x)
