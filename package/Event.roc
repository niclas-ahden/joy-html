module [
    # Click events
    on_click,
    on_click_stop_propagation,
    on_click_prevent_default,
    on_click_custom,
    # Input events
    on_input,
    on_input_stop_propagation,
    on_input_prevent_default,
    on_input_custom,
    # Change events
    on_change,
    on_change_stop_propagation,
    on_change_prevent_default,
    on_change_custom,
    # Keyup events
    on_keyup,
    on_keyup_stop_propagation,
    on_keyup_prevent_default,
    on_keyup_custom,
    # Keydown events
    on_keydown,
    on_keydown_stop_propagation,
    on_keydown_prevent_default,
    on_keydown_custom,
    # Touchstart events
    on_touchstart,
    on_touchstart_stop_propagation,
    on_touchstart_prevent_default,
    on_touchstart_custom,
    # Touchmove events
    on_touchmove,
    on_touchmove_stop_propagation,
    on_touchmove_prevent_default,
    on_touchmove_custom,
    # Touchend events
    on_touchend,
    on_touchend_stop_propagation,
    on_touchend_prevent_default,
    on_touchend_custom,
    # Mousedown events
    on_mousedown,
    on_mousedown_stop_propagation,
    on_mousedown_prevent_default,
    on_mousedown_custom,
    # Mousemove events
    on_mousemove,
    on_mousemove_stop_propagation,
    on_mousemove_prevent_default,
    on_mousemove_custom,
    # Mouseup events
    on_mouseup,
    on_mouseup_stop_propagation,
    on_mouseup_prevent_default,
    on_mouseup_custom,
    # Mouseleave events
    on_mouseleave,
    on_mouseleave_stop_propagation,
    on_mouseleave_prevent_default,
    on_mouseleave_custom,
]

import Attribute exposing [Attribute]

# Click events

on_click : Str -> Attribute
on_click = |handler|
    Event({ name: "onclick", handler, stop_propagation: Bool.false, prevent_default: Bool.false })

on_click_stop_propagation : Str, Bool -> Attribute
on_click_stop_propagation = |handler, should_stop|
    Event({ name: "onclick", handler, stop_propagation: should_stop, prevent_default: Bool.false })

on_click_prevent_default : Str, Bool -> Attribute
on_click_prevent_default = |handler, should_prevent|
    Event({ name: "onclick", handler, stop_propagation: Bool.false, prevent_default: should_prevent })

on_click_custom : Str, Bool, Bool -> Attribute
on_click_custom = |handler, stop_propagation, prevent_default|
    Event({ name: "onclick", handler, stop_propagation, prevent_default })

# Input events

on_input : Str -> Attribute
on_input = |handler|
    Event({ name: "oninput", handler, stop_propagation: Bool.false, prevent_default: Bool.false })

on_input_stop_propagation : Str, Bool -> Attribute
on_input_stop_propagation = |handler, should_stop|
    Event({ name: "oninput", handler, stop_propagation: should_stop, prevent_default: Bool.false })

on_input_prevent_default : Str, Bool -> Attribute
on_input_prevent_default = |handler, should_prevent|
    Event({ name: "oninput", handler, stop_propagation: Bool.false, prevent_default: should_prevent })

on_input_custom : Str, Bool, Bool -> Attribute
on_input_custom = |handler, stop_propagation, prevent_default|
    Event({ name: "oninput", handler, stop_propagation, prevent_default })

# Change events

on_change : Str -> Attribute
on_change = |handler|
    Event({ name: "onchange", handler, stop_propagation: Bool.false, prevent_default: Bool.false })

on_change_stop_propagation : Str, Bool -> Attribute
on_change_stop_propagation = |handler, should_stop|
    Event({ name: "onchange", handler, stop_propagation: should_stop, prevent_default: Bool.false })

on_change_prevent_default : Str, Bool -> Attribute
on_change_prevent_default = |handler, should_prevent|
    Event({ name: "onchange", handler, stop_propagation: Bool.false, prevent_default: should_prevent })

