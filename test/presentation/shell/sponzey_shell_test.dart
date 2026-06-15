import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sponzey_file_sharing/presentation/shell/sponzey_shell.dart';

void main() {
  testWidgets('outgoing shell page does not receive taps during transition', (
    tester,
  ) async {
    var currentLocation = '/old';
    var oldTapCount = 0;

    Widget buildPane() {
      return MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentLocation = '/new';
                    });
                  },
                  child: const Text('Switch'),
                ),
                Expanded(
                  child: ShellContentPane(
                    currentLocation: currentLocation,
                    child: currentLocation == '/old'
                        ? Align(
                            alignment: Alignment.topLeft,
                            child: ElevatedButton(
                              onPressed: () {
                                oldTapCount += 1;
                              },
                              child: const Text('Old action'),
                            ),
                          )
                        : const Align(
                            alignment: Alignment.bottomRight,
                            child: Text('New page'),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    await tester.pumpWidget(buildPane());
    await tester.tap(find.widgetWithText(ElevatedButton, 'Switch'));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Old action'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(oldTapCount, 0);
    expect(find.text('New page'), findsOneWidget);
  });

  testWidgets('incoming shell page receives the first tap during transition', (
    tester,
  ) async {
    var currentLocation = '/old';
    var newTapCount = 0;

    Widget buildPane() {
      return MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentLocation = '/new';
                    });
                  },
                  child: const Text('Switch'),
                ),
                Expanded(
                  child: ShellContentPane(
                    currentLocation: currentLocation,
                    child: currentLocation == '/old'
                        ? const Align(
                            alignment: Alignment.topLeft,
                            child: Text('Old page'),
                          )
                        : Align(
                            alignment: Alignment.bottomRight,
                            child: ElevatedButton(
                              onPressed: () {
                                newTapCount += 1;
                              },
                              child: const Text('New action'),
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    await tester.pumpWidget(buildPane());
    await tester.tap(find.widgetWithText(ElevatedButton, 'Switch'));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.widgetWithText(ElevatedButton, 'New action'));
    await tester.pumpAndSettle();

    expect(newTapCount, 1);
  });
}
