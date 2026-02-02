defmodule PersonalElixirUtils.DeepInspectTest do
  use ExUnit.Case, async: true
  alias PersonalElixirUtils.DeepInspect

  defmodule User do
    defstruct [:id, :name, :profile]
  end

  describe "first_element/2" do
    test "extracts from list at various indices" do
      data = [:a, :b, :c]
      assert DeepInspect.first_element(data, 0) == :a
      assert DeepInspect.first_element(data, 1) == :b
      assert DeepInspect.first_element(data, 5) == nil
    end

    test "extracts from tuple at various indices" do
      data = {:x, :y, :z}
      assert DeepInspect.first_element(data, 0) == :x
      assert DeepInspect.first_element(data, 2) == :z
      assert DeepInspect.first_element(data, 3) == nil
    end

    test "extracts from map (returns {key, value} tuple)" do
      data = %{name: "Alice"}
      assert DeepInspect.first_element(data, 0) == {:name, "Alice"}
      assert DeepInspect.first_element(%{}, 0) == nil
    end

    test "returns error tuple for non-collections" do
      assert DeepInspect.first_element(123) ==
               {:error, "input data is not a collection or unsupported"}

      assert DeepInspect.first_element(nil) ==
               {:error, "input data is not a collection or unsupported"}
    end
  end

  describe "clip_first_element/3" do
    test "extracts a sub-structure and clips its depth" do
      data = [
        %{
          level1: %{
            level2: %{
              level3: :val
            }
          }
        },
        :other
      ]

      result = DeepInspect.clip_first_element(data, 2, 0)

      expected = %{
        level1: %{
          level2: ":…"
        }
      }

      assert result == expected
    end
  end

  describe "clip_depth/2" do
    test "returns placeholder when max_depth is 0" do
      assert DeepInspect.clip_depth(%{a: 1}, 0) == ":…"
      assert DeepInspect.clip_depth([1, 2, 3], 0) == ":…"
      assert DeepInspect.clip_depth({1, 2}, 0) == ":…"
    end

    test "leaves simple types untouched" do
      assert DeepInspect.clip_depth(123, 2) == 123
      assert DeepInspect.clip_depth("hello", 2) == "hello"
      assert DeepInspect.clip_depth(:ok, 2) == :ok
      assert DeepInspect.clip_depth(nil, 2) == nil
    end

    test "handles empty collections" do
      assert DeepInspect.clip_depth([], 2) == []
      assert DeepInspect.clip_depth(%{}, 2) == %{}
      assert DeepInspect.clip_depth({}, 2) == {}
    end

    test "clips nested lists correctly" do
      data = [1, [2, [3, [4]]]]
      assert DeepInspect.clip_depth(data, 1) == [1, ":…"]
      assert DeepInspect.clip_depth(data, 2) == [1, [2, ":…"]]
    end

    test "clips nested maps correctly" do
      data = %{a: 1, b: %{c: 2, d: %{e: 3}}}
      assert DeepInspect.clip_depth(data, 1) == %{a: 1, b: ":…"}
      assert DeepInspect.clip_depth(data, 2) == %{a: 1, b: %{c: 2, d: ":…"}}
    end

    test "clips nested tuples correctly" do
      data = {1, {2, {3, 4}}}
      assert DeepInspect.clip_depth(data, 1) == {1, ":…"}
      assert DeepInspect.clip_depth(data, 2) == {1, {2, ":…"}}
    end

    test "handles structs while preserving the module name" do
      data = %User{
        id: 1,
        name: "Alice",
        profile: %{bio: "Elixir lover", tags: ["fp", "beam"]}
      }

      result = DeepInspect.clip_depth(data, 1)
      assert %User{} = result
      assert result.id == 1
      assert result.profile == ":…"

      result = DeepInspect.clip_depth(data, 2)
      assert result.profile.bio == "Elixir lover"
      assert result.profile.tags == ":…"
    end

    test "handles system structs like Date" do
      date = ~D[2023-01-01]
      assert DeepInspect.clip_depth(date, 0) == ":…"
      assert DeepInspect.clip_depth(date, 1) == date
    end

    test "clips complex map keys" do
      data = %{%{key_depth_1: %{key_depth_2: :val}} => "value"}

      assert DeepInspect.clip_depth(data, 1) == %{":…" => "value"}

      expected = %{%{key_depth_1: ":…"} => "value"}
      assert DeepInspect.clip_depth(data, 2) == expected
    end

    test "handles keyword lists (as they are lists of tuples)" do
      data = [a: 1, b: [c: 2]]
      assert DeepInspect.clip_depth(data, 1) == [a: 1, b: ":…"]
    end

    test "mixed nested structures" do
      data = [a: :ok, b: %{"key1" => "value1", "key2" => {"value2.1", "value2.2"}}]
      assert DeepInspect.clip_depth(data, 1) == [a: :ok, b: ":…"]
      assert DeepInspect.clip_depth(data, 2) == [a: :ok, b: %{"key1" => "value1", "key2" => ":…"}]
    end

    test "ignores PID, Port, and Functions (treated as simple types)" do
      pid = self()
      fun = fn -> :ok end
      assert DeepInspect.clip_depth(pid, 1) == pid
      assert DeepInspect.clip_depth(fun, 1) == fun
    end

    test "handles non-printable binaries (Bitstrings)" do
      data = <<1, 2, 3, 4>>
      assert DeepInspect.clip_depth(data, 1) == data
    end
  end
end
