import 'package:electronrx/chart.dart';
import 'package:electronrx/bpm.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Heart Health Demo',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<SensorValue> data = [];
  List<SensorValue> bpmValues = [];
  bool isBPMEnabled = false;
  Widget? dialog;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heart Health Monitor'),
      ),
      body: Column(
        children: [
          isBPMEnabled
              ? dialog = HeartBPMDialog(
                  context: context,
                  onRawData: (value) {
                    setState(() {
                      if (data.length >= 100) data.removeAt(0);
                      data.add(value);
                    });
                  },
                  onBPM: (value) => setState(() {
                    if (bpmValues.length >= 100) bpmValues.removeAt(0);
                    bpmValues.add(SensorValue(
                        value: value.toDouble(), time: DateTime.now()));
                  }),
                )
              : const SizedBox(),
          isBPMEnabled && bpmValues.isNotEmpty
              ? Container(
                  decoration: BoxDecoration(border: Border.all()),
                  constraints: const BoxConstraints.expand(height: 180),
                  child: BPMChart(bpmValues),
                )
              : const SizedBox(),
          Padding(
            padding:
                const EdgeInsets.only(top: 16, bottom: 8, left: 10, right: 10),
            child: Text(isBPMEnabled
                ? 'Stop recording and measurement'
                : 'Please put your finger over the back camera of the phone and tap the icon below to start recording.'),
          ),
          Center(
            child: IconButton(
              icon: Icon(isBPMEnabled
                  ? Icons.stop_circle_rounded
                  : Icons.video_camera_back),
              onPressed: () => setState(() {
                if (isBPMEnabled) {
                  isBPMEnabled = false;
                  bpmValues.clear();
                } else {
                  isBPMEnabled = true;
                }
              }),
            ),
          ),
        ],
      ),
    );
  }
}
