

import 'package:flutter/material.dart';
import 'package:kline/indicators/indicator_data_handler.dart';
import 'package:kline/kline_config.dart';
import 'package:kline/indicators/indicator_line_painter.dart';
import 'package:kline/indicators/vol_painter.dart';
import 'package:kline/kline_data.dart';
import 'package:kline/main.dart';


class KLinePainter extends CustomPainter {

  final List<KLineData> klineData;
  final double beginIdx;

  KLinePainter(this.klineData, this.beginIdx);

  // late double highest;
  // late double lowest;

  final _riseRectPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.green
    ..isAntiAlias = true;
  final _riseLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.green
    ..isAntiAlias = true
    ..strokeWidth = 2.0;

  final _fallRectPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.red
    ..isAntiAlias = true;
  final _fallLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = Colors.red
    ..isAntiAlias = true
    ..strokeWidth = 2.0;

  final _minMaxLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xff999999)
    ..isAntiAlias = true
    ..strokeWidth = 1.0;

  final _rulerPaint = Paint()
  ..style = PaintingStyle.stroke
  ..color = Colors.blueGrey.withOpacity(0.2);

  // draw kline

  @override
  void paint(Canvas canvas, Size size) {
    if (klineData.isEmpty) return;


    List showSubIndicators = KLineConfig.shared.showSubIndicators;
    int subIndicatorCount = showSubIndicators.length;

    double spacing = KLineConfig.shared.spacing;
    double candleW = KLineConfig.candleWidth(size.width);
    int candleCount = KLineConfig.shared.candleCount;

    double mainTopMargin = KLineConfig.shared.klineMargin.top;
    double mainInfoMargin = KLineConfig.shared.mainIndicatorInfoMargin;

    double indicatorInfoHeight = KLineConfig.shared.indicatorInfoHeight;
    double indicatorSpacing = KLineConfig.shared.indicatorSpacing;

    // main draw area height
    double mainHeight = size.height - (KLineConfig.shared.subIndicatorHeight + indicatorSpacing) * subIndicatorCount
        - KLineConfig.shared.klineMargin.bottom;

    if (KLineConfig.shared.showMainIndicators.isNotEmpty) {
      mainTopMargin += (indicatorInfoHeight + mainInfoMargin);
    }
    mainHeight -= mainTopMargin;

    // if (KLineConfig.shared.isDebug) {
    //   KLineConfig.shared.drawDebugRect(canvas, Rect.fromLTWH(0, mainTopMargin, size.width, mainHeight), Colors.red.withOpacity(0.4));
    // }

    // calculating the highest lowest point
    if (beginIdx >= klineData.length) {
      // debugPrint('debug: beginIdx($beginIdx) >= klineData.length(${klineData.length}) return');
      return;
    }
    KLineData beginData = klineData[beginIdx.round()];
    double highest = beginData.high;
    double lowest = beginData.low;

    double maxVolume = beginData.volume;

    double highestIdx = beginIdx, lowestIdx = beginIdx;

    for (var i = beginIdx; i < beginIdx + candleCount; ++i) {
      if (i >= klineData.length) return;
      final data = klineData[i.round()];
      double high = data.high;
      double low = data.low;
      if (high > highest) {
        highest = high;
        highestIdx = i;
      }
      if (low < lowest) {
        lowest = low;
        lowestIdx = i;
      }
      double volume = data.volume;
      if (volume > maxVolume) maxVolume = volume;
    }

    double mainHighest = highest, mainLowest = lowest;

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
        if (mainIndicatorMax > highest) highest = mainIndicatorMax;
        if (mainIndicatorMin < lowest && mainIndicatorMin != 0.0) lowest = mainIndicatorMin;
      }
    }

    bool isShowBOLL = KLineConfig.shared.showMainIndicators.contains(IndicatorType.boll);
    if (isShowBOLL) {
      int bollPeriod = KLineConfig.shared.bollPeriod;
      int bollBandwidth = KLineConfig.shared.bollBandwidth;

      List bollData = IndicatorDataHandler.boll(klineData, bollPeriod, bollBandwidth, beginIdx);
      mainIndicatorData = bollData[0];
      double bollMax = bollData[1];
      double bollMin = bollData[2];

      if (bollMax > highest) highest = bollMax;
      if (bollMin < lowest && bollMin != 0.0) lowest = bollMin;
    }

    drawRulerLine(canvas, mainHeight, size.width, indicatorInfoHeight + KLineConfig.shared.mainIndicatorInfoMargin, mainHighest, mainLowest);
    
    // KDJ, WR
    Map<IndicatorType, dynamic> subIndicatorData = {};
    Map<IndicatorType, double> subHighest = {}, subLowest = {};
    IndicatorType kdjType = IndicatorType.kdj;
    if (showSubIndicators.contains(kdjType)) {
      List dataList = IndicatorDataHandler.kdj(klineData, KLineConfig.shared.kdjPeriods, beginIdx);
      if (dataList.length == 3) {
        subIndicatorData[kdjType] = dataList[0];
        subHighest[kdjType] = dataList[1];
        subLowest[kdjType] = dataList[2];
      }
    }
    IndicatorType wrType = IndicatorType.wr;
    if (showSubIndicators.contains(wrType)) {
      List dataList = IndicatorDataHandler.wr(klineData, KLineConfig.shared.wrPeriods, beginIdx);
      if (dataList.length == 3) {
        subIndicatorData[wrType] = dataList[0];
        subHighest[wrType] = dataList[1];
        subLowest[wrType] = dataList[2];
      }
    }
    
    // offset between the highest and lowest
    double valueOffset = highest - lowest;

    double rectLeft = 0.0;

    double highestX = 0.0, highestY = 0.0, lowestX = 0.0, lowestY = 0.0;

    double indexOffset =  beginIdx - beginIdx.round();
    double slideOffset = -indexOffset * (candleW + spacing);
    for (var i = beginIdx;i < beginIdx + candleCount;++i) {
      KLineData data = klineData[i.round()];

      double open = data.open;
      double high = data.high;
      double low = data.low;
      double close = data.close;

      double lineX = rectLeft + candleW * 0.5 + slideOffset;
      double lineTop = mainHeight * (1 - (high - lowest) / valueOffset) + mainTopMargin;
      double lineBtm = mainHeight * (1 - (low - lowest) / valueOffset) + mainTopMargin;

      if (i == highestIdx) {
        highestX = lineX;
        highestY = lineTop;
      }
      if (i == lowestIdx) {
        lowestX = lineX;
        lowestY = lineBtm;
      }

      if (close > open) {
        double candleH = (close - open) / valueOffset * mainHeight;
        double rectTop = mainHeight * (1 - (open - lowest) / valueOffset) + mainTopMargin;
        rectTop -= candleH; // rise starts at the top
        canvas.drawRect(
            Rect.fromLTWH(rectLeft + slideOffset, rectTop, candleW, candleH), _riseRectPaint);
        // draw line
        canvas.drawLine(Offset(lineX, lineTop), Offset(lineX, lineBtm), _riseLinePaint);
      } else {
        double candleH = (open - close) / valueOffset * mainHeight;
        double rectTop = mainHeight * (1 - (open - lowest) / valueOffset) + mainTopMargin;
        canvas.drawRect(
            Rect.fromLTWH(rectLeft + slideOffset, rectTop, candleW, candleH), _fallRectPaint);
        // draw line
        canvas.drawLine(Offset(lineX, lineTop), Offset(lineX, lineBtm), _fallLinePaint);
      }
      // debugPrint('drawRectLine:idx:${i.round()}, close:$close, centerX:$lineX');

      rectLeft += (candleW + spacing);
    }

    drawText(canvas, "$mainHighest", Offset(highestX, highestY), size);
    drawText(canvas, "$mainLowest", Offset(lowestX, lowestY), size);

    if (isShowMA || isShowEMA) {
      List<int> indicatorPeriods = isShowMA ? [7, 30] : [7, 25];
      IndicatorLinePainter.paint(canvas, size, mainHeight, KLineConfig.shared.showMainIndicators.first, mainIndicatorData, indicatorPeriods, beginIdx, slideOffset, highest, lowest, top: KLineConfig.shared.klineMargin.top, debugData: klineData);
    }

    if (isShowBOLL) {
      // List<int> indicatorPeriods = isShowMA ? [7, 30] : [7, 25];
      int bollPeriod = KLineConfig.shared.bollPeriod;
      IndicatorLinePainter.paint(canvas, size, mainHeight, KLineConfig.shared.showMainIndicators.first, mainIndicatorData, [bollPeriod,bollPeriod,bollPeriod], beginIdx, slideOffset, highest, lowest, top: KLineConfig.shared.klineMargin.top);
    }

    // draw sub indicator
    double indicatorH = KLineConfig.shared.subIndicatorHeight;

    if (KLineConfig.shared.showSubIndicators.contains(IndicatorType.vol)) {
      VolPainter(klineData, beginIdx).paint(canvas, size, maxVolume, slideOffset);
    }
    // if (KLineConfig.shared.showSubIndicators.contains(IndicatorType.macd)) {
    //   MACDPainter(klineData, beginIdx).paint(canvas, size, maxVolume);
    // }

    for (var idx = subIndicatorCount - 1;idx >= 0;--idx) {
      var type = showSubIndicators[idx];
      int orderIdx = subIndicatorCount - idx;
      double subTop = size.height - orderIdx * (indicatorH + indicatorSpacing) + indicatorSpacing;
      if (type.isLine) {
        IndicatorLinePainter.paint(canvas, size, indicatorH - KLineConfig.shared.indicatorInfoHeight,
            type, subIndicatorData[type], KLineConfig.shared.currentPeriods(type),
            beginIdx, slideOffset, subHighest[type] ?? 0.0, subLowest[type] ?? 0.0, top:subTop, lineColors: KLineConfig.shared.indicatorColors);
      }
    }

  }

  void drawText(Canvas canvas, String text, Offset offset, Size canvasSize) {

    // draw line
    double tranOffsetX = offset.dx < canvasSize.width * 0.5 ? 20 : -20;
    canvas.drawLine(Offset(offset.dx + (tranOffsetX > 0.0 ? 2 : -2), offset.dy), Offset(offset.dx + tranOffsetX, offset.dy), _minMaxLinePaint);

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

  void drawRulerLine(Canvas canvas, double height, double width, double top, double highestPrice, double lowestPrice) {

    for (var i = 1;i < 5;++i) {
      canvas.drawLine(Offset(0, height * i / 5 + top), Offset(width, height * i / 5 + top), _rulerPaint);
    }

    for (var i = 1;i < 5;++i) {
      canvas.drawLine(Offset(width * i / 5, top), Offset(width * i / 5, height + top), _rulerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
