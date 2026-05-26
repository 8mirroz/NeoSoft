extends RefCounted
class_name SpecialSphereType

enum Type {
	NONE,
	BEAM_SPHERE,        # Лучевая сфера (4 в линию)
	HOMING_SPHERE,      # Наводящаяся сфера (2x2 квадрат)
	BLAST_SPHERE,       # Взрывная сфера (L-shape)
	BLAST_SPHERE_PLUS,  # Взрывная сфера+ (T-shape / CROSS)
	PRISM_SPHERE,       # Призматическая сфера (5 в линию)
	DYNAMO_SPHERE,      # Динамо-сфера (6 элементов)
	SINGULARITY_CORE    # Ядро сингулярности (7+ элементов)
}
