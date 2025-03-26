extends Control
@export var fileDialog: FileDialog;
@export var itemList: ItemList;
var pathsList: Array[String];
var selectedListIndexes: Array[int];
var regex = RegEx.new();

@export var currentVolumeData: Dictionary[float, float];
@export var finalVolumeData: Array;

var spectrum = AudioServer.get_bus_effect_instance(0, 0);
var converting: bool = false;
var currentlyConvertedIndex: int = 0;

@export var outputDirDialog: FileDialog;
@export var outputDirButton: Button;

@export var audioPlayer: AudioStreamPlayer;

func _ready():
	regex.compile("[^/]*$");
	itemList.clear();

func _onChooseFiles() -> void:
	fileDialog.visible = true;

func _onFilesSelected(paths: PackedStringArray) -> void:
	pathsList.assign(paths);
	for path in paths:
		var filename = regex.search(path).get_string();
		itemList.add_item(filename);

func _OnMultiSelected(_index: int, _selected: bool) -> void:
	selectedListIndexes.assign(itemList.get_selected_items());
	print(selectedListIndexes);

func _OnClearAll() -> void:
	pathsList.clear();
	itemList.clear();
	selectedListIndexes.clear();

func _OnClearSelected() -> void:
	for xd in selectedListIndexes:
		pathsList.remove_at(xd)
		itemList.remove_item(xd)

	selectedListIndexes.assign(itemList.get_selected_items());

func _onChooseOutputDir() -> void:
	outputDirDialog.visible = true;

func _onDirSelected(dir: String) -> void:
	outputDirButton.text = dir;

func _onConvertPressed() -> void:
	if (
		outputDirButton.text != "Choose output directory..."
		&& pathsList.size() > 0
		&& !converting
		):
		currentlyConvertedIndex = 0;
		convertQueue()
		converting = true;

func convertQueue() -> void:
	if ((currentlyConvertedIndex+1) <= pathsList.size()):
		var audioFile = AudioStreamOggVorbis.load_from_file(pathsList[currentlyConvertedIndex]);
		audioPlayer.set_stream(audioFile);
		audioPlayer.play();
	else:
		saveConvertedData();
		converting = false;

func _onAudioFinished() -> void:
	finalVolumeData.append(currentVolumeData.values());
	currentVolumeData.clear()
	currentlyConvertedIndex += 1;
	convertQueue()

func _process(_delta):
	if (audioPlayer.is_playing()):
		var volume = spectrum.get_magnitude_for_frequency_range(0, 500).length()
		currentVolumeData[AudioServer.get_time_since_last_mix()] = volume;

func saveConvertedData():
	var createdFile = FileAccess.open(outputDirButton.text + '/volumeData.json', FileAccess.WRITE);
	var jsonString = JSON.stringify(finalVolumeData);
	createdFile.store_line(jsonString);
