# CHANGELOG

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
