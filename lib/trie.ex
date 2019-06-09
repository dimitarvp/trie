defmodule Trie do
  @behaviour Access

  @moduledoc ~S"""
  This module contains the type and functions to work with a [Trie (tree data
  structure)](https://en.wikipedia.org/wiki/Trie). The difference from the
  accepted data structure is that this one only keeps one character per node.

  ### Fields

  1. `key`: an integer representing an Unicode character. A word is composed
      by recursively adding (or looking up) its characters, one level at a
      time. **EXAMPLE**: Only loading the word "hello" will return a `Trie`
      which is 6 levels deep: one root node (see below for its field values)
      and 5 nodes for each character.
  2. `children`: a `Map` of `integer` keys (Unicode characters) and `Trie`
     nodes.
  3. `frequency`: amount of times the full word has been added to this `Trie`
     node. A `Trie` node having a `frequency` greater than zero is considered
     to be a word terminator (see the example below for clarification).
  4. `word_count`: cached full recursive count of complete words
     under the current node. It is changed as new words are added to the `Trie`.
     See the example below for clarification.

  ### Root node

  The root node of a newly constructed `Trie` always has a `nil` key and zero
  `frequency`. Its `children` are the first characters of the words.
  Its `word_count` captures the count of all complete words in it.

  ### Example

  Given the words `["ten", "tons", "tea"]` loaded with usage counts of
  `[2, 3, 4]` (which means the word `ten` has been used 2 times in the input
  text, the word `tons` has been used three times, and the word `tea` -- 4
  times), a `Trie` will look like the following (L1 to L4 stand for Levels 1
  to 4 in the tree):

  |L1 |L2 |L3 |L4 |`frequency`  |`word_count`|
  |---|---|---|---|-------------|------------|
  |_root_| | |    |            0|           3|
  |`t`|   |   |   |            0|           3|
  |   |`e`|   |   |            0|           2|
  |   |   |`a`|   |            4|           1|
  |   |   |`n`|   |            2|           1|
  |   |`o`|   |   |            0|           1|
  |   |   |`n`|   |            0|           1|
  |   |   |   |`s`|            3|           1|

  In the above example only the words `tea`, `ten` and `tons` are complete
  while the words `t`, `te`, `to` and `ton` are not.

  ### Implemented behaviors

  - `Access`
  """

  @type key :: char
  @type val :: map
  @type t :: %Trie{
          key: key,
          children: val,
          frequency: integer,
          word_count: integer
        }

  defstruct key: nil, children: %{}, frequency: 0, word_count: 0

  @doc ~S"""
  Convenience function: it invokes `add/3` on a brand new `Trie` object it
  creates. Raises `ArgumentError` if there are non-printable characters
  in the word.
  """
  @spec put_word(charlist | binary, integer) :: t | no_return
  def put_word(word, frequency \\ 1)

  def put_word(word, frequency)
      when is_list(word) and is_integer(frequency) do
    put_word(List.to_string(word), frequency)
  end

  def put_word(word, frequency)
      when is_binary(word) and is_integer(frequency) do
    if not String.printable?(word) do
      raise(ArgumentError, "the parameter must be printable")
    end

    add(%__MODULE__{}, word, frequency)
  end

  @doc ~S"""
  Creates a `Trie` and `add/3`s words (or pairs of words and frequencies) to it.
  Note that any combination of words and words with frequencies is accepted, for
  example `["one", {"word", 2}, {"another", 5}, "day"]` is a valid input and it
  would add the words "one" and "day" with frequencies of one while the words
  "word" and "another" will have frequencies of two and five, respectively.
  """
  @spec put_words([binary] | [{binary, pos_integer}]) :: t
  def put_words(texts) when is_list(texts) do
    Enum.reduce(texts, %__MODULE__{}, fn
      {text, frequency}, acc when is_binary(text) and is_integer(frequency) ->
        add(acc, text, frequency)

      text, acc when is_binary(text) ->
        add(acc, text)
    end)
  end

  defp get_or_create_node(%__MODULE__{children: %{} = children}, key) do
    children
    |> Map.put_new(key, %__MODULE__{key: key})
    |> Map.get(key)
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
  @spec add(t, charlist | binary, integer) :: t
  def add(t, word, frequency \\ 1)

  def add(%__MODULE__{} = t, word, frequency)
      when is_binary(word) and is_integer(frequency) do
    add(t, to_charlist(word), frequency)
  end

  def add(%__MODULE__{} = t, [char | rest_chars], frequency)
      when is_integer(frequency) do
    child = get_or_create_node(t, char)
    child = add(child, rest_chars, frequency)
    child = %__MODULE__{child | word_count: child.word_count + 1}
    children = Map.put(t.children, char, child)
    %__MODULE__{t | children: children}
  end

  def add(%__MODULE__{} = t, [], frequency) when is_integer(frequency) do
    %__MODULE__{t | frequency: t.frequency + frequency, word_count: 0}
  end

  def add(nil, _text, _frequency), do: nil
  def add(%__MODULE__{} = t, nil, _frequency), do: t

  @doc ~S"""
  Implements the callback `c:Access.fetch/2`.
  """
  @spec fetch(t, {charlist | binary}) :: {:ok, t} | :error
  def fetch(t, key)

  def fetch(%__MODULE__{} = t, key) when is_binary(key) do
    fetch(t, to_charlist(key))
  end

  def fetch(%__MODULE__{} = t, [char | rest_chars]) do
    case fetch(t, char) do
      {:ok, child} -> fetch(child, rest_chars)
      :error -> :error
    end
  end

  def fetch(%__MODULE__{} = t, []), do: {:ok, t}

  def fetch(%__MODULE__{} = t, key) when is_integer(key) do
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
  @spec get(t, charlist | binary, t | nil) :: t
  def get(t, key, default \\ nil)

  def get(%__MODULE__{} = t, key, default) do
    case fetch(t, key) do
      {:ok, val} -> val
      :error -> default
    end
  end

  def get(nil, _key, _default), do: :error

  @doc ~S"""
  Implements the callback `c:Access.pop/2`.
  """
  @spec pop(t, {charlist | binary}) :: {nil | t, t}
  def pop(%__MODULE__{} = t, key) when is_binary(key) do
    pop(t, to_charlist(key))
  end

  def pop(%__MODULE__{} = t, [char | rest_chars])
      when is_integer(char) and length(rest_chars) > 0 do
    {popped_trie, modified_trie} = pop(Map.get(t.children, char), rest_chars)
    t = %__MODULE__{t | children: Map.put(t.children, char, modified_trie)}
    {popped_trie, t}
  end

  def pop(%__MODULE__{} = t, [char | rest_chars])
      when is_integer(char) and length(rest_chars) == 0 do
    {popped_trie, modified_children} = Map.pop(t.children, char)
    t = %__MODULE__{t | children: modified_children}
    {popped_trie, t}
  end

  def pop(%__MODULE__{} = _t, ""), do: {nil, %{}}
  def pop(%__MODULE__{} = _t, []), do: {nil, %{}}
  def pop(%__MODULE__{} = _t, nil), do: {nil, %{}}
  def pop(nil, _key), do: {nil, %{}}

  @doc ~S"""
  Implements the callback `c:Access.get_and_update/3`.
  """
  def get_and_update(t, key, fun)

  def get_and_update(%__MODULE__{} = t, key, fun)
      when is_binary(key) and is_function(fun, 1) do
    get_and_update(t, to_charlist(key), fun)
  end

  def get_and_update(%__MODULE__{} = t, key, fun)
      when is_list(key) and is_function(fun, 1) do
    case fun.(key) do
      {old_val, %__MODULE__{} = new_val} ->
        get_and_update_without_pop(t, key, old_val, new_val)

      :pop ->
        pop(t, key)
    end
  end

  defp get_and_update_without_pop(
         %__MODULE__{} = t,
         [char | rest_chars],
         old_val,
         %__MODULE__{} = new_val
       )
       when is_integer(char) and length(rest_chars) > 0 do
    {_, modified_child} =
      get_and_update_without_pop(
        Map.get(
          t.children,
          char
        ),
        rest_chars,
        old_val,
        new_val
      )

    modified_trie = %__MODULE__{
      t
      | children: Map.put(t.children, char, modified_child)
    }

    {old_val, modified_trie}
  end

  defp get_and_update_without_pop(
         %__MODULE__{} = t,
         [char | rest_chars],
         old_val,
         %__MODULE__{} = new_val
       )
       when is_integer(char) and length(rest_chars) == 0 do
    modified_trie = %__MODULE__{
      t
      | children: Map.put(t.children, char, new_val)
    }

    {old_val, modified_trie}
  end

  @doc ~S"""
  Returns a `String` containing one word per line. A `Trie` node is considered
  a word terminator when its `frequency` field is greater than zero.

  ## Examples

      iex> Trie.words(Trie.put_words(["i", "in", "inn"]))
      "i\nin\ninn\n"

      iex> Trie.words(Trie.put_word("inn"))
      "inn\n"

      iex> Trie.words(%Trie{})
      []

  In the first example, `["i", "in", "inn"]` are separate words and each
  `Trie` along the way has a `frequency` equal to one, thus they are all
  printed.

  In the second example, only the word `"inn"` is loaded and thus all the
  `Trie` nodes along the way are not printed because they have a `frequency`
  equalling zero, thus only `"inn"` is printed.
  """
  def words(%__MODULE__{} = t, prefix \\ '') do
    Enum.reduce(t.children, '', fn {_key, child}, acc ->
      Enum.join([
        acc,
        if child.frequency > 0 do
          Enum.join([
            prefix,
            [child.key],
            '\n',
            words(child, prefix ++ [child.key])
          ])
        else
          words(child, prefix ++ [child.key])
        end
      ])
    end)
  end
end
