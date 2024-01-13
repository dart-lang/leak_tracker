# Leak tracking overview

Detecting memory leaks for large applications is hard ([snapshot diffing](https://nodejs.org/en/docs/guides/diagnostics/memory/using-heap-snapshot), [profiling](https://www.atatus.com/blog/how-to-identify-memory-leaks/#:~:text=doomed%20to%20fail.-,Is%20There%20a%20Way%20to%20Tell%20a%20Memory%20Leak%3F,RAM%20and%20crash%20your%20application.)). Normally, the leaks impact users, staying invisible for application teams.

Leak tracker allows to catch risky areas much earlier, by detecting not disposed and not garbage collected objects in Flutter regression tests.

## Read more

- [Concepts](doc/CONCEPTS.md)
- [Motivation](doc/MOTIVATION.md)
- [Detect memory leaks](doc/DETECT.md)
- [Troubleshoot memory leaks](doc/TROUBLESHOOT.md)
