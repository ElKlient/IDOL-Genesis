extends Node
class_name IdolRetargeter

var source_scene:Node
var source_player:AnimationPlayer
var source_skeleton:Skeleton3D
var cache={}
var procedural_upper_body=["spine","clavicle","upperarm","lowerarm","hand","neck","head","index","middle","pinky","ring","thumb"]

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
	var animations=source_player.get_animation_list()
	for w in words:
		var wanted=w.to_lower()
		for a in animations:
			if String(a).to_lower()==wanted:
				return a
	for w in words:
		var wanted=w.to_lower()
		for a in animations:
			if String(a).to_lower().contains(wanted):
				return a
	return &""

func attach(character:Node)->Dictionary:
	var target=find_skeleton(character)
	if not target or not source_player: return {}
	var player=AnimationPlayer.new()
	character.add_child(player)
	player.root_node=NodePath("..")
	player.playback_process_mode=AnimationPlayer.ANIMATION_PROCESS_MANUAL
	var lib=AnimationLibrary.new()
	var target_path=character.get_path_to(target)
	for state in ["idle","walk","work","gather","chop"]:
		var src_name:StringName=&""
		if state=="idle": src_name=choose(["Idle_FoldArms","Zombie_Idle","A_TPose","idle","stand"])
		elif state=="walk": src_name=choose(["Walk_Carry","Zombie_Walk_Fwd","walk","walking"])
		elif state=="gather": src_name=choose(["Farm_Harvest","Farm_PlantSeed","farm","harvest"])
		elif state=="chop": src_name=choose(["TreeChopping","chop","tree"])
		else: src_name=choose(["Farm_Harvest","TreeChopping","farm","chop","hammer","work"])
		if src_name==&"": continue
		var src=source_player.get_animation(src_name)
		if not src: continue
		var anim=src.duplicate(true)
		# Redirect skeleton bone tracks. Upper body stays procedural, so source clips cannot fight the pose layer.
		for ti in range(anim.get_track_count()-1,-1,-1):
			var path=anim.track_get_path(ti)
			var subs=String(path.get_concatenated_subnames())
			var low=(String(path)+" "+subs).to_lower()
			var procedural=false
			for key in procedural_upper_body:
				if low.contains(key):
					procedural=true
					break
			if procedural:
				anim.remove_track(ti)
				continue
			if subs!="":
				if target.find_bone(subs)<0:
					anim.remove_track(ti)
					continue
				anim.track_set_path(ti,NodePath(String(target_path)+":"+subs))
		lib.add_animation(state,anim)
	player.add_animation_library("",lib)
	return {"player":player,"idle":lib.has_animation("idle"),"walk":lib.has_animation("walk"),"work":lib.has_animation("work")}

func play(ctrl:Dictionary,state:String,step:float=0.0):
	if ctrl.is_empty(): return
	var p:AnimationPlayer=ctrl.player
	if not p.has_animation(state):
		state="idle"
	if p.has_animation(state) and p.current_animation!=state:
		p.play(state,0.18,1.0)
	if p.has_animation(state) and step>0.0:
		p.advance(step)
