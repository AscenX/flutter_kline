
class KLineData {
  var open = 0.0;
  var high = 0.0;
  var low = 0.0;
  var close = 0.0;
  var volumne = 0.0;
  var time = 0;

  KLineData.fromJson(dynamic json) {
    open = json['open'];
    high = json['high'];
    low = json['low'];
    close = json['close'];
    volumne = json['volumne'];
    time = json['time'];
  }

  // [
// [
// 1499040000000,      // Kline open time
// "0.01634790",       // Open price
// "0.80000000",       // High price
// "0.01575800",       // Low price
// "0.01577100",       // Close price
// "148976.11427815",  // Volume
// 1499644799999,      // Kline close time
// "2434.19055334",    // Quote asset volume
// 308,                // Number of trades
// "1756.87402397",    // Taker buy base asset volume
// "28.46694368",      // Taker buy quote asset volume
// "0"                 // Unused field. Ignore.
// ]
// ]
  KLineData.fromBinanceData(List list) {
    open = list.length > 1 ? double.parse(list[1]) : 0.0;
    high = list.length > 2 ? double.parse(list[2]) : 0.0;
    low = list.length > 3 ? double.parse(list[3]) : 0.0;
    close = list.length > 4 ? double.parse(list[4]) : 0.0;
    volumne = list.length > 5 ? double.parse(list[5]) : 0.0;
    time = list.length > 6 ? list[6] : 0;
  }
}