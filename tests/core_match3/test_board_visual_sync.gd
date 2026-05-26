extends "res://addons/gut/test.gd"

# Юнит-тесты для BoardView и GemView Sync

func test_board_view_setup() -> void:
	var board := BoardStateEngine.new()
	board.configure(6, 6, 1)
	
	var view := BoardView.new()
	add_child_autofree(view)
	view.setup(board)
	
	assert_eq(view.board_model, board, "BoardView должен сохранять ссылку на BoardStateEngine")
	assert_eq(view.match_pop_fx.size(), 0, "Спец-эффекты матчей должны быть пустыми при инициализации")
	assert_eq(view.visual_queue.size(), 0, "Очередь событий должна быть пустой при инициализации")

func test_animations_finished_signal_after_swap() -> void:
	var board := BoardStateEngine.new()
	board.configure(6, 6, 1)
	
	var view := BoardView.new()
	add_child_autofree(view)
	view.setup(board)
	view.size = Vector2(600, 600) # устанавливаем размер, чтобы вычисления метрик не делили на 0
	
	watch_signals(view)
	
	# Запускаем анимацию обмена
	view.play_swap_fx(Vector2i(0, 0), Vector2i(1, 0))
	
	# Должно начаться проигрывание (is_currently_animating = true)
	assert_true(view.gem_offsets.has(Vector2i(0, 0)), "Должны быть заполнены оффсеты обмена")
	
	# Имитируем кадры анимации в _process
	view._was_animating = true
	
	# Очищаем оффсеты руками для завершения анимации
	view.gem_offsets.clear()
	view.gem_scales.clear()
	view.gem_scale_velocities.clear()
	view.gem_alphas.clear()
	view.is_processing_queue = false
	
	# Шагаем процесс с нулевым дельтой
	view._process(0.01)
	
	assert_signal_emitted(view, "animations_finished", "Сигнал animations_finished должен отправиться при прекращении анимации")

func test_play_effects_queueing() -> void:
	var board := BoardStateEngine.new()
	board.configure(6, 6, 1)
	
	var view := BoardView.new()
	add_child_autofree(view)
	view.setup(board)
	view.size = Vector2(600, 600)
	
	watch_signals(view)
	
	# Запуск нескольких эффектов в очередь
	var matches: Array[Dictionary] = [
		{"piece_id": 1, "cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]}
	]
	
	# Переводим в асинхронный запуск
	view.play_match_pop(matches)
	
	assert_eq(view.visual_queue.size(), 0, "Матч должен сразу извлекаться из очереди для проигрывания")
	assert_true(view.is_processing_queue, "Очередь должна помечаться как обрабатываемая")
