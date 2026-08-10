## Build HTML with plain Roc functions.
##
## `Html(msg)` is a tree of elements. `msg` is the type your event handlers
## produce, so a view has the type `Model -> Html(Msg)`:
##
## ```roc
## view = |model|
##     Html.div([Attribute.class("counter")], [
##         Html.button([Event.on_click(Increment)], [Html.text("+")]),
##         Html.text("count: ${model.count.to_str()}"),
##     ])
## ```
##
## Every element helper takes a list of attributes and a list of children.
## Use `element` for a tag with no helper and `text` for text, which is
## always escaped and so never turns into markup.
##
## `render` turns a tree into an HTML string and `ssr_document` adds the
## doctype. Event handlers render as nothing: they come to life when the
## same view runs in the browser under a joy-zig client. For big views,
## `lazy` skips re-rendering regions that did not change and `keyed` keeps
## list items matched to their data.
##
## Attributes live in `Attribute` and event handlers in `Event`.
import Attribute exposing [Attribute]

Html(msg) := [
    Text(Str),
    Element(Str, List(Attribute(msg)), List(Html(msg))),
    Keyed(Str, Box(Html(msg))),
    Lazy(Box(({} -> Html(msg)))),
].{
    ## Use a view that has its own message type. Every message its handlers
    ## produce goes through `f` on the way to `update!`, so a component can
    ## own a Msg union and the parent wraps it:
    ## `Html.map(counter_view(model.left), |m| LeftCounter(m))`.
    map : Html(a), (a -> b) -> Html(b)
    map = |html_, f|
        match html_ {
            Text(s) => Text(s)
            Element(tag, attrs, children) =>
                Element(tag, attrs.map(|attr| Attribute.map(attr, f)), children.map(|child| Html.map(child, f)))
            # The wrapper thunk is fresh each render, so a mapped lazy region
            # never skips. Produce the parent's msg type inside the thunk
            # instead of mapping over `lazy` when the skip matters.
            Lazy(thunk) => Lazy(Box.box(|_| Html.map((Box.unbox(thunk))({}), f)))
            Keyed(key, child) => Keyed(key, Box.box(Html.map(Box.unbox(child), f)))
        }

    ## A text node. The string is entity-escaped when rendered, so it shows
    ## up exactly as written and never as markup.
    text : Str -> Html(msg)
    text = |s| Text(s)

    ## Skip re-rendering a region whose inputs did not change. Wrap an
    ## expensive part of the view and pass the model fields it reads:
    ## `Html.lazy2(render_cards, model.users, model.category)`. While both
    ## fields stay the same, the previous subtree is kept and `render_cards`
    ## never runs.
    ##
    ## Pass fields and not the whole model: everything you pass is compared,
    ## so one unrelated field changing costs you the skip. The view has to be
    ## a named function too, because a lambda written at the call site is a
    ## new value every render and never matches. Same for arguments built
    ## during the render, like a mapped list or an interpolated string. They
    ## are safe to pass, they just never skip.
    ##
    ## `lazy2` through `lazy8` take more inputs. Past eight, pass a record.
    lazy : (a -> Html(msg)), a -> Html(msg)
    lazy = |view, a| Lazy(Box.box(|_| view(a)))

    ## `lazy` for a view of two inputs. See `lazy`.
    lazy2 : (a, b -> Html(msg)), a, b -> Html(msg)
    lazy2 = |view, a, b| Lazy(Box.box(|_| view(a, b)))

    ## `lazy` for a view of three inputs. See `lazy`.
    lazy3 : (a, b, c -> Html(msg)), a, b, c -> Html(msg)
    lazy3 = |view, a, b, c| Lazy(Box.box(|_| view(a, b, c)))

    ## `lazy` for a view of four inputs. See `lazy`.
    lazy4 : (a, b, c, d -> Html(msg)), a, b, c, d -> Html(msg)
    lazy4 = |view, a, b, c, d| Lazy(Box.box(|_| view(a, b, c, d)))

    ## `lazy` for a view of five inputs. See `lazy`.
    lazy5 : (a, b, c, d, e -> Html(msg)), a, b, c, d, e -> Html(msg)
    lazy5 = |view, a, b, c, d, e| Lazy(Box.box(|_| view(a, b, c, d, e)))

    ## `lazy` for a view of six inputs. See `lazy`.
    lazy6 : (a, b, c, d, e, f -> Html(msg)), a, b, c, d, e, f -> Html(msg)
    lazy6 = |view, a, b, c, d, e, f| Lazy(Box.box(|_| view(a, b, c, d, e, f)))

    ## `lazy` for a view of seven inputs. See `lazy`.
    lazy7 : (a, b, c, d, e, f, g -> Html(msg)), a, b, c, d, e, f, g -> Html(msg)
    lazy7 = |view, a, b, c, d, e, f, g| Lazy(Box.box(|_| view(a, b, c, d, e, f, g)))

    ## `lazy` for a view of eight inputs. See `lazy`.
    lazy8 : (a, b, c, d, e, f, g, h -> Html(msg)), a, b, c, d, e, f, g, h -> Html(msg)
    lazy8 = |view, a, b, c, d, e, f, g, h| Lazy(Box.box(|_| view(a, b, c, d, e, f, g, h)))

    ## Keep a list item tied to its data when the list changes. Children with
    ## no key are matched by position, so removing the first row shifts every
    ## row below it and whatever the browser holds (typed text, focus, scroll
    ## position, a running animation) stays behind at the old position. A key
    ## makes those move with the item instead:
    ##
    ## ```roc
    ## Html.ul([], model.rows.map(|row| Html.keyed(row.id, render_row(row))))
    ## ```
    ##
    ## Key every child of the list rather than a few, and use something from
    ## the data that is unique among siblings and survives a reorder, so not
    ## the list index. The key itself is never rendered. Rows that are also
    ## expensive to build can skip that too:
    ## `Html.keyed(row.id, Html.lazy2(render_row, row, is_selected))`.
    ##
    ## (Elm and Lustre put the key on the container. Here it goes on the
    ## child, so there is no separate keyed container helper.)
    keyed : Str, Html(msg) -> Html(msg)
    keyed = |key, child| Keyed(key, Box.box(child))

    ## Create an element with an arbitrary tag name. The name is sanitized.
    ## Characters other than ASCII letters, digits, `-`, `_`, `.` and `:`
    ## are stripped so a caller-supplied string cannot inject markup.
    element : Str, List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    element = |tag, attrs, children| Element(Attribute.sanitize_name(tag), attrs, children)

    ## Render a tree to an HTML string (server-side rendering). Text and
    ## attribute values are escaped, event handlers are skipped and void
    ## elements render as `<tag />`. Inline `script` text is escaped like any
    ## other text and so cannot run, while `style` text is emitted raw.
    render : Html(msg) -> Str
    render = |h| render_node(h)

    ## A full SSR page: "<!DOCTYPE html>" plus the rendered tree.
    ssr_document : Html(msg) -> Str
    ssr_document = |h| "<!DOCTYPE html>${render_node(h)}"

    # Regular elements

    a : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    a = |attrs, children| Element("a", attrs, children)

    article : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    article = |attrs, children| Element("article", attrs, children)

    aside : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    aside = |attrs, children| Element("aside", attrs, children)

    blockquote : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    blockquote = |attrs, children| Element("blockquote", attrs, children)

    body : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    body = |attrs, children| Element("body", attrs, children)

    button : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    button = |attrs, children| Element("button", attrs, children)

    caption : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    caption = |attrs, children| Element("caption", attrs, children)

    code : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    code = |attrs, children| Element("code", attrs, children)

    dd : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    dd = |attrs, children| Element("dd", attrs, children)

    details : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    details = |attrs, children| Element("details", attrs, children)

    dialog : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    dialog = |attrs, children| Element("dialog", attrs, children)

    div : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    div = |attrs, children| Element("div", attrs, children)

    dl : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    dl = |attrs, children| Element("dl", attrs, children)

    dt : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    dt = |attrs, children| Element("dt", attrs, children)

    em : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    em = |attrs, children| Element("em", attrs, children)

    fieldset : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    fieldset = |attrs, children| Element("fieldset", attrs, children)

    figure : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    figure = |attrs, children| Element("figure", attrs, children)

    footer : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    footer = |attrs, children| Element("footer", attrs, children)

    form : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    form = |attrs, children| Element("form", attrs, children)

    h1 : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    h1 = |attrs, children| Element("h1", attrs, children)

    h2 : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    h2 = |attrs, children| Element("h2", attrs, children)

    h3 : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    h3 = |attrs, children| Element("h3", attrs, children)

    h4 : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    h4 = |attrs, children| Element("h4", attrs, children)

    h5 : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    h5 = |attrs, children| Element("h5", attrs, children)

    h6 : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    h6 = |attrs, children| Element("h6", attrs, children)

    head : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    head = |attrs, children| Element("head", attrs, children)

    header : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    header = |attrs, children| Element("header", attrs, children)

    html : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    html = |attrs, children| Element("html", attrs, children)

    iframe : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    iframe = |attrs, children| Element("iframe", attrs, children)

    label : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    label = |attrs, children| Element("label", attrs, children)

    legend : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    legend = |attrs, children| Element("legend", attrs, children)

    li : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    li = |attrs, children| Element("li", attrs, children)

    main : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    main = |attrs, children| Element("main", attrs, children)

    nav : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    nav = |attrs, children| Element("nav", attrs, children)

    ol : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    ol = |attrs, children| Element("ol", attrs, children)

    ## One choice in a `select`. The label is a text child and the submitted
    ## string is `Attribute.value`. Mark the current choice with
    ## `Attribute.selected`, which is what SSR needs to render a preselected
    ## dropdown.
    option : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    option = |attrs, children| Element("option", attrs, children)

    p : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    p = |attrs, children| Element("p", attrs, children)

    pre : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    pre = |attrs, children| Element("pre", attrs, children)

    progress : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    progress = |attrs, children| Element("progress", attrs, children)

    ## Load JavaScript with the `src` attribute. Inline script text is
    ## escaped like any other text, and browsers do not decode entities
    ## inside `<script>`, so an inline script never runs.
    script : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    script = |attrs, children| Element("script", attrs, children)

    section : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    section = |attrs, children| Element("section", attrs, children)

    ## A dropdown of `option` children. Put `Event.on_change` on the select
    ## itself, not on the options: it reports the chosen option's `value`.
    select : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    select = |attrs, children| Element("select", attrs, children)

    small : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    small = |attrs, children| Element("small", attrs, children)

    span : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    span = |attrs, children| Element("span", attrs, children)

    strong : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    strong = |attrs, children| Element("strong", attrs, children)

    ## Style text is emitted raw, not escaped, so inline CSS works as
    ## written. The one rewrite is `</` to `<\/` (the CSS escape for `/`), so
    ## the text cannot close the element early.
    style : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    style = |attrs, children| Element("style", attrs, children)

    summary : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    summary = |attrs, children| Element("summary", attrs, children)

    ## An SVG root. Inner SVG tags have no helpers here, so build them with
    ## `element("path", ...)`. Camel-cased SVG attribute names survive
    ## sanitizing, so `Attribute.attribute("viewBox", "0 0 24 24")` works.
    svg : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    svg = |attrs, children| Element("svg", attrs, children)

    table : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    table = |attrs, children| Element("table", attrs, children)

    tbody : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    tbody = |attrs, children| Element("tbody", attrs, children)

    td : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    td = |attrs, children| Element("td", attrs, children)

    ## Markup the browser parses but does not render or run until a script
    ## clones it. Its children are ordinary `Html` and are escaped like any
    ## other, so this is a holding pen, not a raw-markup escape hatch.
    template : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    template = |attrs, children| Element("template", attrs, children)

    ## Unlike `input`, a textarea's initial content is a text child rather
    ## than `Attribute.value`: `textarea([], [text(model.draft)])`. Whitespace
    ## inside the tag is significant, so do not pad the text for readability.
    textarea : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    textarea = |attrs, children| Element("textarea", attrs, children)

    tfoot : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    tfoot = |attrs, children| Element("tfoot", attrs, children)

    th : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    th = |attrs, children| Element("th", attrs, children)

    thead : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    thead = |attrs, children| Element("thead", attrs, children)

    time : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    time = |attrs, children| Element("time", attrs, children)

    title : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    title = |attrs, children| Element("title", attrs, children)

    tr : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    tr = |attrs, children| Element("tr", attrs, children)

    ul : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    ul = |attrs, children| Element("ul", attrs, children)

    ## Reference another SVG node by id, the usual way to stamp out a sprite
    ## from a symbol: `use([Attribute.href("#icon-close")], [])`.
    use : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    use = |attrs, children| Element("use", attrs, children)

    video : List(Attribute(msg)), List(Html(msg)) -> Html(msg)
    video = |attrs, children| Element("video", attrs, children)

    # Void elements. They take no children (the DOM ignores children on
    # them anyway) and render as `<tag />` without a closing tag.

    br : List(Attribute(msg)) -> Html(msg)
    br = |attrs| Element("br", attrs, [])

    hr : List(Attribute(msg)) -> Html(msg)
    hr = |attrs| Element("hr", attrs, [])

    img : List(Attribute(msg)) -> Html(msg)
    img = |attrs| Element("img", attrs, [])

    input : List(Attribute(msg)) -> Html(msg)
    input = |attrs| Element("input", attrs, [])

    link : List(Attribute(msg)) -> Html(msg)
    link = |attrs| Element("link", attrs, [])

    meta : List(Attribute(msg)) -> Html(msg)
    meta = |attrs| Element("meta", attrs, [])

    source : List(Attribute(msg)) -> Html(msg)
    source = |attrs| Element("source", attrs, [])
}

