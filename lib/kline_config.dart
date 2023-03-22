
import 'dart:math';

import 'package:flutter/material.dart';


enum IndicatorType {
  ma(name: "MA"),
  ema(name: "EMA"),
  // boll(name: "BOLL"),

  vol(name: "VOL", isLine: false),
  // macd(name: "MACD", isLine: false),
  kdj(name: "KDJ"),
  // rsi(name: "RSI"),
  wr(name: "WR");

  bool get isMain => index < IndicatorType.vol.index;

  final String name;
  final bool isLine; // 只是画线的指标
  const IndicatorType({required this.name, this.isLine = true});

  factory IndicatorType.fromName(String name) {
    for (var type in IndicatorType.values) {
      if (name == type.name) {
        return type;
      }
    }
    return IndicatorType.ma;
  }
}


class KLineConfig {

  bool isDebug = false;
  Color randomColor = Color.fromARGB(100, Random().nextInt(255), Random().nextInt(255), Random().nextInt(255));
  void drawDebugRect(Canvas canvas, Rect rect, Color color) {
    canvas.drawRect(rect, Paint()
      ..style = PaintingStyle.fill
      ..color = color);
  }


  /// 一屏默认显示的蜡烛数量
  int candleCount = 30;
  /// 蜡烛之间的间距
  double spacing = 2.0;
  /// 当前蜡烛的宽度
  double currentCandleW = 0.0;
  /// k线图间距
  var klineMargin = const EdgeInsets.fromLTRB(0, 25, 0, 10);
  /// k线蜡烛最小数量
  int minCandleCount = 7;
  /// k线蜡烛最大数量
  int maxCandleCount = 39;

  /// 指标之间的上下间距
  double indicatorSpacing = 10.0;
  /// 指标信息的上间距
  double indicatorInfoTopMargin = 5.0;
  /// 副指标的高度
  double subIndicatorHeight = 50.0;
  /// 指标信息的高度
  double indicatorInfoHeight = 15.0;

  // 主指标的展示高度 = 总高度 - 上下间距(klineMargin.vertical) - 副指标的高度 - 指标之间的间距高度
  // 副指标的展示高度 = 副指标的高度 - 指标信息的高度


  /// show main indicator
  List<IndicatorType> showMainIndicators = [IndicatorType.ma];
  /// show sub indicator
  List<IndicatorType> showSubIndicators = [IndicatorType.vol, IndicatorType.kdj];

  /// BOLL Calculating Period (N)
  int bollPeriod = 20;
  /// BOLL Bandwidth (P)
  int bollBandwidth = 2;

  /// VOL MA periods
  List<int> volMaPeriods = [5, 10];

  /// KDJ periods
  List<int> kdjPeriods = [9,3,3];
  /// WR periods
  List<int> wrPeriods = [7,14];

  List<int> currentPeriods(IndicatorType type) {
    KLineConfig config = KLineConfig.shared;
    if (type == IndicatorType.kdj) {
      return config.kdjPeriods;
    } else if (type == IndicatorType.wr) {
      return config.wrPeriods;
    }
    return [];
  }

  List<Color> indicatorColors = [Colors.orange, Colors.purple, Colors.blue];

  static double candleWidth(double width) {
    double spacing = KLineConfig.shared.spacing;
    int candleCount = KLineConfig.shared.candleCount;
    // 蜡烛宽度 = 总宽度 / 蜡烛数 - 蜡烛之间的间距，间距数量和蜡烛数量相等
    double candleW = width / candleCount - spacing;
    KLineConfig.shared.currentCandleW = candleW;
    return candleW;
  }

  // 单例
  KLineConfig._internal();
  static final KLineConfig shared = KLineConfig._internal();
  factory KLineConfig() => shared;
}