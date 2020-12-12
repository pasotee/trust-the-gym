import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

class TrainingSet {
  double weight = 10.0;
  int reps = 1;
  bool isDone = false;

  TrainingSet();

  TrainingSet.fromJson(Map<String, dynamic> json) {
    weight = json['weight'];
    reps = json['reps'];
    isDone = json['isDone'];
  }

  Map<String, dynamic> toJson() => {
        'weight': weight,
        'reps': reps,
        'isDone': isDone,
      };
}

class TrainingExercise {
  String name;
  String youtubeLink;

  String targetBreak;
  String targetSets;
  String targetReps;
  String targetRpe;

  List<TrainingSet> sets = new List<TrainingSet>();

  TrainingExercise();

  bool isDone() {
    for (var trainingSet in sets) {
      if (!trainingSet.isDone) {
        return false;
      }
    }

    return true;
  }

  void _generateDefaultSets() {
    int setsCount = int.parse(targetSets);

    TrainingExercise lastDoneExercise = Training.manager.getLastExerciseFor(this);

    for (int i = 0; i < setsCount; i++) {
      TrainingSet newSet = new TrainingSet();

      if (lastDoneExercise != null) {
        TrainingSet setToCopy;
        bool isSetAvaible = i < lastDoneExercise.sets.length;
        if (isSetAvaible) {
          setToCopy = lastDoneExercise.sets[i];
        } else {
          setToCopy = lastDoneExercise.sets.last;
        }

        newSet.weight = setToCopy.weight;
        newSet.reps = setToCopy.reps;
      }

      sets.add(newSet);
    }
  }

  TrainingExercise.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    youtubeLink = json['youtubeLink'];

    targetBreak = json['targetBreak'];
    targetSets = json['targetSets'];
    targetReps = json['targetReps'];
    targetRpe = json['targetRpe'];

    List<dynamic> jsonSets = json['sets'];
    for (var jsonSet in jsonSets) {
      sets.add(TrainingSet.fromJson(jsonSet));
    }

    if (sets.isEmpty) {
      _generateDefaultSets();
    }
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'youtubeLink': youtubeLink,
        'targetBreak': targetBreak,
        'targetSets': targetSets,
        'targetReps': targetReps,
        'targetRpe': targetRpe,
        'sets': sets,
      };
}

class TrainingWorkout {
  String name;
  List<TrainingExercise> exercises = new List<TrainingExercise>();

  TrainingWorkout();

  bool isDone() {
    for (var exercise in exercises) {
      if (!exercise.isDone()) {
        return false;
      }
    }

    return true;
  }

  TrainingWorkout.fromJson(Map<String, dynamic> json) {
    name = json['name'];

    List<dynamic> jsonExercises = json['exercises'];
    for (var jsonExercise in jsonExercises) {
      exercises.add(TrainingExercise.fromJson(jsonExercise));
    }
  }

  Map<String, dynamic> toJson() => {'name': name, 'exercises': exercises};
}

class TrainingWeek {
  String name;
  List<TrainingWorkout> workouts = new List<TrainingWorkout>();

  TrainingWeek();

  bool isDone() {
    for (var workout in workouts) {
      if (!workout.isDone()) {
        return false;
      }
    }

    return true;
  }

  List<TrainingWorkout> getWorkoutsSorted() {
    List<TrainingWorkout> sortedWorkouts = new List<TrainingWorkout>();
    sortedWorkouts.addAll(workouts);

    sortedWorkouts.sort((TrainingWorkout a, TrainingWorkout b) {
      bool aIsDone = a.isDone();
      bool bIsDone = b.isDone();

      if (aIsDone && !bIsDone) {
        return 1;
      }
      if (bIsDone && !aIsDone) {
        return -1;
      }

      return 0;
    });

    return sortedWorkouts;
  }

  TrainingWeek.fromJson(Map<String, dynamic> json) {
    name = json['name'];

    List<dynamic> jsonWorkouts = json['workouts'];
    for (var jsonWorkout in jsonWorkouts) {
      workouts.add(TrainingWorkout.fromJson(jsonWorkout));
    }
  }

  Map<String, dynamic> toJson() => {'name': name, 'workouts': workouts};
}

enum TrainingFileState { TryingToLoad, NotUploaded, Loading, Loaded }

class Training {
  // Singleton
  static Training manager = Training._internal();
  TrainingFileState state = TrainingFileState.TryingToLoad;
  factory Training() {
    return manager;
  }
  Training._internal();

  // Data
  List<TrainingWeek> weeks = new List<TrainingWeek>();

