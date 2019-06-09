defmodule Trie do
  @behaviour Access

  @moduledoc ~S"""
  This module contains the type and functions to work with a [Trie (tree data
  structure)](https://en.wikipedia.org/wiki/Trie).

  It's a recursive node structure with 3 fields:
  1. `key`: an integer representing a character. You can compose a word you are
     looking for by traversing the `Trie` nodes recursively and appending all
     characters along the way.
  2. `children`: a `Map` of `integer` keys (Unicode characters) and `Trie`
     nodes.
  3. `usage_count`: amount of times the full word has been added to this `Trie`
     node. Useful for word counting or weighted NLP. A usage count greater
     than zero is considered to be a form of a word terminator (see the
     example below).
  4. `leaf_count`: caches the full recursive count of leaves under this node.
     In the example below, the "t" node has a `leaf_count` of 3, the "o" has 1,
     and the "e" node has 2.

  The root of a newly constructed `Trie` always has a `nil` key.

  Example:

  Given the words `["ten", "tons", "tea"]` loaded with usage counts of
  `[2, 3, 4]` (which means the word `ten` has been used 2 times in the input
  text, the word `tons` has been used three times, and the word `tea` -- 4
  times), a `Trie` will look like this (`usage_count` given at the start of
  each line):

  <pre>
  (0) -t
  (0)  -e
  (4)   -a
  (2)   -n
  (0)  -o
  (0)   -n
  (3)    -s
  </pre>

  *PLEASE NOTE*: only the end of the word has a count associated with the
  appropriate `Trie` node. The `usage_count` field of each `Trie` node gives
  you a differentation between words that are explicitly loaded vs. the words
  that can be automatically inferred by doing a full recursive visit. In this
  particular example you would know that only the words `tea`, `ten` and
  `tons` are explicitly loaded while conversely, the words `t`, `te`, `to` and
  `ton` are not.

  Implemented behaviors:
  - `Access`
  """

  @type key :: char
  @type val :: map
  @type t :: %Trie{key: key,
                   children: val,
                   usage_count: integer,
                   leaf_count: integer}

  defstruct key: nil, children: %{}, usage_count: 0, leaf_count: 0

  @doc ~S"""
  Convenience function: it invokes `add/3` on a brand new `Trie` object it
  creates. Raises `ArgumentError` if there are non-printable characters
  in the word.
  """
  @spec load(charlist|binary, integer) :: t
  def load(word, usage_count \\ 1)

  def load(word, usage_count) when is_list(word) do
    load(List.to_string(word), usage_count)
  end

  def load(word, usage_count) when is_binary(word) do
    if not String.printable?(word) do
      raise(ArgumentError, "the parameter must be printable")
    end
    add(%Trie{}, word, usage_count)
  end

  @doc ~S"""
  Convenience function: it invokes `add/3` on a brand new `Trie` object it
  creates, for all the strings/charlists in the passed list.
  """
  @spec load_multiple(list) :: t
  def load_multiple(texts) when is_list(texts) do
    t = %Trie{}
    Enum.reduce(texts, t, fn(text, acc) ->
      add(acc, text)
    end)
  end

  @doc ~S"""
  Adds the given word (binary or charlist) into the passed `Trie`.

  The returned `Trie` will have _N_ levels in its tree structure (where _N_ is
  the length of the binary / charlist), with each node along the way having a
  key of the character at the current position.

  It can then be polled via all available mechanisms of the `Access` behaviour
  plus the `Kernel` functions like `Kernel.get_in/2`, `Kernel.put_in/3` and
  friends. Consult the documentation of `Access` for more details.
  """
  @spec add(t, charlist|binary, integer) :: t
  def add(t, word, usage_count \\ 1)

  def add(%Trie{} = t, word, usage_count) when is_binary(word) do
    add(t, to_charlist(word), usage_count)
  end

  def add(%Trie{} = t, [head | tail], usage_count) do
    child = Map.get(t.children, head) || %Trie{key: head}
    child = add(child, tail, usage_count)
    children = Map.put(t.children, head, child)
    %Trie{t | children: children}
  end

  def add(%Trie{} = t, [], usage_count) do
    %Trie{t | usage_count: t.usage_count + usage_count}
  end

  def add(nil, _text, _usage_count), do: nil
  def add(%Trie{} = t, nil, _usage_count), do: t

  @doc ~S"""
  Implements the callback `c:Access.fetch/2`.
  """
  @spec fetch(t, {charlist|binary}) :: ({:ok, t}|:error)
  def fetch(t, key)

  def fetch(%Trie{} = t, key) when is_binary(key) do
    fetch(t, to_charlist(key))
  end

  def fetch(%Trie{} = t, [head | tail]) do
    case fetch(t, head) do
      {:ok, child} -> fetch(child, tail)
      :error -> :error
    end
  end

  def fetch(%Trie{} = t, []), do: {:ok, t}

  def fetch(%Trie{} = t, key) when is_integer(key) do
    case Map.get(t.children || %{}, key) do
      val when not is_nil(val) -> {:ok, val}
      nil -> :error
    end
  end

  def fetch(nil, _key), do: :error
  def fetch(_t, nil), do: :error

  @doc ~S"""
  Implements the callback `c:Access.get/3`.
  """
  @spec get(t, {charlist|binary}, {t|nil}) :: t
  def get(t, key, default \\ nil)

  def get(%Trie{} = t, key, default) do
    case fetch(t, key) do
      {:ok, val} -> val
      :error -> default
    end
  end

  def get(nil, _key, _default), do: :error

  @doc ~S"""
  Implements the callback `c:Access.pop/2`.
  """
  @spec pop(t, {charlist|binary}) :: {t, t}
  def pop(%Trie{} = t, key) when is_binary(key) do
    pop(t, to_charlist(key))
  end

  def pop(%Trie{} = t, [head | tail])
  when is_integer(head) and length(tail) > 0 do
    {popped_trie, modified_trie} = pop(Map.get(t.children, head), tail)
    t = %Trie{t | children: Map.put(t.children, head, modified_trie)}
    {popped_trie, t}
  end

  def pop(%Trie{} = t, [head | tail])
  when is_integer(head) and length(tail) == 0 do
    {popped_trie, modified_children} = Map.pop(t.children, head)
    t = %Trie{t | children: modified_children}
    {popped_trie, t}
  end

  def pop(%Trie{} = _t, ""), do: {nil, %{}}
  def pop(%Trie{} = _t, []), do: {nil, %{}}
  def pop(%Trie{} = _t, nil), do: {nil, %{}}
  def pop(nil, _key), do: {nil, %{}}

  @doc ~S"""
  Implements the callback `c:Access.get_and_update/3`.
  """
  def get_and_update(t, key, fun)

  def get_and_update(%Trie{} = t, key, fun)
  when is_binary(key) and is_function(fun, 1) do
    get_and_update(t, to_charlist(key), fun)
  end

  def get_and_update(%Trie{} = t, key, fun)
  when is_list(key) and is_function(fun, 1) do
    case fun.(key) do
      {old_val, %Trie{} = new_val} ->
        get_and_update_without_pop(t, key, old_val, new_val)
      :pop ->
        pop(t, key)
    end
  end

  defp get_and_update_without_pop(%Trie{} = t,
                                  [head | tail],
                                  old_val,
                                  %Trie{} = new_val)
  when is_integer(head) and length(tail) > 0 do
    {_, modified_child} = get_and_update_without_pop(Map.get(t.children,
      head), tail, old_val, new_val)

    modified_trie = %Trie{t | children: Map.put(t.children, head,
      modified_child)}

    {old_val, modified_trie}
  end

  defp get_and_update_without_pop(%Trie{} = t,
                                  [head | tail],
                                  old_val,
                                  %Trie{} = new_val)
  when is_integer(head) and length(tail) == 0 do
    modified_trie = %Trie{t | children: Map.put(t.children, head, new_val)}
    {old_val, modified_trie}
  end

  @doc ~S"""
  Returns a `String` containing one word per line. A `Trie` node is considered
  a word terminator when its `usage_count` field is greater than zero.

  ## Examples

      iex> Trie.words(Trie.load_multiple(["i", "in", "inn"]))
      "i\nin\ninn\n"

      iex> Trie.words(Trie.load("inn"))
      "inn\n"

      iex> Trie.words(%Trie{})
      []

  In the first example, `["i", "in", "inn"]` are separate words and each
  `Trie` along the way has a `usage_count` equal to one, thus they are all
  printed.

  In the second example, only the word `"inn"` is loaded and thus all the
  `Trie` nodes along the way are not printed because they have a `usage_count`
  equalling zero, thus only `"inn"` is printed.
  """
  def words(%Trie{} = t, prefix \\ '') do
    Enum.reduce(t.children, '', fn({_key,child}, acc) ->
      Enum.join [
        acc,
        if child.usage_count > 0 do
          Enum.join([prefix,
                     [child.key],
                     '\n',
                     words(child, prefix ++ [child.key])])
        else
          words(child, prefix ++ [child.key])
        end
      ]
    end)
  end
end
