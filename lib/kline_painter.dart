

import 'package:flutter/material.dart';
import 'package:kline/indicators/indicator_data_handler.dart';
import 'package:kline/kline_config.dart';
import 'package:kline/indicators/indicator_line_painter.dart';
import 'package:kline/indicators/vol_painter.dart';
import 'package:kline/kline_data.dart';


class KLinePainter extends CustomPainter {
  final List<KLineData> klineData;
  final int beginIdx;

  late double max;
  late double min;

  late final IndicatorLinePainter _linePainter;
  late final IndicatorLinePainter _subLinePainter;

  KLinePainter(this.klineData, this.beginIdx);

  // k线数据

  @override
  void paint(Canvas canvas, Size size) {
    if (klineData.isEmpty) return;

    var riseRectPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.green
      ..isAntiAlias = true;
    var riseLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.green
      ..isAntiAlias = true
      ..strokeWidth = 2.0;

    var fallRectPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.red
      ..isAntiAlias = true;
    var fallLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.red
      ..isAntiAlias = true
      ..strokeWidth = 2.0;

    List showSubIndicators = KLineConfig.shared.showSubIndicators;
    int subIndicatorCount = showSubIndicators.length;

    double mainHeight = size.height;
    if (subIndicatorCount == 1) {
      mainHeight = size.height - KLineConfig.shared.subIndicatorHeight - KLineConfig.shared.indicatorSpacing;
    } else if (subIndicatorCount == 2) {
      mainHeight = size.height - (KLineConfig.shared.subIndicatorHeight + KLineConfig.shared.indicatorSpacing) * 2;
    }
    double width = size.width;

    double spacing = KLineConfig.shared.spacing;
    double candleW = KLineConfig.candleWidth(width);
    int candleCount = KLineConfig.shared.candleCount;

    // 计算最高最低点
    if (beginIdx >= klineData.length) return;
    KLineData beginData = klineData[beginIdx];
    double max = beginData.high;
    double min = beginData.low;

    double maxVolume = beginData.volumne;

    int maxIdx = beginIdx,minIdx = beginIdx;

    for (var i = beginIdx; i < beginIdx + candleCount; ++i) {
      if (i >= klineData.length) return;
      final data = klineData[i];
      double high = data.high;
      double low = data.low;
      if (high > max) {
        max = high;
        maxIdx = i;
      }
      if (low < min) {
        min = low;
        minIdx = i;
      }
      double volume = data.volumne;
      if (volume > maxVolume) maxVolume = volume;
    }

    double mainMax = max, mainMin = min;

    List<List<double>> mainIndicatorData = [];
    bool isShowMA = KLineConfig.shared.showMainIndicators.contains(IndicatorType.ma);
    bool isShowEMA = KLineConfig.shared.showMainIndicators.contains(IndicatorType.ema);
    if (isShowMA || isShowEMA) {
      List<int> indicatorPeriods = isShowMA ? [7, 30] : [7, 25];
      List handleData = [];
      if (isShowMA) {
        handleData = IndicatorDataHandler.ma(klineData, indicatorPeriods, beginIdx);
      } else if (isShowEMA) {
        handleData = IndicatorDataHandler.ema(klineData, indicatorPeriods, beginIdx);
      }
      if (handleData.length == 3) {
        mainIndicatorData = handleData.first;
        double mainIndicatorMax = handleData[1];
        double mainIndicatorMin = handleData[2];
        if (mainIndicatorMax > max) max = mainIndicatorMax;
        if (mainIndicatorMin < min && mainIndicatorMin != 0.0) min = mainIndicatorMin;
      }
    }
    // KDJ, WR
    Map subIndicatorData = {},subMax = {}, subMin = {};
    IndicatorType kdjType = IndicatorType.kdj;
    if (showSubIndicators.contains(kdjType)) {
      List dataList = IndicatorDataHandler.kdj(klineData, KLineConfig.shared.kdjPeriods, beginIdx);
      if (dataList.length == 3) {
        subIndicatorData[kdjType] = dataList[0];
        subMax[kdjType] = dataList[1];
        subMin[kdjType] = dataList[2];
      }
    }
    IndicatorType wrType = IndicatorType.wr;
    if (showSubIndicators.contains(wrType)) {
      List dataList = IndicatorDataHandler.wr(klineData, KLineConfig.shared.wrPeriods, beginIdx);
      if (dataList.length == 3) {
        subIndicatorData[wrType] = dataList[0];
        subMax[wrType] = dataList[1];
        subMin[wrType] = dataList[2];
      }
    }




    // 最高最低差
    double valueOffset = max - min;

    double rectLeft = 0.0;

    double maxX = 0.0, maxY = 0.0, minX = 0.0, minY = 0.0;

    for (var i = beginIdx;i < beginIdx + candleCount;++i) {
      KLineData data = klineData[i];

      double open = data.open;
      double high = data.high;
      double low = data.low;
      double close = data.close;

      double lineX = rectLeft + candleW * 0.5;
      double lineTop = mainHeight * (1 - (high - min) / valueOffset);
      double lineBtm = mainHeight * (1 - (low - min) / valueOffset);

      if (i == maxIdx) {
        maxX = lineX;
        maxY = lineTop;
      }
      if (i == minIdx) {
        minX = lineX;
        minY = lineBtm;
      }

      if (close > open) {
        double candleH = (close - open) / valueOffset * mainHeight;
        double rectTop = mainHeight * (1 - (open - min) / valueOffset);
        rectTop -= candleH; // 涨的起点在上面
        canvas.drawRect(
            Rect.fromLTWH(rectLeft, rectTop, candleW, candleH), riseRectPaint);
        // 画线
        canvas.drawLine(Offset(lineX, lineTop), Offset(lineX, lineBtm), riseLinePaint);
      } else {
        double candleH = (open - close) / valueOffset * mainHeight;
        double rectTop = mainHeight * (1 - (open - min) / valueOffset);
        canvas.drawRect(
            Rect.fromLTWH(rectLeft, rectTop, candleW, candleH), fallRectPaint);
        // 画线
        canvas.drawLine(Offset(lineX, lineTop), Offset(lineX, lineBtm), fallLinePaint);
      }

      rectLeft += (candleW + spacing);
    }

    drawText(canvas, "$mainMax", Offset(maxX, maxY), size);
    drawText(canvas, "$mainMin", Offset(minX, minY), size);

    if (isShowMA || isShowEMA) {
      List<int> indicatorPeriods = isShowMA ? [7, 30] : [7, 25];
      IndicatorLinePainter.paint(canvas, size, mainHeight, KLineConfig.shared.showMainIndicators.first, mainIndicatorData, indicatorPeriods, beginIdx, max, min, top: 0.0);
    }

    // draw sub indicator
    double indicatorH = KLineConfig.shared.subIndicatorHeight;

    if (KLineConfig.shared.showSubIndicators.contains(IndicatorType.vol)) {
      VolPainter(klineData, beginIdx).paint(canvas, size, maxVolume);
    }
    // if (KLineConfig.shared.showSubIndicators.contains(IndicatorType.macd)) {
    //   MACDPainter(klineData, beginIdx).paint(canvas, size, maxVolume);
    // }

    for (var idx = subIndicatorCount - 1;idx >= 0;--idx) {
      var type = showSubIndicators[idx];
      int orderIdx = subIndicatorCount - idx;
      double subTop = size.height - orderIdx * (indicatorH + spacing) + spacing;
      if (type.isLine) {
        IndicatorLinePainter.paint(canvas, size, indicatorH,
            type, subIndicatorData[type], KLineConfig.shared.currentPeriods(type),
            beginIdx, subMax[type], subMin[type], top:subTop, lineColors: KLineConfig.shared.indicatorColors);
      }
    }

  }

  void drawText(Canvas canvas, String text, Offset offset, Size canvasSize) {
    var minMaxLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xff999999)
      ..isAntiAlias = true
      ..strokeWidth = 1.0;

    // 画线
    double tranOffsetX = offset.dx < canvasSize.width * 0.5 ? 20 : -20;
    canvas.drawLine(Offset(offset.dx + (tranOffsetX > 0.0 ? 2 : -2), offset.dy), Offset(offset.dx + tranOffsetX, offset.dy), minMaxLinePaint);

    final painter = TextPainter(
        textDirection: TextDirection.ltr,
        maxLines: 1,
        text: TextSpan(
            text: text,
            style: const TextStyle(
              color: Color(0xff666666),
              fontSize: 13.0,
              height: 0.0,
            )
        )
    )..layout();

    double textHeight = 15.0;
    double offsetY = offset.dy - textHeight * 0.5;
    painter.paint(canvas, Offset(offset.dx + tranOffsetX + (tranOffsetX > 0 ? 5 : -painter.width - 5), offsetY));
  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