# --- SSR renderer ---
# All walkers below are RECURSIVE (index plus accumulator) instead of loops
# or folds: helpers containing loops or folds, reached from another
# function's match branches, trip a compiler OOM at build time.

# SSR forces lazy subtrees, mapped or not. An ordinary constructor is a
# perfectly good view, so these need no purpose-built ones.
expect {
    h : Html([])
    h = Html.lazy(Html.text, "hi")
    Html.render(h) == "hi"
}
expect {
    h : Html([A])
    h = Html.lazy(Html.br, [])
    Html.render(Html.map(h, |m| m)) == "<br />"
}

# lazy2 through lazy8 are hand-written wrappers, so a transposed argument
# would be silent wherever two inputs share a type. This pins the order at
# the widest arity, where a slip is likeliest.
## Named (not a lambda) so `lazy8` accepts it, and Str-typed throughout so a
## transposed argument would change the rendered order.
eight_args : Str, Str, Str, Str, Str, Str, Str, Str -> Html(msg)
eight_args = |a, b, c, d, e, f, g, h| Html.text("${a}${b}${c}${d}${e}${f}${g}${h}")

expect {
    h : Html([])
    h = Html.lazy8(eight_args, "1", "2", "3", "4", "5", "6", "7", "8")
    Html.render(h) == "12345678"
}

