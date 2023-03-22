import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kline/kline_config.dart';
import 'package:kline/kline_data.dart';
import 'package:kline/kline_painter.dart';
import 'package:flutter/services.dart';

class _KLineViewState extends State<KLineView> {

  late final ScrollController _klineSc;

  var _hasInitScrollController = false;
  var _beginIdx = -1;
  var _lastBeginIdx = -1;

  var _currentScale = 1.0;

  var _dataLength = 0;

  void _initScrollController(double initOffset) {
    if (_hasInitScrollController) return;
    _klineSc = ScrollController(initialScrollOffset: initOffset);

    _klineSc.addListener(() {
      double offsetX = _klineSc.offset;
      _klineDidScroll(offsetX);
    });
    _hasInitScrollController = true;
  }

  void _klineDidScroll(double offsetX) {
    double candleW = KLineConfig.shared.currentCandleW;
    double spacing = KLineConfig.shared.spacing;
    int nowIdx = (offsetX / (candleW + spacing)).round();
    // print("_klineDidScroll--------- nowIdx:$nowIdx, data length:$_dataLength");
    if (nowIdx < 0) {
      _beginIdx = 0;
    } else {
        if (nowIdx + KLineConfig.shared.candleCount > _dataLength) {
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

    int count = 30;

    count = KLineConfig.shared.candleCount + ((1 - _currentScale) * 10).round();

    int maxCount = _dataLength > KLineConfig.shared.maxCandleCount ? KLineConfig.shared.maxCandleCount : _dataLength;
    count = count > maxCount ? maxCount : count;
    count = count < KLineConfig.shared.minCandleCount ? KLineConfig.shared.minCandleCount : count;
    // print("11111111 _currentScale:$_currentScale, count:$count");
    if (count + _beginIdx >= _dataLength) {
      _beginIdx = _dataLength - count;
    }
    KLineConfig.shared.candleCount = count;
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: KLineConfig.shared.klineMargin,
      color: KLineConfig.shared.isDebug ? Colors.deepPurple.withAlpha(30) : null,
      child: FutureBuilder(
            future: _loadJson(),
            initialData: const <KLineData>[],
            builder: (ctx, snapShot) {
              final klineData = snapShot.data as List<KLineData>;
              int dataLength = klineData.length;
              _dataLength = dataLength;
              if (dataLength == 0) {
                return const Center(child: Text('Loading...'),);
              }

              return LayoutBuilder(
                builder: (ctx, constraints) {
                  double containerW = constraints.biggest.width;
                  double containerH = constraints.biggest.height;

                  int candleCount = KLineConfig.shared.candleCount;
                  double candleW = KLineConfig.candleWidth(containerW);
                  double spacing = KLineConfig.shared.spacing;
                  // 计算滑动size
                  double contentSizeW = dataLength * (candleW + spacing);
                  if (_beginIdx < 0) { // init
                    // 展示的起始index
                    _beginIdx = dataLength - candleCount;
                    if (_beginIdx < 0) _beginIdx = 0;
                    // double beginOffset = _beginIdx / dataLength * contentSizeW;
                    double beginOffset = dataLength < candleCount ? 0.0 : contentSizeW - containerW;
                    _initScrollController(beginOffset);
                    print("init, size:($containerW, $containerH), _beginIdx:$_beginIdx, dataLength:$dataLength, candleCount: $candleCount");
                  }

                  // double klineHeight = containerH - KLineConfig.shared.indicatorHeight;

                  return CustomPaint(
                          painter: KLinePainter(klineData, _beginIdx),
                          size: Size(containerW, containerH),
                          child: GestureDetector(
                            onScaleUpdate: (details) {
                              _klineDidZoom(details);
                            },
                            child: SingleChildScrollView(
                              controller: _klineSc,
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: contentSizeW,
                                height: containerH,
                              ),
                            ),
                          )
                      );
                });
            })
    );
  }

  Future<List<KLineData>> _loadJson() async {
    final jsonStr = await rootBundle.loadString('lib/kline.json');
    List jsonList = json.decode(jsonStr);
    List<KLineData> dataList = [];
    for (var data in jsonList) {
      var klineData = KLineData.fromBinanceData(data);
      dataList.add(klineData);
    }
    return dataList;
  }

  @override
  void dispose() {
    _klineSc.dispose();
    super.dispose();
  }
}

class KLineView extends StatefulWidget {
  const KLineView({super.key});

  @override
  State<StatefulWidget> createState() => _KLineViewState();
}
