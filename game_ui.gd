extends CanvasLayer

@export var label_niveau: Label
@export var barre_ecologie: ProgressBar

# Gère l'affichage de l'argent (Éco-pièces)
func mettre_a_jour_niveau(nouvel_argent):
	if label_niveau:
		label_niveau.text = "Eco-Pièces : " + str(nouvel_argent)

# Gère la barre de vie et sa couleur (Vert -> Jaune -> Rouge)
func mettre_a_jour_ecologie(nouvelle_valeur):
	if barre_ecologie:
		barre_ecologie.value = nouvelle_valeur
		
		# 1. On calcule le pourcentage de la barre (de 0.0 à 1.0)
		var pourcentage = float(nouvelle_valeur) / float(barre_ecologie.max_value)
		
		# 2. On mélange les couleurs : Vert quand c'est plein, Rouge quand c'est vide
		var couleur_dynamique = Color.RED.lerp(Color.GREEN, pourcentage)
		
		# 3. On applique la couleur directement sur le style "Fill" qu'on a créé
		if barre_ecologie.has_theme_stylebox_override("fill"):
			var style_remplissage = barre_ecologie.get_theme_stylebox("fill")
			if style_remplissage is StyleBoxFlat:
				style_remplissage.bg_color = couleur_dynamique
