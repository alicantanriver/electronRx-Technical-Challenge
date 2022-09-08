import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// A class to store one sample data point
class SensorValue {
  final DateTime time;

  final num value;

  SensorValue({required this.time, required this.value});

  /// Returns JSON mapped data point
  Map<String, dynamic> toJSON() => {'time': time, 'value': value};

  static List<Map<String, dynamic>> toJSONArray(List<SensorValue> data) =>
      List.generate(data.length, (index) => data[index].toJSON());
}

class HeartBPMDialog extends StatefulWidget {
  final void Function(int) onBPM;

  final void Function(SensorValue)? onRawData;

  final int sampleDelay;

  final BuildContext context;

  double alpha = 0.6;

  final Widget? child;

  HeartBPMDialog({
    Key? key,
    required this.context,
    this.sampleDelay = 2000 ~/ 30,
    required this.onBPM,
    this.onRawData,
    this.alpha = 0.8,
    this.child,
  }) : super(key: key);

  void setAlpha(double a) {
    if (a <= 0) {
      throw Exception(
          "$HeartBPMDialog: smoothing factor cannot be 0 or negative");
    }
    if (a > 1) {
      throw Exception(
          "$HeartBPMDialog: smoothing factor cannot be greater than 1");
    }
    alpha = a;
  }

  @override
  HeartBPPView createState() => HeartBPPView();
}

class HeartBPPView extends State<HeartBPMDialog> {
  CameraController? _controller;

  bool _processing = false;

  int currentValue = 0;

  bool isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    var timer = Timer(const Duration(seconds: 30), () => _deInitController());
    _initController();
  }

  @override
  void dispose() {
    _deInitController();
    super.dispose();
  }

  /// Deinitialize the camera controller
  void _deInitController() async {
    isCameraInitialized = false;
    if (_controller == null) return;
    await _controller!.dispose();
  }

  /// Initialize the camera controller
  /// Function to initialize the camera controller and start data collection.
  Future<void> _initController() async {
    if (_controller != null) return;
    try {
      List<CameraDescription> cameras = await availableCameras();

      _controller = CameraController(cameras.first, ResolutionPreset.low,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);

      await _controller!.initialize();

      Future.delayed(const Duration(milliseconds: 500))
          .then((value) => _controller!.setFlashMode(FlashMode.torch));

      _controller!.startImageStream((image) {
        if (!_processing && mounted) {
          _processing = true;
          _scanImage(image);
        }
      });

      setState(() {
        isCameraInitialized = true;
      });
    } catch (e) {
      print(e);
      throw e;
    }
  }

  static const int windowLength = 50;
  final List<SensorValue> measureWindow = List<SensorValue>.filled(
      windowLength, SensorValue(time: DateTime.now(), value: 0),
      growable: true);

  void _scanImage(CameraImage image) async {
    double avg =
        image.planes.first.bytes.reduce((value, element) => value + element) /
            image.planes.first.bytes.length;

    measureWindow.removeAt(0);
    measureWindow.add(SensorValue(time: DateTime.now(), value: avg));

    _smoothBPM(avg).then((value) {
      widget.onRawData!(
        SensorValue(
          time: DateTime.now(),
          value: avg,
        ),
      );

      Future<void>.delayed(Duration(milliseconds: widget.sampleDelay))
          .then((onValue) {
        if (mounted) {
          setState(() {
            _processing = false;
          });
        }
      });
    });
  }

  Future<int> _smoothBPM(double newValue) async {
    double maxVal = 0, avg = 0;

    for (var element in measureWindow) {
      avg += element.value / measureWindow.length;
      if (element.value > maxVal) maxVal = element.value as double;
    }

    double threshold = (maxVal + avg) / 2;
    int counter = 0, previousTimestamp = 0;
    double tempBPM = 0;
    for (int i = 1; i < measureWindow.length; i++) {
      if (measureWindow[i - 1].value < threshold &&
          measureWindow[i].value > threshold) {
        if (previousTimestamp != 0) {
          counter++;
          tempBPM += 60000 /
              (measureWindow[i].time.millisecondsSinceEpoch -
                  previousTimestamp);
        }
        previousTimestamp = measureWindow[i].time.millisecondsSinceEpoch;
      }
    }

    if (counter > 0) {
      tempBPM /= counter;
      tempBPM = (1 - widget.alpha) * currentValue + widget.alpha * tempBPM;
      setState(() {
        currentValue = tempBPM.toInt();
      });
      widget.onBPM(currentValue);
    }
    return currentValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: isCameraInitialized
          ? Column(
              children: [
                Container(
                  constraints:
                      const BoxConstraints.tightFor(width: 100, height: 130),
                  child: _controller!.buildPreview(),
                ),
                Text(currentValue.toStringAsFixed(0)),
                widget.child == null ? const SizedBox() : widget.child!,
              ],
            )
          : const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('See your results below'),
              ),
            ),
    );
  }
}
