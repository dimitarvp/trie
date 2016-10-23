# Trie

  This module contains the type and functions to work with a [Trie (tree data
  structure)](https://en.wikipedia.org/wiki/Trie).

  It's a recursive node structure with 3 fields:
  1. `key`: an integer representing a character. When traversing the `Trie`
     you can compose the word you are looking for by traversing the nodes
     recursively.
  2. `children`: a `Map` of `integer` keys (a character) and `Trie` values.
  3. `count`: amount of times the full word has been added to this `Trie` node.
     Useful for word counting or weighted NLP.

  The root of any `Trie` has a `nil` key and a zero count.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `trie` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:trie, "~> 0.1.0"}]
    end
    ```

  2. Ensure `trie` is started before your application:

    ```elixir
    def application do
      [applications: [:trie]]
    end
    ```