on_change_custom : Str, Bool, Bool -> Attribute
on_change_custom = |handler, stop_propagation, prevent_default|
    Event({ name: "onchange", handler, stop_propagation, prevent_default })

# Keyup events

on_keyup : Str -> Attribute
on_keyup = |handler|
    Event({ name: "onkeyup", handler, stop_propagation: Bool.false, prevent_default: Bool.false })

on_keyup_stop_propagation : Str, Bool -> Attribute
on_keyup_stop_propagation = |handler, should_stop|
    Event({ name: "onkeyup", handler, stop_propagation: should_stop, prevent_default: Bool.false })

on_keyup_prevent_default : Str, Bool -> Attribute
on_keyup_prevent_default = |handler, should_prevent|
    Event({ name: "onkeyup", handler, stop_propagation: Bool.false, prevent_default: should_prevent })

on_keyup_custom : Str, Bool, Bool -> Attribute
on_keyup_custom = |handler, stop_propagation, prevent_default|
    Event({ name: "onkeyup", handler, stop_propagation, prevent_default })

# Keydown events

on_keydown : Str -> Attribute
on_keydown = |handler|
    Event({ name: "onkeydown", handler, stop_propagation: Bool.false, prevent_default: Bool.false })

on_keydown_stop_propagation : Str, Bool -> Attribute
on_keydown_stop_propagation = |handler, should_stop|
    Event({ name: "onkeydown", handler, stop_propagation: should_stop, prevent_default: Bool.false })

on_keydown_prevent_default : Str, Bool -> Attribute
on_keydown_prevent_default = |handler, should_prevent|
    Event({ name: "onkeydown", handler, stop_propagation: Bool.false, prevent_default: should_prevent })

on_keydown_custom : Str, Bool, Bool -> Attribute
on_keydown_custom = |handler, stop_propagation, prevent_default|
    Event({ name: "onkeydown", handler, stop_propagation, prevent_default })

# Touchstart events

on_touchstart : Str -> Attribute
on_touchstart = |handler|
    Event({ name: "ontouchstart", handler, stop_propagation: Bool.false, prevent_default: Bool.false })

on_touchstart_stop_propagation : Str, Bool -> Attribute
on_touchstart_stop_propagation = |handler, should_stop|
    Event({ name: "ontouchstart", handler, stop_propagation: should_stop, prevent_default: Bool.false })

on_touchstart_prevent_default : Str, Bool -> Attribute
on_touchstart_prevent_default = |handler, should_prevent|
    Event({ name: "ontouchstart", handler, stop_propagation: Bool.false, prevent_default: should_prevent })

on_touchstart_custom : Str, Bool, Bool -> Attribute
on_touchstart_custom = |handler, stop_propagation, prevent_default|
    Event({ name: "ontouchstart", handler, stop_propagation, prevent_default })

# Touchmove events

on_touchmove : Str -> Attribute
on_touchmove = |handler|
    Event({ name: "ontouchmove", handler, stop_propagation: Bool.false, prevent_default: Bool.false })

on_touchmove_stop_propagation : Str, Bool -> Attribute
on_touchmove_stop_propagation = |handler, should_stop|
    Event({ name: "ontouchmove", handler, stop_propagation: should_stop, prevent_default: Bool.false })

on_touchmove_prevent_default : Str, Bool -> Attribute
on_touchmove_prevent_default = |handler, should_prevent|
    Event({ name: "ontouchmove", handler, stop_propagation: Bool.false, prevent_default: should_prevent })

on_touchmove_custom : Str, Bool, Bool -> Attribute
on_touchmove_custom = |handler, stop_propagation, prevent_default|
    Event({ name: "ontouchmove", handler, stop_propagation, prevent_default })

# Touchend events

on_touchend : Str -> Attribute
on_touchend = |handler|
    Event({ name: "ontouchend", handler, stop_propagation: Bool.false, prevent_default: Bool.false })

on_touchend_stop_propagation : Str, Bool -> Attribute
on_touchend_stop_propagation = |handler, should_stop|
    Event({ name: "ontouchend", handler, stop_propagation: should_stop, prevent_default: Bool.false })

