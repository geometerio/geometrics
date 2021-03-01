# Javascript

Geometrics provides a few hooks for tracing front-end Javascript along with back-end Elixir. This demonstrates the premise of distributed tracing—in a single trace, one could potentially see the timings of a user's browser page load, then connection to LiveView, along with each event that transpires.

## Tracing across stack boundaries

Some extra steps are necessary to tie front end and back end spans together. It is necessary to "propagate" an identifier from the server to the frontend in order to ensure that frontend events show up in the same trace as the backend events that initiated the request. This is called "context propagation." The way that Geometrics achieves context propagation is by placing `meta` tags in the root layout that `opentelemetry-js` understands and can use to tie together to all the spans that are then created on the front end.

```.eex
<%= Geometrics.Phoenix.View.meta_tags() %>
```

## Collecting traces

In order aggregate and export trace events, the frontend needs to speak with a public endpoint separate from your Phoenix backend. This endpoint is a running server called a [`opentelemetry-collector`](https://github.com/open-telemetry/opentelemetry-collector). It's main purpose is receive requests containing trace information to buffer and export traces to visualization services like Honeycomb.

## Usage

To capture spans, you can wrap whatever block of code you wish to capture in a `withSpan`. This function allows you to pass a name for the span, as well as a function that will wrap the code for the span. This function will also receive the span, which you can use to get useful information off like the context it's being created in, and the current span's parent span, if there is one. In this example we create a span for initializing a liveSocket connection.

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

At the moment, spans will not nest within each other if you call `withSpan` from within another `withSpan` block. This is 
a known issue and is being worked on.