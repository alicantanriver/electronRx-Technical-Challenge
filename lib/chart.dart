import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

import 'bpm.dart';

export 'package:electronrx/bpm.dart' show BPMChart;

class BPMChart extends StatelessWidget {
  final List<charts.Series<SensorValue, DateTime>> _data;

  BPMChart(
    List<SensorValue> data, {
    Key? key,
    List<SensorValue>? data2,
  })  : _data = data2 == null
            ? [_updateChartData(data)]
            : [_updateChartData(data), _updateChartData(data2, 2)],
        super(key: key);

  static charts.Series<SensorValue, DateTime> _updateChartData(
      List<SensorValue> data,
      [int seriesNumber = 1]) {
    return charts.Series<SensorValue, DateTime>(
      id: "BPM",
      colorFn: (datum, index) => seriesNumber == 1
          ? charts.MaterialPalette.red.shadeDefault
          : charts.MaterialPalette.green.shadeDefault,
      domainFn: (datum, index) => datum.time,
      measureFn: (datum, index) => datum.value,
      data: data,
    );
  }

  @override
  Widget build(BuildContext context) {
    num min = _data[0]
            .data
            .reduce((value, element) =>
                (value.value < element.value) ? value : element)
            .value,
        max = _data[0]
            .data
            .reduce((value, element) =>
                (value.value > element.value) ? value : element)
            .value;

    return charts.TimeSeriesChart(
      _data,
      primaryMeasureAxis: charts.NumericAxisSpec(
        showAxisLine: false,
        renderSpec: const charts.NoneRenderSpec(),
        viewport: charts.NumericExtents(min, max),
        tickProviderSpec:
            charts.StaticNumericTickProviderSpec(<charts.TickSpec<num>>[
          charts.TickSpec<num>(min),
          charts.TickSpec<num>(max),
        ]),
      ),
      behaviors: [
        charts.ChartTitle('Time',
            behaviorPosition: charts.BehaviorPosition.bottom,
            titleStyleSpec: const charts.TextStyleSpec(fontSize: 14),
            titleOutsideJustification:
                charts.OutsideJustification.middleDrawArea),
        charts.ChartTitle('Beat',
            behaviorPosition: charts.BehaviorPosition.start,
            titleStyleSpec: const charts.TextStyleSpec(
              fontSize: 14,
            ),
            titleOutsideJustification:
                charts.OutsideJustification.middleDrawArea),
        charts.ChartTitle('Beat per Minute (BPM)',
            behaviorPosition: charts.BehaviorPosition.top,
            titleStyleSpec: const charts.TextStyleSpec(
              fontSize: 14,
            ),
            titleOutsideJustification:
                charts.OutsideJustification.middleDrawArea),
      ],
      domainAxis: const charts.DateTimeAxisSpec(),
      dateTimeFactory: const charts.LocalDateTimeFactory(),
    );
  }
}
