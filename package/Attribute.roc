module [
    Attribute,
    accept,
    accept_charset,
    accesskey,
    action,
    align,
    allow,
    allowfullscreen,
    alpha,
    alt,
    aria,
    async,
    attribute,
    autocapitalize,
    autocomplete,
    autofocus,
    autoplay,
    background,
    bgcolor,
    border,
    buffered,
    capture,
    challenge,
    charset,
    checked,
    cite,
    class,
    class_list,
    classes,
    code,
    codebase,
    color,
    cols,
    colspan,
    content,
    contenteditable,
    contextmenu,
    controls,
    coords,
    crossorigin,
    csp,
    data,
    datetime,
    decoding,
    default,
    defer,
    dir,
    dirname,
    disabled,
    download,
    draggable,
    enctype,
    enterkeyhint,
    for,
    form,
    formaction,
    formenctype,
    formmethod,
    formnovalidate,
    formtarget,
    headers,
    height,
    hidden,
    high,
    href,
    hreflang,
    http_equiv,
    icon,
    id,
    importance,
    inert,
    inputmode,
    integrity,
    intrinsicsize,
    ismap,
    itemprop,
    itemscope,
    itemtype,
    keytype,
    kind,
    label,
    lang,
    language,
    list,
    loading,
    loop,
    low,
    manifest,
    max,
    maxlength,
    media,
    method,
    min,
    minlength,
    multiple,
    muted,
    name,
    nomodule,
    novalidate,
    oncontextmenu,
    open,
    optimum,
    pattern,
    ping,
    placeholder,
    playsinline,
    poster,
    preload,
    property,
    radiogroup,
    readonly,
    referrerpolicy,
    rel,
    required,
    reversed,
    role,
    rows,
    rowspan,
    sandbox,
    scope,
    scoped,
    selected,
    shadowrootclonable,
    shadowrootdelegatesfocus,
    shadowrootserializable,
    shape,
    size,
    sizes,
    slot,
    span,
    spellcheck,
    src,
    srcdoc,
    srclang,
    srcset,
    start,
    step,
    style,
    summary,
    tabindex,
    target,
    title,
    translate,
    type,
    usemap,
    value,
    width,
    wrap,
]

Attribute : [
    Boolean { key : Str, value : Bool },
    String { key : Str, value : Str },
    # NOTE: Perhaps we want `Enumerated` attributes in the future?
    # https://developer.mozilla.org/en-US/docs/Glossary/Enumerated
]

# Special cases
classes : List Str -> Attribute
classes = |cs| String({ key: "class", value: Str.join_with(cs, " ") })

class_list : List (Str, Bool) -> Attribute
class_list = |cs|
    val =
        cs
        |> List.keep_if(|(_, active)| active)
        |> List.map(|(klass, _)| klass)
        |> Str.join_with(" ")

    String({ key: "class", value: val })

style : List (Str, Str) -> Attribute
style = |styles|
    val =
        List.map(styles, |(k, v)| "${k}: ${v}")
        |> Str.join_with(";")

    String({ key: "style", value: val })

data : Str, Str -> Attribute
data = |data_name, data_value|
    String({ key: "data-${data_name}", value: data_value })

aria : Str, Str -> Attribute
aria = |aria_name, aria_value|
    String({ key: "aria-${aria_name}", value: aria_value })

# Boolean attributes: https://chinedufn.github.io/percy/html-macro/boolean-attributes/index.html

boolean_attribute : Str -> (Bool -> Attribute)
boolean_attribute = |key| |val| Boolean({ key, value: val })

allowfullscreen = boolean_attribute("allowfullscreen")
alpha = boolean_attribute("alpha")
async = boolean_attribute("async")
autofocus = boolean_attribute("autofocus")
autoplay = boolean_attribute("autoplay")
controls = boolean_attribute("controls")
default = boolean_attribute("default")
defer = boolean_attribute("defer")
formnovalidate = boolean_attribute("formnovalidate")
inert = boolean_attribute("inert")
ismap = boolean_attribute("ismap")
itemscope = boolean_attribute("itemscope")
loop = boolean_attribute("loop")
multiple = boolean_attribute("multiple")
muted = boolean_attribute("muted")
nomodule = boolean_attribute("nomodule")
novalidate = boolean_attribute("novalidate")
open = boolean_attribute("open")
playsinline = boolean_attribute("playsinline")
readonly = boolean_attribute("readonly")
required = boolean_attribute("required")
reversed = boolean_attribute("reversed")
selected = boolean_attribute("selected")
shadowrootclonable = boolean_attribute("shadowrootclonable")
shadowrootdelegatesfocus = boolean_attribute("shadowrootdelegatesfocus")
shadowrootserializable = boolean_attribute("shadowrootserializable")

