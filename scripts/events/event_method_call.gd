class_name EventMethodCall
extends HorrorEvent

@export var target_node: Node
@export var method_name: String
@export var arg1: Variant
@export var arg2: Variant
@export var arg3: Variant

func _run_event():
	if target_node and target_node.has_method(method_name):
		# We'll support up to 3 optional arguments
		var args = []
		if arg1 != null: args.append(arg1)
		if arg2 != null: args.append(arg2)
		if arg3 != null: args.append(arg3)
		
		target_node.callv(method_name, args)
		
	finish()