render_node : Html(msg) -> Str
render_node = |h|
    match h {
        # SSR has no retained previous render, so a lazy subtree is simply
        # forced.
        Lazy(thunk) => render_node((Box.unbox(thunk))({}))
        Keyed(_key, child) => render_node(Box.unbox(child))
        Text(t) => escape_text(t)
        Element(tag, attrs, children) =>
            if is_void_tag(tag) {
                # Void-ness is decided by tag name, so any children on a
                # void element are dropped. The void constructors above
                # never take children in the first place.
                "<${open_tag(tag, attrs)} />"
            } else if tag.caseless_ascii_equals("style") {
                # Tag matching is caseless because HTML's is. <STYLE> is
                # rawtext to the browser just like <style>.
                #
                # Style contents are emitted raw so inline CSS works. CSS
                # cannot execute code, and neutralize_end_tags makes sure
                # the text cannot close the element. Neutralizing happens
                # after the join so a `</style` split across adjacent text
                # nodes cannot reassemble. Script gets no such pass since
                # no context-free rewrite preserves JS semantics, so its
                # contents stay escaped and inert. Load scripts via `src`
                # instead.
                children_str = neutralize_end_tags(style_children_str(children, 0, ""))
                "<${open_tag(tag, attrs)}>${children_str}</${tag}>"
            } else {
                "<${open_tag(tag, attrs)}>${render_children(children, 0, "")}</${tag}>"
            }
    }

