## Attributes for HTML elements.
##
## Common attributes have helpers that take the value as a string, like
## `class("btn")`, `href("/about")` and `placeholder("Name")`. Boolean
## attributes take a `Bool` and only appear when true, like
## `disabled(Bool.True)` and `checked(is_done)`. Anything without a helper
## can be set with `attribute("data-foo", "bar")`, and `data`, `aria`,
## `classes`, `class_list` and `style` cover the usual dynamic cases.
##
## Event handlers are attributes too. They carry typed messages rather
## than handler strings: `on_click(msg)` sends `msg` to your update
## function when the element is clicked, and `on_input(|s| Typed(s))`
## builds the message from the input's current value. That second one
## takes a function and not a bare `Typed`, because Roc tag constructors
## are not functions. The most common handlers are also exposed from the
## `Event` module.
##
## Attribute values are escaped when rendered and attribute names are
## sanitized, so a dynamic string cannot break out of its attribute.

Attribute(msg) := [
	Boolean(Str, Bool),
	String(Str, Str),

	## decoder of the `FileInfo` record, fired when a file input's selection
	## changes. See `on_file`.
	FileHandler(Box(FileInfo -> Box(msg))),

	## Child identity for list reconciliation. See `key`.
	Key(Str),

	## event name, key filter (empty matches all), prevent_default,
	## stop_propagation, decoder of the `KeyEvent` record. See `on_keydown`.
	KeyHandler(Str, List(Str), Bool, Bool, Box(KeyEvent -> Box(msg))),

	## event name, prevent_default, stop_propagation, msg
	MsgHandler(Str, Bool, Bool, Box(msg)),

	## event name, prevent_default, stop_propagation, decoder of the
	## `PointerEvent` record. See `on_pointer_down`.
	PointerHandler(Str, Bool, Bool, Box(PointerEvent -> Box(msg))),

	## event name, DOM property to read off the event target, prevent_default,
	## stop_propagation, decoder of the property's stringified value. See
	## `on_property`.
	PropertyHandler(Str, Str, Bool, Bool, Box(Str -> Box(msg))),

	## root_margin, rearm_key, msg. See `on_visible`.
	VisibilityHandler(Str, Str, Box(msg)),
].{

	## The pointer event record delivered to `on_pointer` handlers. Annotate
	## handlers as `Attribute.PointerEvent`. `client_x`/`client_y` are
	## viewport coordinates, `page_x`/`page_y` include scroll, and
	## `offset_x`/`offset_y` are relative to the target element's padding
	## box. `button` is the button that caused a press (0 left/touch, 1
	## middle, 2 right). `buttons` is the bitmask of buttons currently held
	## (1 left, 2 right, 4 middle), which is what move handlers usually want
	## (`e.buttons != 0` = dragging). The four modifier flags say whether
	## that modifier was held when the event fired.
	PointerEvent : {
		client_x : F64,
		client_y : F64,
		page_x : F64,
		page_y : F64,
		offset_x : F64,
		offset_y : F64,
		button : U8,
		buttons : U8,
		ctrl : Bool,
		shift : Bool,
		alt : Bool,
		meta : Bool,
	}

	## The keyboard event record delivered to `on_key` handlers. Annotate
	## handlers as `Attribute.KeyEvent`. `key` is the character the keypress
	## produced ("a", "A") or the name of a non-printing key ("Enter",
	## "Escape", "ArrowLeft"), and is affected by the keyboard layout and by
	## Shift. `code` is the physical key's location ("KeyA", "Enter"), which
	## is the one to match on for WASD-style controls. `repeat` is true while
	## a held key auto-repeats, and `is_composing` is true mid-IME
	## composition, when a keystroke is being combined into a character and
	## should usually be ignored.
	KeyEvent : {
		key : Str,
		code : Str,
		ctrl : Bool,
		shift : Bool,
		alt : Bool,
		meta : Bool,
		repeat : Bool,
		is_composing : Bool,
	}

	## The record delivered by `on_file` when the user picks a file. `id` is
	## an opaque handle to the browser-held File object. `size` is in bytes
	## and `mime` is the browser-reported content type ("" when unknown).
	FileInfo : {
		id : U32,
		name : Str,
		mime : Str,
		size : U64,
	}

	## Re-target an attribute to a parent message type by passing every
	## message its handler produces through `f`. This is the plumbing under
	## `Html.map`, apps rarely call it directly.
	map : Attribute(a), (a -> b) -> Attribute(b)
	map = |attr, f|
		match attr {
			Boolean(name_, val) => Boolean(name_, val)
			Key(val) => Key(val)
			String(name_, val) => String(name_, val)
			MsgHandler(name_, pd, sp, msg) => MsgHandler(name_, pd, sp, Box.box(f(Box.unbox(msg))))
			PropertyHandler(name_, prop, pd, sp, cb) =>
				PropertyHandler(
					name_,
					prop,
					pd,
					sp,
					Box.box(
						|s| {
							inner = Box.unbox(cb)
							Box.box(f(Box.unbox(inner(s))))
						},
					),
				)
			KeyHandler(name_, keys, pd, sp, cb) =>
				KeyHandler(
					name_,
					keys,
					pd,
					sp,
					Box.box(
						|e| {
							inner = Box.unbox(cb)
							Box.box(f(Box.unbox(inner(e))))
						},
					),
				)
			PointerHandler(name_, pd, sp, cb) =>
				PointerHandler(
					name_,
					pd,
					sp,
					Box.box(
						|e| {
							inner = Box.unbox(cb)
							Box.box(f(Box.unbox(inner(e))))
						},
					),
				)
			FileHandler(cb) =>
				FileHandler(
					Box.box(
						|info| {
							inner = Box.unbox(cb)
							Box.box(f(Box.unbox(inner(info))))
						},
					),
				)
			VisibilityHandler(margin, rearm, msg) => VisibilityHandler(margin, rearm, Box.box(f(Box.unbox(msg))))
		}

	## SSR text for one attribute, used by `Html.render`. String attributes
	## render as `key="escaped value"` with `&` and `"` entity-escaped.
	## Boolean attributes render as the bare key when true and disappear
	## when false (HTML boolean attribute semantics). Everything else
	## (events, keys, visibility observers) is a client-side concern and
	## renders as "", which the caller drops.
	to_ssr_str : Attribute(msg) -> Str
	to_ssr_str = |attr|
		match attr {
			String(key_, val) => "${key_}=\"${escape_attr_value(val)}\""
			Boolean(key_, val) => if val {
				key_
			} else {
				""
			}
			_ => ""
		}

	## Stop the event at this element instead of letting it bubble on to
	## ancestor handlers: `on_click(Ignored).stop_propagation()`. This is
	## what keeps a click inside a modal from reaching a backdrop that
	## closes it. No effect on attributes that are not event handlers, and
	## SSR ignores it like every other handler concern.
	stop_propagation : Attribute(msg) -> Attribute(msg)
	stop_propagation = |attr|
		match attr {
			MsgHandler(name_, pd, _sp, msg) => MsgHandler(name_, pd, Bool.True, msg)
			PropertyHandler(name_, prop, pd, _sp, cb) => PropertyHandler(name_, prop, pd, Bool.True, cb)
			KeyHandler(name_, keys, pd, _sp, cb) => KeyHandler(name_, keys, pd, Bool.True, cb)
			PointerHandler(name_, pd, _sp, cb) => PointerHandler(name_, pd, Bool.True, cb)
			other => other
		}

	## Suppress the browser's default action for this event:
	## `on_click(Navigate).prevent_default()` on a link keeps the browser
	## from following its href. On a key handler with a key filter the
	## default is only suppressed for the listed keys. No effect on
	## attributes that are not event handlers, and SSR ignores it.
	prevent_default : Attribute(msg) -> Attribute(msg)
	prevent_default = |attr|
		match attr {
			MsgHandler(name_, _pd, sp, msg) => MsgHandler(name_, Bool.True, sp, msg)
			PropertyHandler(name_, prop, _pd, sp, cb) => PropertyHandler(name_, prop, Bool.True, sp, cb)
			KeyHandler(name_, keys, _pd, sp, cb) => KeyHandler(name_, keys, Bool.True, sp, cb)
			PointerHandler(name_, _pd, sp, cb) => PointerHandler(name_, Bool.True, sp, cb)
			other => other
		}

	## Whether this attribute stops the event at its element, the flag the
	## client runtime reads to decide on a stopPropagation call. False for
	## everything that is not an event handler carrying the flag, including
	## every non-event attribute. SSR ignores it (see `to_ssr_str`).
	##
	## Exposed because the variants themselves are private to this module, so
	## this is the only way a renderer or a facade like `Event` can see the
	## flag. Without it a delegating wrapper can drop the flag and no test
	## outside this file can tell.
	stops_propagation : Attribute(msg) -> Bool
	stops_propagation = |attr|
		match attr {
			MsgHandler(_name, _pd, sp, _msg) => sp
			PropertyHandler(_name, _prop, _pd, sp, _cb) => sp
			KeyHandler(_name, _keys, _pd, sp, _cb) => sp
			PointerHandler(_name, _pd, sp, _cb) => sp
			_ => Bool.False
		}

	## Whether this attribute suppresses the browser default for its event,
	## the flag the client runtime reads to decide on a preventDefault call.
	## Exposed for the same reason as `stops_propagation`.
	prevents_default : Attribute(msg) -> Bool
	prevents_default = |attr|
		match attr {
			MsgHandler(_name, pd, _sp, _msg) => pd
			PropertyHandler(_name, _prop, pd, _sp, _cb) => pd
			KeyHandler(_name, _keys, pd, _sp, _cb) => pd
			PointerHandler(_name, pd, _sp, _cb) => pd
			_ => Bool.False
		}

	## Strip every character that is not an ASCII letter, digit, `-`, `_`,
	## `.` or `:` from an HTML tag or attribute name. Names come in as plain
	## strings via `Html.element` and `attribute`/`data`/`aria`, and no
	## quoting can make a bad character safe in name position. A space or
	## `>` in a key breaks out of the tag no matter how the value is
	## escaped, so the only safe rewrite is removal. Sanitizing here, where
	## the string enters the tree, covers both SSR and client rendering.
	sanitize_name : Str -> Str
	sanitize_name = |raw|
		match Str.from_utf8(keep_name_bytes(Str.to_utf8(raw), 0, [])) {
			Ok(sanitized) => sanitized
			# Unreachable since the kept bytes are all ASCII.
			Err(_) => ""
		}

	## An arbitrary string attribute, e.g. `attribute("data-id", "42")`.
	## The key is sanitized (see `sanitize_name`).
	attribute : Str, Str -> Attribute(msg)
	attribute = |name_, val| String(Attribute.sanitize_name(name_), val)

	## An arbitrary boolean attribute, e.g. `boolean("hidden", Bool.True)`.
	## Rendered as present/absent (HTML boolean attribute semantics).
	boolean : Str, Bool -> Attribute(msg)
	boolean = |name_, val| Boolean(name_, val)

	## A stable identity for a child in a list. When siblings carry keys, the
	## client differ matches them by key across renders, so inserting,
	## removing or reordering items moves the existing DOM nodes instead of
	## rewriting every position. Keys must be unique among siblings. Never
	## rendered, in SSR or DOM.
	key : Str -> Attribute(msg)
	key = |val| Key(val)

	## Inline styles: `style([("display", "flex"), ("padding", "20px")])`.
	style : List((Str, Str)) -> Attribute(msg)
	style = |props| String("style", style_str(props, 0, ""))

	## A class attribute from a list of names, joined with spaces.
	classes : List(Str) -> Attribute(msg)
	classes = |cs| String("class", Str.join_with(cs, " "))

	## A class attribute from (name, active) pairs, keeping only the active
	## names: `class_list([("btn", Bool.True), ("hidden", is_hidden)])`.
	class_list : List((Str, Bool)) -> Attribute(msg)
	class_list = |cs| String("class", class_list_str(cs, 0, ""))

	## A `data-*` attribute: `data("id", "42")` is `data-id="42"`. The name
	## is sanitized (see `sanitize_name`).
	data : Str, Str -> Attribute(msg)
	data = |data_name, data_value| String("data-${Attribute.sanitize_name(data_name)}", data_value)

	## An `aria-*` attribute: `aria("label", "Close")` is `aria-label="Close"`.
	## The name is sanitized (see `sanitize_name`).
	aria : Str, Str -> Attribute(msg)
	aria = |aria_name, aria_value| String("aria-${Attribute.sanitize_name(aria_name)}", aria_value)

	class : Str -> Attribute(msg)
	class = |val| String("class", val)

	id : Str -> Attribute(msg)
	id = |val| String("id", val)

	value : Str -> Attribute(msg)
	value = |val| String("value", val)

	placeholder : Str -> Attribute(msg)
	placeholder = |val| String("placeholder", val)

	name : Str -> Attribute(msg)
	name = |val| String("name", val)

	href : Str -> Attribute(msg)
	href = |val| String("href", val)

	src : Str -> Attribute(msg)
	src = |val| String("src", val)

	alt : Str -> Attribute(msg)
	alt = |val| String("alt", val)

	## The `for` attribute on labels. Named `for_` because `for` is a Roc keyword.
	for_ : Str -> Attribute(msg)
	for_ = |val| String("for", val)

	## The `type` attribute, as on `input([type("checkbox")])`.
	type : Str -> Attribute(msg)
	type = |val| String("type", val)

	## The document language, as `html([lang("en")])`. Set it on the `html`
	## element: screen readers and hyphenation depend on it.
	lang : Str -> Attribute(msg)
	lang = |val| String("lang", val)

	accept : Str -> Attribute(msg)
	accept = |val| String("accept", val)

	## Renders as `accept-charset`, the character encodings a form accepts.
	accept_charset : Str -> Attribute(msg)
	accept_charset = |val| String("accept-charset", val)

	action : Str -> Attribute(msg)
	action = |val| String("action", val)

	## Whether a touch keyboard capitalizes automatically: "none",
	## "sentences", "words" or "characters".
	autocapitalize : Str -> Attribute(msg)
	autocapitalize = |val| String("autocapitalize", val)

	autocomplete : Str -> Attribute(msg)
	autocomplete = |val| String("autocomplete", val)

	content : Str -> Attribute(msg)
	content = |val| String("content", val)

	## CORS mode for a fetched subresource: "anonymous" or
	## "use-credentials". Needed on `script` and `img` when you want error
	## details or canvas access for a cross-origin file.
	crossorigin : Str -> Attribute(msg)
	crossorigin = |val| String("crossorigin", val)

	datetime : Str -> Attribute(msg)
	datetime = |val| String("datetime", val)

	## Image decoding hint: "sync", "async" or "auto".
	decoding : Str -> Attribute(msg)
	decoding = |val| String("decoding", val)

	## Turns a link into a download rather than a navigation. The value is
	## the suggested filename, and `download("")` keeps the server's.
	download : Str -> Attribute(msg)
	download = |val| String("download", val)

	## Renders as `http-equiv`, for `meta` directives.
	http_equiv : Str -> Attribute(msg)
	http_equiv = |val| String("http-equiv", val)

	## Which touch keyboard to show: "numeric", "decimal", "tel", "email",
	## "url", "search" or "text". A hint only, it does not validate.
	inputmode : Str -> Attribute(msg)
	inputmode = |val| String("inputmode", val)

	## Microdata property name, paired with `itemscope` and `itemtype`.
	itemprop : Str -> Attribute(msg)
	itemprop = |val| String("itemprop", val)

	## Microdata vocabulary URL, e.g. "https://schema.org/Person".
	itemtype : Str -> Attribute(msg)
	itemtype = |val| String("itemtype", val)

	## Deferred loading for `img` and `iframe`: "lazy" or "eager".
	loading : Str -> Attribute(msg)
	loading = |val| String("loading", val)

	## The upper bound of an input's range. A `Str` and not a number because
	## the bound follows the input's type: "10" and "1.5" for `number`, but
	## "2026-12-31" for `date` and "23:59" for `time`. See also `min`.
	max : Str -> Attribute(msg)
	max = |val| String("max", val)

	media : Str -> Attribute(msg)
	media = |val| String("media", val)

	method : Str -> Attribute(msg)
	method = |val| String("method", val)

	## The lower bound of an input's range. A `Str` for the same reason as
	## `max`.
	min : Str -> Attribute(msg)
	min = |val| String("min", val)

	pattern : Str -> Attribute(msg)
	pattern = |val| String("pattern", val)

	## Open Graph and RDFa property name, as on `meta`. Unrelated to DOM
	## properties, which `on_property` reads.
	property : Str -> Attribute(msg)
	property = |val| String("property", val)

	rel : Str -> Attribute(msg)
	rel = |val| String("rel", val)

	role : Str -> Attribute(msg)
	role = |val| String("role", val)

	sizes : Str -> Attribute(msg)
	sizes = |val| String("sizes", val)

	srcset : Str -> Attribute(msg)
	srcset = |val| String("srcset", val)

	## The granularity an input's value must fall on. A `Str` because it
	## takes "any" as well as numbers, and because the unit follows the
	## input's type as it does for `min` and `max`.
	step : Str -> Attribute(msg)
	step = |val| String("step", val)

	target : Str -> Attribute(msg)
	target = |val| String("target", val)

	## The `title` attribute, which browsers show as a tooltip. For the
	## page title use the `Html.title` element instead.
	title : Str -> Attribute(msg)
	title = |val| String("title", val)

	# Numeric attributes. Roc has no default integer type, so these fix one:
	# `U64` for counts, which is what `List.len` returns, so
	# `colspan(cells.len())` needs no conversion. HTML has no numeric syntax
	# of its own, and these render as the decimal text of the number.

	## Visible width of a `textarea`, in characters.
	cols : U64 -> Attribute(msg)
	cols = |val| String("cols", val.to_str())

	## Visible height of a `textarea`, in lines.
	rows : U64 -> Attribute(msg)
	rows = |val| String("rows", val.to_str())

	## How many columns a table cell spans.
	colspan : U64 -> Attribute(msg)
	colspan = |val| String("colspan", val.to_str())

	## How many rows a table cell spans.
	rowspan : U64 -> Attribute(msg)
	rowspan = |val| String("rowspan", val.to_str())

	## Longest accepted input, in characters.
	maxlength : U64 -> Attribute(msg)
	maxlength = |val| String("maxlength", val.to_str())

	## Intrinsic width in pixels, for `img`, `video` and `canvas`. Setting it
	## with `height` reserves the right space before the image loads. For a
	## percentage or any other CSS length use `style` instead.
	width : U64 -> Attribute(msg)
	width = |val| String("width", val.to_str())

	## Intrinsic height in pixels. See `width`.
	height : U64 -> Attribute(msg)
	height = |val| String("height", val.to_str())

	## Keyboard navigation order. Signed because the useful values include
	## `-1`, which makes an element focusable by script or click but skips it
	## in the tab order. `0` puts it in document order. Positive values jump
	## the queue and are best avoided.
	tabindex : I32 -> Attribute(msg)
	tabindex = |val| String("tabindex", val.to_str())

	# Boolean attributes. HTML has no `disabled="false"`: the attribute is
	# either present or absent, so these render as the bare name when true
	# and disappear entirely when false.

	allowfullscreen : Bool -> Attribute(msg)
	allowfullscreen = |val| Boolean("allowfullscreen", val)

	## Focus this element when the page loads. At most one per document.
	autofocus : Bool -> Attribute(msg)
	autofocus = |val| Boolean("autofocus", val)

	autoplay : Bool -> Attribute(msg)
	autoplay = |val| Boolean("autoplay", val)

	## Whether a checkbox or radio starts checked. Read the live state back
	## with `on_check`.
	checked : Bool -> Attribute(msg)
	checked = |val| Boolean("checked", val)

	## Show the browser's built-in play and volume controls on `video`.
	controls : Bool -> Attribute(msg)
	controls = |val| Boolean("controls", val)

	defer : Bool -> Attribute(msg)
	defer = |val| Boolean("defer", val)

	disabled : Bool -> Attribute(msg)
	disabled = |val| Boolean("disabled", val)

	## Hide the element from rendering and from assistive technology. CSS
	## `display` overrides it, so prefer `class_list` when you style it
	## anyway.
	hidden : Bool -> Attribute(msg)
	hidden = |val| Boolean("hidden", val)

	## Start a microdata item, scoping the `itemprop`s inside it.
	itemscope : Bool -> Attribute(msg)
	itemscope = |val| Boolean("itemscope", val)

	## Accept more than one value, on `select` and on `input([type("file")])`.
	multiple : Bool -> Attribute(msg)
	multiple = |val| Boolean("multiple", val)

	muted : Bool -> Attribute(msg)
	muted = |val| Boolean("muted", val)

	## Skip the browser's own form validation on submit, leaving it to your
	## update function.
	novalidate : Bool -> Attribute(msg)
	novalidate = |val| Boolean("novalidate", val)

	## Whether a `details` element starts expanded.
	open : Bool -> Attribute(msg)
	open = |val| Boolean("open", val)

	readonly : Bool -> Attribute(msg)
	readonly = |val| Boolean("readonly", val)

	required : Bool -> Attribute(msg)
	required = |val| Boolean("required", val)

	## Which `option` a `select` starts on. Without it a rendered dropdown
	## always opens on its first entry.
	selected : Bool -> Attribute(msg)
	selected = |val| Boolean("selected", val)

	## Send `msg` when the named DOM event fires: `on("mousedown", Grab)`.
	## Never rendered in SSR.
	on : Str, msg -> Attribute(msg)
	on = |event_name, msg| MsgHandler(event_name, Bool.False, Bool.False, Box.box(msg))

	## Send `msg` when the element is clicked, by mouse, touch or by keyboard
	## activation on a focusable element.
	on_click : msg -> Attribute(msg)
	on_click = |msg| MsgHandler("click", Bool.False, Bool.False, Box.box(msg))

	## Send `msg` when a form submits, suppressing the browser's default
	## (which would reload the page and lose the model). Put it on the
	## `form` element and submission by Enter or a submit button both fire.
	on_submit : msg -> Attribute(msg)
	on_submit = |msg| MsgHandler("submit", Bool.True, Bool.False, Box.box(msg))

	## Send the message produced from reading the named DOM property off the
	## event target when the named event fires:
	## `on_property("change", "checked", |s| Toggled(s == "true"))`.
	## The client runtime stringifies the property before calling the decoder,
	## so booleans arrive as "true"/"false" and numbers as their decimal text.
	## A property that is missing, null, or NaN on the target reads as "".
	on_property : Str, Str, (Str -> msg) -> Attribute(msg)
	on_property = |event_name, property_name, to_msg|
		PropertyHandler(event_name, property_name, Bool.False, Bool.False, Box.box(|s| Box.box(to_msg(s))))

	## Send the message produced from the event target's `value` when the named
	## event fires: `on_value("input", |s| UserTyped(s))`.
	on_value : Str, (Str -> msg) -> Attribute(msg)
	on_value = |event_name, to_msg| Attribute.on_property(event_name, "value", to_msg)

	## Send the message built from the control's `value` on every keystroke,
	## as `on_input(|s| NameTyped(s))`. For a value read only once the edit
	## is committed, use `on_change`.
	on_input : (Str -> msg) -> Attribute(msg)
	on_input = |to_msg| Attribute.on_property("input", "value", to_msg)

	## Send the message produced from the control's `value` when it commits a
	## change. Reads `value` for every element type, so one handler on a radio
	## group receives the selected radio's value. For a checkbox's on/off
	## state use `on_check`.
	on_change : (Str -> msg) -> Attribute(msg)
	on_change = |to_msg| Attribute.on_property("change", "value", to_msg)

	## Send the message produced from a checkbox's checked state when it
	## changes: `on_check(|now| UserToggled(now))`. Don't combine with
	## `on_change` on the same element: both bind the change event, and the
	## runtime keeps one handler per event, so the last one wins.
	on_check : (Bool -> msg) -> Attribute(msg)
	on_check = |to_msg| Attribute.on_property("change", "checked", |s| to_msg(s == "true"))

	## Send the message produced from the `KeyEvent` record (key, physical
	## code, modifiers, repeat) when a keyboard event fires on this element:
	## `on_key("keydown", ["Enter"], |_| UserSubmitted)`. An empty key list
	## matches every key. A non-empty one fires (and, with
	## `.prevent_default()`, suppresses the browser default) only when the
	## event's `key` is listed. The match is case-sensitive.
	on_key : Str, List(Str), (KeyEvent -> msg) -> Attribute(msg)
	on_key = |event_name, keys, to_msg|
		KeyHandler(event_name, keys, Bool.False, Bool.False, Box.box(|e| Box.box(to_msg(e))))

	## Every key pressed down on this element, browser defaults left intact.
	## Chain `.prevent_default()` to suppress them, but note that on an
	## unfiltered handler that includes Tab and the browser's own shortcuts,
	## so prefer a key filter: `on_key("keydown", ["Enter"], to_msg)
	## .prevent_default()` suppresses the default for exactly those keys.
	on_keydown : (KeyEvent -> msg) -> Attribute(msg)
	on_keydown = |to_msg| Attribute.on_key("keydown", [], to_msg)

	## Every key released on this element. Unlike keydown it does not repeat
	## while a key is held.
	on_keyup : (KeyEvent -> msg) -> Attribute(msg)
	on_keyup = |to_msg| Attribute.on_key("keyup", [], to_msg)

	## Send the message produced from the `PointerEvent` record (coordinates,
	## buttons, modifiers) when the named pointer event fires on this element.
	## Pointer events unify mouse, touch and pen input. Chain
	## `.prevent_default()` to suppress the browser default (text selection
	## while dragging, touch scrolling).
	on_pointer : Str, (PointerEvent -> msg) -> Attribute(msg)
	on_pointer = |event_name, to_msg|
		PointerHandler(event_name, Bool.False, Bool.False, Box.box(|e| Box.box(to_msg(e))))

	## A mouse button, finger or pen made contact. The start of a drag.
	on_pointer_down : (PointerEvent -> msg) -> Attribute(msg)
	on_pointer_down = |to_msg| Attribute.on_pointer("pointerdown", to_msg)

	## The pointer moved over this element. Fires whether or not a button is
	## held, so drag handlers should check `e.buttons != 0` first.
	on_pointer_move : (PointerEvent -> msg) -> Attribute(msg)
	on_pointer_move = |to_msg| Attribute.on_pointer("pointermove", to_msg)

	## Contact ended over this element. A drag can also end outside it, so
	## pair this with `on_pointer_leave` and `on_pointer_cancel`.
	on_pointer_up : (PointerEvent -> msg) -> Attribute(msg)
	on_pointer_up = |to_msg| Attribute.on_pointer("pointerup", to_msg)

	## The pointer left the element (or was lifted, on touch). Dragging code
	## should usually handle this like `on_pointer_up`.
	on_pointer_leave : (PointerEvent -> msg) -> Attribute(msg)
	on_pointer_leave = |to_msg| Attribute.on_pointer("pointerleave", to_msg)

	## The pointer entered the element. Unlike a bubbling hover event this
	## does not fire again as the pointer crosses into a child.
	on_pointer_enter : (PointerEvent -> msg) -> Attribute(msg)
	on_pointer_enter = |to_msg| Attribute.on_pointer("pointerenter", to_msg)

	## The browser canceled the pointer stream (e.g. it decided a touch was a
	## scroll). Treat like `on_pointer_up`.
	on_pointer_cancel : (PointerEvent -> msg) -> Attribute(msg)
	on_pointer_cancel = |to_msg| Attribute.on_pointer("pointercancel", to_msg)

	## Send the message produced from the `FileInfo` record when the user
	## picks a file in this `<input type="file">`:
	## `input([type("file"), on_file(|f| UserPickedFile(f))])`.
	on_file : (FileInfo -> msg) -> Attribute(msg)
	on_file = |to_msg| FileHandler(Box.box(|info| Box.box(to_msg(info))))

	## Send `msg` when this element scrolls into view. The client runtime
	## attaches an IntersectionObserver whose lifetime it ties to the
	## element. Never rendered in SSR.
	##
	## `root_margin` grows the viewport for the check, so "200px" fires the
	## msg 200px before the element actually becomes visible.
	##
	## An observer only fires when the element crosses into view. If the
	## element stays on screen after a re-render it would never fire again,
	## which stalls patterns like infinite scroll. Give `rearm_key` a value
	## that changes when you want visibility re-checked (say, the number of
	## items shown) and the runtime re-arms the observer whenever the key
	## changes. Keep it constant to fire once per crossing.
	on_visible : msg, { root_margin : Str, rearm_key : Str } -> Attribute(msg)
	on_visible = |msg, opts| VisibilityHandler(opts.root_margin, opts.rearm_key, Box.box(msg))
}

