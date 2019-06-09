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
    t = Trie.put_words(~w{hello hi there})
    assert Trie.word_count(t) == 3
  end

  test "load words with frequencies" do
    assert Trie.put_words([{"a", 2}, {"b", 3}, {"c", 4}]) == %Trie{
             children: %{
               97 => %Trie{children: %{}, frequency: 2, key: ?a},
               98 => %Trie{children: %{}, frequency: 3, key: ?b},
               99 => %Trie{children: %{}, frequency: 4, key: ?c}
             },
             frequency: 0,
             key: nil
           }
  end

  test "words function returns the originally loaded words" do
    words = [
      "damn",
      "dang",
      "hello",
      "helm",
      "hey",
      "hi",
      "oh",
      "ohh",
      "ohhhhhh"
    ]

    t = Trie.put_words(words)
    assert Enum.sort(Trie.words(t)) == Enum.sort(words)
  end

  test "searching with existing string prefixes" do
    words = [
      "damn",
      "dang",
      "hello",
      "helm",
      "hey",
      "hi",
      "oh",
      "ohh",
      "ohhhhhh"
    ]

    t = Trie.put_words(words)

    assert Enum.sort(Trie.search(t, "h")) ==
             Enum.sort(["hi", "hey", "helm", "hello"])

    assert Enum.sort(Trie.search(t, "he")) ==
             Enum.sort(["hey", "helm", "hello"])

    assert Enum.sort(Trie.search(t, "hel")) ==
             Enum.sort(["helm", "hello"])

    assert Enum.sort(Trie.search(t, "d")) ==
             Enum.sort(["dang", "damn"])

    assert Enum.sort(Trie.search(t, "da")) ==
             Enum.sort(["dang", "damn"])

    assert Enum.sort(Trie.search(t, "dam")) == ["damn"]

    assert Enum.sort(Trie.search(t, "dan")) == ["dang"]

    assert Enum.sort(Trie.search(t, "o")) ==
             Enum.sort(["ohhhhhh", "ohh", "oh"])

    assert Enum.sort(Trie.search(t, "oh")) ==
             Enum.sort(["ohhhhhh", "ohh", "oh"])

    assert Enum.sort(Trie.search(t, "ohh")) ==
             Enum.sort(["ohhhhhh", "ohh"])

    assert Enum.sort(Trie.search(t, "ohhh")) == ["ohhhhhh"]
  end

  test "searching with existing charlist prefixes" do
    words = [
      "damn",
      "dang",
      "hello",
      "helm",
      "hey",
      "hi",
      "oh",
      "ohh",
      "ohhhhhh"
    ]

    t = Trie.put_words(words)

    assert Enum.sort(Trie.search(t, 'h')) ==
             Enum.sort(["hi", "hey", "helm", "hello"])

    assert Enum.sort(Trie.search(t, 'he')) ==
             Enum.sort(["hey", "helm", "hello"])

    assert Enum.sort(Trie.search(t, 'hel')) ==
             Enum.sort(["helm", "hello"])

    assert Enum.sort(Trie.search(t, 'd')) ==
             Enum.sort(["dang", "damn"])

    assert Enum.sort(Trie.search(t, 'da')) ==
             Enum.sort(["dang", "damn"])

    assert Enum.sort(Trie.search(t, 'dam')) == ["damn"]

    assert Enum.sort(Trie.search(t, 'dan')) == ["dang"]

    assert Enum.sort(Trie.search(t, 'o')) ==
             Enum.sort(["ohhhhhh", "ohh", "oh"])

    assert Enum.sort(Trie.search(t, 'oh')) ==
             Enum.sort(["ohhhhhh", "ohh", "oh"])

    assert Enum.sort(Trie.search(t, 'ohh')) ==
             Enum.sort(["ohhhhhh", "ohh"])

    assert Enum.sort(Trie.search(t, 'ohhh')) == ["ohhhhhh"]
  end

  test "search with non-existing prefix" do
    t = Trie.put_words(~w{a b c})
    assert Trie.search(t, "x") == []
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

    assert Trie.get(t, 'ab1') == %Trie{
             key: ?1,
             frequency: 1,
             children: %{}
           }

    assert Trie.get(t, 'ab2') == %Trie{
             key: ?2,
             frequency: 1,
             children: %{}
           }

    assert Trie.get(t, 'ab3') == %Trie{
             key: ?3,
             frequency: 1,
             children: %{}
           }

    refute Trie.get(t, 'ab4')
  end

  test "load 2 chars and pop the bottom leaf" do
    t = Trie.put_word("ab")
    {popped, modified} = Trie.pop(t, 'ab')

    assert popped == %Trie{
             key: ?b,
             frequency: 1,
             children: %{}
           }

    refute Trie.get(modified, 'ab')

    assert Trie.get(modified, 'a') ==
             %Trie{key: ?a, frequency: 0, children: %{}}
  end

  test "load 2 chars and get and update the bottom leaf" do
    t = Trie.put_word("ab")

    {old_val, new_val} =
      Trie.get_and_update(t, 'ab', fn cur_val ->
        {cur_val, %Trie{key: ?b, frequency: 7, children: %{}}}
      end)

    assert old_val == 'ab'

    assert Trie.get(new_val, 'ab') ==
             %Trie{key: ?b, frequency: 7, children: %{}}
  end

  test "non-printable word should result in an ArgumentError" do
    assert_raise(ArgumentError, fn ->
      Trie.put_word('ab\u0001')
    end)
  end

  test "add a binary word" do
    t = Trie.put_word("a")

    assert Trie.add(t, "b") ==
             %Trie{
               children: %{
                 ?a => %Trie{
                   children: %{},
                   frequency: 1,
                   key: ?a
                 },
                 ?b => %Trie{
                   children: %{},
                   frequency: 1,
                   key: ?b
                 }
               },
               frequency: 0,
               key: nil
             }
  end

  test "add a list word" do
    t = Trie.put_word("a")

    assert Trie.add(t, 'b') ==
             %Trie{
               children: %{
                 ?a => %Trie{
                   children: %{},
                   frequency: 1,
                   key: ?a
                 },
                 ?b => %Trie{
                   children: %{},
                   frequency: 1,
                   key: ?b
                 }
               },
               frequency: 0,
               key: nil
             }
  end

  test "add an empty list word" do
    t = Trie.put_word("a")

    assert Trie.add(t, '', 2) ==
             %Trie{
               children: %{
                 ?a => %Trie{
                   children: %{},
                   frequency: 1,
                   key: ?a
                 }
               },
               frequency: 2,
               key: nil
             }
  end

  test "add a word with usage count" do
    t = Trie.put_word("a")

    assert Trie.add(t, "a", 3) ==
             %Trie{
               children: %{
                 97 => %Trie{
                   children: %{},
                   frequency: 4,
                   key: ?a
                 }
               },
               frequency: 0,
               key: nil
             }
  end

  test "fetching a node via binary key" do
    t = Trie.put_word("a")

    assert Trie.fetch(t, "a") ==
             {:ok, %Trie{key: ?a, frequency: 1, children: %{}}}
  end

  test "fetching with an empty key" do
    t = Trie.put_word("a")
    assert Trie.fetch(t, '') == {:ok, t}
  end

  test "getting with an empty key" do
    t = Trie.put_word("a")
    assert Trie.get(t, '') == t
  end

  test "popping a single letter key" do
    t = Trie.put_word("a")

    assert Trie.pop(t, 'a') ==
             {%Trie{children: %{}, frequency: 1, key: ?a},
              %Trie{children: %{}, frequency: 0, key: nil}}

    assert Trie.pop(t, "a") ==
             {%Trie{children: %{}, frequency: 1, key: ?a},
              %Trie{children: %{}, frequency: 0, key: nil}}
  end

  test "popping a multiple letter key" do
    t = Trie.put_word("ab")

    expected_popped = %Trie{
      children: %{},
      frequency: 1,
      key: ?b
    }

    expected_modified = %Trie{
      children: %{
        ?a => %Trie{
          children: %{},
          frequency: 0,
          key: ?a
        }
      },
      frequency: 0,
      key: nil
    }

    assert Trie.pop(t, 'ab') == {expected_popped, expected_modified}

    assert Trie.pop(t, "ab") == {expected_popped, expected_modified}
  end

  test "popping from a node with a nil, empty binary or empty list key" do
    t = Trie.put_word("a")
    assert Trie.pop(t, "") == {nil, %{}}
    assert Trie.pop(t, '') == {nil, %{}}
  end

  test "get_and_update and popping a node" do
    t = Trie.put_word("a")

    assert Trie.get_and_update(t, "a", fn _key -> :pop end) ==
             {%Trie{children: %{}, frequency: 1, key: ?a},
              %Trie{children: %{}, frequency: 0, key: nil}}
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

    t =
      put_in(t["ad"], %Trie{
        key: ?d,
        frequency: 0,
        children: %{}
      })

    assert Map.keys(Trie.get(t, 'a').children) == 'bcd'
  end

  test "Access.update_in compatibility" do
    t = Trie.put_word("ab")
    expected = %Trie{key: ?b, frequency: 10, children: %{}}
    t = update_in(t, ['ab'], fn _v -> expected end)
    assert Trie.get(t, 'ab') == expected
  end
end
