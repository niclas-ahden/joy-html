module [
    Html,
    a,
    abbr,
    address,
    area,
    article,
    aside,
    audio,
    b,
    base,
    bdi,
    bdo,
    blockquote,
    body,
    br,
    button,
    canvas,
    caption,
    cite,
    code,
    col,
    colgroup,
    data,
    datalist,
    dd,
    del,
    details,
    dfn,
    dialog,
    div,
    dl,
    dt,
    element,
    em,
    embed,
    fieldset,
    figcaption,
    figure,
    footer,
    form,
    h1,
    h2,
    h3,
    h4,
    h5,
    h6,
    head,
    header,
    hr,
    html,
    i,
    iframe,
    img,
    input,
    ins,
    kbd,
    label,
    legend,
    li,
    link,
    main,
    map,
    mark,
    math,
    menu,
    meta,
    meter,
    nav,
    noscript,
    object,
    ol,
    optgroup,
    option,
    output,
    p,
    picture,
    portal,
    pre,
    progress,
    q,
    rp,
    rt,
    ruby,
    s,
    samp,
    script,
    section,
    select,
    slot,
    small,
    source,
    span,
    ssr_document,
    strong,
    style,
    sub,
    summary,
    sup,
    svg,
    table,
    tbody,
    td,
    template,
    text,
    textarea,
    tfoot,
    th,
    thead,
    time,
    title,
    tr,
    track,
    u,
    ul,
    use,
    var,
    video,
    wbr,
]

import Attribute exposing [Attribute]
import Internal

Html state : [
    None,
    Text Str,
    Element
        {
            tag : Str,
            attrs : List Attribute,
        }
        (List (Html state)),
    VoidElement
        {
            tag : Str,
            attrs : List Attribute,
        },
]

ssr_document : Html state -> Str
ssr_document = |h| "<!DOCTYPE html>${ssr_element(h)}"

ssr_element : Html state -> Str
ssr_element = |h| html_to_str_without_events(h)

html_to_str_without_events : Html state -> Str
html_to_str_without_events = |h|
    when h is
        None -> ""
        Text(t) -> escape_text(t)
        Element({ tag, attrs }, children) ->
            children_str =
                # Tag matching is caseless because HTML's is. <STYLE> is
                # rawtext to the browser just like <style>.
                if Str.caseless_ascii_equals(tag, "style") then
                    # Style contents are emitted raw so inline CSS works. CSS
                    # cannot execute code, and neutralize_end_tags makes sure
                    # the text cannot close the element. Neutralizing happens
                    # after the join so a `</style` split across adjacent text
                    # nodes cannot reassemble. Script gets no such pass since
                    # no context-free rewrite preserves JS semantics, so its
                    # contents stay escaped and inert. Load scripts via `src`
                    # instead.
                    List.map(children, |c| style_text(c))
                    |> Str.join_with("")
                    |> neutralize_end_tags
                else
                    List.map(children, |c| html_to_str_without_events(c)) |> Str.join_with("")

            "<${open_tag(tag, attrs)}>${children_str}</${tag}>"

        VoidElement({ tag, attrs }) ->
            "<${open_tag(tag, attrs)} />"

escape_text : Str -> Str
escape_text = |t|
    t
    |> Str.replace_each("&", "&amp;")
    |> Str.replace_each("<", "&lt;")
    |> Str.replace_each(">", "&gt;")

escape_attr_value : Str -> Str
escape_attr_value = |v|
    v
    |> Str.replace_each("&", "&amp;")
    |> Str.replace_each("\"", "&quot;")

style_text : Html state -> Str
style_text = |h|
    when h is
        Text(t) -> t
        _ -> html_to_str_without_events(h)

## Rewrite every `</` to `<\/` so style text can never close its element.
## We rewrite every `</` and not just `</style` because HTML matches end
## tags caselessly and the style text is joined from possibly many
## fragments, so matching one spelling of one tag is not enough. The
## rewrite keeps every valid stylesheet meaning the same. `\/` is the CSS
## escape for `/` in strings and identifiers, comments ignore it, and a
## bare `</` outside those was never valid CSS anyway.
neutralize_end_tags : Str -> Str
neutralize_end_tags = |css| Str.replace_each(css, "</", "<\\/")

## The inner text of a start tag. With render-able attributes it is
## `tag attrs`. With none it is the bare `tag`, skipping the separator so an
## attribute-less element does not emit a stray space (`<td >`).
open_tag : Str, List Attribute -> Str
open_tag = |tag, attrs|
    when attrs_to_str(attrs) is
        "" -> tag
        attrs_str -> "${tag} ${attrs_str}"

attrs_to_str : List Attribute -> Str
attrs_to_str = |attrs|
    attrs
    |> List.keep_if(
        |attr|
            when attr is
                String(_) -> Bool.true
                Boolean({ value }) -> value
                Event(_) -> Bool.false # Events are not rendered in SSR
                Visibility(_) -> Bool.false, # Visibility observers are wired up client-side, not in SSR
    )
    |> List.map(
        |attr|
            when attr is
                String({ key, value }) -> "${key}=\"${escape_attr_value(value)}\""
                Boolean({ key }) -> key
                Event(_) -> "" # Events are not rendered in SSR
                Visibility(_) -> "", # Visibility observers are wired up client-side, not in SSR
    )
    |> Str.join_with(" ")

text : Str -> Html state
text = |str| Text(str)

## Create an element with an arbitrary tag name. The name is sanitized.
## Characters other than ASCII letters, digits, `-`, `_`, `.` and `:` are
## stripped so a caller-supplied string cannot inject markup.
element : Str -> (List Attribute, List (Html state) -> Html state)
element = |tag|
    sanitized_tag = Internal.sanitize_name(tag)
    |attrs, children| Element({ tag: sanitized_tag, attrs }, children)

