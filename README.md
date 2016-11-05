#thx.stream

[![Build Status](https://travis-ci.org/fponticelli/thx.stream.svg)](https://travis-ci.org/fponticelli/thx.stream)

Streaming library

## install

From the command line just type:

```bash
haxelib install thx.stream
```

To use the `dev` version do:

```bash
haxelib git thx.core https://github.com/fponticelli/thx.stream.git
```



TODO
====
  * endWhen<TOther>(other: Stream<TOther>): Stream<T> (from xstream): Uses another stream to determine when to complete the current stream. When the given other stream emits an event or completes, the output stream will complete. Before that happens, the output stream will behaves like the input stream.
  * recover(other: Stream<T>): Stream<T>: if the stream ends with an error it is replaced by `other`
  * compose (from xstream): Passes the input stream to a custom operator, to produce an output stream. compose is a handy way of using an existing function in a chained style. Instead of writing outStream = f(inStream) you can write outStream = inStream.compose(f).
  * remember() (from xstream): Returns an output stream that behaves like the input stream, but also remembers the most recent event that happens on the input stream, so that a newly added listener will immediately receive that memorised event.
  * imitate: https://github.com/staltz/xstream#imitate
  * query methods
    * any
    * all
    * contains
    * memberOf
