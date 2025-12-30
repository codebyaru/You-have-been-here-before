
extends Node

# Global persistence for Mahoraga's adaptations
var adapted_elements: Array = []
var adaptation_counts: Dictionary = {}
var current_lives: int = 30  # MAX_LIVES se sync karo

func reset_all_adaptations():
	"""Completely reset Mahoraga's memory - jab game restart ho"""
	adapted_elements.clear()
	adaptation_counts.clear()
	current_lives = 30
	print("🔄 MAHORAGA MEMORY WIPED")

func add_adaptation(element: String):
	"""Naya adaptation add karo"""
	if element not in adapted_elements:
		adapted_elements.append(element)
		print("💾 GLOBAL MEMORY: Adapted to ", element)

func increment_adaptation_count(element: String):
	"""Adaptation progress track karo"""
	if not adaptation_counts.has(element):
		adaptation_counts[element] = 0
	adaptation_counts[element] += 1

func is_adapted_to(element: String) -> bool:
	"""Check karo ki element adapted hai ya nahi"""
	return element in adapted_elements

func get_adaptation_progress(element: String) -> int:
	"""Kitni baar hit hua hai check karo"""
	return adaptation_counts.get(element, 0)
