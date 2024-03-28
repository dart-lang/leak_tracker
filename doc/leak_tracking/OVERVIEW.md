# Leak tracking overview

Detecting memory leaks for large applications is hard ([snapshot diffing](https://nodejs.org/en/docs/guides/diagnostics/memory/using-heap-snapshot), [profiling](https://www.atatus.com/blog/how-to-identify-memory-leaks/#:~:text=doomed%20to%20fail.-,Is%20There%20a%20Way%20to%20Tell%20a%20Memory%20Leak%3F,RAM%20and%20crash%20your%20application.)). Normally, the leaks impact users, staying invisible for application teams.

`leak_tracker` helps to catch memory issues much earlier by detecting not-disposed and not-garbage-collected objects in Flutter regression tests.

## Read more

- [Concepts](CONCEPTS.md)
- [Motivation](MOTIVATION.md)
- [Detect memory leaks](DETECT.md)
- [Troubleshoot memory leaks](TROUBLESHOOT.md)
