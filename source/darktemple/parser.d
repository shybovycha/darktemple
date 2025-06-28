module darktemple.parser;

private import std.algorithm: canFind;
private import std.ascii: isWhite;

// TODO: Create ParserConfig struct instead and use it as template parametr for parser
enum Block : string {
    PlaceholderStart="{{",
    PlaceholderEnd="}}",
    StatementStart="{%",
    StatementEnd="%}",
    CommentStart="{#",
    CommentEnd="#}",
}

enum string[] blockStartTokens = [Block.PlaceholderStart, Block.StatementStart, Block.CommentStart];

enum FragmentType {
    Text,
    Placeholder,
    Statement,
    Comment,
}

pure struct Fragment {
    FragmentType type;
    string data;
    ulong line;
}

// TODO: Throw error, when  cannot find block end ('}}', '%}', '#}')
pure struct Parser {
    private immutable string _data;

    private ulong _cursor = 0;
    private ulong _cursor_ln = 0;
    private ulong _block_start = 0;
    private ulong _block_start_ln = 0;
    private ulong _block_end = 0;
    private FragmentType _block_type;

    this(immutable string data) pure {
        _data = data;
    }

    immutable(Fragment) front() pure {
        if (_block_end <= _block_start)
            findNextBlock;

        if (_block_end > _block_start)
            return Fragment(
                type: _block_type,
                data: _data[_block_start .. _block_end],
                line: _block_start_ln,
            );

        assert(0, "Parser result already consumed!");
    }

    bool empty() const pure {
        return _block_start >= _data.length;
    }

    void consumeBlock() pure {
        // in case of non-text blocks, we have to skip block start token and strip spaces
        final switch(_block_type) {
            case FragmentType.Text:
                // Do nothing here. It is just text
                break;
        
            case FragmentType.Placeholder, FragmentType.Statement, FragmentType.Comment:
                _cursor += 2;
                while (_data[_cursor].isWhite) _cursor++;
                _block_start = _cursor;
                break;
        }
        
        while (_cursor < _data.length) {
            if (_data[_cursor] == '\n')
                _cursor_ln++;

            final switch(_block_type) {
                case FragmentType.Text:
                    if (_data.length - _cursor >= 2 && blockStartTokens.canFind(_data[_cursor .. _cursor+2])) {
                        _block_end = _cursor;
                        return;
                    }
                    break;
                
                case FragmentType.Placeholder:
                    if (_data.length - _cursor >= 2 && _data[_cursor .. _cursor + 2] == Block.PlaceholderEnd) {
                        _block_end = _cursor;
                        _cursor += 2;
                        while(_block_end - 1 > _block_start && _data[_block_end - 1].isWhite) _block_end--;
                        return;
                    }
                    break;
                
                case FragmentType.Statement:
                    if (_data.length - _cursor >= 2 && _data[_cursor .. _cursor + 2] == Block.StatementEnd) {
                        _block_end = _cursor;
                        _cursor += 2;
                        while(_block_end - 1 > _block_start && _data[_block_end - 1].isWhite) _block_end--;
                        return;
                    }
                    break;
                
                case FragmentType.Comment:
                    if (_data.length - _cursor >= 2 && _data[_cursor .. _cursor + 2] == Block.CommentEnd) {
                        _block_end = _cursor;
                        _cursor += 2;
                        while(_block_end - 1 > _block_start && _data[_block_end - 1].isWhite) _block_end--;
                        return;
                    }
                    break;
            }

            _cursor++;
        }
        
        _block_end = _data.length;
    }

    void findNextBlock() pure {
        if (_data.length - _cursor < 3) {
            // There are less then 3 characters left, treat them as text
            _block_type = FragmentType.Text;
            consumeBlock;
            return;
        }
        
        import std.stdio;
        
        switch (_data[_cursor .. _cursor + 2]) {
            case Block.PlaceholderStart:
                _block_type = FragmentType.Placeholder;
                break;
        
            case Block.StatementStart:
                _block_type = FragmentType.Statement;
                break;
            
            case Block.CommentStart:
                _block_type = FragmentType.Comment;
                break;
            
            default:
                _block_type = FragmentType.Text;
                break;
        }

        consumeBlock;
    }

    void popFront() pure
    in (!empty, "Attempt to popFront already consumed parser") {
        _block_start = _cursor;
        _block_start_ln = _cursor_ln;
    }

}


