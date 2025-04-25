module [
    accept,
    accept_charset,
    accesskey,
    action,
    align,
    allow,
    allowfullscreen,
    alpha,
    alt,
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

# Special cases
classes = |cs| { key: "class", value: Str.join_with(cs, " ") }

class_list : List (Str, Bool) -> { key : Str, value : Str }
class_list = |cs|
    val =
        cs
        |> List.keep_if(|(_, active)| active)
        |> List.map(|(klass, _)| klass)
        |> Str.join_with(" ")

    { key: "class", value: val }

style : List (Str, Str) -> { key : Str, value : Str }
style = |styles|
    val =
        List.map(styles, |(k, v)| "${k}: ${v}")
        |> Str.join_with(";")

    { key: "style", value: val }

data : Str, Str -> { key : Str, value : Str }
data = |data_name, data_value|
    { key: "data-${data_name}", value: data_value }

# Boolean attributes: https://chinedufn.github.io/percy/html-macro/boolean-attributes/index.html

boolean_attribute : Str -> (Bool -> { key : Str, value : Str })
boolean_attribute = |key| |val| { key, value: if val then "true" else "false" }

# NOTE: The list of boolean attributes must be kept in sync with Joy's list
# in `roc_to_percy_attrs` in the file `crates/web/src/lib.rs`.
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
##     input([ type("checkbox"), checked(isChecked) ] [ { name: "onclick", handler: ...
##
## If the `onclick` event toggles the value of `isChecked`, the element will be re-rendered and its
## state will change to reflect its current "checkedness".
##
## Read more:
## https://chinedufn.github.io/percy/html-macro/boolean-attributes/index.html
## https://chinedufn.github.io/percy/html-macro/special-attributes/index.html
checked : Bool -> { key : Str, value : Str }
checked = boolean_attribute("checked")

## `disabled` is a boolean/binary attribute. Given `Bool.true` it'll be present on the element,
## otherwise it'll be absent. It's impossible to set it to a certain value like other attributes
## (e.g. `disabled="true"` or `disabled="1"`).
disabled : Bool -> { key : Str, value : Str }
disabled = boolean_attribute("disabled")

# Special attributes: https://chinedufn.github.io/percy/html-macro/special-attributes/index.html
# TODO: Do we need special treatment of `value`?

# Attributes

attribute : Str -> (Str -> { key : Str, value : Str })
attribute = |key| |v| { key, value: v }

accept = attribute("accept")
accept_charset = attribute("accept-charset")
accesskey = attribute("accesskey")
action = attribute("action")
align = attribute("align")
allow = attribute("allow")
alt = attribute("alt")
autocapitalize = attribute("autocapitalize")
autocomplete = attribute("autocomplete")
background = attribute("background")
bgcolor = attribute("bgcolor")
border = attribute("border")
buffered = attribute("buffered")
capture = attribute("capture")
challenge = attribute("challenge")
charset = attribute("charset")
cite = attribute("cite")
class = attribute("class")
code = attribute("code")
codebase = attribute("codebase")
color = attribute("color")
cols = attribute("cols")
colspan = attribute("colspan")
content = attribute("content")
contenteditable = attribute("contenteditable")
contextmenu = attribute("contextmenu")
coords = attribute("coords")
crossorigin = attribute("crossorigin")
csp = attribute("csp")
datetime = attribute("datetime")
decoding = attribute("decoding")
dir = attribute("dir")
dirname = attribute("dirname")
download = attribute("download")
draggable = attribute("draggable")
enctype = attribute("enctype")
enterkeyhint = attribute("enterkeyhint")
for = attribute("for")
form = attribute("form")
formaction = attribute("formaction")
formenctype = attribute("formenctype")
formmethod = attribute("formmethod")
formtarget = attribute("formtarget")
headers = attribute("headers")
height = attribute("height")
hidden = attribute("hidden")
high = attribute("high")
href = attribute("href")
hreflang = attribute("hreflang")
http_equiv = attribute("http-equiv")
icon = attribute("icon")
id = attribute("id")
importance = attribute("importance")
inputmode = attribute("inputmode")
integrity = attribute("integrity")
intrinsicsize = attribute("intrinsicsize")
itemprop = attribute("itemprop")
itemtype = attribute("itemtype")
keytype = attribute("keytype")
kind = attribute("kind")
label = attribute("label")
lang = attribute("lang")
language = attribute("language")
list = attribute("list")
loading = attribute("loading")
low = attribute("low")
manifest = attribute("manifest")
max = attribute("max")
maxlength = attribute("maxlength")
media = attribute("media")
method = attribute("method")
min = attribute("min")
minlength = attribute("minlength")
name = attribute("name")
oncontextmenu = attribute("oncontextmenu")
optimum = attribute("optimum")
pattern = attribute("pattern")
ping = attribute("ping")
placeholder = attribute("placeholder")
poster = attribute("poster")
preload = attribute("preload")
property = attribute("property")
radiogroup = attribute("radiogroup")
referrerpolicy = attribute("referrerpolicy")
rel = attribute("rel")
role = attribute("role")
rows = attribute("rows")
rowspan = attribute("rowspan")
sandbox = attribute("sandbox")
scope = attribute("scope")
scoped = attribute("scoped")
shape = attribute("shape")
size = attribute("size")
sizes = attribute("sizes")
slot = attribute("slot")
span = attribute("span")
spellcheck = attribute("spellcheck")
src = attribute("src")
srcdoc = attribute("srcdoc")
srclang = attribute("srclang")
srcset = attribute("srcset")
start = attribute("start")
step = attribute("step")
summary = attribute("summary")
tabindex = attribute("tabindex")
target = attribute("target")
title = attribute("title")
translate = attribute("translate")
type = attribute("type")
usemap = attribute("usemap")
value = attribute("value")
width = attribute("width")
wrap = attribute("wrap")
