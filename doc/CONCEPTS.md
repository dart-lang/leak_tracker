Coming soon! See https://github.com/flutter/devtools/issues/3951.

The text below is under construction.

# Understand Memory Leak Tracking Concepts

This page describes leak tracking concepts.
See other information on memory leaks [here](../README.md).

Before reading about leak tracking, understand [Dart memory concepts](https://docs.flutter.dev/development/tools/devtools/memory#basic-memory-concepts).

## Addressed leak types

The leak tracker can catch only certain types of leaks, in particular,
related to timing of disposal and garbage collection.
With proper memory management, this tool assumes that,
an object's disposal and garbage collection occur in quick succession.
That is, the object should be garbage collected
during next garbage collection cycle after disposal.

By monitoring disposal and Garbage Collect events, the tool detects
different types of leaks:

- **Not disposed, but GCed (not-disposed)**:

    - **Definition**: a disposable object was GCed,
       without being disposed first. This means that the object's disposable content
       is using memory after the object is no longer needed.

    - **Fix**: invoke `dispose()` for the object to free up the memory.

- **Disposed, but not GCed (not-GCed)**:
    - **Definition**: an object was disposed,
       but not GCed after certain number of GC events. This means that
       a reference to the object is preventing it from being
       garbage collected after it's no longer needed.

    - **Fix**: To fix the leak, assign all reachable references
       of the object to null after disposal:

        ```
        myField.dispose();
        myField = null;
        ```

- **Disposed and GCed late (GCed-late)**:
    - **Definition**: an object was disposed and then GCed,
       but GC happened later than expected. This means the retaining path was
       holding the object in memory for some period, but then disappeared.

    - **Fix**: the same as for **not-GCed**

- **Disposed, but not GCed, without path (not-GCed-without-path)**:
    - **Definition**: an object
       was disposed and not GCed when expected, but retaining path
       is not detected,
       that means that the object will be most likely GCed in
       the next GC cycle,
       and the leak will convert to **GCed-late** leak.

    - **Fix**: please,
    [create issue](https://github.com/dart-lang/leak_tracker/issues)
    if you see this type of leaks, as it means
    something is wrong with the tool.

## Culprits and victims

If you have a set of not-GCed objects, some of them (victims)
might not be GC-ed because they are held by others (culprits).
Normally, to fix the leaks, you need to only fix the culprits.

**Victim**: a leaked object, for which the tool could find another
leaked object that, if fixed, would also fix the first leak.

**Culprit**: a leaked object that is not detected to be the victim
of another object.

The tool detects which leaked objects are culprits, so you know where to focus.

For example, out of four not-GCed leaks on the following diagram,
only one is the culprit, because, when the object is fixed
and GCed, the victims it referenced will be also GCed:

<img width="204" alt="Screenshot 2023-01-26 at 4 31 54 PM" src="https://user-images.githubusercontent.com/12115586/214981096-9967c554-f037-4ed0-812b-ff5b387bb4e1.png">
