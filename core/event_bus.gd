extends Node

## Global typed signal bus for decoupled cross-department communication.

signal quality_preset_changed(preset_name: String)
signal time_of_day_changed(phase_name: String, sun_elevation_deg: float)
signal debug_overlay_toggled(visible: bool)
signal touch_move_updated(move_vector: Vector2)
signal touch_look_updated(look_delta: Vector2)
signal touch_action_triggered(action_name: String)
signal locomotion_state_changed(state_name: String)
signal vault_context_changed(available: bool)
signal sprint_lock_changed(active: bool)
signal crouch_changed(active: bool)
signal protagonist_changed(protagonist_id: String, display_name: String)
signal chunk_loaded(chunk_coord: Vector2i)
signal chunk_unloaded(chunk_coord: Vector2i)
signal renderer_initialized(build_tier: String, renderer_method: String)
signal hud_message_requested(message: String)