## Escape an attribute value for SSR inside double quotes. Only `&` and `"`
## need rewriting there. There is no Str.replace_each to call, so replacement
## is split_on plus join_with, `&` first so the ampersands it introduces are
## not escaped again.
escape_attr_value : Str -> Str
escape_attr_value = |v|
	Str.join_with(Str.split_on(Str.join_with(Str.split_on(v, "&"), "&amp;"), "\""), "&quot;")

## Recursive byte filter under `sanitize_name`. Written as recursion rather
## than List.keep_if because a helper containing a loop or fold trips a
## compiler OOM at build time when it is reached from a match branch.
keep_name_bytes : List(U8), U64, List(U8) -> List(U8)
keep_name_bytes = |bytes, idx, acc|
	match bytes.get(idx) {
		Ok(b) =>
			if is_name_byte(b) {
				keep_name_bytes(bytes, idx + 1, acc.append(b))
			} else {
				keep_name_bytes(bytes, idx + 1, acc)
			}
		Err(_) => acc
	}

## The bytes `sanitize_name` keeps: ASCII letters, digits, `-`, `_`, `.`, `:`.
is_name_byte : U8 -> Bool
is_name_byte = |byte|
	(byte >= 'a' and byte <= 'z')
		or (byte >= 'A' and byte <= 'Z')
			or (byte >= '0' and byte <= '9')
				or (byte == '-')
					or (byte == '_')
						or (byte == '.')
							or (byte == ':')

