## Event handlers for HTML elements.
##
## Each `on_*` function builds an `Attribute(msg)` that sends a message to
## your update function when the event fires. Simple events take the
## message directly, value events take a function from the event's value
## to a message:
##
## ```roc
## Html.button([Event.on_click(Increment)], [Html.text("+")])
## Html.input([Event.on_input(|s| NameTyped(s))], [])
## ```
##
## Keyboard, pointer, file and visibility handlers live in `Attribute`.
## Handlers are omitted from server-rendered output and only take effect
## in the browser.
##
## To stop an event at its element or suppress the browser default, chain
## the `Attribute` modifiers on any handler:
## `Event.on_click(Ignored).stop_propagation()`.
import Attribute exposing [Attribute]
# Html is only used by the expects at the bottom.
import Html exposing [Html]

Event := [].{
    ## Send `msg` on click.
    on_click : msg -> Attribute(msg)
    on_click = |msg| Attribute.on_click(msg)

    ## Send the message produced from the input's value on every keystroke.
    on_input : (Str -> msg) -> Attribute(msg)
    on_input = |to_msg| Attribute.on_input(to_msg)

    ## Send the message produced from the control's `value` when it commits a
    ## change. Reads `value` for every element type, so one handler on a
    ## radio group receives the selected radio's value. For a checkbox's
    ## on/off state use `on_check`.
    on_change : (Str -> msg) -> Attribute(msg)
    on_change = |to_msg| Attribute.on_change(to_msg)

    ## Send the message produced from a checkbox's checked state when it
    ## changes: `on_check(|now| UserToggled(now))`. Don't combine with
    ## `on_change` on the same element, see `Attribute.on_check`.
    on_check : (Bool -> msg) -> Attribute(msg)
    on_check = |to_msg| Attribute.on_check(to_msg)

    ## Send `msg` when a touch starts on this element.
    on_touchstart : msg -> Attribute(msg)
    on_touchstart = |msg| Attribute.on("touchstart", msg)

    ## Send `msg` when a touch ends on this element.
    on_touchend : msg -> Attribute(msg)
    on_touchend = |msg| Attribute.on("touchend", msg)
}

# --- roc test (run via `roc test --main=package/main.roc package/Event.roc`) ---
# Attribute variants are only matchable inside Attribute.roc, so these tests
# pin the facade through what it does expose: SSR output (event attributes are
# skipped in server rendering, exactly like the Attribute constructors they
# delegate to, whose construction is pinned in Attribute.roc) and the
# `Attribute.stops_propagation` / `Attribute.prevents_default` accessors.

# The modifiers dispatch on Attribute, so they chain onto the facade's
# handlers like anything else that returns one.

expect Attribute.stops_propagation(Event.on_click("clicked").stop_propagation())
expect !Attribute.stops_propagation(Event.on_click("clicked"))
expect Attribute.prevents_default(Event.on_click("clicked").prevent_default())
expect !Attribute.prevents_default(Event.on_click("clicked"))

expect Attribute.stops_propagation(Event.on_input(|s| "typed:${s}").stop_propagation())
expect !Attribute.stops_propagation(Event.on_input(|s| "typed:${s}"))

expect Attribute.stops_propagation(Event.on_change(|s| "chose:${s}").stop_propagation())
expect !Attribute.stops_propagation(Event.on_change(|s| "chose:${s}"))

# One modifier leaves the other flag alone, and chaining sets both.
expect !Attribute.prevents_default(Event.on_click("clicked").stop_propagation())
expect {
    both = Event.on_click("clicked").stop_propagation().prevent_default()
    Attribute.stops_propagation(both) and Attribute.prevents_default(both)
}

# Non-event attributes report False rather than failing to match, and the
# modifiers leave them untouched.
expect !Attribute.stops_propagation(Attribute.class("btn"))
expect !Attribute.stops_propagation(Attribute.class("btn").stop_propagation())
expect !Attribute.prevents_default(Attribute.class("btn").prevent_default())
expect Attribute.stops_propagation(Event.on_check(|b| if b "on" else "off").stop_propagation())
expect Attribute.stops_propagation(Event.on_touchstart("start").stop_propagation())

expect
    Html.render(Html.button([Event.on_click("clicked")], [Html.text("Go")]))
    == "<button>Go</button>"

expect
    Html.render(Html.button([Event.on_click("clicked").stop_propagation()], [Html.text("Go")]))
    == "<button>Go</button>"

expect
    Html.render(Html.input([Event.on_input(|s| "typed:${s}"), Attribute.value("v")]))
    == "<input value=\"v\" />"

expect
    Html.render(Html.input([Event.on_input(|s| "typed:${s}").stop_propagation()]))
    == "<input />"

expect
    Html.render(Html.select([Event.on_change(|s| "chose:${s}")], []))
    == "<select></select>"

expect
    Html.render(Html.select([Event.on_change(|s| "chose:${s}").prevent_default()], []))
    == "<select></select>"

expect
    Html.render(Html.input([Event.on_check(|b| if b "on" else "off"), Attribute.type("checkbox")]))
    == "<input type=\"checkbox\" />"

expect
    Html.render(Html.div([Event.on_touchstart("start"), Event.on_touchend("end")], [Html.text("t")]))
    == "<div>t</div>"
