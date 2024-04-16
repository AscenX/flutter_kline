import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kline/kline_controller.dart';
import 'package:kline/kline_data.dart';
import 'package:kline/kline_info_widget.dart';
import 'package:kline/kline_painter.dart';

class KLineView extends StatefulWidget {

  final List<KLineData> data;

  const KLineView({super.key, required this.data});

  @override
  State<StatefulWidget> createState() => _KLineViewState();
}

class _KLineViewState extends State<KLineView> {

  late final ScrollController _klineScrollCtr;

  var _hasInitScrollController = false;
  var _beginIdx = -1.0;

  var _currentScale = 1.0;

  var _dataLength = 0;

  void _initScrollController(double initOffset) {
    if (_hasInitScrollController) return;
    _klineScrollCtr = ScrollController(initialScrollOffset: initOffset);

    _klineScrollCtr.addListener(() {
      double offsetX = _klineScrollCtr.offset;
      _klineDidScroll(offsetX);
    });
    _hasInitScrollController = true;
  }

  void _klineDidScroll(double offsetX) {
    double candleW = KLineController.shared.currentCandleW;
    double spacing = KLineController.shared.spacing;
    double nowIdx = offsetX / (candleW + spacing);
    // print("_klineDidScroll--------- nowIdx:$nowIdx, data length:$_dataLength");
    if (nowIdx < 0) {
      _beginIdx = 0.0;
    } else {
        if (nowIdx + KLineController.shared.candleCount > _dataLength) {
          // print("00000000 return:$nowIdx, count:${KLineConfig.shared.candleCount}, dataLength: $_dataLength");
          return;
        }
        _beginIdx = nowIdx;
    }
    // if (_lastBeginIdx == _beginIdx) return;
    setState(() {
      // _lastBeginIdx = _beginIdx;
    });
  }

  void _klineDidZoom(ScaleUpdateDetails details) {
    double scale = details.scale;
    if (details.pointerCount != 2) {
      return;
    }

    if (scale > 1.5) {
      _currentScale = 1.5;
    } else if (scale < 0.5) {
      _currentScale = 0.5;
    } else {
      _currentScale = scale;
    }
    
    int count = KLineController.shared.candleCount + ((1 - _currentScale) * 10).round();

    int maxCount = _dataLength > KLineController.shared.maxCandleCount ? KLineController.shared.maxCandleCount : _dataLength;
    count = count > maxCount ? maxCount : count;
    count = count < KLineController.shared.minCandleCount ? KLineController.shared.minCandleCount : count;
    if (count + _beginIdx >= _dataLength) {
      _beginIdx = (_dataLength - count).toDouble();
    }
    KLineController.shared.candleCount = count;
    setState(() {
    });
  }

  void _klineLongPress(double offsetX) {
    KLineController.shared.longPressController.add(offsetX);
  }

  @override
  Widget build(BuildContext context) {

    int dataLength = widget.data.length;
    _dataLength = dataLength;
    if (dataLength == 0) {
      return const Center(child: CircularProgressIndicator(
        strokeWidth: 2.0,
        color: Colors.blueGrey,
      ));
    }
    return Container(
      margin: KLineController.shared.klineMargin,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          double containerW = constraints.biggest.width;
          double containerH = constraints.biggest.height;

          int candleCount = KLineController.shared.candleCount;
          double candleW = KLineController.candleWidth(containerW);
          double spacing = KLineController.shared.spacing;
          // scroll size
          double contentSizeW = dataLength * (candleW + spacing);
          if (_beginIdx < 0) { // init
            // show begin index
            _beginIdx = (dataLength - candleCount).toDouble();
            if (_beginIdx < 0) _beginIdx = 0;
            // double beginOffset = _beginIdx / dataLength * contentSizeW;
            double beginOffset = dataLength < candleCount ? 0.0 : contentSizeW - containerW;
            _initScrollController(beginOffset);
          }

          // double klineHeight = containerH - KLineConfig.shared.indicatorHeight;

          return CustomPaint(
              painter: KLinePainter(widget.data, _beginIdx),
              size: Size(containerW, containerH),
              child: GestureDetector(
                onScaleUpdate: (details) {
                  _klineDidZoom(details);
                },
                onLongPressStart: (LongPressStartDetails details) {
                  // debugPrint('00000000 onLongPressStart:${details.localPosition.dx}');
                  _klineLongPress(details.localPosition.dx);
                },
                onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) {
                  // debugPrint('11111111 onLongPressMoveUpdate:${details.localPosition.dx}');
                  _klineLongPress(details.localPosition.dx);
                },
                onLongPressEnd: (LongPressEndDetails details) {
                  // debugPrint('22222222 onLongPressEnd details:${details.localPosition.dx}');
                  _klineLongPress(-1);
                },
                child: Stack(
                  children: [
                    Positioned.fill(child: SingleChildScrollView(
                      controller: _klineScrollCtr,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: contentSizeW,
                        height: containerH,
                      ),
                    )),
                    Align(
                      alignment: Alignment.topLeft,
                      child: KlineInfoWidget(widget.data, _beginIdx),
                    )
                  ],
                ),
              )
          );
        })
    );
  }

  @override
  void dispose() {
    _klineScrollCtr.dispose();
    super.dispose();
  }
}
