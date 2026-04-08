import 'package:example/bloc/counter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final CounterBloc counterBloc;

  @override
  void initState() {
    counterBloc = CounterBloc();
    super.initState();
  }

  @override
  void dispose() {
    counterBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            BlocConsumer<CounterBloc, CounterState>(
              bloc: counterBloc,
              listener: (context, state) => state.listenWhen(
                evenNumber: () {
                  final snackBar = SnackBar(
                    content: const Text('Even number'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        counterBloc.add(DecrementEvent());
                      },
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                },
                oddNumber: () {
                  final snackBar = SnackBar(
                    content: const Text('Odd number'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        counterBloc.add(DecrementEvent());
                      },
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                },
              ),
              listenWhen: (previous, current) => current.isListener,
              buildWhen: (previous, current) => current.isBuilder,
              builder: (context, state) => state.buildWhen(
                main: (count) => Text(
                  "$count",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                orElse: () => Text(
                  'State not handled',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: .end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              counterBloc.add(IncrementEvent());
            },
            tooltip: 'Increment',
            child: const Icon(Icons.plus_one),
          ),
          SizedBox(height: 20),
          FloatingActionButton(
            onPressed: () async {
              counterBloc.add(DecrementEvent());
            },
            tooltip: 'Decrement',
            child: const Icon(Icons.exposure_minus_1),
          ),
          SizedBox(height: 20),
          FloatingActionButton(
            onPressed: () async {
              counterBloc.add(RestartEvent());
            },
            tooltip: 'Restart',
            child: const Icon(Icons.replay),
          ),
        ],
      ),
    );
  }
}
