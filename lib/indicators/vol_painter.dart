import 'package:flutter/material.dart';
import 'package:kline/indicators/indicator_line_painter.dart';
import 'package:kline/kline_config.dart';
import 'package:kline/kline_data.dart';
import 'package:kline/indicators/indicator_data_handler.dart';


class VolPainter  {
  final List<KLineData> klineData;
  final int beginIdx;

  VolPainter(this.klineData, this.beginIdx);


  void paint(Canvas canvas, Size size, double max) {
    if (klineData.isEmpty) return;

    var riseRectPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.green
      ..isAntiAlias = true;

    var fallRectPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.red
      ..isAntiAlias = true;


    double height = KLineConfig.shared.subIndicatorHeight;
    double width = size.width;

    double spacing = KLineConfig.shared.spacing;
    double candleW = KLineConfig.candleWidth(width);
    int candleCount = KLineConfig.shared.candleCount;

    double min = 0.0;
    // 计算MA线
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

    // 最高最低差
    double valueOffset = max;
    double rectLeft = spacing;

    List showSubIndicators = KLineConfig.shared.showSubIndicators;
    int subIndicatorCount = showSubIndicators.length;

    double originY = size.height;
    if (subIndicatorCount == 2 && showSubIndicators.first == IndicatorType.vol) {
        originY = size.height - KLineConfig.shared.subIndicatorHeight - KLineConfig.shared.indicatorSpacing;
    }

    for (var i = beginIdx;i < beginIdx + candleCount;++i) {
      KLineData data = klineData[i];

      double open = data.open;
      double close = data.close;
      double volume = data.volumne;

      double volumeH = height * volume / valueOffset;

      canvas.drawRect(
            Rect.fromLTWH(rectLeft, originY - volumeH, candleW, volumeH), close > open ? riseRectPaint : fallRectPaint);

      rectLeft += (candleW + spacing);
    }

    IndicatorLinePainter.paint(canvas, Size(size.width, height), height, IndicatorType.ma, maList, maPeriods, beginIdx, max, min, top: originY - height, infoTopOffset: 15);

  }

  void drawMa(Canvas canvas, Size size) {

  }

}