// Simple test with only placeholder
unittest {
    auto p = Parser("Hello {{ name }}!");
    assert(!p.empty);
    assert(p.front.data == "Hello ");
    assert(p.front.data == "Hello ");  // No changes when getting front
    assert(p.front.type == FragmentType.Text);
    p.popFront;
    assert(!p.empty);
    assert(p.front.data == "name");
    assert(p.front.type == FragmentType.Placeholder);
    p.popFront;
    assert(!p.empty);
    assert(p.front.data == "!");
    assert(p.front.type == FragmentType.Text);
    assert(!p.empty);
    p.popFront;
    assert(p.empty);
}

// Simple test with only placeholder
unittest {
    import std.algorithm;
    import std.array: array;
    auto p = Parser("Hello {{ name }}! Some {% statement %} and {# comment #}.");

    auto fragments = array(p);
    assert(fragments[0].type == FragmentType.Text);
    assert(fragments[0].data == "Hello ");

    assert(fragments[1].type == FragmentType.Placeholder);
    assert(fragments[1].data == "name");

    assert(fragments[2].type == FragmentType.Text);
    assert(fragments[2].data == "! Some ");

    assert(fragments[3].type == FragmentType.Statement);
    assert(fragments[3].data == "statement");

    assert(fragments[4].type == FragmentType.Text);
    assert(fragments[4].data == " and .");

    // Comment blocks should be ignored by the parser
    assert(p.map!((in a) => a.data).array == ["Hello ", "name", "! Some ", "statement", " and ", "comment", "."]);
}

// Test that parser works in compile time
unittest {
    import std.algorithm;
    import std.array: array;
    immutable auto a = Parser("Hello {{ name }}! Some {% statement %} and {# comment #}.").array.map!((a) => a.data).array;

    // Comment blocks should be ignored (skipped) by parser.
    assert(a == ["Hello ", "name", "! Some ", "statement", " and ", "comment", "."]);
}

// Test some multiline template
unittest {
    auto p = Parser(
            "Hello, {{ name }}!\n" ~
            "Some text line here\n" ~
            "\n\n" ~
            "{% some statement %}");

    assert(p.front.data == "Hello, ");
    assert(p.front.type == FragmentType.Text);
    assert(p.front.line == 0);
    p.popFront;
    assert(p.front.data == "name");
    assert(p.front.type == FragmentType.Placeholder);
    assert(p.front.line == 0);
    p.popFront;
    assert(p.front.data == "!\nSome text line here\n\n\n");
    assert(p.front.type == FragmentType.Text);
    assert(p.front.line == 0);
    p.popFront;
    assert(p.front.data == "some statement");
    assert(p.front.type == FragmentType.Statement);
    assert(p.front.line == 4);
    p.popFront;
    assert(p.empty);
}

unittest {
    import std.algorithm;
    import std.array: array;
    immutable auto p = Parser(`Hello{% if check %} "{{ name }}"{% endif %}!`).array.map!((a) => a.data).array;;
    assert(p == ["Hello", "if check", " \"", "name", "\"", "endif", "!"]);
}

// Test parsing imported file
unittest {
    import std.ascii: newline;
    auto p = Parser(import("test-templates/template.1.tmpl"));

    assert(p.front.data == "Test template." ~ newline ~ newline ~ "User: ");
    assert(p.front.type == FragmentType.Text);
    assert(p.front.line == 0);
    p.popFront;
    assert(p.front.data == "user.name");
    assert(p.front.type == FragmentType.Placeholder);
    assert(p.front.line == 2);
    p.popFront;
    assert(p.front.data == newline);
    assert(p.front.type == FragmentType.Text);
    assert(p.front.line == 2);
    p.popFront;
    assert(p.front.data == "Show active or blocked state for user, depending on active field");
    assert(p.front.type == FragmentType.Comment);
    assert(p.front.line == 3);
    p.popFront;
    assert(p.front.data == newline ~ "User is ");
    assert(p.front.type == FragmentType.Text);
    assert(p.front.line == 3);
    p.popFront;
    assert(p.front.data == "if user.active");
    assert(p.front.type == FragmentType.Statement);
    assert(p.front.line == 4);
    p.popFront;
    assert(p.front.data == "active");
    assert(p.front.type == FragmentType.Text);
    assert(p.front.line == 4);
    p.popFront;
    assert(p.front.data == "else");
    assert(p.front.type == FragmentType.Statement);
    assert(p.front.line == 4);
    p.popFront;
    assert(p.front.data == "blocked");
    assert(p.front.type == FragmentType.Text);
    assert(p.front.line == 4);
    p.popFront;
    assert(p.front.data == "endif");
    assert(p.front.type == FragmentType.Statement);
    assert(p.front.line == 4);
    p.popFront;
    assert(p.front.data == "!" ~ newline);
    assert(p.front.type == FragmentType.Text);
    assert(p.front.line == 4);
    p.popFront;
    assert(p.empty);
}
