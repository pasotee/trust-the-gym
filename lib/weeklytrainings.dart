import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:trust_the_gym/activeworkout.dart';
import 'package:trust_the_gym/training.dart';

class WeeklyTrainingsPage extends StatefulWidget {
  WeeklyTrainingsPage({Key key, this.title, this.itemsPerRow}) : super(key: key);

  final String title;
  final int itemsPerRow;

  @override
  _WeeklyTrainingsPageState createState() => _WeeklyTrainingsPageState();
}

//TODO: Have multiple states for a workout (not started, started, finished)
//TODO: Sort weeks based on all workouts finished

class _WeeklyTrainingsPageState extends State<WeeklyTrainingsPage> {
  _WeeklyTrainingsPageState() {
    loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Training.manager.state == TrainingFileState.Loaded
          ? displayTrainingWeeks()
          : displayTrainigFileState(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.upload_file),
        onPressed: () => pickTrainingFile(),
      ),
    );
  }

  Widget displayTrainigFileState() {
    bool displayLoadingWidget = false;
    String displayText = "";

    switch (Training.manager.state) {
      case TrainingFileState.TryingToLoad:
        displayLoadingWidget = true;
        displayText = "Checking for saved workouts. Please wait.";
        break;
      case TrainingFileState.NotUploaded:
        displayLoadingWidget = false;
        displayText = "No workouts found. Please upload your workout";
        break;
      case TrainingFileState.Loading:
        displayText = "Loading workout from file. Please wait.";
        displayLoadingWidget = true;
        break;
      case TrainingFileState.Loaded:
        displayText = "Workout loaded. UI will refresh";
        displayLoadingWidget = false;
        break;
    }

    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            displayText,
            textAlign: TextAlign.center,
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [displayLoadingWidget ? CircularProgressIndicator() : Text("")]),
        ]);
  }

  void loadInitialData() async {
    await Training.manager.load();

    setState(() {});
  }

  Future<void> pickTrainingFile() async {
    //TODO: Consider moving this inside the trainig class
    //TODO: Have to option to add additional tranings or override
    try {
      setState(() {});

      Future<FilePickerResult> paths = FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowMultiple: false,
          allowedExtensions: ['.xlsx']); //TODO: find a way do display only spreadsheets

      FilePickerResult fileResult = await paths;
      await Training.manager.importFromExcel(fileResult.paths.first);

      setState(() {});
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    } catch (ex) {
      print(ex);
    }
  }

  Widget displayTrainingWeeks() {
    return ListView.separated(
      itemCount: Training.manager.weeks.length,
      itemBuilder: displayWeekWorkouts,
      separatorBuilder: (BuildContext context, int index) => const Divider(),
    );
  }

  Widget displayWeekWorkouts(BuildContext context, int index) {
    TrainingWeek trainingWeek = Training.manager.getWeeksSorted()[index];

    return StickyHeader(
        header: new Container(
          height: 45.0,
          color: Theme.of(context).dialogBackgroundColor,
          padding: new EdgeInsets.symmetric(horizontal: 12.0),
          alignment: Alignment.centerLeft,
          child: new Text(
            trainingWeek.name,
            style: TextStyle(
                color: Theme.of(context).indicatorColor, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        content: GridView.count(
          physics: new NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          childAspectRatio: 1.4,
          crossAxisCount: widget.itemsPerRow,
          children: List.generate(trainingWeek.workouts.length,
              (subIndex) => displayWorkoutInformation(trainingWeek, subIndex)),
        ));
  }

  Widget displayWorkoutInformation(TrainingWeek trainingWeek, int workoutIndex) {
    TrainingWorkout workout = trainingWeek.getWorkoutsSorted()[workoutIndex];

    IconData iconData = workout.isDone() ? Icons.check_circle : Icons.run_circle_rounded;

    return Center(
        child: Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              iconData,
              size: 35,
            ),
            title: Text(
              workout.name,
              style: TextStyle(fontSize: 20),
            ),
          ),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: [
              FlatButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ActiveWorkoutPage(
                              title: "Active Workout",
                              workout: workout,
                            )),
                  );
                },
                child: Icon(Icons.play_arrow),
              ),
              FlatButton(
                  onPressed: () {
                    trainingWeek.workouts.remove(workout);
                    setState(() {});
                  },
                  child: Icon(Icons.delete)),
            ],
          ),
        ],
      ),
    ));
  }
}
