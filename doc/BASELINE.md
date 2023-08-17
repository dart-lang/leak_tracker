Coming soon!

The text below is under construction.

# Memory baselining

## What is it?

Memory baselining helps you to measure if your code change impacted memory footprint of a feature.

Please, note, that the obtained numbers are not showing real values in released application,
because. The numbers can be used only as relative measure, when the only change between runs
is the code.
All other parameters, like version of Dart/Flutter SDK, target platform, build mode, hardware,
should stay the same.
ß
## How to use it?

To take baseline of memory footprint for your `testWidgetsWithLeakTracking`, pass baselining configuration to the test. It is recommended
to run the test more than once to stabilize the numbers.
After first execution copy the code in the output as parameter of `MemoryBaselining`.

Then make your change, run the test again and see how the change affected memory footprint.

Code example:

```
for (var i in Iterable.generate(1000)) {
    testWidgetsWithLeakTracking(
        'baselining with multiple runs',
        (widgetTester) async {
          ...
        },
        leakTrackingTestConfig: const LeakTrackingTestConfig(
            isLeakTrackingPaused: true,
            baselining: MemoryBaselining(),
        ),
    );
}

```

The output will be like this:

```
initialValue: 136.2 MB - 138.0 MB = -1.9 MB (-1.35%)
deltaAvg: 7.7 MB - 7.7 MB = 28 KB (0.35%)
deltaMax: 13.0 MB - 13.0 MB = 48 KB (0.36%)
absAvg: 143.8 MB - 145.7 MB = -1.8 MB (-1.26%)
absMax: 149.2 MB - 151.0 MB = -1.8 MB (-1.20%)
samples: 249 - 249 = 0

To set as new baseline, set parameter of MemoryBaselining:
      baseline: MemoryBaseline(
        rss: ValueSampler(initialValue: 142770176, deltaAvg: 8089353.253012049, deltaMax: 13680640, absAvg: 150827171.84000006, absMax: 156450816, samples: 249,),
      )
```

## Limitations

Baselining in `leak_tracker` only works, if the measured code deals with
[instrumented classes](DETECT.md#limitations), because samples are taken at the moments when objects dispatch their creation or disposal.

Flutter Framework contains number of instrumented classes, so baselining normally works well for
Flutter tests.

## Regression testing

If you want your tests to fail in case of significant diviation from baseline,
please, upvote and comment the issue: https://github.com/dart-lang/leak_tracker/issues/120.
