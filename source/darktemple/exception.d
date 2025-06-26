module darktemple.exception;

private import std.exception;

@safe:

pure class DarkTempleException : Exception {
    mixin basicExceptionCtors;
}
