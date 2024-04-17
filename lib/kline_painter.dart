import 'package:flutter/material.dart';
import 'package:kline/indicators/indicator_data_handler.dart';
import 'package:kline/indicators/indicator_result.dart';
import 'package:kline/kline_controller.dart';
import 'package:kline/indicators/indicator_line_painter.dart';
import 'package:kline/indicators/vol_painter.dart';
import 'package:kline/kline_data.dart';

class KLinePainter extends CustomPainter {
  final List<KLineData> klineData;
  final double beginIdx;

  KLinePainter(this.klineData, this.beginIdx);


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

    debugPrint('debug: kline painter repaint');

    List showSubIndicators = KLineController.shared.showSubIndicators;
    int subIndicatorCount = showSubIndicators.length;

    double spacing = KLineController.shared.spacing;
    double itemW = KLineController.getItemWidth(size.width);
    int itemCount = KLineController.shared.itemCount;

    double mainTopMargin = KLineController.shared.klineMargin.top;
    double mainInfoMargin = KLineController.shared.mainIndicatorInfoMargin;

    double indicatorInfoHeight = KLineController.shared.indicatorInfoHeight;
    double indicatorSpacing = KLineController.shared.indicatorSpacing;

    // main draw area height
    double mainHeight =
        size.height - (KLineController.shared.subIndicatorHeight + indicatorSpacing) * subIndicatorCount - KLineController.shared.klineMargin.bottom;

    if (KLineController.shared.showMainIndicators.isNotEmpty) {
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

    for (var i = beginIdx; i < beginIdx + itemCount; ++i) {
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
    bool isShowMA = KLineController.shared.showMainIndicators.contains(IndicatorType.ma);
    bool isShowEMA = KLineController.shared.showMainIndicators.contains(IndicatorType.ema);
    if (isShowMA || isShowEMA) {
      List<int> indicatorPeriods = isShowMA ? [7, 30] : [7, 25];
      var res = IndicatorResult.empty;
      if (isShowMA) {
        res = IndicatorDataHandler.ma(klineData, indicatorPeriods, beginIdx);
      } else if (isShowEMA) {
        res = IndicatorDataHandler.ema(klineData, indicatorPeriods, beginIdx);
      }

      mainIndicatorData = res.data;
      double mainIndicatorMax = res.maxValue;
      double mainIndicatorMin = res.minValue;
      if (mainIndicatorMax > highest) highest = mainIndicatorMax;
      if (mainIndicatorMin < lowest && mainIndicatorMin != 0.0) lowest = mainIndicatorMin;
    }

    bool isShowBOLL = KLineController.shared.showMainIndicators.contains(IndicatorType.boll);
    if (isShowBOLL) {
      int bollPeriod = KLineController.shared.bollPeriod;
      int bollBandwidth = KLineController.shared.bollBandwidth;

      var res = IndicatorDataHandler.boll(klineData, bollPeriod, bollBandwidth, beginIdx);
      mainIndicatorData = res.data;
      double bollMax = res.maxValue;
      double bollMin = res.minValue;

      if (bollMax > highest) highest = bollMax;
      if (bollMin < lowest && bollMin != 0.0) lowest = bollMin;
    }

    drawRulerLine(canvas, mainHeight, size.width, indicatorInfoHeight + KLineController.shared.mainIndicatorInfoMargin, highest, lowest, size);

    // KDJ, WR
    Map<IndicatorType, dynamic> subIndicatorData = {};
    Map<IndicatorType, double> subHighest = {}, subLowest = {};
    IndicatorType kdjType = IndicatorType.kdj;
    if (showSubIndicators.contains(kdjType)) {
      var res = IndicatorDataHandler.kdj(klineData, KLineController.shared.kdjPeriods, beginIdx);
      subIndicatorData[kdjType] = res.data;
      subHighest[kdjType] = res.maxValue;
      subLowest[kdjType] = res.minValue;
    }
    IndicatorType wrType = IndicatorType.wr;
    if (showSubIndicators.contains(wrType)) {
      var res = IndicatorDataHandler.wr(klineData, KLineController.shared.wrPeriods, beginIdx);
      subIndicatorData[wrType] = res.data;
      subHighest[wrType] = res.maxValue;
      subLowest[wrType] = res.minValue;
    }

    IndicatorType obvType = IndicatorType.obv;
    if (showSubIndicators.contains(obvType)) {
      var res = IndicatorDataHandler.obv(klineData, beginIdx);
      subIndicatorData[obvType] = res.data;
      subHighest[obvType] = res.maxValue;
      subLowest[obvType] = res.minValue;
    }

    // offset between the highest and lowest
    double valueOffset = highest - lowest;

    double rectLeft = 0.0;

    double highestX = 0.0, highestY = 0.0, lowestX = 0.0, lowestY = 0.0;

    double indexOffset = beginIdx - beginIdx.round();
    double slideOffset = -indexOffset * (itemW + spacing);
    for (var i = beginIdx; i < beginIdx + itemCount; ++i) {
      KLineData data = klineData[i.round()];

      double open = data.open;
      double high = data.high;
      double low = data.low;
      double close = data.close;

      double lineX = rectLeft + itemW * 0.5 + slideOffset;
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
        double itemH = (close - open) / valueOffset * mainHeight;
        double rectTop = mainHeight * (1 - (open - lowest) / valueOffset) + mainTopMargin;
        rectTop -= itemH; // rise starts at the top
        canvas.drawRect(Rect.fromLTWH(rectLeft + slideOffset, rectTop, itemW, itemH), _riseRectPaint);
        // draw line
        canvas.drawLine(Offset(lineX, lineTop), Offset(lineX, lineBtm), _riseLinePaint);
      } else {
        double itemH = (open - close) / valueOffset * mainHeight;
        double rectTop = mainHeight * (1 - (open - lowest) / valueOffset) + mainTopMargin;
        canvas.drawRect(Rect.fromLTWH(rectLeft + slideOffset, rectTop, itemW, itemH), _fallRectPaint);
        // draw line
        canvas.drawLine(Offset(lineX, lineTop), Offset(lineX, lineBtm), _fallLinePaint);
      }
      // debugPrint('drawRectLine:idx:${i.round()}, close:$close, centerX:$lineX');

      rectLeft += (itemW + spacing);
    }

    drawHighestLowestText(canvas, "$mainHighest", Offset(highestX, highestY), size);
    drawHighestLowestText(canvas, "$mainLowest", Offset(lowestX, lowestY), size);

    if (isShowMA || isShowEMA) {
      List<int> indicatorPeriods = isShowMA ? [7, 30] : [7, 25];
      IndicatorLinePainter.paint(canvas, size, mainHeight, KLineController.shared.showMainIndicators.first, mainIndicatorData, indicatorPeriods,
          beginIdx, slideOffset, highest, lowest,
          top: KLineController.shared.klineMargin.top, debugData: klineData);
    }

    if (isShowBOLL) {
      // List<int> indicatorPeriods = isShowMA ? [7, 30] : [7, 25];
      int bollPeriod = KLineController.shared.bollPeriod;
      IndicatorLinePainter.paint(canvas, size, mainHeight, KLineController.shared.showMainIndicators.first, mainIndicatorData,
          [bollPeriod, bollPeriod, bollPeriod], beginIdx, slideOffset, highest, lowest,
          top: KLineController.shared.klineMargin.top);
    }

    // draw sub indicator
    double indicatorH = KLineController.shared.subIndicatorHeight;

    // if (KLineConfig.shared.showSubIndicators.contains(IndicatorType.macd)) {
    //   MACDPainter(klineData, beginIdx).paint(canvas, size, maxVolume);
    // }


    for (var idx = subIndicatorCount - 1; idx >= 0; --idx) {
      var type = showSubIndicators[idx];
      int orderIdx = subIndicatorCount - idx;
      double subTop = size.height - orderIdx * (indicatorH + indicatorSpacing) + indicatorSpacing;

      double subHighestValue = type == IndicatorType.vol ? maxVolume : subHighest[type] ?? 0.0;
      double subLowestValue = subLowest[type] ?? 0.0;

      // draw ruler text
      drawSubIndicatorRulerText(canvas, indicatorH, size.width, subTop, subHighestValue, subLowestValue, size);

      if (type == IndicatorType.vol) {
        VolPainter(klineData, beginIdx).paint(canvas, size, maxVolume, slideOffset);
      }

      if (type.isLine) {
        IndicatorLinePainter.paint(canvas, size, indicatorH - KLineController.shared.indicatorInfoHeight, type, subIndicatorData[type],
            KLineController.shared.currentPeriods(type), beginIdx, slideOffset, subHighest[type] ?? 0.0, subLowest[type] ?? 0.0,
            top: subTop, lineColors: KLineController.shared.indicatorColors);
      }
    }
  }

