import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kline/kline_controller.dart';
import 'package:kline/kline_data.dart';


class KlineLongPressWidget extends StatelessWidget {

  final List<KLineData> klineData;
  final double beginIdx;

  const KlineLongPressWidget(this.klineData, this.beginIdx, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ValueListenableBuilder<Offset>(
        valueListenable: KLineController.shared.longPressOffset,
        builder: (ctx, offset, child) {
          return CustomPaint(
        foregroundPainter: KLineLongPressPainter(klineData, beginIdx, offset),
      );})
    );
  }
}

class KLineLongPressPainter extends CustomPainter {
  final List<KLineData> klineData;
  final double beginIdx;

  StreamSubscription? longPressSub;

  var longPressOffset = Offset.zero;

  KLineLongPressPainter(this.klineData, this.beginIdx, this.longPressOffset);
  // {
  //   longPressSub = KLineController.shared.longPressController.stream.listen((event) {
  //     if (event is Offset) {
  //       longPressOffset = event;
  //     }
  //   });
  // }

  final _linePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.blueGrey.withOpacity(0.2);


  // draw kline

  @override
  void paint(Canvas canvas, Size size) {
    if (klineData.isEmpty) return;

    // draw vertical line
    canvas.drawLine(Offset(longPressOffset.dx, 0), Offset(longPressOffset.dx, size.height), _linePaint);
    // draw horizontal line
    canvas.drawLine(Offset(0, longPressOffset.dy), Offset(size.width, longPressOffset.dy), _linePaint);
  }

  @override
  bool shouldRepaint(covariant KLineLongPressPainter oldDelegate) {
    // print('1111111 old delete:${oldDelegate.longPressOffset}');
    return longPressOffset.dx.round() != oldDelegate.longPressOffset.dx.round() ||
        longPressOffset.dy != oldDelegate.longPressOffset.dy;
  }
}