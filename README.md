# PersonalElixirUtils

A personal collection of Elixir utilities to streamline debugging and development.

## Installation

This package is not published on Hex. Install it directly from GitHub by adding it to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:personal_elixir_utils, git: "https://github.com/ll1zt/personal_elixir_utils.git", branch: "main"}
  ]
end
```

## Key Features

### DeepInspect
Trim deeply nested structures for cleaner debugging output.

```elixir
import PersonalElixirUtils

# Clips data at depth 2 and prints via IO.inspect
huge_map |> debug(2)

# Or just get the clipped term
clipped = clip_depth(complex_data, 1)
# => [1, ":…", 3]
```

## Development

### Running Tests
```bash
mix test
```

### Generating Documentation
```bash
mix docs
```