## Recursive builder for `style`: "k1: v1; k2: v2".
style_str : List((Str, Str)), U64, Str -> Str
style_str = |props, idx, acc|
	match props.get(idx) {
		Ok(prop) => {
			part = "${prop.0}: ${prop.1}"
			joined = if Str.is_empty(acc) {
				part
			} else {
				"${acc}; ${part}"
			}
			style_str(props, idx + 1, joined)
		}
		Err(_) => acc
	}

## Recursive builder for `class_list`: active names joined with spaces.
class_list_str : List((Str, Bool)), U64, Str -> Str
class_list_str = |cs, idx, acc|
	match cs.get(idx) {
		Ok(pair) => {
			joined =
				if pair.1 {
					if Str.is_empty(acc) {
						pair.0
					} else {
						"${acc} ${pair.0}"
					}
				} else {
					acc
				}
			class_list_str(cs, idx + 1, joined)
		}
		Err(_) => acc
	}

# --- roc test (run via `roc test --main=package/main.roc package/Attribute.roc`) ---
# Note: no `==` on whole Attribute values in these tests. They can hold boxed
# functions, which have no equality.

expect {
	match Attribute.style([("display", "flex"), ("padding", "20px")]) {
		String(name_, css) => name_ == "style" and css == "display: flex; padding: 20px"
		_ => Bool.False
	}
}

