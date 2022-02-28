tool
#Superclass.
#Contains refrences to the editor (editor_reference) and the timeline ( timeline_reference )
extends DialogicEditorPlugin

const section_name:= "plugin_multilang" #where settings for this plugin are stored
const index_name:= "lang_index" # index is index of current langauge (default 0)
const list_name := "lang_list" # lang list is list of languages (default ["English"])

#This is the editor script for the Multilang plugin.
#If this plugin does not need to run in the editor, you may freely delete this script and scene.

var new_lang_name := ""
var index:int
var list:Array


#setup will be called from res://addons/dialogic/Editor/EditorView.gd during project load
#This is where you connect to signals and hook into Dialogic's editor features.
func setup():
	.setup()
	

func _ready():
	index = DialogicResources.get_settings_value(section_name, index_name, 0)
	
	#TODO: set hooks to intercept event load and save in timeline editor
	
	#run only when testing this component
	if not Engine.editor_hint:
		popup_centered()
	

func set_editzone_visible(value):
	$container/Editpanel.visible = value


func _on_container_resized():
	set_size($container.rect_size)


func _on_about_to_show():
	index = DialogicResources.get_settings_value(section_name, index_name, 0)
	list = DialogicResources.get_settings_value(section_name, list_name, [])
	_repopulate_list()
	
func _repopulate_list():
	var list_menu:OptionButton = $container/Langpanel/lang_box/Langpicker
	list_menu.clear()
	list_menu.add_item(" - DEFAULT - ")
	for l in list:
		list_menu.add_item(l)
	list_menu.select(index)
	
func _on_newlang_text_changed(new_text):
	new_lang_name = new_text
	_correct_newlang_name()

func _correct_newlang_name():
	var caret:int = $container/Editpanel/HBoxContainer/newlang.caret_position
	new_lang_name.replace(" ", "_")
	$container/Editpanel/HBoxContainer/newlang.text = new_lang_name
	$container/Editpanel/HBoxContainer/newlang.caret_position = caret

func _on_addlang():
	_correct_newlang_name()
	if new_lang_name in list:
		return
	list.append(new_lang_name)
	index = len(list)
	DialogicResources.set_settings_value(section_name, list_name, list)
	_repopulate_list()

func _on_newlang_text(new_text):
	_on_newlang_text_changed(new_text)
	_on_addlang()


func _on_set_index(new_index):
	index = new_index