void_element = |tag|
    |attrs| VoidElement({ tag, attrs })

# Void elements
area = void_element("area")
base = void_element("base")
br = void_element("br")
col = void_element("col")
embed = void_element("embed")
hr = void_element("hr")
img = void_element("img")
input = void_element("input")
link = void_element("link")
meta = void_element("meta")
source = void_element("source")
track = void_element("track")
wbr = void_element("wbr")

# Regular elements
a = element("a")
abbr = element("abbr")
address = element("address")
article = element("article")
aside = element("aside")
audio = element("audio")
b = element("b")
bdi = element("bdi")
bdo = element("bdo")
blockquote = element("blockquote")
body = element("body")
button = element("button")
canvas = element("canvas")
caption = element("caption")
cite = element("cite")
code = element("code")
colgroup = element("colgroup")
data = element("data")
datalist = element("datalist")
dd = element("dd")
del = element("del")
details = element("details")
dfn = element("dfn")
dialog = element("dialog")
div = element("div")
dl = element("dl")
dt = element("dt")
em = element("em")
fieldset = element("fieldset")
figcaption = element("figcaption")
figure = element("figure")
footer = element("footer")
form = element("form")
h1 = element("h1")
h2 = element("h2")
h3 = element("h3")
h4 = element("h4")
h5 = element("h5")
h6 = element("h6")
head = element("head")
header = element("header")
html = element("html")
i = element("i")
iframe = element("iframe")
ins = element("ins")
kbd = element("kbd")
label = element("label")
legend = element("legend")
li = element("li")
main = element("main")
map = element("map")
mark = element("mark")
math = element("math")
menu = element("menu")
meter = element("meter")
nav = element("nav")
noscript = element("noscript")
object = element("object")
ol = element("ol")
optgroup = element("optgroup")
option = element("option")
output = element("output")
p = element("p")
picture = element("picture")
portal = element("portal")
pre = element("pre")
progress = element("progress")
q = element("q")
rp = element("rp")
rt = element("rt")
ruby = element("ruby")
s = element("s")
samp = element("samp")
## Inline script text is entity-escaped like all other text, which makes it
## inert. Browsers do not decode entities inside `<script>`, so `<` and `&`
## in the source arrive as literal entity text and the script cannot run.
## Load JavaScript via the `src` attribute instead of inline text.
script = element("script")
section = element("section")
select = element("select")
slot = element("slot")
small = element("small")
span = element("span")
strong = element("strong")
## Style text children are emitted raw (not entity-escaped) so inline CSS
## works as written. The only rewrite is `</` to `<\/`, using the CSS escape
## for `/`, so the text can never close the element.
style = element("style")
sub = element("sub")
summary = element("summary")
sup = element("sup")
svg = element("svg")
table = element("table")
tbody = element("tbody")
td = element("td")
template = element("template")
textarea = element("textarea")
tfoot = element("tfoot")
th = element("th")
thead = element("thead")
time = element("time")
title = element("title")
tr = element("tr")
u = element("u")
ul = element("ul")
use = element("use")
var = element("var")
video = element("video")

# Minimal test to ensure CI works. Please, future me, add proper coverage.
expect
    ssr_element(
        a(
            [],
            [
                span([], [text("foo")]),
            ],
        ),
    )
    == "<a><span>foo</span></a>"

expect
    ssr_element(p([], [text("1 < 2 & 3 > 2, not <em>markup</em>")]))
    == "<p>1 &lt; 2 &amp; 3 &gt; 2, not &lt;em&gt;markup&lt;/em&gt;</p>"

expect
    ssr_element(a([Attribute.href("/?a=1&b=\"2\"")], [text("x")]))
    == "<a href=\"/?a=1&amp;b=&quot;2&quot;\">x</a>"

# Script contents are escaped like any other text, so a `</script>`
# breakout attempt stays inside the element as inert text.
expect
    ssr_element(script([], [text("</script><script>alert(1)")]))
    == "<script>&lt;/script&gt;&lt;script&gt;alert(1)</script>"

# Style contents are raw so inline CSS works as written.
expect
    ssr_element(style([], [text("a > b { color: red; }")]))
    == "<style>a > b { color: red; }</style>"

# But style text cannot close its element. Every `</` (any tag, any case)
# is rewritten to `<\/`, and the rest stays inert rawtext inside the tag.
expect
    ssr_element(style([], [text("</style><script>alert(1)</StYlE>")]))
    == "<style><\\/style><script>alert(1)<\\/StYlE></style>"

# Even a `</style` split across adjacent text nodes cannot reassemble,
# because neutralization runs on the joined style text.
expect
    ssr_element(style([], [text("</st"), text("yle><script>alert(1)</script>")]))
    == "<style><\\/style><script>alert(1)<\\/script></style>"

# Tag matching is caseless like HTML's. <STYLE> is rawtext to the browser,
# so its contents must stay raw too (entities are not decoded there).
expect
    ssr_element((element("STYLE"))([], [text("a > b { color: red; }")]))
    == "<STYLE>a > b { color: red; }</STYLE>"

# element() strips characters that could inject markup from the tag name.
expect
    ssr_element((element("div><script>alert(1)</script"))([], []))
    == "<divscriptalert1script></divscriptalert1script>"

# Attribute keys are sanitized at construction, so a hostile key cannot
# smuggle in an event handler.
expect
    ssr_element(div([Attribute.attribute("x\" onmouseover=\"alert(1)\" y", "v")], []))
    == "<div xonmouseoveralert1y=\"v\"></div>"