expect {
	match Attribute.style([]) {
		String(name_, css) => name_ == "style" and css == ""
		_ => Bool.False
	}
}

expect {
	match Attribute.classes(["btn", "btn-primary"]) {
		String(name_, val) => name_ == "class" and val == "btn btn-primary"
		_ => Bool.False
	}
}

expect {
	match Attribute.class_list([("btn", Bool.True), ("hidden", Bool.False), ("active", Bool.True)]) {
		String(name_, val) => name_ == "class" and val == "btn active"
		_ => Bool.False
	}
}

# data/aria/attribute keys are sanitized at construction, so a hostile key
# cannot smuggle in an event handler.
expect {
	match Attribute.data("x\" y", "v") {
		String(name_, val) => name_ == "data-xy" and val == "v"
		_ => Bool.False
	}
}

expect {
	match Attribute.aria("label", "Close") {
		String(name_, val) => name_ == "aria-label" and val == "Close"
		_ => Bool.False
	}
}

expect {
	match Attribute.attribute("x\" onmouseover=\"alert(1)\" y", "v") {
		String(name_, val) => name_ == "xonmouseoveralert1y" and val == "v"
		_ => Bool.False
	}
}

# `type` is a plain identifier in Roc, so the attribute keeps the bare
# name. `for` is a keyword, so `for_` carries the trailing underscore.
expect {
	match Attribute.type("checkbox") {
		String(name_, val) => name_ == "type" and val == "checkbox"
		_ => Bool.False
	}
}

