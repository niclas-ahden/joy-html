module [
    Html,
    ssr_document,
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

# TODO: Move `events` into `attrs` for an API like:
#
#     button([], [on_click("foo")])
#
# This would:
# - Remove the need for `element` vs `element_with_events`. Why/how does `joy-html` decide which
#   elements can/should have events?
# - Make the API more "expected". `onclick` is an HTML attribute and users would naturally expect
#   that it goes in the same argument slot as other attributes.
# - Remove an unnecessary empty list of events for elements that _can_ have events, but don't:
#       select([], [...children...], [])
Html state : [
    None,
    Text Str,
    Element
        {
            tag : Str,
            attrs : List { key : Str, value : Str },
            events : List { name : Str, handler : Str },
        }
        (List (Html state)),
]

ssr_document : Html state -> Str
ssr_document = |h| "<!DOCTYPE html>${ssr_element(h)}"

ssr_element : Html state -> Str
ssr_element = |h| html_to_str_without_events(h)

html_to_str_without_events : Html state -> Str
html_to_str_without_events = |h|
    when h is
        None -> ""
        Text(t) -> t
        Element({ tag, attrs }, children) ->
            attrs_str = List.map(attrs, |attr| "${attr.key}=\"${attr.value}\"") |> Str.join_with(" ")
            open_tag =
                [tag, attrs_str]
                |> List.keep_if(|ss| Str.is_empty(ss) == Bool.false)
                |> Str.join_with(" ")
            "<${open_tag}>${List.map(children, |c| html_to_str_without_events(c)) |> Str.join_with("")}</${tag}>"

text : Str -> Html state
text = |str| Text(str)

element : Str -> (List { key : Str, value : Str }, List (Html state) -> Html state)
element = |tag|
    |attrs, children| Element({ tag, attrs, events: [] }, children)

element_with_events : Str -> (List { key : Str, value : Str }, List { name : Str, handler : Str }, List (Html state) -> Html state)
element_with_events = |tag|
    |attrs, events, children| Element({ tag, attrs, events }, children)

void_element = |tag|
    |attrs| Element({ tag, attrs, events: [] }, [])

void_element_with_events = |tag|
    |attrs, events| Element({ tag, attrs, events }, [])

# Elements

# TODO: How do we want to handle events long-term?
button = element_with_events("button")
input = void_element_with_events("input")
select = element_with_events("select")
textarea = element_with_events("textarea")

# Void elements
area = void_element("area")
base = void_element("base")
br = void_element("br")
col = void_element("col")
embed = void_element("embed")
hr = void_element("hr")
img = void_element("img")
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
script = element("script")
section = element("section")
slot = element("slot")
small = element("small")
span = element("span")
strong = element("strong")
style = element("style")
sub = element("sub")
summary = element("summary")
sup = element("sup")
svg = element("svg")
table = element("table")
tbody = element("tbody")
td = element("td")
template = element("template")
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
