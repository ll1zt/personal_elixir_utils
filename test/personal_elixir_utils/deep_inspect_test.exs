defmodule PersonalElixirUtils.DeepInspectTest do
  use ExUnit.Case, async: true
  alias PersonalElixirUtils.DeepInspect

  defmodule User do
    defstruct [:id, :name, :profile]
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
        profile: %{bio: "Exilir lover", tags: ["fp", "beam"]}
      }

      result = DeepInspect.clip_depth(data, 1)
      assert %User{} = result
      assert result.id == 1
      assert result.profile == ":…"

      result = DeepInspect.clip_depth(data, 2)
      assert result.profile.bio == "Exilir lover"
      assert result.profile.tags == ":…"
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
  end
end
