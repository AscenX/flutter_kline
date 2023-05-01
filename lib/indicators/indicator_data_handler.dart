
import 'package:kline/kline_config.dart';
import 'package:kline/kline_data.dart';

class IndicatorDataHandler {

  static List ma(List<KLineData> klineData, List<int> periods, double beginIdx, {bool isVol=false}) {
    if (klineData.isEmpty || periods.isEmpty) return [];

    List<List<double>> maData = [];
    double max = 0.0;
    double min = 0.0;

    int candleCount = KLineConfig.shared.candleCount;

    for (var i = 0;i < periods.length; ++i) {

      List<double> maList = [];
      int period = periods[i];

      for (var j = beginIdx;j <= beginIdx + candleCount;++j) {

        if (j < period - 1) {
          maList.add(-1);
          continue;
        } else if (j == period - 1) {
          continue;
        }

        double startIdx = j > period ? j - period : 0;

        List<KLineData> sublist = klineData.sublist(startIdx.round(), (startIdx + period).round());
        if (sublist.isEmpty) continue;
        double sum = 0.0;
        if (isVol) {
          sum = sublist.fold(0.0, (pre, e) => pre + e.volumne);
        } else {
          sum = sublist.fold(0.0, (pre, e) => pre + e.close);
        }
        double maValue = sum / sublist.length;

        if (max == 0 || maValue > max) max = maValue;
        if (min == 0 || maValue < min) min = maValue;

        maList.add(maValue);
      }

      maData.add(maList);
    }
    return [maData, max, min];
  }

  static List ema(List<KLineData> klineData, List<int> periods, double beginIdx) {
    if (klineData.isEmpty) return [];

    List<List<double>> emaData = [];
    double max = 0.0;
    double min = 0.0;

    int candleCount = KLineConfig.shared.candleCount;

    for (var i = 0; i < periods.length;++i) {
      List<double> emaList = [];
      int period = periods[i];

      double lastEma = klineData.first.close;
      double sum = 0.0;

      for (var j = 0;j < klineData.length;++j) {

        double close = klineData[j].close;

        if (j < period - 1) {
          emaList.add(-1);
          sum += close;
          continue;
        } else if (j == period - 1) {
          sum += close;
          lastEma = sum / period;
          emaList.add(lastEma);
          continue;
        }

        double deno = period * (period + 1) * 0.5;
        double emaValue = close * period / deno + (deno - period) * lastEma / deno;


        if (j >= beginIdx-1 && j < beginIdx + candleCount) {
          if (max == 0 || emaValue > max) max = emaValue;
          if (min == 0 || emaValue < min) min = emaValue;
        }

        lastEma = emaValue;
        emaList.add(emaValue);
      }

      double start = beginIdx > 0 ? beginIdx -1 : 0;
      List<double> subList = emaList.sublist(start.round(), start.round() + candleCount);
      emaData.add(subList);
    }
    return [emaData, max, min];
  }

  static List boll(List<KLineData> klineData, int period, int bandwidth, int beginIdx) {
    if (klineData.isEmpty || period < 0 || bandwidth < 0) return [];

    List<double> dataList = [];
    double max = 0.0;
    double min = 0.0;
    for (var i = 0; i < klineData.length; ++i) {
      if (i < period - 1) {
        dataList.add(-1);
        continue;
      }

      double ma = 0.0;

    }

    return [];
  }

  static List macd(List<KLineData> klineData, List periods) {
    return [];
  }

  static List kdj(List<KLineData> klineData, List<int> periods, double beginIdx) {
    List kdjData = [];
    if (klineData.isEmpty || periods.length != 3) return kdjData;
    int period = periods[0];
    int period2 = periods[1];
    int period3 = periods[2];

    double lastK = 0.0, lastD = 0.0;

    List<double> kValues = [], dValues = [], jValues = [];
    double max = 0.0, min = 0.0;
    for(var i = 0;i < klineData.length; ++i) {
      KLineData data = klineData[i];
      if (i == 0) {
        double rsv = (data.close - data.low) / (data.high - data.low) * 100;
        lastK = lastD = rsv;
        continue;
      }

      int startIdx = i > period ? i - period : 0;
      List<KLineData> sublist = klineData.sublist(startIdx, startIdx + period);
      double hn = sublist.first.high;
      double ln = sublist.first.low;
      for (int j = 0;j < sublist.length; ++j) {
        KLineData subData = sublist[j];
        if (subData.high > hn) hn = subData.high;
        if (subData.low < ln) ln = subData.low;
      }
      if (ln == hn) return [];


      int candleCount = KLineConfig.shared.candleCount;
      if (i >= beginIdx.round() && i < beginIdx.round() + candleCount) {

        double rsv = (data.close - ln) / (hn - ln) * 100;
        double kValue = (lastK * (period2 - 1) + rsv) / period2;
        double dValue = (lastD * (period3 - 1) + kValue) / period3;
        double jValue = kValue * 3 - dValue * 2;

        if (kValue > max || max == 0.0) max = kValue;
        if (dValue > max) max = dValue;
        if (jValue > max) max = jValue;
        if (kValue < min || min == 0.0) min = kValue;
        if (dValue < min) min = dValue;
        if (jValue < min) min = jValue;

        kValues.add(kValue);
        dValues.add(dValue);
        jValues.add(jValue);

        lastK = kValue;
        lastD = dValue;
      }
    }

    List res = [[kValues, dValues, jValues], max, min];
    return res;
  }

  static List wr(List<KLineData> klineData, List<int> periods, double beginIdx) {
    if (klineData.isEmpty || periods.isEmpty) return [];
    List<List<double>> dataList = [];
    double max = 0.0, min = 0.0;
    for(var idx = 0;idx < periods.length; ++ idx) {
      int period = periods[idx];
      List<double> wrList = [];

      int candleCount = KLineConfig.shared.candleCount;
      for (var i = beginIdx;i < beginIdx + candleCount; ++i) {
        double end = i+1;
        double start = i  < period ? 0 : i - period;
        List<KLineData> sublist = klineData.sublist(start.round(), end.round());
        double highest = sublist.first.high;
        double lowest = sublist.first.low;
        for(var j = 1;j < sublist.length; ++j) {
          KLineData subData = sublist[j];
          if (subData.low < lowest) lowest = subData.low;
          if (subData.high > highest) highest = subData.high;
        }
        double wr = (highest - klineData[i.round()].close) / (highest - lowest) * 100;
        if (wr < min || min == 0.0) min = wr;
        if (wr > max || max == 0.0) max = wr;
        wrList.add(wr);
      }
      dataList.add(wrList);
    }
    return [dataList, max, min];
  }
}