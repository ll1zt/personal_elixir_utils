defmodule PersonalElixirUtils.DeepInspect do
  @moduledoc """
  For debugging purposes, trim the structure of the term to the maximum depth.
  """

  @placeholder ":…"

  @spec clip_depth(term(), non_neg_integer()) :: term()
  def clip_depth(data, max_depth) when is_integer(max_depth) and max_depth >= 0 do
    do_clip(data, max_depth, 0)
  end

  defp do_clip(data, max_depth, current_depth)
       when current_depth >= max_depth and (is_list(data) or is_map(data) or is_tuple(data)) do
    @placeholder
  end

  defp do_clip(%{} = map, max_depth, current_depth) do
    if is_struct(map) do
      struct_module = map.__struct__

      map
      |> Map.from_struct()
      |> Enum.map(fn {k, v} -> {k, do_clip(v, max_depth, current_depth + 1)} end)
      |> Enum.into(%{})
      |> Map.put(:__struct__, struct_module)
    else
      map
      |> Enum.map(fn {k, v} ->
        {
          do_clip(k, max_depth, current_depth + 1),
          do_clip(v, max_depth, current_depth + 1)
        }
      end)
      |> Enum.into(%{})
    end
  end

  defp do_clip(list, max_depth, current_depth) when is_list(list) do
    Enum.map(list, fn
      {k, v} ->
        {do_clip(k, max_depth, current_depth + 1), do_clip(v, max_depth, current_depth + 1)}

      item ->
        do_clip(item, max_depth, current_depth + 1)
    end)
  end

  defp do_clip(tuple, max_depth, current_depth) when is_tuple(tuple) do
    tuple
    |> Tuple.to_list()
    |> Enum.map(&do_clip(&1, max_depth, current_depth + 1))
    |> List.to_tuple()
  end

  defp do_clip(other, _max_depth, _current_depth), do: other
end