on_touchend_prevent_default : Str, Bool -> Attribute
on_touchend_prevent_default = |handler, should_prevent|
    Event({ name: "ontouchend", handler, stop_propagation: Bool.false, prevent_default: should_prevent })

on_touchend_custom : Str, Bool, Bool -> Attribute
on_touchend_custom = |handler, stop_propagation, prevent_default|
    Event({ name: "ontouchend", handler, stop_propagation, prevent_default })

# Mousedown events

on_mousedown : Str -> Attribute
on_mousedown = |handler|
    Event({ name: "onmousedown", handler, stop_propagation: Bool.false, prevent_default: Bool.false })

on_mousedown_stop_propagation : Str, Bool -> Attribute
on_mousedown_stop_propagation = |handler, should_stop|
    Event({ name: "onmousedown", handler, stop_propagation: should_stop, prevent_default: Bool.false })

on_mousedown_prevent_default : Str, Bool -> Attribute
on_mousedown_prevent_default = |handler, should_prevent|
    Event({ name: "onmousedown", handler, stop_propagation: Bool.false, prevent_default: should_prevent })

on_mousedown_custom : Str, Bool, Bool -> Attribute
on_mousedown_custom = |handler, stop_propagation, prevent_default|
    Event({ name: "onmousedown", handler, stop_propagation, prevent_default })

# Mousemove events

on_mousemove : Str -> Attribute
on_mousemove = |handler|
    Event({ name: "onmousemove", handler, stop_propagation: Bool.false, prevent_default: Bool.false })

on_mousemove_stop_propagation : Str, Bool -> Attribute
on_mousemove_stop_propagation = |handler, should_stop|
    Event({ name: "onmousemove", handler, stop_propagation: should_stop, prevent_default: Bool.false })

on_mousemove_prevent_default : Str, Bool -> Attribute
on_mousemove_prevent_default = |handler, should_prevent|
    Event({ name: "onmousemove", handler, stop_propagation: Bool.false, prevent_default: should_prevent })

on_mousemove_custom : Str, Bool, Bool -> Attribute
on_mousemove_custom = |handler, stop_propagation, prevent_default|
    Event({ name: "onmousemove", handler, stop_propagation, prevent_default })

# Mouseup events

on_mouseup : Str -> Attribute
on_mouseup = |handler|
    Event({ name: "onmouseup", handler, stop_propagation: Bool.false, prevent_default: Bool.false })

on_mouseup_stop_propagation : Str, Bool -> Attribute
on_mouseup_stop_propagation = |handler, should_stop|
    Event({ name: "onmouseup", handler, stop_propagation: should_stop, prevent_default: Bool.false })

on_mouseup_prevent_default : Str, Bool -> Attribute
on_mouseup_prevent_default = |handler, should_prevent|
    Event({ name: "onmouseup", handler, stop_propagation: Bool.false, prevent_default: should_prevent })

on_mouseup_custom : Str, Bool, Bool -> Attribute
on_mouseup_custom = |handler, stop_propagation, prevent_default|
    Event({ name: "onmouseup", handler, stop_propagation, prevent_default })

# Mouseleave events

on_mouseleave : Str -> Attribute
on_mouseleave = |handler|
    Event({ name: "onmouseleave", handler, stop_propagation: Bool.false, prevent_default: Bool.false })

on_mouseleave_stop_propagation : Str, Bool -> Attribute
on_mouseleave_stop_propagation = |handler, should_stop|
    Event({ name: "onmouseleave", handler, stop_propagation: should_stop, prevent_default: Bool.false })

on_mouseleave_prevent_default : Str, Bool -> Attribute
on_mouseleave_prevent_default = |handler, should_prevent|
    Event({ name: "onmouseleave", handler, stop_propagation: Bool.false, prevent_default: should_prevent })

on_mouseleave_custom : Str, Bool, Bool -> Attribute
on_mouseleave_custom = |handler, stop_propagation, prevent_default|
    Event({ name: "onmouseleave", handler, stop_propagation, prevent_default })
