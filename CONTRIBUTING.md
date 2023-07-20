# Contributing code

We gladly accept contributions via GitHub pull requests!

## How to enable logs

To temporary enable logs, add this line to `main`:

```
Logger.root.onRecord.listen((LogRecord record) => print(record.message));
```
