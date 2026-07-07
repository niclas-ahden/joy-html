module [sanitize_name]

## Strip every character that is not an ASCII letter, digit, `-`, `_`, `.` or
## `:` from an HTML tag or attribute name. Names come in as plain strings via
## `Html.element` and `Attribute.attribute`/`data`/`aria`, and no quoting can
## make a bad character safe in name position. A space or `>` in a key breaks
## out of the tag no matter how the value is escaped, so the only safe rewrite
## is removal. Sanitizing here, where the string enters the tree, covers both
## SSR and the client-side renderer.
sanitize_name : Str -> Str
sanitize_name = |name|
    kept = name |> Str.to_utf8 |> List.keep_if(is_name_byte)
    when Str.from_utf8(kept) is
        Ok(sanitized) -> sanitized
        Err(_) -> "" # Unreachable since the kept bytes are all ASCII

is_name_byte : U8 -> Bool
is_name_byte = |byte|
    (byte >= 'a' and byte <= 'z')
    or (byte >= 'A' and byte <= 'Z')
    or (byte >= '0' and byte <= '9')
    or (byte == '-')
    or (byte == '_')
    or (byte == '.')
    or (byte == ':')

expect sanitize_name("data-foo") == "data-foo"
expect sanitize_name("hx-on:click") == "hx-on:click"
expect sanitize_name("x\" onmouseover=\"alert(1)\" y") == "xonmouseoveralert1y"
