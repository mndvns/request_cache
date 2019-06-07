# RequestCache

A cache that stores items per Plug request. Built on top of [ConCache](https://github.com/sasa1977/con_cache).

## Usage

For best results, add the RequestCache plug to your plug pipeline:

```
plug(RequestCache.Plug)

```

You can use it without plug. It will key off of the main
process pid instead of off a request.

## Installation

```elixir
def deps do
  [
    {:request_cache, "~> 0.1.0"}
  ]
end
```
