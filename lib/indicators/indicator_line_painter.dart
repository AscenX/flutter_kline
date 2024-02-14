
import 'package:flutter/material.dart';
import 'package:kline/kline_config.dart';
import 'package:kline/kline_data.dart';

class IndicatorLinePainter  {


  static void paint(Canvas canvas, Size size, double drawAreaHeight,
      IndicatorType type, List<List<double>> dataList, List<int> periods, double beginIdx, double slideOffset,
      double maxValue, double minValue, {double top = 0.0, List<Color> lineColors = const [], double infoTopOffset = 0.0, List<KLineData> debugData = const []}) {
    if (periods.isEmpty) return;
    if (lineColors.isEmpty) lineColors = KLineConfig.shared.indicatorColors;

    double width = size.width;

    double spacing = KLineConfig.shared.spacing;
    double candleW = KLineConfig.candleWidth(width);
    int candleCount = KLineConfig.shared.candleCount;

    double valueOffset = maxValue - minValue;
    double indicatorX = spacing + candleW * 0.5;

    List<String> maInfoList = [];
    for (int idx = 0;idx < periods.length; ++idx) {
      if (dataList.isEmpty) return;
      if (dataList.length == idx) {
        debugPrint('debug:dataList.length == idx');
        continue;
      }
      int period = periods[idx];

      Color color = (idx < lineColors.length) ? lineColors[idx] : const Color(0xff333333);
      var linePaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = color
        ..isAntiAlias = true
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 1;

      double lastY = 0.0;
      double lastX = 0.0;
      double lastValue = 0.0;

      for (var i = beginIdx;i < beginIdx + candleCount;++i) {
        if (dataList[idx].isEmpty) {
          debugPrint('debug:dataList[idx].isEmpty');
          return;
        }

        if ((i - beginIdx).round() >= dataList[idx].length) {
          debugPrint('debug:range error, type:$type, index:${i - beginIdx}, length:${dataList[idx].length}');
          continue;
        }
        if (type == IndicatorType.kdj) {
          int firstPeriod = periods.first;
          if (i.round() < firstPeriod - 1) continue;
        } else {
          if (i.round()  < period - 1) continue;
        }

        double value = dataList[idx][(i - beginIdx).round()];
        // if (type == IndicatorType.kdj && periods.length == 3) {
        //   debugPrint('111111 index:${(i - beginIdx).round()}, i:$i, begin:$beginIdx value:$value');
        // }
        lastValue = value;
        double indicatorY = drawAreaHeight * (1 - (value - minValue) / valueOffset) + top;
        if (type.isMain) indicatorY += KLineConfig.shared.mainIndicatorInfoMargin;
        indicatorY += KLineConfig.shared.indicatorInfoHeight;

        indicatorX = (i - beginIdx) * (candleW + spacing) + candleW * 0.5 + slideOffset;

        if (lastX == 0.0 && lastY == 0.0) {
          lastX = indicatorX;
          lastY = indicatorY;
        }

        canvas.drawLine(Offset(lastX, lastY), Offset(indicatorX, indicatorY), linePaint);
        if (type == IndicatorType.ma) {
          // debugPrint('drawLine: beginIdx:$beginIdx, idx:${i.round()},close:${debugData[i.round()].close} ($indicatorX, $indicatorY), slideOffset:$slideOffset, dataIdx:${(i - beginIdx).round()}, total:${dataList[idx].length}, candleCount:${KLineConfig.shared.candleCount}');
        }
        lastY = indicatorY;
        lastX = indicatorX;
      }
      if (lastValue > 0.0) {
        if (type == IndicatorType.kdj) {
          if (idx == 0) {
            maInfoList.add("${type.name}($period, ${periods[1]}, ${periods[2]})");
            maInfoList.add("K ${lastValue.toStringAsFixed(2)}");
          } else if (idx == 1) {
            maInfoList.add("D ${lastValue.toStringAsFixed(2)}");
          } else if (idx == 2) {
            maInfoList.add("J ${lastValue.toStringAsFixed(2)}");
          }
        } else {
          maInfoList.add("${type.name}($period): ${lastValue.toStringAsFixed(2)}");
        }
      }
    }

    // line debug area
    if (KLineConfig.shared.isDebug) {

      double originY = top + KLineConfig.shared.indicatorInfoHeight;
      if (type.isMain && KLineConfig.shared.showMainIndicators.isNotEmpty) {
        originY += KLineConfig.shared.mainIndicatorInfoMargin;
      }
      Rect rect = Rect.fromLTWH(0, originY, size.width, drawAreaHeight);
      KLineConfig.shared.drawDebugRect(canvas, rect, Colors.green .withAlpha(50));
    }

    showIndicatorInfo(canvas, size, type, maInfoList, top, lineColors: lineColors, topOffset: infoTopOffset);

  }

  static void showIndicatorInfo(Canvas canvas, Size size, IndicatorType type, List<String> infoList, double top, {List<Color> lineColors = const [], double topOffset = 0.0}) {
    final painter = TextPainter(textDirection: TextDirection.ltr);

    double lastWidth = 0.0;
    for (var i = 0;i < infoList.length;++i) {
      if (i >= infoList.length) return;
      String info = infoList[i];
      Color color = (i < lineColors.length) ? lineColors[i] : const Color(0xff666666);
      painter.text = TextSpan(text: info, style: TextStyle(
          color: color,
          fontSize: 13.0,
          height: 0.0,
          // backgroundColor: Colors.pink
      ));
      painter.layout(maxWidth: size.width);



      double offsetX = lastWidth + (i == 0 ? 5 : i * 10);
      double originY = top + topOffset;
      // originY = type.isMain ? originY  : originY;
      painter.paint(canvas, Offset(offsetX, originY));
      lastWidth += painter.width;
    }

    if (KLineConfig.shared.isDebug) {
      double originY = top + topOffset;
      double rectH = KLineConfig.shared.indicatorInfoHeight;
      Rect rect = Rect.fromLTWH(0, originY, size.width, rectH);
      KLineConfig.shared.drawDebugRect(canvas, rect, Colors.blue.withAlpha(50));
    }

  }
}