# Numeric attributes render as decimal text, including the negative
# tabindex that is the whole reason that one is signed.
expect Attribute.to_ssr_str(Attribute.rows(4)) == "rows=\"4\""
expect Attribute.to_ssr_str(Attribute.cols(80)) == "cols=\"80\""
expect Attribute.to_ssr_str(Attribute.colspan(3)) == "colspan=\"3\""
expect Attribute.to_ssr_str(Attribute.rowspan(2)) == "rowspan=\"2\""
expect Attribute.to_ssr_str(Attribute.maxlength(140)) == "maxlength=\"140\""
expect Attribute.to_ssr_str(Attribute.width(1920)) == "width=\"1920\""
expect Attribute.to_ssr_str(Attribute.height(0)) == "height=\"0\""
expect Attribute.to_ssr_str(Attribute.tabindex(-1)) == "tabindex=\"-1\""
expect Attribute.to_ssr_str(Attribute.tabindex(0)) == "tabindex=\"0\""

# A count taken straight from List.len needs no conversion, which is why
# the unsigned ones are U64.
expect Attribute.to_ssr_str(Attribute.colspan(["a", "b", "c"].len())) == "colspan=\"3\""

# The added boolean attributes follow present/absent semantics like the
# rest, and the added string ones render normally.
expect Attribute.to_ssr_str(Attribute.selected(Bool.True)) == "selected"
expect Attribute.to_ssr_str(Attribute.selected(Bool.False)) == ""
expect Attribute.to_ssr_str(Attribute.multiple(Bool.True)) == "multiple"
expect Attribute.to_ssr_str(Attribute.open(Bool.True)) == "open"
expect Attribute.to_ssr_str(Attribute.hidden(Bool.True)) == "hidden"
expect Attribute.to_ssr_str(Attribute.controls(Bool.True)) == "controls"
expect Attribute.to_ssr_str(Attribute.autoplay(Bool.False)) == ""
expect Attribute.to_ssr_str(Attribute.novalidate(Bool.True)) == "novalidate"
expect Attribute.to_ssr_str(Attribute.lang("en")) == "lang=\"en\""
expect Attribute.to_ssr_str(Attribute.download("")) == "download=\"\""
expect Attribute.to_ssr_str(Attribute.download("report.pdf")) == "download=\"report.pdf\""

