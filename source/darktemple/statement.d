module darktemple.statement;


private import std.regex;
private import std.range;
private import std.array: Appender, replace;


pure abstract class TemplateStatement {

    string generateCode() const pure;

    //void render(T)(ref T output);
}

pure class TemplateDataBlock : TemplateStatement {
    private const string _data;

    this(in string data) pure {
        _data = data;
    }

    override string generateCode() const pure {
        return "    output.put(\"" ~ _data.replace("\"", "\\\"") ~ "\");\n";
    }

}

pure class TemplateVariableBlock : TemplateStatement {
    private const string _expression;

    this(in string expression) pure {
        _expression = expression;
    }

    override string generateCode() const pure {
        return "    output.put(" ~ _expression ~ ");\n";
    }

}

/// Template block that contains multiple statements
pure class TemplateMultiST: TemplateStatement {
    private TemplateStatement[] _statements;

    this() pure {
        _statements = [];
    }

    void addStatement(TemplateStatement st) pure {
        _statements ~= st;
    }

    override string generateCode() const pure {
        string res = "";
        foreach(st; _statements)
            res ~= st.generateCode();
        return res;
    }
}

pure class TemplateForBlock : TemplateMultiST {
    override string generateCode() const pure {
        return "throw new Exception(\"Not implemented!\");\n";
    }
}

pure class Template : TemplateMultiST {

    this(in string input) pure {
        super();
        TemplateMultiST[] stack = [this];

        int start = 0;
        TemplateStatement current_node;
        //for(int i=start; i <= input.length-2; i++) {
            //if (input[i:i+1] == "{{") {
            //} else {
                //continue;
            //}

        //}
        stack.front.addStatement(new TemplateDataBlock(input));
    }

    override string generateCode() const pure {
        string tmpl = "void render_impl(T)(ref T output) {\n";
        tmpl ~= super.generateCode();
        tmpl ~= "}\n";
        return tmpl;
    }
}


// TODO: render file, specify file, that have to be imported, and do import.
template render(string tmpl) {
    mixin(new Template(tmpl).generateCode);

    string render() pure {
        auto o = appender!string;
        render_impl(o);
        return o[];
    }
}

unittest {
    immutable auto tmpl = new Template("Hello World!");
    assert(render!("Hello World!") == "Hello World!");
}
