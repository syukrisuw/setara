import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:shelf_static/shelf_static.dart' as shelf_static;

class MainPage extends StatefulWidget {
  const MainPage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MainPage> createState() => _MainPageState();
}

Response _helloWorldHandler(Request request) => Response.ok('Hello, World!');

Response _sumHandler(request, String a, String b) {
  final aNum = int.parse(a);
  final bNum = int.parse(b);
  return Response.ok(
    const JsonEncoder.withIndent(' ')
        .convert({'a': aNum, 'b': bNum, 'sum': aNum + bNum}),
    headers: {
      'content-type': 'application/json',
      'Cache-Control': 'public, max-age=604800',
    },
  );
}

final _staticHandler =
    shelf_static.createStaticHandler('./', defaultDocument: 'index.html');

final _router = shelf_router.Router()
  ..get('/helloworld', _helloWorldHandler)
  ..get(
    '/time',
    (request) => Response.ok(DateTime.now().toUtc().toIso8601String()),
  )
  ..get('/sum/<a|[0-9]+>/<b|[0-9]+>', _sumHandler);

class _MainPageState extends State<MainPage> {
  int _counter = 0;
  HttpServer? server;
  String message ="";

  bool isServerCreated = false;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(
              child: Text(isServerCreated? "Server Already Started": "Start Server"),
              onPressed: onBtnSetupServerPressed,
            ),
            Text(isServerCreated? "Server Info ($message) : Server IP: ${server!.address.toString()} Server Port: ${server!.port.toString()} ":"Server Info :")
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void onBtnSetupServerPressed() {
    setupServer().then((value) {
      if(server != null) {
        print("Server created");
        isServerCreated = true;
      }
    });
    setState(() {

    });
  }

  Future<void> setupServer() async {
    if (!isServerCreated) {
      try {
        final port = int.parse(Platform.environment['PORT'] ?? '8080');

        // See https://pub.dev/documentation/shelf/latest/shelf/Cascade-class.html
        final cascade = Cascade()
            // First, serve files from the 'public' directory
            .add(_staticHandler)
            // If a corresponding file is not found, send requests to a `Router`
            .add(_router);

        // See https://pub.dev/documentation/shelf/latest/shelf_io/serve.html
        server = await shelf_io.serve(
          // See https://pub.dev/documentation/shelf/latest/shelf/logRequests.html
          logRequests()
              // See https://pub.dev/documentation/shelf/latest/shelf/MiddlewareExtensions/addHandler.html
              .addHandler(cascade.handler),
          InternetAddress.anyIPv4, // Allows external connections
          port,
        );
      } on Exception catch (e){
        message = e.toString();
      }

      if(server!= null) {
        isServerCreated = true;
      }
    } else {
      print("Server already running");
    }


    print('Serving at http://${server!.address.host}:${server!.port}');
  }

  void onError() {

  }
}
