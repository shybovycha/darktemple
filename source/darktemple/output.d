module darktemple.output;

private import std.array: appender, Appender;
private import std.traits : isSomeString;
private import std.conv: to;

@safe:

/** Implementation of output object for dark temple.
  * It implements automatic convertion to string when needed
  **/
struct DarkTempleOutput {
    private Appender!string _output;

    const(Appender!string) output() const pure => _output;

    void put(T)(in T value) pure {
        static if (isSomeString!(typeof(value))) {
            _output.put(value);
        } else static if (__traits(compiles, value.toString(_output))) {
            value.toString(_output);
        } else static if (__traits(compiles, value.toString())) {
            _output.put(value.toString());
        } else {
            _output.put(value.to!string);
        }
    }
}
