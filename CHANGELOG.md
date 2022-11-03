# CHANGELOG

## 1.0.3-rc.3

Add support for tracing async / await behavior with frontend withSpan.

## 1.0.2-rc.3

Update npm dependencies to resolve security vulnerabilities.

## 1.0.1-rc.3

Updates OpenTelemetry JS/Hex dependencies

- @opentelemetry/web -> @opentelemetry/sdk-trace-web
- @opentelemetry/tracing -> @opentelemetry/sdk-trace-base
- @opentelemetry/exporter-collector -> @opentelemetry/exporter-trace-otlp-http

Additionally adds @opentelemetry/auto-instrumentation-web and @opentelemetry/instrumentation

For Hex deps:

- opentelemetry 1.0.0 -> 1.1.1
- opentelemetry_api 1.0.0 -> 1.1.0
- opentelemetry_ecto 1.0.0-rc.5 -> 1.0.0
- opentelemetry_phoenix 1.0.0-rc.7 -> 1.0.0
- opentelemetry_telemetry 1.0.0-beta.7 -> 1.0.0

NOTE:

* LiveView tracing has been broken up into multiple traces with this update. While some
  LiveView frontend and backend events still do get reported together, handle_event's and second mount's
  will show up in separate traces.
* Also add package.json to top level of project that specifies an entry
  / "main" module

## 1.0.0

**Breaking Changes**

Updated to opentelemetry `1.x` in both Elixir and JavaScript. This introduced
breaking changes to the configuration of exporters.

See https://hexdocs.pm/geometrics/upgrading_to_1-0.html

## 0.2.0

- Fix crash when propagator returns multiple items.
- Update Elixir OpenTelemetry libraries to `~> 1.0.0-rc`.
- Update JS OpenTelemetry libraries to `0.22.0`.

**Breaking Changes**

- `span.context()` -> `span.spanContext()`
  ```javascript
  withSpan('span name', (span) => {
    const traceContext = span.spanContext();
  });
  ```

## 0.1.0

Initial release.