expect Attribute.sanitize_name("data-foo") == "data-foo"
expect Attribute.sanitize_name("hx-on:click") == "hx-on:click"
expect Attribute.sanitize_name("x\" onmouseover=\"alert(1)\" y") == "xonmouseoveralert1y"

# SSR text: strings render escaped in double quotes, true booleans render as
# the bare key, false booleans and events render as "".
expect Attribute.to_ssr_str(Attribute.href("/?a=1&b=\"2\"")) == "href=\"/?a=1&amp;b=&quot;2&quot;\""
expect Attribute.to_ssr_str(Attribute.checked(Bool.True)) == "checked"
expect Attribute.to_ssr_str(Attribute.checked(Bool.False)) == ""
expect Attribute.to_ssr_str(Attribute.on_click("clicked")) == ""
expect Attribute.to_ssr_str(Attribute.on_input(|s| "typed:${s}")) == ""
expect Attribute.to_ssr_str(Attribute.key("row-7")) == ""
expect Attribute.to_ssr_str(Attribute.on_visible("seen", { root_margin: "200px", rearm_key: "k1" })) == ""

# on_check reads the `checked` property and decodes the stringified boolean.
# Anything but "true" is False.
expect {
	match Attribute.on_check(|b| if b "on" else "off") {
		PropertyHandler(event, prop, _pd, _sp, cb) => {
			inner = Box.unbox(cb)
			event == "change"
				and prop == "checked"
					and Box.unbox(inner("true")) == "on"
						and Box.unbox(inner("false")) == "off"
							and Box.unbox(inner("")) == "off"
		}
		_ => Bool.False
	}
}

