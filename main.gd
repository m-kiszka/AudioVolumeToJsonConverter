extends Control
@export var fileDialog: FileDialog;
@export var itemList: ItemList;
var pathsList: Array[String];
var selectedListIndexes: Array[int];
var regexFilename = RegEx.new();
var regexFilenameNoExtension = RegEx.new();

@export var currentVolumeData: Dictionary[float, float];
@export var finalVolumeData: Array;

var spectrum = AudioServer.get_bus_effect_instance(0, 0);
var converting: bool = false;
var currentlyConvertedIndex: int = 0;
@export var convertedList: ItemList;

@export var outputDirDialog: FileDialog;
@export var outputDirButton: Button;

@export var convertingBtn: Button;

@export var audioPlayer: AudioStreamPlayer;

func _ready():
	regexFilename.compile("[^/]*$");
	regexFilenameNoExtension.compile("(.+?)(\\.[^.]*$|$)");
	itemList.clear();
	convertedList.clear();

func _onChooseFiles() -> void:
	fileDialog.visible = true;

func _onFilesSelected(paths: PackedStringArray) -> void:
	pathsList.assign(paths);
	for path in paths:
		var filename = regexFilename.search(path).get_string();
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
		convertQueue();
		convertingStarted();
		

func convertQueue() -> void:
	if ((currentlyConvertedIndex+1) <= pathsList.size()):
		var audioFile = AudioStreamOggVorbis.load_from_file(pathsList[currentlyConvertedIndex]);
		audioPlayer.set_stream(audioFile);
		audioPlayer.play();
	else:
		convertingFinished();

func _onAudioFinished() -> void:
	saveConvertedData();
	currentVolumeData.clear()
	currentlyConvertedIndex += 1;
	convertQueue()

func convertingFinished():
	convertingBtn.disabled = false;
	convertingBtn.text = "CONVERT";
	converting = false;

func convertingStarted():
	convertingBtn.disabled = true;
	convertingBtn.text = "CONVERTING...";
	converting = true;

func _process(_delta):
	if (audioPlayer.is_playing()):
		var volume = spectrum.get_magnitude_for_frequency_range(0, 500).length()
		currentVolumeData[AudioServer.get_time_since_last_mix()] = volume;

func saveConvertedData():
	var jsonFilename = regexFilenameNoExtension.search(itemList.get_item_text(currentlyConvertedIndex)).get_string(1) + '.json';
	convertedList.add_item(jsonFilename);
	var createdFile = FileAccess.open(outputDirButton.text + '/' + jsonFilename, FileAccess.WRITE);
	var jsonString = JSON.stringify(currentVolumeData);
	createdFile.store_line(jsonString);
