
import 'package:flutter/material.dart';
import 'package:kline/kline_config.dart';

class IndicatorLinePainter  {


  static void paint(Canvas canvas, Size size, double drawAreaHeight,
      IndicatorType type, List<List<double>> dataList, List<int> periods, double beginIdx, double slideOffset,
      double max, double min, {double top = 0.0, List<Color> lineColors = const [], double infoTopOffset = 0.0}) {
    if (periods.isEmpty) return;
    if (lineColors.isEmpty) lineColors = KLineConfig.shared.indicatorColors;

    double width = size.width;

    double spacing = KLineConfig.shared.spacing;
    double candleW = KLineConfig.candleWidth(width);
    int candleCount = KLineConfig.shared.candleCount;


    double valueOffset = max - min;
    double indicatorX = spacing + candleW * 0.5;

    List<String> maInfoList = [];
    for (int idx = 0;idx < periods.length; ++idx) {
      if (dataList.isEmpty) return;
      if (dataList.length == idx) continue;
      int period = periods[idx];

      Color color = (idx < (lineColors?.length ?? 0)) ? lineColors![idx] : const Color(0xff333333);
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

        if (dataList[idx].isEmpty) return;
        double value = dataList[idx][(i-beginIdx).round()];
        if (value < 0) continue;
        lastValue = value;
        double indicatorY = drawAreaHeight * (1 - (value - min) / valueOffset) + top;
        // if (!type.isMain) indicatorY += KLineConfig.shared.indicatorInfoHeight;
        indicatorY += KLineConfig.shared.indicatorInfoHeight;

        indicatorX = (i - beginIdx - 1) * (candleW + spacing) + candleW * 0.5 + slideOffset;

        if (lastX == 0.0 && lastY == 0.0) {
          lastX = indicatorX;
          lastY = indicatorY;
        }

        // if (!type.isMain) print("i:$i,period:${period},value:${value},max:$max,min:($min),offset:(${(value - min) / valueOffset}), height:$height---lastY:${lastY - topY - KLineConfig.shared.indicatorInfoHeight}");
        // if (!type.isMain) print("111111111 --- lastY:${lastY - topY - KLineConfig.shared.indicatorInfoHeight}--------$i---value:$value----max:$max---$min");
        canvas.drawLine(Offset(lastX, lastY), Offset(indicatorX, indicatorY), linePaint);

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

    if (KLineConfig.shared.isDebug) {

      double originY = top + KLineConfig.shared.indicatorInfoHeight;
      double rectH = drawAreaHeight;
      // if (!type.isMain) originY += KLineConfig.shared.indicatorInfoHeight;
      Rect rect = Rect.fromLTWH(0, originY, size.width, rectH);
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
      Color color = (i < (lineColors?.length ?? 0)) ? lineColors![i] : const Color(0xff666666);
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