  void drawSubIndicatorRulerText(Canvas canvas, double height, double width, double top, double highest, double lowest, Size canvasSize) {
    // draw highest text
    drawText(canvas, highest.toStringAsFixed(2), Offset(width - 56, top + KLineController.shared.indicatorInfoHeight), canvasSize, width: 56);

    // draw lowest text
    drawText(canvas, lowest.toStringAsFixed(2), Offset(width - 56, top + height - 14.0), canvasSize, width: 56);
  }

  /// draw Text in canvas
  void drawText(Canvas canvas, String text, Offset offset, Size canvasSize, {double? width}) {
    final painter = TextPainter(
        textDirection: TextDirection.ltr,
        maxLines: 1,
        text: TextSpan(
            text: text,
            style: const TextStyle(
              color: Color(0xff999999),
              fontSize: 12.0,
              height: 1.0,
            )))
      ..layout();

    double textWidth = painter.width;
    painter.paint(canvas, Offset(width != null ? (offset.dx + width! - textWidth) : offset.dx, offset.dy));
  }

  void drawHighestLowestText(Canvas canvas, String text, Offset offset, Size canvasSize) {
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
            )))
      ..layout();

    double textHeight = 15.0;
    double offsetY = offset.dy - textHeight * 0.5;
    painter.paint(canvas, Offset(offset.dx + tranOffsetX + (tranOffsetX > 0 ? 5 : -painter.width - 5), offsetY));
  }

  void drawRulerLine(Canvas canvas, double height, double width, double top, double highestPrice, double lowestPrice, Size canvasSize) {
    double priceOffset = highestPrice - lowestPrice;
    var ctr = KLineController.shared;
    double scaleTop = ctr.mainIndicatorInfoMargin + ctr.indicatorInfoHeight + ctr.klineMargin.top;
    double scaleHeight = height; // mainHeight - fontHeight
    // draw main ruler
    for (var i = 0; i < 5; ++i) {
      // draw vertical line
      canvas.drawLine(Offset(width * i / 5, 0), Offset(width * i / 5, canvasSize.height), _rulerPaint);
      // draw horizontal line
      if (i > 0) canvas.drawLine(Offset(0, height * i / 4 + top), Offset(width, height * i / 4 + top), _rulerPaint);
      // draw rule text
      drawText(canvas, '${(highestPrice - priceOffset * i / 4).toStringAsFixed(2)}', Offset(width - 56, scaleHeight * i / 4 + scaleTop - 12), canvasSize, width: 56);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
