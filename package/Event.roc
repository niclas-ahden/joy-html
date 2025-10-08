module [
    on_click,
    on_input,
    on_change,
    on_keyup,
    on_keydown,
    on_click_stop_propagation,
    on_input_stop_propagation,
    on_change_stop_propagation,
    on_keyup_stop_propagation,
    on_keydown_stop_propagation,
    on_click_prevent_default,
    on_input_prevent_default,
    on_change_prevent_default,
    on_keyup_prevent_default,
    on_keydown_prevent_default,
    on_click_custom,
    on_input_custom,
    on_change_custom,
    on_keyup_custom,
    on_keydown_custom,
]

import Attribute exposing [Attribute]

# Basic event handlers (no propagation control)

on_click : Str -> Attribute
on_click = |handler|
    Event({ name: "onclick", handler, stop_propagation: Bool.false, prevent_default: Bool.false })

on_input : Str -> Attribute
on_input = |handler|
    Event({ name: "oninput", handler, stop_propagation: Bool.false, prevent_default: Bool.false })

on_change : Str -> Attribute
on_change = |handler|
    Event({ name: "onchange", handler, stop_propagation: Bool.false, prevent_default: Bool.false })

on_keyup : Str -> Attribute
on_keyup = |handler|
    Event({ name: "onkeyup", handler, stop_propagation: Bool.false, prevent_default: Bool.false })

on_keydown : Str -> Attribute
on_keydown = |handler|
    Event({ name: "onkeydown", handler, stop_propagation: Bool.false, prevent_default: Bool.false })

# Stop propagation variants

on_click_stop_propagation : Str, Bool -> Attribute
on_click_stop_propagation = |handler, should_stop|
    Event({ name: "onclick", handler, stop_propagation: should_stop, prevent_default: Bool.false })

on_input_stop_propagation : Str, Bool -> Attribute
on_input_stop_propagation = |handler, should_stop|
    Event({ name: "oninput", handler, stop_propagation: should_stop, prevent_default: Bool.false })

on_change_stop_propagation : Str, Bool -> Attribute
on_change_stop_propagation = |handler, should_stop|
    Event({ name: "onchange", handler, stop_propagation: should_stop, prevent_default: Bool.false })

on_keyup_stop_propagation : Str, Bool -> Attribute
on_keyup_stop_propagation = |handler, should_stop|
    Event({ name: "onkeyup", handler, stop_propagation: should_stop, prevent_default: Bool.false })

on_keydown_stop_propagation : Str, Bool -> Attribute
on_keydown_stop_propagation = |handler, should_stop|
    Event({ name: "onkeydown", handler, stop_propagation: should_stop, prevent_default: Bool.false })

# Prevent default variants

on_click_prevent_default : Str, Bool -> Attribute
on_click_prevent_default = |handler, should_prevent|
    Event({ name: "onclick", handler, stop_propagation: Bool.false, prevent_default: should_prevent })

on_input_prevent_default : Str, Bool -> Attribute
on_input_prevent_default = |handler, should_prevent|
    Event({ name: "oninput", handler, stop_propagation: Bool.false, prevent_default: should_prevent })

on_change_prevent_default : Str, Bool -> Attribute
on_change_prevent_default = |handler, should_prevent|
    Event({ name: "onchange", handler, stop_propagation: Bool.false, prevent_default: should_prevent })

on_keyup_prevent_default : Str, Bool -> Attribute
on_keyup_prevent_default = |handler, should_prevent|
    Event({ name: "onkeyup", handler, stop_propagation: Bool.false, prevent_default: should_prevent })

on_keydown_prevent_default : Str, Bool -> Attribute
on_keydown_prevent_default = |handler, should_prevent|
    Event({ name: "onkeydown", handler, stop_propagation: Bool.false, prevent_default: should_prevent })

# Full control variants (custom)

on_click_custom : Str, Bool, Bool -> Attribute
on_click_custom = |handler, stop_propagation, prevent_default|
    Event({ name: "onclick", handler, stop_propagation, prevent_default })

on_input_custom : Str, Bool, Bool -> Attribute
on_input_custom = |handler, stop_propagation, prevent_default|
    Event({ name: "oninput", handler, stop_propagation, prevent_default })

on_change_custom : Str, Bool, Bool -> Attribute
on_change_custom = |handler, stop_propagation, prevent_default|
    Event({ name: "onchange", handler, stop_propagation, prevent_default })

on_keyup_custom : Str, Bool, Bool -> Attribute
on_keyup_custom = |handler, stop_propagation, prevent_default|
    Event({ name: "onkeyup", handler, stop_propagation, prevent_default })

on_keydown_custom : Str, Bool, Bool -> Attribute
on_keydown_custom = |handler, stop_propagation, prevent_default|
    Event({ name: "onkeydown", handler, stop_propagation, prevent_default })