## Render every child in order and concatenate the results.
render_children : List(Html(msg)), U64, Str -> Str
render_children = |children, idx, acc|
    match children.get(idx) {
        Ok(child) => render_children(children, idx + 1, Str.concat(acc, render_node(child)))
        Err(_) => acc
    }

## Direct text children of a style element stay raw, anything else renders
## normally.
style_children_str : List(Html(msg)), U64, Str -> Str
style_children_str = |children, idx, acc|
    match children.get(idx) {
        Ok(child) => {
            part = match child {
                Text(t) => t
                _ => render_node(child)
            }
            style_children_str(children, idx + 1, Str.concat(acc, part))
        }
        Err(_) => acc
    }

## The inner text of a start tag. With render-able attributes it is
## `tag attrs`. With none it is the bare `tag`, skipping the separator so an
## attribute-less element does not emit a stray space (`<td >`).
open_tag : Str, List(Attribute(msg)) -> Str
open_tag = |tag, attrs| {
    attrs_str = attrs_to_str(attrs, 0, "")
    if Str.is_empty(attrs_str) {
        tag
    } else {
        "${tag} ${attrs_str}"
    }
}

## Render-able attributes joined with single spaces. Handlers, false
## booleans and visibility observers produce "" from `Attribute.to_ssr_str`
## and are dropped here so they leave no stray separator.
attrs_to_str : List(Attribute(msg)), U64, Str -> Str
attrs_to_str = |attrs, idx, acc|
    match attrs.get(idx) {
        Ok(attr) => {
            part = Attribute.to_ssr_str(attr)
            joined =
                if Str.is_empty(part) {
                    acc
                } else if Str.is_empty(acc) {
                    part
                } else {
                    "${acc} ${part}"
                }
            attrs_to_str(attrs, idx + 1, joined)
        }
        Err(_) => acc
    }

