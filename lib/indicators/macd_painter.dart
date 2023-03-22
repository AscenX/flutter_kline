import 'package:flutter/material.dart';
import 'package:kline/kline_config.dart';
import 'package:kline/kline_data.dart';


class MACDPainter  {
  final List<KLineData> klineData;
  final int beginIdx;

  MACDPainter(this.klineData, this.beginIdx);


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

    // 最高最低差
    double valueOffset = max;
    double rectLeft = spacing;
    double btmMargin = KLineConfig.shared.klineMargin.bottom;

    List showSubIndicators = KLineConfig.shared.showSubIndicators;
    int subIndicatorCount = showSubIndicators.length;

    double originY = size.height;
    // if (subIndicatorCount > 0 && showSubIndicators.first == IndicatorType.macd) {
    //   originY = size.height - KLineConfig.shared.subIndicatorHeight - KLineConfig.shared.indicatorSpacing;
    // }

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

  }
}