# on_change reads `value` uniformly, with on_property as the primitive
# underneath it.
expect {
	match Attribute.on_change(|s| "chose:${s}") {
		PropertyHandler(event, prop, _pd, _sp, cb) => {
			inner = Box.unbox(cb)
			event == "change" and prop == "value" and Box.unbox(inner("red")) == "chose:red"
		}
		_ => Bool.False
	}
}

expect {
	match Attribute.on_property("input", "valueAsNumber", |s| "n:${s}") {
		PropertyHandler(event, prop, _pd, _sp, cb) => {
			inner = Box.unbox(cb)
			event == "input" and prop == "valueAsNumber" and Box.unbox(inner("42")) == "n:42"
		}
		_ => Bool.False
	}
}

# `map` is Box plumbing, and a mistake there (wrong unbox depth, a dropped
# wrap) is invisible to SSR because events are never rendered. Pin it by
# firing the mapped handlers directly and checking what they produce.

expect {
	match Attribute.on_click("clicked").map(|s| "outer:${s}") {
		MsgHandler(event, pd, _sp, boxed) =>
			event == "click" and pd == Bool.False and Box.unbox(boxed) == "outer:clicked"
		_ => Bool.False
	}
}

expect {
	match Attribute.on_input(|s| "typed:${s}").map(|s| "outer:${s}") {
		PropertyHandler(event, prop, _pd, _sp, cb) => {
			inner = Box.unbox(cb)
			event == "input" and prop == "value" and Box.unbox(inner("abc")) == "outer:typed:abc"
		}
		_ => Bool.False
	}
}

