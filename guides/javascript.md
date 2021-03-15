# Javascript

Geometrics provides a few hooks for tracing front-end Javascript along with back-end Elixir. This demonstrates the
premise of distributed tracing—in a single trace, one could potentially see the timings of a user's browser page load,
then connection to LiveView, along with each event that transpires.

## Tracing across stack boundaries

In order to tie the backend tracing context to front end events, you must provide a set of meta tags in your root
layout.

```.eex
<%= Geometrics.Phoenix.View.meta_tags() %>
```

This will create two `meta` tags:

* A tag with the name `traceparent` that contains a unique identifier used by OpenTelemetry to tie traces together. The
  naming for this meta tag arises from a recent W3C proposal around distributed tracing. It proposes a standard format
  for headers that lets you identify traces across services. If you're curious to read more about it, check out the
  proposal [here](https://www.w3.org/TR/trace-context/#problem-statement)).
* A tag with the name `collector_endpoint` whose value is the endpoint url that the frontend will send telemetry events
  to.

## Collecting traces

In order aggregate and export trace events, the frontend needs to speak with a public endpoint separate from your
Phoenix backend. This endpoint is a running server called
an [opentelemetry-collector](https://github.com/open-telemetry/opentelemetry-collector). Its main purpose is to receive
requests containing trace information to buffer and export traces to visualization services like Honeycomb.

## Usage

To capture spans, you can wrap whatever block of code you wish to capture in a `withSpan`. This function allows you to
pass a name for the span, as well as a function that will wrap the code for the span. This function will also receive a
javascript object which represents the span that is being created. In the example below we use this object to pass the
context of our frontend event to our LiveView backend via param.

```.js
import {withSpan, initTracer} from "geometrics"

const liveSocket = withSpan("liveSocket.connect()", (span) => {
  const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
  const options = {
    params: {
      _csrf_token: csrfToken,
      traceContext: span.context()
    }
  }
  const liveSocket = new LiveSocket("/live", Socket, options)
  liveSocket.connect()

  return liveSocket
})
```

Note that we pass the `span.context()` in the socket connection params as `traceContext`. We pick up this context on the
backend and use it to tie the frontend span with the trace context in the backend.

At the moment, it is only possible to record synchronous behavior executed in the context of a `withSpan`.