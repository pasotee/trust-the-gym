import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trust_the_gym/exerciselog.dart';
import 'package:trust_the_gym/training.dart';

class ActiveWorkoutPage extends StatefulWidget {
  ActiveWorkoutPage({Key key, this.title, this.workout}) : super(key: key);

  final String title;
  final TrainingWorkout workout;

  @override
  _ActiveWorkoutPageState createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends State<ActiveWorkoutPage> {
  PageController _controller = PageController(
    initialPage: 0,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: PageView(
          // by default go to initial page to the first not done exercise.
          controller: _controller,
          children: getExerciseWidgets(),
        ));
  }

  List<Widget> getExerciseWidgets() {
    List<Widget> list = new List<Widget>();
    for (var exercise in widget.workout.exercises) {
      list.add(new ExerciseLog(exercise: exercise, onExerciseFinished: onExerciseFinished));
    }
    return list;
  }

  void onExerciseFinished() {
    if (!widget.workout.isDone()) {
      //TODO: go to any page without done exercises not necesarly only next
      _controller.nextPage(duration: Duration(milliseconds: 400), curve: Curves.easeIn);
    } else {
      Navigator.pop(context);
    }
  }
}