# map leaves plain data attributes untouched.
expect {
	match Attribute.class("btn").map(|s| "outer:${s}") {
		String(name_, val) => name_ == "class" and val == "btn"
		_ => Bool.False
	}
}

# --- stop_propagation / prevent_default modifiers ---
# Whether an event keeps bubbling or triggers the browser default is decided
# by the client runtime, so SSR shows nothing either way (pinned at the bottom
# of this block). What these tests pin is the flags where they actually live,
# on the constructed attribute, since a modifier that silently drops one is
# exactly the bug this replaced.

# The plain handlers let the event bubble and leave the default intact.
expect {
	match Attribute.on_click("clicked") {
		MsgHandler(event, pd, sp, _boxed) => event == "click" and pd == Bool.False and sp == Bool.False
		_ => Bool.False
	}
}

expect {
	match Attribute.on_input(|s| "typed:${s}") {
		PropertyHandler(event, prop, pd, sp, _cb) =>
			event == "input" and prop == "value" and pd == Bool.False and sp == Bool.False
		_ => Bool.False
	}
}

# on_submit suppresses the browser default but still bubbles: the two flags
# are independent, and a transposed pair here would swap them.
expect {
	match Attribute.on_submit("submitted") {
		MsgHandler(event, pd, sp, _boxed) => event == "submit" and pd == Bool.True and sp == Bool.False
		_ => Bool.False
	}
}

# Each modifier flips its own flag and leaves the other, and the message,
# untouched.
expect {
	match Attribute.on_click("clicked").stop_propagation() {
		MsgHandler(event, pd, sp, boxed) =>
			event == "click" and pd == Bool.False and sp == Bool.True and Box.unbox(boxed) == "clicked"
		_ => Bool.False
	}
}

expect {
	match Attribute.on_click("clicked").prevent_default() {
		MsgHandler(event, pd, sp, boxed) =>
			event == "click" and pd == Bool.True and sp == Bool.False and Box.unbox(boxed) == "clicked"
		_ => Bool.False
	}
}

# The modifiers chain, and order does not matter.
expect {
	match Attribute.on("mousedown", "grabbed").prevent_default().stop_propagation() {
		MsgHandler(event, pd, sp, boxed) =>
			event == "mousedown" and pd == Bool.True and sp == Bool.True and Box.unbox(boxed) == "grabbed"
		_ => Bool.False
	}
}

expect {
	match Attribute.on_input(|s| "typed:${s}").stop_propagation() {
		PropertyHandler(event, prop, pd, sp, cb) => {
			inner = Box.unbox(cb)
			event == "input"
				and prop == "value"
					and pd == Bool.False
						and sp == Bool.True
							and Box.unbox(inner("abc")) == "typed:abc"
		}
		_ => Bool.False
	}
}

expect {
	match Attribute.on_key("keydown", ["Enter"], |e| "key:${e.key}").prevent_default() {
		KeyHandler(event, keys, pd, sp, _cb) =>
			event == "keydown" and keys == ["Enter"] and pd == Bool.True and sp == Bool.False
		_ => Bool.False
	}
}

expect {
	match Attribute.on_pointer_down(|_| "pressed").stop_propagation().prevent_default() {
		PointerHandler(event, pd, sp, _cb) =>
			event == "pointerdown" and pd == Bool.True and sp == Bool.True
		_ => Bool.False
	}
}

# On a non-event attribute the modifiers are a no-op rather than an error.
expect {
	match Attribute.class("btn").stop_propagation().prevent_default() {
		String(name_, val) => name_ == "class" and val == "btn"
		_ => Bool.False
	}
}

# map re-targets the message and must leave the flags alone. A component that
# stops propagation keeps stopping it after the parent wraps its Msg.
expect {
	match Attribute.on_click("inner").stop_propagation().map(|s| "outer:${s}") {
		MsgHandler(event, pd, sp, boxed) =>
			event == "click" and pd == Bool.False and sp == Bool.True and Box.unbox(boxed) == "outer:inner"
		_ => Bool.False
	}
}

expect {
	match Attribute.on_input(|s| "typed:${s}").stop_propagation().map(|s| "outer:${s}") {
		PropertyHandler(event, prop, pd, sp, cb) => {
			inner = Box.unbox(cb)
			event == "input"
				and prop == "value"
					and pd == Bool.False
						and sp == Bool.True
							and Box.unbox(inner("abc")) == "outer:typed:abc"
		}
		_ => Bool.False
	}
}

# Both flags are a client-side concern, so these render as nothing, exactly
# like the plain handlers.
expect Attribute.to_ssr_str(Attribute.on_click("clicked").stop_propagation()) == ""
expect Attribute.to_ssr_str(Attribute.on_input(|s| "typed:${s}").prevent_default()) == ""
