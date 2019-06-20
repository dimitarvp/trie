defmodule Trie do
  @behaviour Access

  @moduledoc ~S"""
  This module contains the type and functions to work with a [Trie (tree data
  structure)](https://en.wikipedia.org/wiki/Trie). The difference from the
  accepted data structure is that this one only keeps one character per node.
  The data structure here also implements the Elixir's `Access` behaviour.

  ### Functions of interest

  - `search/2`: searches for a prefix in the trie and returns a list of
    complete words that match the prefix.
  - `words/1`: returns a list of all complete words found in the trie.
    No particular order is guaranteed.
  - `word_count/1`: returns the count of all complete words in the trie.

  ### Fields

  **IMPORTANT NOTE**: None of the fields should be relied on as a public API.
  Anything you need from a `Trie` should be achievable by its functions.

  This section is provided as an informative piece to demonstrate the internal
  data structure.

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

  ### Root node

  The root node of a newly constructed `Trie` always has a `nil` key and zero
  `frequency`. Its `children` are the first characters of the words.

  ### Example

  Given the words `["ten", "tons", "tea"]` loaded with frequencies of
  2, 3 and 4 respectively, a `Trie` will look like the following (L0 to L4
  stand for Levels 0 to 4 in the tree):

  |L0    |L1 |L2 |L3 |L4 |Frequency|
  |------|---|---|---|---|--------:|
  |_root_|   |   |   |   |        0|
  |      |`t`|   |   |   |        0|
  |      |   |`e`|   |   |        0|
  |      |   |   |`a`|   |        4|
  |      |   |   |`n`|   |        2|
  |      |   |`o`|   |   |        0|
  |      |   |   |`n`|   |        0|
  |      |   |   |   |`s`|        3|

  In the above example only the words `tea`, `ten` and `tons` are complete
  while the words `t`, `te`, `to` and `ton` are not.
  """

  @type key :: char
  @type optional_key :: char | nil
  @type children :: %{required(key) => t} | %{}
  @type t :: %Trie{
          key: optional_key,
          children: children,
          frequency: non_neg_integer
        }

  defstruct key: nil, children: %{}, frequency: 0

  @doc ~S"""
  Creates a `Trie` and invokes `add/3`.
  Raises `ArgumentError` if there are non-printable characters in the word.
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
  Creates a `Trie` and invokes `add/3` on each word (or pairs of words and
  frequencies) to it.
  Note that any combination of words and words with frequencies is accepted, for
  example `["one", {"word", 2}, {"another", 5}, "day"]` is a valid input and it
  would add the words "one" and "day" with frequencies of one while the words
  "word" and "another" will have frequencies of two and five, respectively.
  Also see `put_word/2`.
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

  @spec get_or_create_node(t, key) :: t
  defp get_or_create_node(%__MODULE__{children: %{} = children}, key)
       when is_integer(key) do
    children
    |> Map.put_new(key, %__MODULE__{key: key})
    |> Map.get(key)
  end

  @spec get_node(t, key) :: t | nil
  defp get_node(%__MODULE__{children: %{} = children}, key)
       when is_integer(key) do
    Map.get(children, key)
  end

  @spec fetch_node(t, key) :: {:ok, t} | :error
  defp fetch_node(%__MODULE__{children: %{} = children}, key)
       when is_integer(key) do
    Map.fetch(children, key)
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

  def add(
        %__MODULE__{children: %{} = children} = t,
        [char | rest_chars],
        frequency
      )
      when is_integer(frequency) do
    child = get_or_create_node(t, char)
    child = add(child, rest_chars, frequency)
    children = Map.put(children, char, child)
    %__MODULE__{t | children: children}
  end

  def add(%__MODULE__{} = t, [], frequency) when is_integer(frequency) do
    %__MODULE__{t | frequency: t.frequency + frequency}
  end

  @doc ~S"""
  Implements the callback `c:Access.fetch/2`.
  """
  @spec fetch(t, charlist | binary) :: {:ok, t} | :error
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

  def fetch(%__MODULE__{} = t, key)
      when is_integer(key) do
    fetch_node(t, key)
  end

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

  @doc ~S"""
  Implements the callback `c:Access.pop/2`.
  """
  @spec pop(t, charlist | binary) :: {nil | t, t}
  def pop(%__MODULE__{} = t, key) when is_binary(key) do
    pop(t, to_charlist(key))
  end

  def pop(%__MODULE__{children: %{} = children} = t, [char | rest_chars])
      when is_integer(char) and length(rest_chars) > 0 do
    {popped_trie, modified_trie} = pop(get_node(t, char), rest_chars)
    t = %__MODULE__{t | children: Map.put(children, char, modified_trie)}
    {popped_trie, t}
  end

  def pop(%__MODULE__{children: %{} = children} = t, [char | rest_chars])
      when is_integer(char) and length(rest_chars) == 0 do
    {popped_trie, modified_children} = Map.pop(children, char)
    t = %__MODULE__{t | children: modified_children}
    {popped_trie, t}
  end

  def pop(%__MODULE__{} = _t, ""), do: {nil, %{}}
  def pop(%__MODULE__{} = _t, []), do: {nil, %{}}

  @doc ~S"""
  Implements the callback `c:Access.get_and_update/3`.
  """
  @spec get_and_update(t, charlist | binary, (key -> {t, t} | :pop)) :: {t, t}
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

  @spec get_and_update_without_pop(t, charlist, t | nil, t) :: {t, t}

  defp get_and_update_without_pop(
         %__MODULE__{children: %{} = children} = t,
         [char],
         old_val,
         %__MODULE__{} = new_val
       )
       when is_integer(char) do
    modified_trie = %__MODULE__{
      t
      | children: Map.put(children, char, new_val)
    }

    {old_val, modified_trie}
  end

  defp get_and_update_without_pop(
         %__MODULE__{children: %{} = children} = t,
         [char | rest_chars],
         old_val,
         %__MODULE__{} = new_val
       )
       when is_integer(char) do
    {_, modified_child} =
      get_and_update_without_pop(
        Map.get(
          children,
          char
        ),
        rest_chars,
        old_val,
        new_val
      )

    modified_trie = %__MODULE__{
      t
      | children: Map.put(children, char, modified_child)
    }

    {old_val, modified_trie}
  end

  @spec get_words(t, charlist, [binary]) :: [binary]
  defp get_words(
         %__MODULE__{
           children: %{} = children,
           frequency: frequency,
           key: key
         },
         word,
         words
       ) do
    {next_word, next_words} =
      case frequency do
        f when f > 0 ->
          new_word =
            [key | word]
            |> Enum.reverse()
            |> to_string()

          {[key | word], [new_word | words]}

        _ ->
          if is_nil(key) do
            {word, words}
          else
            {[key | word], words}
          end
      end

    Enum.reduce(children, next_words, fn {_key, trie}, acc ->
      get_words(trie, next_word, acc)
    end)
  end

  @spec words(t) :: [binary]
  @doc ~S"""
  Returns a list of all words.
  """
  def words(%__MODULE__{} = t) do
    get_words(t, [], [])
  end

  @spec word_count_by_frequency(non_neg_integer) :: 0 | 1
  defp word_count_by_frequency(freq) when freq > 0, do: 1
  defp word_count_by_frequency(_), do: 0

  @spec word_count(t) :: non_neg_integer
  @doc ~S"""
  Returns the count of all words (`Trie` nodes that have a non-zero frequency).
  """
  def word_count(%__MODULE__{children: %{} = children, frequency: frequency} = _t) do
    Enum.reduce(
      children,
      word_count_by_frequency(frequency),
      fn {_key, child}, total ->
        total + word_count(child)
      end
    )
  end

  @spec search(t, charlist | binary) :: [binary]

  @doc ~S"""
  Searches for a prefix and returns a list of word matches.
  """
  def search(%__MODULE__{} = t, prefix) when is_binary(prefix) do
    cut_prefix = String.slice(prefix, 0..-2)
    sub_trie = get(t, prefix) || %__MODULE__{}

    sub_trie
    |> words()
    |> Enum.map(&(cut_prefix <> &1))
  end

  def search(%__MODULE__{} = t, prefix) when is_list(prefix) do
    search(t, to_string(prefix))
  end
end
