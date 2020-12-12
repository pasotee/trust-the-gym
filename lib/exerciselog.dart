import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trust_the_gym/training.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'appdefines.dart';

typedef PickerCallback = void Function(int index);
typedef PickerText = String Function(int index);

class ExerciseLog extends StatefulWidget {
  ExerciseLog({Key key, this.exercise, this.onExerciseFinished}) : super(key: key);

  final TrainingExercise exercise;
  final VoidCallback onExerciseFinished;

  @override
  _ExerciseLogState createState() => _ExerciseLogState(exercise);
}

class _ExerciseLogState extends State<ExerciseLog> {
  YoutubePlayerController _controller;

  int currentlySelectedRow = 0;

  FixedExtentScrollController weightController = FixedExtentScrollController(initialItem: 0);
  FixedExtentScrollController repsController = FixedExtentScrollController(initialItem: 0);

  bool canUpdateWeight = false;
  bool canUpdateReps = false;

  _ExerciseLogState(TrainingExercise exercise) {
    _controller = YoutubePlayerController(
      initialVideoId: exercise.youtubeLink,
      flags: YoutubePlayerFlags(autoPlay: false, controlsVisibleAtStart: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    canUpdateWeight = true;
    canUpdateReps = true;

    return Column(
      children: <Widget>[
        displayExerciseTitle(),
        displayExerciseVideo(context),
        displaySetsTable(),
        displayInputButtons(),
        Spacer(),
        Container(
            padding: new EdgeInsets.symmetric(horizontal: 12.0),
            height: 100,
            child: Row(
              children: displayWeightPicker() + displayRepsPicker(),
            ))
      ],
    );
  }

  Widget displayExerciseTitle() {
    return Container(
      height: 45.0,
      color: Theme.of(context).dialogBackgroundColor,
      padding: new EdgeInsets.symmetric(horizontal: 12.0),
      alignment: Alignment.centerLeft,
      child: new Text(
        widget.exercise.name,
        style: TextStyle(
            color: Theme.of(context).indicatorColor, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget displayExerciseVideo(BuildContext context) {
    if (widget.exercise.youtubeLink.isEmpty) {
      return Text("Missing video link");
    } else {
      return YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressColors: ProgressBarColors(
          playedColor: Theme.of(context).primaryColor,
          handleColor: Theme.of(context).accentColor,
        ),
      );
    }
  }

  Widget displayInputButtons() {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Ink(
        decoration: ShapeDecoration(
          color: Theme.of(context).primaryColor,
          shape: CircleBorder(),
        ),
        child: IconButton(
          icon: Icon(Icons.plus_one),
          color: Colors.white,
          onPressed: () {
            setState(() {
              print("not implemented");
              //TODO: Implement this.
            });
          },
        ),
      ),
      Ink(
        decoration: ShapeDecoration(
          color: Theme.of(context).primaryColor,
          shape: CircleBorder(),
        ),
        child: IconButton(
          icon: Icon(Icons.check),
          color: Colors.white,
          onPressed: () {
            setSetDone();
          },
        ),
      )
    ]);
  }

  List<Widget> displayPicker(String name, FixedExtentScrollController controller, int optionsCount,
      PickerCallback pickerCallback, PickerText pickerText) {
    return [
      Text(name),
      Expanded(
        child: CupertinoPicker(
          itemExtent: 75,
          scrollController: controller,
          onSelectedItemChanged: (int index) => {pickerCallback(index)},
          children: List<Widget>.generate(optionsCount, (int index) {
            return Center(
              child: Text(
                pickerText(index),
              ),
            );
          }),
        ),
      ),
    ];
  }

  List<Widget> displayWeightPicker() {
    var exerciseSets = widget.exercise.sets;
    if (exerciseSets.length <= currentlySelectedRow) {
      return [];
    }

    var trainingSet = exerciseSets[currentlySelectedRow];

    return displayPicker(
        "Weight",
        weightController,
        (AppDefines.maxWeight / AppDefines.weightIncrement).round(),
        (int i) => {updateWeight(trainingSet, i * AppDefines.weightIncrement)},
        (int i) => (i * AppDefines.weightIncrement).toString() + " kg");
  }

  List<Widget> displayRepsPicker() {
    var exerciseSets = widget.exercise.sets;
    if (exerciseSets.length <= currentlySelectedRow) {
      return [];
    }

    var trainingSet = exerciseSets[currentlySelectedRow];

    return displayPicker("Reps", repsController, AppDefines.maxReps,
        (int i) => {updateReps(trainingSet, i + 1)}, (int i) => (i + 1).toString());
  }

  Widget displaySetsTable() {
    return DataTable(
        showCheckboxColumn: false, // <-- this is important
        columns: [
          DataColumn(label: tableHeaderWidget("")),
          DataColumn(label: tableHeaderWidget("Set")),
          DataColumn(label: tableHeaderWidget("Weight")),
          DataColumn(label: tableHeaderWidget("Reps")),
        ],
        //TODO: default row first set not done.
        rows: generateSetRows());
  }

  Widget tableHeaderWidget(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 18),
    );
  }

  List<DataRow> generateSetRows() {
    List<DataRow> rows = new List<DataRow>();

    for (int i = 0; i < widget.exercise.sets.length; i++) {
      rows.add(tableRowWidget(widget.exercise.sets[i], i));
    }

    return rows;
  }

  DataRow tableRowWidget(TrainingSet trainingSet, int setIndex) {
    IconData currentIcon = trainingSet.isDone ? Icons.check_box : Icons.check_box_outline_blank;

    Color bgColor = setIndex == currentlySelectedRow ? Colors.grey : Colors.white;

    return DataRow(
        color: MaterialStateColor.resolveWith((states) => bgColor),
        cells: [
          DataCell(Center(child: Icon(currentIcon))),
          DataCell(Center(child: Text(setIndex.toString()))),
          DataCell(Center(child: Text(trainingSet.weight.toString() + " kg"))),
          DataCell(Center(child: Text(trainingSet.reps.toString()))),
        ],
        onSelectChanged: (newValue) {
          setState(() {
            currentlySelectedRow = setIndex;

            resetPickersToNewRow();
          });
        });
  }

  void setSetDone() {
    var exerciseSets = widget.exercise.sets;
    if (exerciseSets.length > currentlySelectedRow) {
      exerciseSets[currentlySelectedRow].isDone = true;
      currentlySelectedRow++;

      Training.manager.save();

      resetPickersToNewRow();
    }

    if (exerciseSets.length <= currentlySelectedRow) {
      widget.onExerciseFinished();
    }
  }

  void updateWeight(TrainingSet trainingSet, double newWeight) {
    if (canUpdateWeight) {
      trainingSet.weight = newWeight;
    }

    setState(() {});
  }

  void updateReps(TrainingSet trainingSet, int newReps) {
    if (canUpdateReps) {
      trainingSet.reps = newReps;
    }

    setState(() {});
  }

  void resetPickersToNewRow() {
    var trainingSet = widget.exercise.sets[currentlySelectedRow];

    canUpdateReps = false;
    canUpdateWeight = false;

    weightController.jumpToItem((trainingSet.weight / AppDefines.weightIncrement).round());
    repsController.jumpToItem(trainingSet.reps - 1);
  }
}
