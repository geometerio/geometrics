# Geometrics and testing

When adding Geometrics to a Phoenix project, a plug and a handler is registered. This
handler expects that when LiveView connections are made, a `traceContext` param is
sent.

This can cause warnings in live view tests, if the parameter is not configured. This can
be done as follows, where the values of `traceId` and `spanId` can be set to anything:

```elixir
defmodule MyAppWeb.PageLiveTest do
  use MyAppWeb.ConnCase

  import Phoenix.LiveViewTest
  alias Phoenix.LiveViewTest

  test "renders", %{conn: conn} do
    {:ok, home_live, disconnected_html} =
      conn
      |> LiveViewTest.put_connect_params(%{
        "traceContext" => %{"traceId" => "11111", "spanId" => "22222"}
      })
      |> live("/")

    assert disconnected_html =~ "Some text"
    assert render(home_live) =~ "Some text"
  end
end
```

Alternatively, this warning can be disabled entirely for tests by adding the following to
`config/test.exs`:

```elixir
config :geometrics, :warn_on_no_trace_context, false
```
