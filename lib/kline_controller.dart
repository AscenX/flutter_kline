import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

enum IndicatorType {
  // main
  ma(name: "MA"),
  ema(name: "EMA"),
  boll(name: "BOLL"),
  // sar(name: 'SAR'),

  // sub
  vol(name: "VOL", isLine: false),
  maVol(name: "MAVOL"), // same as ma, use for volume's ma
  // macd(name: "MACD", isLine: false),
  kdj(name: "KDJ"),
  // rsi(name: "RSI"),
  wr(name: "WR"),
  obv(name: 'OBV');

  bool get isMain => index < IndicatorType.vol.index;

  final String name;
  final bool isLine; // just need draw a line
  const IndicatorType({required this.name, this.isLine = true});

  factory IndicatorType.fromName(String name) {
    if (!IndicatorType.values.map((e) => e.name).toList().contains(name)) {
      return IndicatorType.ma;
    }
    return IndicatorType.values.firstWhere((element) => element.name == name);
  }
}


class KLineController {

  bool isDebug = false;
  Color randomColor = Color.fromARGB(100, Random().nextInt(255), Random().nextInt(255), Random().nextInt(255));
  void drawDebugRect(Canvas canvas, Rect rect, Color color) {
    canvas.drawRect(rect, Paint()
      ..style = PaintingStyle.fill
      ..color = color);
  }

  /// current display candle count
  int candleCount = 30;
  /// spacing between candle
  double spacing = 2.0;
  /// current candle width
  double currentCandleW = 0.0;
  /// kline view margin
  var klineMargin = const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0);
  /// min candle count
  int minCandleCount = 7;
  /// max candle count
  int maxCandleCount = 39;

  double mainIndicatorInfoMargin = 5.0;
  double subIndicatorInfoMargin = 5.0;

  final StreamController longPressController = StreamController.broadcast();

  // info
  /// set null to fix text's width
  double? infoWidgetMaxWidth = 130;
  EdgeInsets infoWidgetMargin = const EdgeInsets.only(left: 8, top: 10);
  EdgeInsets infoWidgetPadding = const EdgeInsets.all(4);
  double infoWidgetBorderRadius = 4;
  Border infoWidgetBorder = Border.all(color: Colors.blueGrey.withOpacity(0.5), width: 0.5);

  // /// main indicator information top margin
  // double mainIndicatorInfoTopMargin = 5.0;

  /// spacing between indicator
  double indicatorSpacing = 10.0;
  /// sub indicator height
  double subIndicatorHeight = 50.0;
  /// indicator information height
  double indicatorInfoHeight = 15.0;

  // 主指标的展示高度 = 总高度 - 上下间距(klineMargin.vertical) - 副指标的高度 - 指标之间的间距高度
  // 副指标的展示高度 = 副指标的高度 - 指标信息的高度


  /// show main indicator
  List<IndicatorType> showMainIndicators = [IndicatorType.ma];
  /// show sub indicator
  List<IndicatorType> showSubIndicators = [IndicatorType.vol, IndicatorType.kdj];

  /// BOLL Calculating Period (N)
  int bollPeriod = 21;
  /// BOLL Bandwidth (P)
  int bollBandwidth = 2;

  /// VOL MA periods
  List<int> volMaPeriods = [7, 14];

  /// KDJ periods
  List<int> kdjPeriods = [9,3,3];
  /// WR periods
  List<int> wrPeriods = [7,14];

  List<int> currentPeriods(IndicatorType type) {
    KLineController config = KLineController.shared;
    if (type == IndicatorType.kdj) {
      return config.kdjPeriods;
    } else if (type == IndicatorType.wr) {
      return config.wrPeriods;
    } else if (type == IndicatorType.obv) {
      return [0];
    }
    return [];
  }

  List<Color> indicatorColors = [Colors.orange, Colors.purple, Colors.blue];

  static double candleWidth(double width) {
    double spacing = KLineController.shared.spacing;
    int candleCount = KLineController.shared.candleCount;
    // 蜡烛宽度 = 总宽度 / 蜡烛数 - 蜡烛之间的间距，间距数量和蜡烛数量相等
    double candleW = width / candleCount - spacing;
    KLineController.shared.currentCandleW = candleW;
    return candleW;
  }

  // singleton
  KLineController._internal();
  static final KLineController shared = KLineController._internal();
  factory KLineController() => shared;
}