# Simple state object
class_name State

var name: String
var callback: Callable

func _init(_name: String, _callback: Callable = func() -> void: pass) -> void:
    name = _name
    callback = _callback

func enter() -> void:
    callback.call()