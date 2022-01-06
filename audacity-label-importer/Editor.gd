tool
extends DialogicEditorPlugin
export(int) var text_preview_length

onready var targetList:ItemList = $s_container/target/s/items
onready var sourceList:ItemList = $s_container/source/s/items
var targetdata = []
var loaded_timecodes:Array = []

func setup():
	.setup()
	timeline_reference.connect("selection_updated", self, "onTimelineSelection")
	self.connect("about_to_show", self, "refresh_me")
func onTimelineSelection():
	reloadTargets()
func reloadTargets():
	targetList.clear()
	targetdata = []
	for evt in timeline_reference.selected_items:
		if not evt.event_data["event_id"] in ['dialogic_001', 'dialogic_010']:
			continue #Ignore if selected event is not a text or question event
		var vandt = evt.get_body()#find_node("TextAndVoiceEditor") #vandt - voice and text
		if not vandt: #ignore if noice and text editor is not found
			continue
		var audio_lines = vandt.voice_editor.audio_lines
		var text = ''
		if vandt.event_data['event_id'] == 'dialogic_001':
			text = vandt.event_data['text']
		# in case this is a question event
		elif vandt.event_data['event_id'] == 'dialogic_010':
			text = vandt.event_data['question']
		# otherwise
		else:
			text = vandt.event_data['text']
		var text_list = text.split('\n')
		for line in audio_lines:
			var display = ""
			if vandt.event_data.has('voice_data') && vandt.event_data['voice_data'].has(str(line)):
				display += ("(" + str(vandt.event_data['voice_data'][str(line)].get('start_time',"0.0"))
				+ "s - " + str(vandt.event_data['voice_data'][str(line)].get('stop_time',"0.0"))+ "s)")
			else:
				display += "(0.0s - 0.0s)"
			display += text_list[line].substr(0, min(text_preview_length, len(text)))
			if len(text_list[line]) > text_preview_length:
				display.add("...")
			#Add to the target itemlist
			targetList.add_item(display)
			#Add data on target event and line
			var target = {"target" : vandt, "line" : line}
			targetdata.append(target)
func refresh_me():
	if loaded_timecodes.size() <= 0:
		load_new()
		return
	reloadTargets()
func load_new():
	hide()
	editor_reference.godot_dialog("*.txt", EditorFileDialog.MODE_OPEN_FILE, EditorFileDialog.ACCESS_FILESYSTEM)
	editor_reference.godot_dialog_connect(self, "load_audacity_labels")
func load_audacity_labels(path, _target):
	var fileLoader:= File.new()
	var status = fileLoader.open(path, File.READ)
	if status != OK :
		print("file loading returned error " + status)
		return
	var line:String = fileLoader.get_line()
	#testing the audacity parser to check if the file is in the audacity label format.
	var first_data = parse_audacity_label(line)
	if not (first_data["start_time"] is float && first_data["stop_time"] is float):
		return #this is the failiure state.
	loaded_timecodes = []
	sourceList.clear()
	window_title = path.get_file()
	while not line.empty():
		var data = parse_audacity_label(line)
		sourceList.add_item("start: " + String(data["start_time"]) + " - stop: " + String(data["stop_time"]) + " " + data["comment"])
		loaded_timecodes.push_back(data)
		line = fileLoader.get_line()
	fileLoader.close()
	popup()
func parse_audacity_label(line:String):
	var data = {}
	data["start_time"] = stepify(float(line), 0.1)
	data["stop_time"] = stepify(float(line.substr(line.find('\t'))), 0.1)
	#comment, aka label name, is only used to display a context hint. It will NOT be saved in Event Data
	data["comment"] = line.substr(line.find_last('\t')+1)
	return data


func setData(target:int, source:int):
	var vandt = targetdata[target]['target']
	var line = targetdata[target]['line']
	var data = loaded_timecodes[source]
	vandt.event_data['voice_data'][str(line)]['start_time'] = data['start_time']
	vandt.event_data['voice_data'][str(line)]['stop_time'] = data['stop_time']
	vandt.data_changed()
	vandt.voice_editor.update_data()

	#update list item name
	var text = ''
	if vandt.event_data['event_id'] == 'dialogic_001':
		text = vandt.event_data['text']
	# in case this is a question event
	elif vandt.event_data['event_id'] == 'dialogic_010':
		text = vandt.event_data['question']
	# otherwise
	else:
		text = vandt.event_data['text']
	text = text.split('\n')[line]
	var display = ("(" + str(vandt.event_data['voice_data'][str(line)].get('start_time',"0.0"))
	+ "s - " + str(vandt.event_data['voice_data'][str(line)].get('stop_time',"0.0"))+ "s)")
	
	display += text.substr(0, min(text_preview_length, len(text)))
	if len(text) > text_preview_length:
		display.add("...")

	targetList.set_item_text(target, display)

### Button and list signal handlers

func _on_source_nothing_selected():
	$s_container/target/btnsetdata.disabled = true


func _on_source_item_selected(_index:int):
	if targetList.is_anything_selected():
		$s_container/target/btnsetdata.disabled = false


func _on_source_item_activated(index:int):
	if not targetList.is_anything_selected():
		return
	setData(targetList.get_selected_items()[0], index)


func _on_target_item_selected(_index:int):
	if sourceList.is_anything_selected():
		$s_container/target/btnsetdata.disabled = false


func _on_target_item_activated(index:int):
	if not sourceList.is_anything_selected():
		return
	setData(index, sourceList.get_selected_items()[0])


func _on_target_nothing_selected():
	$s_container/target/btnsetdata.disabled = true


func _on_btnloadnew_pressed():
	load_new()

func _on_btnsetdata_pressed():
	if not sourceList.is_anything_selected() && not targetList.is_anything_selected():
		return
	setData(sourceList.get_selected_items()[0], targetList.get_selected_items()[0]) 
