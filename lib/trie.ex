defmodule Trie do
  @behaviour Access

  @moduledoc ~S"""
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

  Implemented behaviors:
  - `Access`
  """

  @type key :: char
  @type val :: map
  @type t :: %Trie{key: key, children: val, count: integer}

  defstruct key: nil, children: %{}, count: 0

  @doc ~S"""
  Convenience function: it invokes `add/3` on a brand new `Trie` object it
  creates. Raises `ArgumentError` if there are non-printable characters
  in the word.
  """
  @spec load(charlist|binary, integer) :: t
  def load(word, count \\ 1)

  def load(word, count) when is_list(word) do
    load(List.to_string(word), count)
  end

  def load(word, count) when is_binary(word) do
    if not String.printable?(word) do
      raise(ArgumentError, "the parameter must be printable")
    end
    add(%Trie{}, word, count)
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
  def add(t, word, count \\ 1)

  def add(%Trie{} = t, word, count) when is_binary(word) do
    add(t, to_char_list(word), count)
  end

  def add(%Trie{} = t, [head | tail], count) do
    child = Map.get(t.children, head) || %Trie{key: head}
    child = add(child, tail, count)
    children = Map.put(t.children, head, child)
    %Trie{t | children: children}
  end

  def add(%Trie{} = t, [], count) do
    %Trie{t | count: t.count + count}
  end

  def add(nil, _text, _count), do: nil
  def add(%Trie{} = t, nil, _count), do: t

  @doc ~S"""
  Implements the callback `c:Access.fetch/2`.
  """
  @spec fetch(t, {charlist|binary}) :: ({:ok, t}|:error)
  def fetch(t, key)

  def fetch(%Trie{} = t, key) when is_binary(key) do
    fetch(t, to_char_list(key))
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
    pop(t, to_char_list(key))
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
    get_and_update(t, to_char_list(key), fun)
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
end
