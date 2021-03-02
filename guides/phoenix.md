# Phoenix + Ecto

Geometrics uses `OpentelemetryPhoenix` and `OpentelemetryEcto` to set up some
basic bindings on `:telemetry` events. This is useful, even though it's not the
recommended way of using OpenTelemetry.

## Process crashes and exits

OpenTelemetry recommends that spans be created by wrapping code blocks with the 
`OpenTelemetry.Tracer.with_span/3` macro. This has the benefit of rescuing 
exceptions and catching exits. Phoenix and Ecto instead use `:telemetry`, with
a block syntax that sends `:start`, `:stop`, and `:exception` messages—the
downside being that exits are not caught.

Geometrics attempts to solve this.

Geometrics adds extra telemetry attachments, so that after a span is opened it 
is added to the `Logger.metadata`. This allows us to watch process exits in a
custom logger module... if a process crashes or exits with an open span, we can
send a custom telemetry event to make sure spans aren't orphaned.

## LiveView

`OpentelemetryPhoenix` does not currently support LiveView. Geometrics adds
custom telemetry attachments to watch for `:mount` and `:handle_event` events,
and put them into a common trace for the current page view.

If a `traceContext` parameter is included in the Javascript that initializes
the LiveView session, the trace can be tied back to the initial page load, as
well as potentially include other OpenTelemetry spans created in Javascript.

At the time of writing, some issues with propagating trace ids through the
Javascript layer have yet to be fully worked out, but the basic flow of a
trace from the initial page load, to the browser, then back into the LiveView
socket has been proven to work.

Note: before updating `OpentelemetryPhoenix`, please verify that it does not 
introducing conflicting tracing code.

