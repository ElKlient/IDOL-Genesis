extends Node
class_name IdolRetargeter

var source_scene:Node
var source_player:AnimationPlayer
var source_skeleton:Skeleton3D
var cache={}

func initialize():
	var packed=load("res://assets/animations/UAL2_Standard.glb")
	if not packed: return false
	source_scene=packed.instantiate()
	add_child(source_scene)
	source_scene.visible=false
	source_player=find_anim_player(source_scene)
	source_skeleton=find_skeleton(source_scene)
	if not source_player or not source_skeleton: return false
	return true

func find_anim_player(n:Node)->AnimationPlayer:
	if n is AnimationPlayer: return n
	for c in n.get_children():
		var x=find_anim_player(c)
		if x: return x
	return null

func find_skeleton(n:Node)->Skeleton3D:
	if n is Skeleton3D: return n
	for c in n.get_children():
		var x=find_skeleton(c)
		if x: return x
	return null

func choose(words:Array[String])->StringName:
	if not source_player: return &""
	for a in source_player.get_animation_list():
		var low=String(a).to_lower()
		for w in words:
			if low.contains(w.to_lower()):
				return a
	return &""

func attach(character:Node)->Dictionary:
	var target=find_skeleton(character)
	if not target or not source_player: return {}
	var player=AnimationPlayer.new()
	character.add_child(player)
	var lib=AnimationLibrary.new()
	var target_path=player.get_path_to(target)
	for state in ["idle","walk","work"]:
		var src_name:StringName=&""
		if state=="idle": src_name=choose(["idle","stand"])
		elif state=="walk": src_name=choose(["walk","walking"])
		else: src_name=choose(["farm","chop","hammer","work"])
		if src_name==&"": continue
		var src=source_player.get_animation(src_name)
		if not src: continue
		var anim=src.duplicate(true)
		# Redirect skeleton bone tracks. Keep :BoneName subname unchanged.
		for ti in range(anim.get_track_count()):
			var path=anim.track_get_path(ti)
			var subs=path.get_concatenated_subnames()
			if subs!="":
				anim.track_set_path(ti,NodePath(String(target_path)+":"+subs))
		lib.add_animation(state,anim)
	player.add_animation_library("",lib)
	return {"player":player,"idle":lib.has_animation("idle"),"walk":lib.has_animation("walk"),"work":lib.has_animation("work")}

func play(ctrl:Dictionary,state:String):
	if ctrl.is_empty(): return
	var p:AnimationPlayer=ctrl.player
	if p.has_animation(state) and p.current_animation!=state:
		p.play(state,0.18,1.0)
