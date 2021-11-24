tool
extends AcceptDialog
var editor_reference
var timeline_reference
export(String) var plugin_name : String
export(Texture) var plugin_icon : Texture

var loaded_timecodes:Array = []

func setup():
	editor_reference = find_parent('EditorView')
	timeline_reference = editor_reference.get_node("MainPanel/TimelineEditor")
	timeline_reference.connect("selection_updated", self, "onTimelineSelection")
	self.connect("about_to_show", self, "refresh_me")

func onTimelineSelection():
	print("hello timeline")
func on_plugin_button_pressed():
	if visible:
		hide()
	else:
		popup()
func refresh_me():
	if loaded_timecodes.size() <= 0:
		load_new()
func load_new():
	hide()
	editor_reference.godot_dialog("*.txt", EditorFileDialog.MODE_OPEN_FILE, EditorFileDialog.ACCESS_FILESYSTEM)
	editor_reference.godot_dialog_connect(self, "load_audacity_labels")
func load_audacity_labels(path, _target):
	var fileLoader:= File.new()
	fileLoader.open(path, File.READ)
	var line:String = fileLoader.get_line()
	#testing the audacity parser to check if the file is in the audacity label format.
	var first_data = parse_audacity_label(line)
	if not (first_data["start_time"] is float && first_data["stop_time"] is float):
	return #this is the failiure state.
	loaded_timecodes = []
	$scrollbox/items.clear()
	window_title = path.get_file()
		while not line.empty():
		var data = parse_audacity_label(line)
		$Timecodes/scrollbox/items.add_item("start: " + String(data["start_time"]) + " - stop: " + String(data["stop_time"]) + " " + data["comment"])
		loaded_timecodes.push_back(data)
		line = fileLoader.get_line()
	#print(loaded_timecodes)#testing for now
	fileLoader.close()
	popup()

func parse_audacity_label(line:String):
	var data = {}
	data["start_time"] = stepify(float(line), 0.1)
	data["stop_time"] = stepify(float(line.substr(line.find('\t'))), 0.1)
	#comment, aka label name, is only used to display a context hint. It will NOT be saved in Event Data
	data["comment"] = line.substr(line.find_last('\t')+1)
	return data

###TODO: continue rewriting old code

### old code, kept for refrence. Previusly hardcoded into EditorView itself

# $Timecodes/request_new_timecodes.connect("pressed", self, "load_timecode_data")
# $Timecodes/scrollbox/items.connect("item_selected", self, "on_send_timecodes")


# # Audacity label importer - KvaGram
# var timecode_target #AudioPicker
# var loaded_timecodes:Array

# func open_timecode_menu(target):
# timecode_target = target
# $Timecodes.popup()
# $Timecodes.rect_global_position = get_viewport().get_mouse_position()

# #if timecode list is empty, hide scrollbox containing menu
# $Timecodes/scrollbox.visible = loaded_timecodes.size() > 0
# #and show a button to request new timecodes instead
# $Timecodes/request_new_timecodes.visible = loaded_timecodes.size() <= 0	

# func load_timecode_data():
# $Timecodes.hide()
# godot_dialog("*.txt", EditorFileDialog.MODE_OPEN_FILE, EditorFileDialog.ACCESS_FILESYSTEM)
# godot_dialog_connect(self, "read_timecode_data")

# func read_timecode_data(path, target):
# var fileLoader:= File.new()
# fileLoader.open(path, File.READ)
# var line:String = fileLoader.get_line()
# #NOTE: other audio editors may have a simular feature,
# # possebly with their own format. If so, support should be added here.
# #testing the audacity parser to check if the file is in the audacity label format.
# var first_data = parse_audacity_label(line)
# if not (first_data["start_time"] is float && first_data["stop_time"] is float):
# 	return #this is the failiure state.
# loaded_timecodes = []
# $Timecodes/scrollbox/items.clear()
# $Timecodes.window_title = path.get_file()
# while not line.empty():
# 	var data = parse_audacity_label(line)
# 	$Timecodes/scrollbox/items.add_item("start: " + String(data["start_time"]) + " - stop: " + String(data["stop_time"]) + " " + data["comment"])
# 	loaded_timecodes.push_back(data)
# 	line = fileLoader.get_line()
# #print(loaded_timecodes)#testing for now
# fileLoader.close()
# func parse_audacity_label(line:String):
# var data = {}
# data["start_time"] = stepify(float(line), 0.1)
# data["stop_time"] = stepify(float(line.substr(line.find('\t'))), 0.1)
# #comment, aka label name, is only used to display a context hint. It will NOT be saved in Event Data
# data["comment"] = line.substr(line.find_last('\t')+1)
# return data
# func on_send_timecodes(index):
# if timecode_target == null || not "event_data" in timecode_target:
# 	return #target is invalid (log error?)
# var event_data = timecode_target.event_data
# event_data["start_time"] = loaded_timecodes[index]["start_time"]
# event_data["stop_time"] = loaded_timecodes[index]["stop_time"]
# timecode_target.load_data(event_data)