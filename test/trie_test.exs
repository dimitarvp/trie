defmodule TrieTest do
  use ExUnit.Case
  doctest Trie

  defp trie_validate_node(t, node_count, node_key, children_keys) do
    assert is_integer(t.frequency)
    assert t.frequency == node_count

    assert is_nil(t.key) or is_integer(t.key)
    assert t.key == node_key

    assert is_map(t.children)
    assert Map.keys(t.children) == to_charlist(children_keys)
  end

  test "root should have word count of 3 after loading 3 words" do
    t = Trie.put_words(~w{1 2 3})
    assert t.word_count == 3
  end

  test "load 3 words" do
    t = Trie.put_words(~w{aa ab ac})
    trie_validate_node(t, 0, nil, 'a')

    {:ok, child_a} = Trie.fetch(t, 'a')
    trie_validate_node(child_a, 0, ?a, 'abc')
  end

  test "load 1 char" do
    t = Trie.put_word('a')
    trie_validate_node(t, 0, nil, 'a')

    {:ok, child_a} = Trie.fetch(t, 'a')
    trie_validate_node(child_a, 1, ?a, [])
  end

  test "load 2 chars and fetch" do
    t = Trie.put_word("ab")
    trie_validate_node(t, 0, nil, 'a')

    {:ok, child_a} = Trie.fetch(t, 'a')
    trie_validate_node(child_a, 0, ?a, 'b')

    {:ok, child_ab} = Trie.fetch(t, 'ab')
    trie_validate_node(child_ab, 1, ?b, '')
  end

  test "load 2 chars with usage count and fetch" do
    t = Trie.put_word("ab", 7)
    trie_validate_node(t, 0, nil, 'a')

    {:ok, child_a} = Trie.fetch(t, 'a')
    trie_validate_node(child_a, 0, ?a, 'b')

    {:ok, child_ab} = Trie.fetch(t, 'ab')
    trie_validate_node(child_ab, 7, ?b, '')
  end

  test "load 3 chars and fetch" do
    t = Trie.put_word("abc")
    trie_validate_node(t, 0, nil, 'a')

    {:ok, child_a} = Trie.fetch(t, 'a')
    trie_validate_node(child_a, 0, ?a, 'b')

    {:ok, child_ab} = Trie.fetch(t, 'ab')
    trie_validate_node(child_ab, 0, ?b, 'c')

    {:ok, child_abc} = Trie.fetch(t, 'abc')
    trie_validate_node(child_abc, 1, ?c, '')
  end

  test "load 3 chars and add 2 other leafs on level 3, then get" do
    t = Trie.put_word("ab1")
    t = Trie.add(t, "ab2")
    t = Trie.add(t, "ab3")

    assert Map.keys(Trie.get(t, 'a').children) == 'b'
    assert Map.keys(Trie.get(t, 'ab').children) == '123'
    assert Trie.get(t, 'ab1') == %Trie{key: ?1, frequency: 1, word_count: 1, children: %{}}
    assert Trie.get(t, 'ab2') == %Trie{key: ?2, frequency: 1, word_count: 1, children: %{}}
    assert Trie.get(t, 'ab3') == %Trie{key: ?3, frequency: 1, word_count: 1, children: %{}}
    refute Trie.get(t, 'ab4')
  end

  test "load 2 chars and pop the bottom leaf" do
    t = Trie.put_word("ab")
    {popped, modified} = Trie.pop(t, 'ab')
    assert popped == %Trie{key: ?b, frequency: 1, word_count: 1, children: %{}}
    refute Trie.get(modified, 'ab')
    assert Trie.get(modified, 'a') ==
      %Trie{key: ?a, frequency: 0, word_count: 1, children: %{}}
  end

  test "load 2 chars and get and update the bottom leaf" do
    t = Trie.put_word("ab")
    {old_val, new_val} = Trie.get_and_update(t, 'ab', fn(cur_val) ->
      {cur_val, %Trie{key: ?b, frequency: 7, word_count: 0, children: %{}}}
    end)
    assert old_val == 'ab'
    assert Trie.get(new_val, 'ab') ==
      %Trie{key: ?b, frequency: 7, word_count: 0, children: %{}}
  end

  test "non-printable word should result in an ArgumentError" do
    assert_raise(ArgumentError, fn ->
      Trie.put_word('ab\u0001')
    end)
  end

  test "add a nil word" do
    t = Trie.put_word("ab")
    assert Trie.add(t, nil) == t
  end

  test "add to a nil object" do
    assert Trie.add(nil, "a") == nil
    assert Trie.add(nil, "a", 3) == nil
  end

  test "add a binary word" do
    t = Trie.put_word("a")
    assert Trie.add(t, "b") ==
      %Trie{children: %{?a => %Trie{children: %{}, frequency: 1, word_count: 1, key: ?a},
                        ?b => %Trie{children: %{}, frequency: 1, word_count: 1, key: ?b}},
            frequency: 0, key: nil}
  end

  test "add a list word" do
    t = Trie.put_word("a")
    assert Trie.add(t, 'b') ==
      %Trie{children: %{?a => %Trie{children: %{}, frequency: 1, word_count: 1, key: ?a},
                        ?b => %Trie{children: %{}, frequency: 1, word_count: 1, key: ?b}},
            frequency: 0, key: nil}
  end

  test "add an empty list word" do
    t = Trie.put_word("a")
    assert Trie.add(t, '', 2) ==
      %Trie{children: %{?a => %Trie{children: %{}, frequency: 1, word_count: 1, key: ?a}},
            frequency: 2, word_count: 0, key: nil}

  end

  test "add a word with usage count" do
    t = Trie.put_word("a")
    assert Trie.add(t, "a", 3) ==
      %Trie{children: %{97 => %Trie{children: %{}, frequency: 4, word_count: 1, key: ?a}},
            frequency: 0, word_count: 0, key: nil}
  end

  test "fetching a node via binary key" do
    t = Trie.put_word("a")
    assert Trie.fetch(t, "a") ==
      {:ok, %Trie{key: ?a, frequency: 1, word_count: 1, children: %{}}}
  end

  test "fetching from a nil object" do
    assert Trie.fetch(nil, "a") == :error
    assert Trie.fetch(nil, 'a') == :error
  end

  test "fetching with a nil or empty key" do
    t = Trie.put_word("a")
    assert Trie.fetch(t, nil) == :error
    assert Trie.fetch(t, '') == {:ok, t}
  end

  test "getting from a nil object" do
    assert Trie.get(nil, "a") == :error
    assert Trie.get(nil, 'a') == :error
  end

  test "getting with a nil or empty key" do
    t = Trie.put_word("a")
    assert Trie.get(t, nil) == nil
    assert Trie.get(t, '') == t
  end

  test "popping a single letter key" do
    t = Trie.put_word("a")
    assert Trie.pop(t, 'a') == {%Trie{children: %{}, frequency: 1, word_count: 1, key: ?a},
                                %Trie{children: %{}, frequency: 0, word_count: 0, key: nil}}

    assert Trie.pop(t, "a") == {%Trie{children: %{}, frequency: 1, word_count: 1, key: ?a},
                                %Trie{children: %{}, frequency: 0, word_count: 0, key: nil}}
  end

  test "popping a multiple letter key" do
    t = Trie.put_word("ab")
    assert Trie.pop(t, 'ab') ==
      {%Trie{children: %{}, frequency: 1, word_count: 1, key: ?b},
       %Trie{children: %{?a => %Trie{children: %{}, frequency: 0, word_count: 1, key: ?a}},
        frequency: 0, word_count: 0, key: nil}}
    assert Trie.pop(t, "ab") ==
      {%Trie{children: %{}, frequency: 1, word_count: 1, key: ?b},
       %Trie{children: %{?a => %Trie{children: %{}, frequency: 0, word_count: 1, key: ?a}},
        frequency: 0, word_count: 0, key: nil}}
  end

  test "popping from a node with a nil, empty binary or empty list key" do
    t = Trie.put_word("a")
    assert Trie.pop(t, nil) == {nil, %{}}
    assert Trie.pop(t, "") == {nil, %{}}
    assert Trie.pop(t, '') == {nil, %{}}
  end

  test "popping from a nil object" do
    assert Trie.pop(nil, nil) == {nil, %{}}
    assert Trie.pop(nil, 'a') == {nil, %{}}
    assert Trie.pop(nil, "a") == {nil, %{}}
    assert Trie.pop(nil, '') == {nil, %{}}
    assert Trie.pop(nil, "") == {nil, %{}}
  end

  test "get_and_update and popping a node" do
    t = Trie.put_word("a")
    assert Trie.get_and_update(t, "a", fn(_key) -> :pop end) ==
      {%Trie{children: %{}, frequency: 1, word_count: 1, key: ?a},
       %Trie{children: %{}, frequency: 0, word_count: 0, key: nil}}
  end

  test "square brackets access" do
    t = Trie.put_word("ab") |> Trie.add("ac") |> Trie.add("ad")
    assert t['a'] == Trie.get(t, 'a')
    assert t['ab'] == Trie.get(t, 'ab')
    assert t['ac'] == Trie.get(t, 'ac')
    assert t['ad'] == Trie.get(t, 'ad')
  end

  test "Access.get_in compatibility" do
    t = Trie.put_word("abc")
    assert Trie.get(t, 'a') == get_in(t, 'a')
    assert Trie.get(t, 'ab') == get_in(t, 'ab')
    assert Trie.get(t, 'abc') == get_in(t, 'abc')
  end

  test "Access.pop_in compatibility" do
    t = Trie.put_word("ab") |> Trie.add("ac") |> Trie.add("ad")
    {_, t} = pop_in(t, ['ac'])
    assert Map.keys(Trie.get(t, 'a').children) == 'bd'
  end

  test "Access.put_in compatibility" do
    t = Trie.put_word("ab") |> Trie.add("ac")
    t = put_in(t["ad"], %Trie{key: ?d, frequency: 0, word_count: 0, children: %{}})
    assert Map.keys(Trie.get(t, 'a').children) == 'bcd'
  end

  test "Access.update_in compatibility" do
    t = Trie.put_word("ab")
    expected = %Trie{key: ?b, frequency: 10, word_count: 0, children: %{}}
    t = update_in(t, ['ab'], fn(_v) -> expected end)
    assert Trie.get(t, 'ab') == expected
  end
end