  // Functionality
  List<TrainingWeek> getWeeksSorted() {
    List<TrainingWeek> sortedWeeks = new List<TrainingWeek>();
    sortedWeeks.addAll(weeks);

    sortedWeeks.sort((TrainingWeek a, TrainingWeek b) {
      bool aIsDone = a.isDone();
      bool bIsDone = b.isDone();

      if (aIsDone && !bIsDone) {
        return 1;
      }
      if (bIsDone && !aIsDone) {
        return -1;
      }

      return 0;
    });

    return sortedWeeks;
  }

  TrainingExercise getLastExerciseFor(TrainingExercise exercise) {
    var info = _getExerciseInfo(exercise);
    if (info.isEmpty) {
      return null;
    }

    int weekIndex = info[0];
    int workoutIndex = info[1];

    TrainingExercise previousExercise = _getExerciseFromPreviousWeeks(exercise, false, weekIndex, workoutIndex);

    if (previousExercise == null) {
      previousExercise = _getExerciseFromPreviousWeeks(exercise, true, weekIndex, workoutIndex);
    }

    return previousExercise;
  }

  //Save & Load
  Future<void> load() async {
    final directory = await getApplicationDocumentsDirectory();
    String directoryPath = directory.path;
    File saveJson = File('$directoryPath/training.json');

    bool fileExists = await saveJson.exists();

    if (fileExists) {
      state = TrainingFileState.Loading;
      String contents = await saveJson.readAsString();
      Map<String, dynamic> json = jsonDecode(contents);
      manager = Training.fromJson(json);
      manager.state = TrainingFileState.Loaded;
    } else {
      state = TrainingFileState.NotUploaded;
    }
  }

  Future<void> save() async {
    final directory = await getApplicationDocumentsDirectory();
    String directoryPath = directory.path;
    File saveJson = File('$directoryPath/training.json');

    String jsonString = jsonEncode(toJson());
    saveJson.writeAsString(jsonString);
  }

  Training.fromJson(Map<String, dynamic> json) {
    List<dynamic> jsonWeeks = json['weeks'];
    for (var jsonWeek in jsonWeeks) {
      weeks.add(TrainingWeek.fromJson(jsonWeek));
    }
  }

  Map<String, dynamic> toJson() => {'weeks': weeks};

  //Importing
  Future<void> importFromExcel(String filePath) async {
    state = TrainingFileState.Loading;

    var file = filePath;
    var bytes = File(file).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    // Reset the list in case we want to override any prexisting workout.
    weeks = new List();

    for (var table in excel.tables.keys) {
      TrainingWeek week = new TrainingWeek();
      week.name = table;

      for (int i = 0; i < excel.tables[table].maxRows; i++) {
        TrainingWorkout workout = new TrainingWorkout();
        workout.name = excel.tables[table].rows[i][0];

        i++; // Skip over the header row.

        while (i < excel.tables[table].maxRows && excel.tables[table].rows[i][0] != null) {
          TrainingExercise exercise = new TrainingExercise();

          exercise.name = excel.tables[table].rows[i][0];
          exercise.targetSets = excel.tables[table].rows[i][1];
          exercise.targetReps = excel.tables[table].rows[i][2];
          exercise.targetRpe = excel.tables[table].rows[i][3];
          exercise.targetBreak = excel.tables[table].rows[i][4];
          exercise.youtubeLink = excel.tables[table].rows[i][5];

          exercise._generateDefaultSets();

          workout.exercises.add(exercise);
          i++;
        }

        week.workouts.add(workout);
      }

      weeks.add(week);
    }

    await save();

    state = TrainingFileState.Loaded;
  }

  // Internals
  List _getExerciseInfo(TrainingExercise exercise) {
    for (int weekIndex = 0; weekIndex < weeks.length; weekIndex++) {
      var weekWorkouts = weeks[weekIndex].workouts;
      for (int workoutIndex = 0; workoutIndex < weekWorkouts.length; workoutIndex++) {
        if (weekWorkouts[workoutIndex].exercises.contains(exercise)) {
          return [weekIndex, workoutIndex];
        }
      }
    }

    return [];
  }

  TrainingExercise _getExerciseFromPreviousWeeks(TrainingExercise exercise, bool anyWorkoutName, int weekIndex, int workoutIndex) {
    TrainingWorkout trainingWorkout = weeks[weekIndex].workouts[workoutIndex];

    for (int i = weekIndex - 1; i >= 0; i--) {
      for (int j = workoutIndex; j >= 0; j--) {
        TrainingWorkout currentWorkout = weeks[i].workouts[j];
        if (anyWorkoutName || currentWorkout.name == trainingWorkout.name) {
          for (int exerciseIndex = 0; exerciseIndex < currentWorkout.exercises.length; exerciseIndex++) {
            TrainingExercise currentExercise = currentWorkout.exercises[exerciseIndex];
            if (currentExercise.name == exercise.name) {
              return currentExercise;
            }
          }
        }
      }
    }

    return null;
  }
}
