import 'package:flutter/material.dart';
import 'package:kline/indicators/indicator_line_painter.dart';
import 'package:kline/kline_config.dart';
import 'package:kline/kline_data.dart';
import 'package:kline/indicators/indicator_data_handler.dart';


class VolPainter  {
  final List<KLineData> klineData;
  final double beginIdx;

  VolPainter(this.klineData, this.beginIdx);

  final riseRectPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.green
    ..isAntiAlias = true;

  final fallRectPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.red
    ..isAntiAlias = true;


  void paint(Canvas canvas, Size size, double max, double slideOffset) {
    if (klineData.isEmpty) return;

    double height = KLineConfig.shared.subIndicatorHeight;
    double width = size.width;

    double spacing = KLineConfig.shared.spacing;
    double candleW = KLineConfig.candleWidth(width);
    int candleCount = KLineConfig.shared.candleCount;

    double min = 0.0;
    // calculated MA volume
    List<int> maPeriods = KLineConfig.shared.volMaPeriods;
    List maDataList = IndicatorDataHandler.ma(klineData, maPeriods, beginIdx, isVol: true);
    List<List<double>> maList = [];
    double maMax = 0.0;
    if (maDataList.length == 3) {
      maList = maDataList.first;
      maMax = maDataList[1];
      double maMin = maDataList[2];
      if (maMax > max) max = maMax;
      // if (maMin < min) min = maMin;
    }

    double valueOffset = max;
    double rectLeft = spacing;

    List showSubIndicators = KLineConfig.shared.showSubIndicators;
    int subIndicatorCount = showSubIndicators.length;

    double originBtm = size.height;
    if (subIndicatorCount == 2 && showSubIndicators.first == IndicatorType.vol) {
      originBtm = size.height - KLineConfig.shared.subIndicatorHeight - KLineConfig.shared.indicatorSpacing;
    }
    // originBtm -= KLineConfig.shared.indicatorInfoHeight;


    for (var i = beginIdx;i < beginIdx + candleCount;++i) {
      KLineData data = klineData[i.round()];

      double open = data.open;
      double close = data.close;
      double volume = data.volumne;

      double volumeH = (height - KLineConfig.shared.indicatorInfoHeight) * volume / valueOffset;

      canvas.drawRect(
            Rect.fromLTWH(rectLeft + slideOffset, originBtm - volumeH, candleW, volumeH), close > open ? riseRectPaint : fallRectPaint);

      rectLeft += (candleW + spacing);
    }

    // debug
    // if (KLineConfig.shared.isDebug) {
    //   KLineConfig.shared.drawDebugRect(canvas, Rect.fromLTWH(0, originBtm - KLineConfig.shared.subIndicatorHeight, width, height), Colors.orange.withOpacity(0.5));
    // }

    // volume ma indicator
    IndicatorLinePainter.paint(canvas, Size(size.width, height), height - KLineConfig.shared.indicatorInfoHeight, IndicatorType.maVol, maList, maPeriods, beginIdx, slideOffset, max, min, top: originBtm - height, infoTopOffset: 0.0);

  }

  void drawMa(Canvas canvas, Size size) {

  }

}
