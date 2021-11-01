import 'package:flutter/material.dart';
import 'dart:io';

import 'package:socket_io/socket_io.dart';
import 'package:socket_io_client/socket_io_client.dart' as IOClient;

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
class _MainPageState extends State<MainPage> {
  Server? ioServer;
  String message ="";
  String statusMessage = "";

  bool isServerCreated = false;

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
            Text(isServerCreated? "Server Info ($message) : Server IP: ${ioServer!.toString()} Server Port: ${ioServer!.port.toString()} ":"Server Info :"),
            Text("Status : $statusMessage"),
            TextButton(
              child: Text(isServerCreated? "Simulate Client Request": "Server Not Ready"),
              onPressed: onBtnClientPressed,
            ),
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void onBtnSetupServerPressed() {
    setupServer().then((value) {
      if(ioServer != null) {
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
        ioServer = Server();
        var nsp = ioServer!.of('/some');
        nsp.on('connection', (client) {
          print('connection /some');
          client.on('msg', (data) {
            print('data from /some => $data');

            setState(() {
              statusMessage = 'data from /some => $data';
            });

            client.emit('fromServer', "ok 2");
          });
        });
        ioServer!.on('connection', (client) {
          print('connection default namespace');
          client.on('msg', (data) {
            print('data from default => $data');
            setState(() {
              statusMessage = 'data from default => $data';
            });
            client.emit('fromServer', "ok");
          });
        });
        ioServer!.listen(3000);
        isServerCreated = true;
      } on Exception catch (e){
        message = e.toString();
      }

    } else {
      print("Server already running");
    }
    print('Serving at http://${ioServer!.toString()}:${ioServer!.port}');
  }

  void onError() {

  }

  void onBtnClientPressed() {
    IOClient.Socket socket = IOClient.io('http://localhost:3000');
    socket.on('connect', (_) {
      print('connect');
      setState(() {
        message = "connect";
      });
      socket.emit('msg', 'test');
    });
    socket.on('event', (data) => print(data));
    socket.on('disconnect', (_) => print('disconnect'));
    socket.on('fromServer', (_) => print(_));
  }
}