## Entity-escape text content. There is no Str.replace_each to call, so
## replacement is split_on plus join_with, `&` first so the ampersands it
## introduces are not escaped again.
escape_text : Str -> Str
escape_text = |t| {
    amp = Str.join_with(Str.split_on(t, "&"), "&amp;")
    lt = Str.join_with(Str.split_on(amp, "<"), "&lt;")
    Str.join_with(Str.split_on(lt, ">"), "&gt;")
}

## Rewrite every `</` to `<\/` so style text can never close its element.
## Every `</` is rewritten and not just `</style` because HTML matches end
## tags caselessly and the style text is joined from possibly many
## fragments, so matching one spelling of one tag is not enough. The
## rewrite keeps every valid stylesheet meaning the same. `\/` is the CSS
## escape for `/` in strings and identifiers, comments ignore it, and a
## bare `</` outside those was never valid CSS anyway.
neutralize_end_tags : Str -> Str
neutralize_end_tags = |css| Str.join_with(Str.split_on(css, "</"), "<\\/")

## The HTML void elements, the ones that take no children and render with
## no closing tag. Matched by lowercase tag name.
is_void_tag : Str -> Bool
is_void_tag = |tag|
    tag == "area"
    or tag == "base"
    or tag == "br"
    or tag == "col"
    or tag == "embed"
    or tag == "hr"
    or tag == "img"
    or tag == "input"
    or tag == "link"
    or tag == "meta"
    or tag == "source"
    or tag == "track"
    or tag == "wbr"

# --- roc test (run via `roc test --main=package/main.roc package/Html.roc`) ---
# Assertions compare rendered strings, never Html values: trees can hold
# boxed event functions, which have no equality. Msg is Str throughout.

## `render` pinned to a concrete msg type so the expects below type-check.
view_render : Html(Str) -> Str
view_render = |h| Html.render(h)

## `ssr_document` pinned to a concrete msg type, as with `view_render`.
view_document : Html(Str) -> Str
view_document = |h| Html.ssr_document(h)

expect
    view_render(Html.a([], [Html.span([], [Html.text("foo")])]))
    == "<a><span>foo</span></a>"

# Text nodes are entity-escaped.
expect
    view_render(Html.p([], [Html.text("1 < 2 & 3 > 2, not <em>markup</em>")]))
    == "<p>1 &lt; 2 &amp; 3 &gt; 2, not &lt;em&gt;markup&lt;/em&gt;</p>"

