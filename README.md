# joy-html

Build HTML for [Joy](https://www.github.com/niclas-ahden/joy) on the front- and back-end.

```roc
view = |model|
    Html.div([Attribute.class("counter")], [
        Html.button([Event.on_click(Increment)], [Html.text("+")]),
        Html.text("count: ${model.count.to_str()}"),
    ])
```

Render that tree to a string with `Html.render`, or with `Html.ssr_document` for a full page with a doctype. Event handlers are attached automatically in the browser, and ignored on the back-end.

- `Html.roc`: the `Html(msg)` tree, element helpers, `map` and `lazy`, and the server-side renderer.
- `Attribute.roc`: every attribute, including the event handlers. Values are escaped and names are sanitized, so a dynamic string cannot break out of its attribute.
- `Event.roc`: the common `on_*` handlers, so simple views need not import `Attribute`. Any handler takes the `.stop_propagation()` and `.prevent_default()` modifiers, which set flags the client runtime acts on. Server rendering ignores them.

If you're missing an element or atttribute you can always construct them yourself using `Html.element` and `Attribute.attribute`.
