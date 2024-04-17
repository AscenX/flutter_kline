import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kline/kline_controller.dart';
import 'package:kline/kline_data.dart';
import 'package:kline/kline_info_widget.dart';
import 'package:kline/kline_long_press_widget.dart';
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
    KLineController.shared.longPressOffset.update(Offset.zero);
    double itemW = KLineController.shared.itemWidth;
    double spacing = KLineController.shared.spacing;
    double nowIdx = offsetX / (itemW + spacing);
    if (nowIdx < 0) {
      _beginIdx = 0.0;
    } else {
        if (nowIdx + KLineController.shared.itemCount > _dataLength) {
          // print("00000000 return:$nowIdx, count:${KLineConfig.shared.itemCount}, dataLength: $_dataLength");
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
    
    int count = KLineController.shared.itemCount + ((1 - _currentScale) * 10).round();

    int maxCount = _dataLength > KLineController.shared.maxCount ? KLineController.shared.maxCount : _dataLength;
    count = count > maxCount ? maxCount : count;
    count = count < KLineController.shared.minCount ? KLineController.shared.minCount : count;
    if (count + _beginIdx >= _dataLength) {
      _beginIdx = (_dataLength - count).toDouble();
    }
    KLineController.shared.itemCount = count;
    setState(() {
    });
  }

  void _klineLongPress(Offset offset) {
    KLineController.shared.longPressOffset.update(offset);
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

          int itemCount = KLineController.shared.itemCount;
          double itemW = KLineController.getItemWidth(containerW);
          double spacing = KLineController.shared.spacing;
          // scroll size
          double contentSizeW = dataLength * (itemW + spacing);
          if (_beginIdx < 0) { // init
            // show begin index
            _beginIdx = (dataLength - itemCount).toDouble();
            if (_beginIdx < 0) _beginIdx = 0;
            // double beginOffset = _beginIdx / dataLength * contentSizeW;
            double beginOffset = dataLength < itemCount ? 0.0 : contentSizeW - containerW;
            _initScrollController(beginOffset);
          }
          return CustomPaint(
              painter: KLinePainter(widget.data, _beginIdx),
              size: Size(containerW, containerH),
              child: GestureDetector(
                onScaleUpdate: (details) => _klineDidZoom(details),
                onLongPressStart: (details) => _klineLongPress(details.localPosition),
                onLongPressMoveUpdate: (details) => _klineLongPress(details.localPosition),
                onLongPressEnd: (details) => _klineLongPress(details.localPosition),
                onTap: () => _klineLongPress(Offset.zero),
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
                      child: RepaintBoundary(
                        child: KlineInfoWidget(widget.data, _beginIdx),
                      ),
                    ),
                    Positioned.fill(child: RepaintBoundary(
                      child: KlineLongPressWidget(widget.data, _beginIdx),
                    ))
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
