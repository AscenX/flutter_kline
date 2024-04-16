import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kline/kline_controller.dart';
import 'package:kline/kline_data.dart';

class KlineInfoWidget extends StatefulWidget {

  final List<KLineData> klineData;
  final double beginIdx;
  KlineInfoWidget(this.klineData, this.beginIdx);

  @override
  State<StatefulWidget> createState() => _KlineInfoWidgetState();

}

class _KlineInfoWidgetState extends State<KlineInfoWidget> {

  StreamSubscription? _longPressSub;

  double _offsetX = -1.0;

  KLineData _longPressData = KLineData.fromJson({});

  @override
  void initState() {
    super.initState();

    _longPressSub = KLineController.shared.longPressController.stream.listen((event) {
      if (event is double) {
        double offsetX = event;
        int index = (offsetX / (KLineController.shared.currentCandleW + KLineController.shared.spacing) + widget.beginIdx).round();
        if (index >= 0 && index < widget.klineData.length) {
          KLineData data = widget.klineData[index];
          setState(() {
            _offsetX = offsetX;
            _longPressData = data;
          });
        } else {
          debugPrint('debug: long press index error:$index');
          setState(() {
            _offsetX = -1;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _longPressSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_offsetX < 0.0) return const SizedBox();
    var ctr = KLineController.shared;
    var style = TextStyle(
      fontSize: 12
    );
    return Container(
      width: ctr.infoWidgetMaxWidth,
      margin: ctr.infoWidgetMargin,
      padding: ctr.infoWidgetPadding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ctr.infoWidgetBorderRadius),
        border: ctr.infoWidgetBorder,
        color: Colors.white.withOpacity(0.8)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('high:${_longPressData.high.toStringAsFixed(2)}', style: style),
          Text('open:${_longPressData.open.toStringAsFixed(2)}', style: style),
          Text('low:${_longPressData.low.toStringAsFixed(2)}', style: style),
          Text('close:${_longPressData.close.toStringAsFixed(2)}', style: style),
          Text('volumn:${_longPressData.volume.toStringAsFixed(2)}', style: style),
          Text('time:${DateTime.fromMillisecondsSinceEpoch(_longPressData.time).toString()}', style: style),
        ],
      ),
    );
  }
}