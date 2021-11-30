# CHANGELOG

## 0.2.1

- Fix crash when propagator returns multiple items.

## 0.2.0

- Update Elixir OpenTelemetry libraries to `~> 1.0.0-rc`.
- Update JS OpenTelemetry libraries to `0.22.0`.

**Breaking Change**

- `span.context()` -> `span.spanContext()`
  ```javascript
  withSpan('span name', (span) => {
    const traceContext = span.spanContext();
  });
  ```

## 0.1.0

Initial release.
