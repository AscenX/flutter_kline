import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kline/kline_controller.dart';
import 'package:kline/kline_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
        title: "flutter_kline demo app", home: MyHomePage(title: 'flutter_kline demo'));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> mainIndicators =
      KLineController.shared.showMainIndicators.map((e) => e.name).toList();
  List<String> subIndicators =
      KLineController.shared.showSubIndicators.map((e) => e.name).toList();

  Widget buildIndicator(
      String name, bool isMain, void Function(String, bool) click) {
    Color c =
        (isMain ? mainIndicators.contains(name) : subIndicators.contains(name))
            ? Colors.blue
            : Colors.grey;
    return InkWell(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(name, style: TextStyle(fontSize: 14, color: c)),
      ),
      onTap: () => click(name, isMain),
    );
  }

  void clickIndicator(name, isMain) {
    if (isMain) {
      if (mainIndicators.contains(name)) {
        mainIndicators.remove(name);
      } else {
        if (mainIndicators.isNotEmpty) mainIndicators.removeAt(0);
        mainIndicators.add(name);
      }

      KLineController.shared.showMainIndicators =
          mainIndicators.map((e) => IndicatorType.fromName(e)).toList();
    } else {
      if (subIndicators.contains(name)) {
        subIndicators.remove(name);
      } else if (subIndicators.length == 2) {
        if (subIndicators.isNotEmpty) subIndicators.removeAt(0);
        subIndicators.add(name);
      } else {
        subIndicators.add(name);
      }
      KLineController.shared.showSubIndicators =
          subIndicators.map((e) => IndicatorType.fromName(e)).toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
            child: Column(
          children: [
            Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  const Text("Main Indicator"),
                  ...IndicatorType.values
                      .where((element) => element.isMain)
                      .map((e) {
                    return buildIndicator(e.name, e.isMain, clickIndicator);
                  })
                ])),
            Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  const Text("Sub Indicator"),
                  ...IndicatorType.values
                      .where((element) =>
                          !element.isMain && element != IndicatorType.maVol)
                      .map((e) {
                    return buildIndicator(e.name, e.isMain, clickIndicator);
                  })
                ])),
            Container(
                width: MediaQuery.of(context).size.width,
                height: 400,
                decoration: const BoxDecoration(
                    border: Border.symmetric(
                        horizontal: BorderSide(color: Colors.black))),
                child: const KLineView())
          ],
        )) // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