## `checked` is a boolean/binary attribute. Given `Bool.true` it'll be present on the element,
## otherwise it'll be absent. It's impossible to set it to a certain value like other attributes
## (e.g. `checked="true"` or `checked="1"`).
##
## This platform uses `percy-dom` to render HTML and `percy-dom` treats `checked` in a non-standard
## way. Usually `checked` is used to determine if the element is checked by default on first
## render, but it will not be affected if a user checks/unchecks the element later. There's a
## different way to access the current state of the element, but it's not this attribute. However,
## `percy-dom` goes against the grain and _does_ use this attribute to set the current state of the
## element. This makes for an ergonomic API:
##
##     input([ type("checkbox"), checked(is_checked) ] [ { name: "onclick", handler: ...
##
## If the `onclick` event toggles the value of `is_checked`, the element will be re-rendered and its
## state will change to reflect its current "checkedness".
##
## Read more:
## https://chinedufn.github.io/percy/html-macro/boolean-attributes/index.html
## https://chinedufn.github.io/percy/html-macro/special-attributes/index.html
checked : Bool -> Attribute
checked = boolean_attribute("checked")

## `disabled` is a boolean/binary attribute. Given `Bool.true` it'll be present on the element,
## otherwise it'll be absent. It's impossible to set it to a certain value like other attributes
## (e.g. `disabled="true"` or `disabled="1"`).
disabled : Bool -> Attribute
disabled = boolean_attribute("disabled")

# Special attributes: https://chinedufn.github.io/percy/html-macro/special-attributes/index.html
# TODO: Do we need special treatment of `value`?

# Attributes

# Exposed generic function to create arbitrary attributes
attribute : Str, Str -> Attribute
attribute = |key, v| String({ key, value: v })

attribute_function : Str -> (Str -> Attribute)
attribute_function = |key| |v| String({ key, value: v })

accept = attribute_function("accept")
accept_charset = attribute_function("accept-charset")
accesskey = attribute_function("accesskey")
action = attribute_function("action")
align = attribute_function("align")
allow = attribute_function("allow")
alt = attribute_function("alt")
autocapitalize = attribute_function("autocapitalize")
autocomplete = attribute_function("autocomplete")
background = attribute_function("background")
bgcolor = attribute_function("bgcolor")
border = attribute_function("border")
buffered = attribute_function("buffered")
capture = attribute_function("capture")
challenge = attribute_function("challenge")
charset = attribute_function("charset")
cite = attribute_function("cite")
class = attribute_function("class")
code = attribute_function("code")
codebase = attribute_function("codebase")
color = attribute_function("color")
cols = attribute_function("cols")
colspan = attribute_function("colspan")
content = attribute_function("content")
contenteditable = attribute_function("contenteditable")
contextmenu = attribute_function("contextmenu")
coords = attribute_function("coords")
crossorigin = attribute_function("crossorigin")
csp = attribute_function("csp")
datetime = attribute_function("datetime")
decoding = attribute_function("decoding")
dir = attribute_function("dir")
dirname = attribute_function("dirname")
download = attribute_function("download")
draggable = attribute_function("draggable")
enctype = attribute_function("enctype")
enterkeyhint = attribute_function("enterkeyhint")
for = attribute_function("for")
form = attribute_function("form")
formaction = attribute_function("formaction")
formenctype = attribute_function("formenctype")
formmethod = attribute_function("formmethod")
formtarget = attribute_function("formtarget")
headers = attribute_function("headers")
height = attribute_function("height")
hidden = attribute_function("hidden")
high = attribute_function("high")
href = attribute_function("href")
hreflang = attribute_function("hreflang")
http_equiv = attribute_function("http-equiv")
icon = attribute_function("icon")
id = attribute_function("id")
importance = attribute_function("importance")
inputmode = attribute_function("inputmode")
integrity = attribute_function("integrity")
intrinsicsize = attribute_function("intrinsicsize")
itemprop = attribute_function("itemprop")
itemtype = attribute_function("itemtype")
keytype = attribute_function("keytype")
kind = attribute_function("kind")
label = attribute_function("label")
lang = attribute_function("lang")
language = attribute_function("language")
list = attribute_function("list")
loading = attribute_function("loading")
low = attribute_function("low")
manifest = attribute_function("manifest")
max = attribute_function("max")
maxlength = attribute_function("maxlength")
media = attribute_function("media")
method = attribute_function("method")
min = attribute_function("min")
minlength = attribute_function("minlength")
name = attribute_function("name")
oncontextmenu = attribute_function("oncontextmenu")
optimum = attribute_function("optimum")
pattern = attribute_function("pattern")
ping = attribute_function("ping")
placeholder = attribute_function("placeholder")
poster = attribute_function("poster")
preload = attribute_function("preload")
property = attribute_function("property")
radiogroup = attribute_function("radiogroup")
referrerpolicy = attribute_function("referrerpolicy")
rel = attribute_function("rel")
role = attribute_function("role")
rows = attribute_function("rows")
rowspan = attribute_function("rowspan")
sandbox = attribute_function("sandbox")
scope = attribute_function("scope")
scoped = attribute_function("scoped")
shape = attribute_function("shape")
size = attribute_function("size")
sizes = attribute_function("sizes")
slot = attribute_function("slot")
span = attribute_function("span")
spellcheck = attribute_function("spellcheck")
src = attribute_function("src")
srcdoc = attribute_function("srcdoc")
srclang = attribute_function("srclang")
srcset = attribute_function("srcset")
start = attribute_function("start")
step = attribute_function("step")
summary = attribute_function("summary")
tabindex = attribute_function("tabindex")
target = attribute_function("target")
title = attribute_function("title")
translate = attribute_function("translate")
type = attribute_function("type")
usemap = attribute_function("usemap")
value = attribute_function("value")
width = attribute_function("width")
wrap = attribute_function("wrap")