# Attribute values are escaped inside double quotes.
expect
    view_render(Html.a([Attribute.href("/?a=1&b=\"2\"")], [Html.text("x")]))
    == "<a href=\"/?a=1&amp;b=&quot;2&quot;\">x</a>"

# A nested document render, with the doctype up front.
expect
    view_document(
        Html.html(
            [],
            [
                Html.head([], [Html.title([], [Html.text("Hi")])]),
                Html.body([Attribute.class("page")], [Html.h1([], [Html.text("Hello")])]),
            ],
        ),
    )
    == "<!DOCTYPE html><html><head><title>Hi</title></head><body class=\"page\"><h1>Hello</h1></body></html>"

# Void elements render without closing tags, and without a stray space when
# they carry no attributes.
expect view_render(Html.br([])) == "<br />"
expect view_render(Html.img([Attribute.src("/x.png"), Attribute.alt("x")])) == "<img src=\"/x.png\" alt=\"x\" />"
expect view_render(Html.input([Attribute.type("text"), Attribute.disabled(Bool.True)])) == "<input type=\"text\" disabled />"
expect view_render(Html.meta([Attribute.attribute("charset", "utf-8")])) == "<meta charset=\"utf-8\" />"
expect view_render(Html.hr([])) == "<hr />"

# Event attributes are skipped in SSR and leave no stray space.
expect
    view_render(Html.button([Attribute.on_click("clicked")], [Html.text("Go")]))
    == "<button>Go</button>"

expect
    view_render(Html.button([Attribute.class("btn"), Attribute.on_click("clicked")], [Html.text("Go")]))
    == "<button class=\"btn\">Go</button>"

expect
    view_render(Html.input([Attribute.on_input(|s| "typed:${s}"), Attribute.value("v")]))
    == "<input value=\"v\" />"

# False boolean attributes disappear, true ones render as the bare key.
expect
    view_render(Html.input([Attribute.checked(Bool.False), Attribute.required(Bool.True)]))
    == "<input required />"

# Script contents are escaped like any other text, so a `</script>`
# breakout attempt stays inside the element as inert text.
expect
    view_render(Html.script([], [Html.text("</script><script>alert(1)")]))
    == "<script>&lt;/script&gt;&lt;script&gt;alert(1)</script>"

# Style contents are raw so inline CSS works as written.
expect
    view_render(Html.style([], [Html.text("a > b { color: red; }")]))
    == "<style>a > b { color: red; }</style>"

# But style text cannot close its element. Every `</` (any tag, any case)
# is rewritten to `<\/`, and the rest stays inert rawtext inside the tag.
expect
    view_render(Html.style([], [Html.text("</style><script>alert(1)</StYlE>")]))
    == "<style><\\/style><script>alert(1)<\\/StYlE></style>"

# Even a `</style` split across adjacent text nodes cannot reassemble,
# because neutralization runs on the joined style text.
expect
    view_render(Html.style([], [Html.text("</st"), Html.text("yle><script>alert(1)</script>")]))
    == "<style><\\/style><script>alert(1)<\\/script></style>"

# Tag matching is caseless like HTML's. <STYLE> is rawtext to the browser,
# so its contents must stay raw too (entities are not decoded there).
expect
    view_render(Html.element("STYLE", [], [Html.text("a > b { color: red; }")]))
    == "<STYLE>a > b { color: red; }</STYLE>"

# element() strips characters that could inject markup from the tag name.
expect
    view_render(Html.element("div><script>alert(1)</script", [], []))
    == "<divscriptalert1script></divscriptalert1script>"

# Attribute keys are sanitized at construction, so a hostile key cannot
# smuggle in an event handler.
expect
    view_render(Html.div([Attribute.attribute("x\" onmouseover=\"alert(1)\" y", "v")], []))
    == "<div xonmouseoveralert1y=\"v\"></div>"

# Html.map passes every produced message through the wrapper while leaving
# the rendered output untouched.
expect
    view_render(Html.div([Attribute.on_click("inner")], [Html.text("hello")]).map(|s| "outer:${s}"))
    == "<div>hello</div>"
