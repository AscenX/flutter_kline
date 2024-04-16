import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kline/kline_controller.dart';
import 'package:kline/kline_data.dart';

class KlineInfoWidget extends StatelessWidget {
  final List<KLineData> klineData;
  final double beginIdx;

  const KlineInfoWidget(this.klineData, this.beginIdx, {super.key});

  // @override
  // Widget build(BuildContext context) {
  //   var ctr = KLineController.shared;
  //   var style = const TextStyle(fontSize: 12);
  //   return ValueListenableBuilder<Offset>(
  //     valueListenable: ctr.longPressOffset,
  //     builder: (ctx, offset, child) {
  //       double offsetX = offset.dx;
  //       int index = (offsetX / (ctr.itemWidth + ctr.spacing) + beginIdx).round();
  //       if (offsetX != 0.0 && index >= 0 && index < klineData.length) {
  //         KLineData data = klineData[index];
  //         return Container(
  //           width: ctr.infoWidgetMaxWidth,
  //           margin: ctr.infoWidgetMargin,
  //           padding: ctr.infoWidgetPadding,
  //           decoration: BoxDecoration(
  //               borderRadius: BorderRadius.circular(ctr.infoWidgetBorderRadius),
  //               border: ctr.infoWidgetBorder,
  //               color: Colors.white.withOpacity(0.8)),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Text('high:${data.high.toStringAsFixed(2)}', style: style),
  //               Text('open:${data.open.toStringAsFixed(2)}', style: style),
  //               Text('low:${data.low.toStringAsFixed(2)}', style: style),
  //               Text('close:${data.close.toStringAsFixed(2)}', style: style),
  //               Text('volumn:${data.volume.toStringAsFixed(2)}', style: style),
  //               Text('time:${DateTime.fromMillisecondsSinceEpoch(data.time).toString()}', style: style),
  //             ],
  //           ),
  //         );
  //       }
  //       return const SizedBox();
  //     },
  //   );
  //

  @override
  Widget build(BuildContext context) {
    var ctr = KLineController.shared;
    return Container(
        child: ValueListenableBuilder<Offset>(
            valueListenable: KLineController.shared.longPressOffset,
            builder: (ctx, offset, child) {
              double offsetX = offset.dx;
              int index = (offsetX / (ctr.itemWidth + ctr.spacing) + beginIdx).round();
              if (offsetX != 0.0 && index >= 0 && index < klineData.length) {
                KLineData data = klineData[index];
                return Container(
                    width: ctr.infoWidgetMaxWidth,
                    margin: ctr.infoWidgetMargin,
                    padding: ctr.infoWidgetPadding,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(ctr.infoWidgetBorderRadius),
                        border: ctr.infoWidgetBorder,
                        color: Colors.white.withOpacity(0.8)),
                    child: CustomPaint(
                      size: Size(ctr.infoWidgetMaxWidth ?? 120, 110),
                      foregroundPainter: KLineLongPressInfoPainter(data, beginIdx, offset),
                    ));
              } else {
                return CustomPaint();
              }
            }));
  }
}

class KLineLongPressInfoPainter extends CustomPainter {
  final KLineData klineData;
  final double beginIdx;

  StreamSubscription? longPressSub;

  var longPressOffset = Offset.zero;

  KLineLongPressInfoPainter(this.klineData, this.beginIdx, this.longPressOffset);
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
    // if (klineData.isEmpty) return;

    // // draw vertical line
    // canvas.drawLine(Offset(longPressOffset.dx, 0), Offset(longPressOffset.dx, size.height), _linePaint);
    // // draw horizontal line
    // canvas.drawLine(Offset(0, longPressOffset.dy), Offset(size.width, longPressOffset.dy), _linePaint);

    drawText(canvas, 'high:${klineData.high.toStringAsFixed(2)}', Offset(8, 10), size);
    drawText(canvas, 'open:${klineData.open.toStringAsFixed(2)}', Offset(8, 24), size);
    drawText(canvas, 'low:${klineData.low.toStringAsFixed(2)}', Offset(8, 38), size);
    drawText(canvas, 'close:${klineData.close.toStringAsFixed(2)}', Offset(8, 52), size);
    drawText(canvas, 'volumn:${klineData.volume.toStringAsFixed(2)}', Offset(8, 66), size);
    drawText(canvas, 'time:${DateTime.fromMillisecondsSinceEpoch(klineData.time).toString()}', Offset(8, 80), size, width: size.width);

    //               Text('open:${data.open.toStringAsFixed(2)}', style: style),
    //               Text('low:${data.low.toStringAsFixed(2)}', style: style),
    //               Text('close:${data.close.toStringAsFixed(2)}', style: style),
    //               Text('volumn:${data.volume.toStringAsFixed(2)}', style: style),
    //               Text('time:${DateTime.fromMillisecondsSinceEpoch(data.time).toString()}', style: style),
  }

  void drawText(Canvas canvas, String text, Offset offset, Size canvasSize, {double? width}) {
    final painter = TextPainter(
        textDirection: TextDirection.ltr,
        maxLines: 2,
        text: TextSpan(
            text: text,
            style: const TextStyle(
              color: Color(0xff999999),
              fontSize: 12.0,
              height: 1.0,
            )))
      ..layout(maxWidth: width ?? canvasSize.width);

    double textWidth = painter.width;
    painter.paint(canvas, Offset(offset.dx, offset.dy));
  }

  @override
  bool shouldRepaint(covariant KLineLongPressInfoPainter oldDelegate) {
    // print('1111111 old delete:${oldDelegate.longPressOffset}');
    return longPressOffset.dx.round() != oldDelegate.longPressOffset.dx.round() || longPressOffset.dy != oldDelegate.longPressOffset.dy;
  }
}
