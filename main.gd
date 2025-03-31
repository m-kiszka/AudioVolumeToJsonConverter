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
var convertedListIndexes: Array[int];

@export var outputDirDialog: FileDialog;
@export var outputDirButton: Button;

@export var convertingBtn: Button;

@export var audioPlayer: AudioStreamPlayer;
@export var playbackTimer: Timer;
var maxAudioPosition: float;

@export var progressBar: ProgressBar;

@export var fromHzBox: SpinBox;
@export var toHzBox: SpinBox;
var fromHz: float = 0.0;
var toHz: float = 500.0;

@export var intervalBox: SpinBox;
var interval: float = 0.0;
var startTimestamp: float = 0;

@export var popupWindow: Window;
@export var popupLabel: Label;

var canClick: bool = true;

func _ready():
	regexFilename.compile("[^/]*$");
	regexFilenameNoExtension.compile("(.+?)(\\.[^.]*$|$)");
	itemList.clear();
	convertedList.clear();

func _onChooseFiles() -> void:
	if (!canClick): return;
	fileDialog.visible = true;

func _onFilesSelected(paths: PackedStringArray) -> void:
	if (!canClick): return;
	pathsList.assign(paths);
	for path in paths:
		var filename = regexFilename.search(path).get_string();
		itemList.add_item(filename);

func _OnMultiSelected(_index: int, _selected: bool) -> void:
	if (!canClick): return;
	selectedListIndexes.assign(itemList.get_selected_items());

func _OnClearAll() -> void:
	if (!canClick): return;
	pathsList.clear();
	itemList.clear();
	selectedListIndexes.clear();

func _OnClearSelected() -> void:
	if (!canClick): return;
	for xd in selectedListIndexes:
		pathsList.remove_at(xd)
		itemList.remove_item(xd)

	selectedListIndexes.assign(itemList.get_selected_items());

func _onChooseOutputDir() -> void:
	if (!canClick): return;
	outputDirDialog.visible = true;

func _onDirSelected(dir: String) -> void:
	if (!canClick): return;
	outputDirButton.text = dir;

func _onConvertPressed() -> void:
	if (!canClick): return;

	if (
		!converting
	):
		if (pathsList.size() == 0):
			popupWindow.title = "ERROR";
			popupLabel.text = "Choose the files you want to convert!";
			popupWindow.visible = true;
			return;
		if (outputDirButton.text == "Choose output directory..."):
			popupWindow.title = "ERROR";
			popupLabel.text = "Choose an output directory!";
			popupWindow.visible = true;
			return;

		currentlyConvertedIndex = 0;
		convertQueue();
		convertingStarted();

func convertQueue() -> void:
	if ((currentlyConvertedIndex+1) <= pathsList.size()):
		var audioFile = AudioStreamOggVorbis.load_from_file(pathsList[currentlyConvertedIndex]);

		maxAudioPosition = audioFile.get_length();
		progressBar.max_value = maxAudioPosition;
		playbackTimer.start(maxAudioPosition);

		audioPlayer.set_stream(audioFile);
		audioPlayer.play();

		getCurrentVolumeData();
		if (interval > 0):
			startTimestamp = Time.get_ticks_msec();
	else:
		convertingFinished();

func _onAudioFinished() -> void:
	saveConvertedData();
	currentVolumeData.clear()
	currentlyConvertedIndex += 1;
	convertQueue()

func convertingFinished():
	progressBar.visible = false;
	progressBar.value = 0.0;
	convertingBtn.disabled = false;
	convertingBtn.text = "CONVERT";
	canClick = true;
	converting = false;
	startTimestamp = 0;

	popupWindow.title = "Great success!";
	popupLabel.text = "Conversion finished successfully!";
	popupWindow.visible = true;

func convertingStarted():
	interval = intervalBox.value;
	fromHz = fromHzBox.value;
	toHz = toHzBox.value;
	progressBar.visible = true;
	convertingBtn.disabled = true;
	convertingBtn.text = "CONVERTING...";
	canClick = false;
	converting = true;

func _process(_delta):
	if (audioPlayer.is_playing()):
		if (interval > 0):
			if (Time.get_ticks_msec() > (startTimestamp + interval)):
				print(Time.get_ticks_msec() - startTimestamp)
				getCurrentVolumeData();
				startTimestamp = Time.get_ticks_msec();
		else:
			getCurrentVolumeData();

		#var percentageLeft = (playbackTimer.time_left * 100) / maxAudioPosition;
		progressBar.value = playbackTimer.time_left;

func getCurrentVolumeData():
	var volume = spectrum.get_magnitude_for_frequency_range(fromHz, toHz).length()
	currentVolumeData[AudioServer.get_time_since_last_mix()] = volume;

func saveConvertedData():
	var jsonFilename = regexFilenameNoExtension.search(itemList.get_item_text(currentlyConvertedIndex)).get_string(1) + '.json';
	convertedList.add_item(jsonFilename);
	var createdFile = FileAccess.open(outputDirButton.text + '/' + jsonFilename, FileAccess.WRITE);
	var jsonString = JSON.stringify(currentVolumeData, '\n');
	createdFile.store_line(jsonString);


func _onClearSelectedConverted() -> void:
	if (!canClick): return;
	for xd in convertedListIndexes:
		convertedList.remove_item(xd)

func _onClearAllConverted() -> void:
	if (!canClick): return;
	convertedListIndexes.clear();
	convertedList.clear();


func _onMultiSelectedConverted(_index: int, _selected: bool) -> void:
	if (!canClick): return;
	convertedListIndexes.assign(convertedList.get_selected_items());

func _onWindowClose() -> void:
	popupWindow.visible = false;
