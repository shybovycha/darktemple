module darktemple.parser;

private import std.algorithm: canFind;

// TODO: Create ParserConfig struct instead and use it as template parametr for parser
enum Block : string {
    FieldStart="{{",
    FieldEnd="}}",
    StatementStart="{%",
    StatementEnd="%}",
    CommentStart="{#",
    CommentEnd="#}",
}


pure struct Parser {
    private immutable string _data;

    private ulong _cursor = 0;
    private ulong _block_start = 0;
    private ulong _block_end = 0;

    this(immutable string data) pure {
        _data = data;
    }

    string front() pure {
        if (_block_end <= _block_start)
            findNextBlock;

        if (_block_end > _block_start)
            return _data[_block_start .. _block_end];

        return "";
    }

    bool empty() const pure {
        return _cursor == _data.length;
    }

    void consumeBlock(in string[] search_tokens, in bool include_end=false) pure {
        while (_cursor < _data.length - 2) {
            if (search_tokens.canFind(_data[_cursor .. _cursor+2])) {
                if (include_end) {
                    // Here we have to include search_token,
                    // so we have to move cursor (and _block_end) to first symbol after search_token
                    _block_end = _cursor + 2;
                    _cursor += 2;
                } else {
                    // cursor position is on token found, thus no need to move it forward.
                    // So, we set only _block_end.
                    _block_end = _cursor;
                }
                return;
            }
            _cursor++;
        }
        _block_end = _data.length;
    }

    void consumeTextBlock() pure {
        consumeBlock(
            search_tokens: [Block.FieldStart, Block.StatementStart, Block.CommentStart],
            include_end: false,
        );
    }

    void findNextBlock() pure {
        if (_data.length - _cursor < 4) {
            // There are less then 4 digits, left, thus it could be just text block.
            _block_start = _cursor;
            _block_end = _data.length;
            _cursor = _data.length;
            return;
        }
        import std.stdio;
        switch (_data[_cursor .. _cursor + 2]) {
            case Block.FieldStart:
                consumeBlock([Block.FieldEnd], include_end: true);
                return;
            case Block.StatementStart:
                consumeBlock([Block.StatementEnd], include_end: true);
                return;
            case Block.CommentStart:
                consumeBlock([Block.CommentEnd], include_end: true);

                // We have to skip comment blocks, thus just find next block.
                findNextBlock;
                return;
            default:
                consumeTextBlock();
                return;
        }
    }

    void popFront() pure {
        _block_start = _block_end;
    }

}


// Simple test with only placeholder
unittest {
    auto p = Parser("Hello {{ name }}!");
    assert(!p.empty);
    assert(p.front == "Hello ");
    p.popFront;
    assert(!p.empty);
    assert(p.front == "{{ name }}");
    p.popFront;
    assert(!p.empty);
    assert(p.front == "!");
    p.popFront;
    assert(p.empty);
}

// Simple test with only placeholder
unittest {
    import std.array: array;
    auto p = Parser("Hello {{ name }}! Some {% statement %} and {# comment #}.");

    // Comment blocks should be ignored (skipped) by parser.
    assert(p.array == ["Hello ", "{{ name }}", "! Some ", "{% statement %}", " and ", "."]);
}

// Test that parser works in compile time
unittest {
    import std.array: array;
    immutable auto a = Parser("Hello {{ name }}! Some {% statement %} and {# comment #}.").array;

    // Comment blocks should be ignored (skipped) by parser.
    assert(a == ["Hello ", "{{ name }}", "! Some ", "{% statement %}", " and ", "."]);
}
