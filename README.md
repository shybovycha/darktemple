# DarkTemple

> Born in the darkest place universe full of darkest magic...

DarkTemple is a [Jinja](https://jinja.palletsprojects.com/en/stable/)-like compile-time template engine for D programming language.
The goal is to make it reliable, simple and convenient in the world of D.

## Note

This library is a work-in-progress project. API and implementation might change drastically.

## Usage

### Simple

```d
string name = "John";
assert(render!(`Hello "{{ name }}"!`, name) == `Hello "John"!`);
```

### File template

`template.1.tmpl`:

```jinja
Test template.

User: {{ user.name }}
{# Show active or blocked state for user, depending on active field #}
User is {% if user.active %}active{% else %}blocked{% endif %}!
```

`main.d`:

```d
struct User {
    string name;
    bool active;
}

User user = User(name: "John", active: true);
auto result = renderFile!("test-templates/template.1.tmpl", user);
```

The above code produces:

```
Test template.

User: John

User is active!
```

## License

DarkTemple is distributed under MPL-2.0 license.
