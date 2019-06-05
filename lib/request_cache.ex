defmodule RequestCache do
  use RequestCache.Wrapper

  def clear() do
    delete(state_uuid())
  end

  def count() do
    length(list(:structs))
  end

  def list(group \\ :structs)

  def list(:all) do
    req_id = state_uuid()

    ets()
    |> :ets.tab2list()
    |> Enum.find_value([], fn {k, v} -> if k == req_id, do: v end)
  end

  def list(:structs) do
    list(:all)
    |> Stream.reject(fn {k, _} -> is_binary(k) end)
    |> Stream.map(fn {_, v} -> v end)
    |> Enum.into([])
  end

  def list(:references) do
    list(:all)
    |> Stream.filter(fn {k, _} -> is_binary(k) end)
    |> Stream.map(fn {_, v} -> v end)
    |> Enum.into([])
  end

  def find(%{__struct__: mod} = var) do
    find(mod, Map.from_struct(var))
  end

  def find(mod) do
    find(mod, %{})
  end

  def find(mod, args) do
    handle = fn mod, args, _key -> struct(mod, args) end
    find(mod, args, handle)
  end

  def find(mod, args, handle) do
    key_parts = {mod, args}
    key = state_encode_key(key_parts)

    case state_has_key?(key) do
      false -> handle.(mod, args, key)
      true -> state_get(key)
    end
    |> (&state_get_struct(mod, &1)).()
    |> (&state_put(key, mod, &1)).()
  end

  def remove(%{__struct__: mod, id: id}) do
    case state_has_key?({mod, id}) do
      true -> state_delete({mod, id})
      _ -> nil
    end
  end

  defp state_all() do
    req_id = state_uuid()
    state = get(req_id)
    state || %{}
  end

  defp state_get(key) do
    Map.get(state_all(), key)
  end

  defp state_get_struct(mod, %{__struct__: mod} = val) do
    val
  end

  defp state_get_struct(mod, %{} = conf) do
    struct(mod, conf)
  end

  defp state_get_struct(mod, {mod, id}) do
    state_get_struct(mod, id)
  end

  defp state_get_struct(mod, id) do
    case state_get({mod, id}) do
      %{__struct__: _} = val -> val
      %{} = conf -> struct(mod, conf)
      other -> other
    end
  end

  defp state_put(key, val) do
    state = state_all()
    updated = Map.put(state, key, val)
    put(state_uuid(), updated)
  end

  defp state_put(key, mod, list) when is_list(list) do
    Enum.map(list, &state_put(key, mod, &1))
  end

  defp state_put(key, mod, %{__struct__: mod, id: id} = val) do
    state_put(key, {mod, id})
    state_put({mod, id}, val)
    val
  end

  defp state_put(_key, mod, {mod, id} = val) do
    state_get({mod, id})
    val
  end

  defp state_delete(key) do
    state = state_all()
    updated = Map.delete(state, key)
    put(state_uuid(), updated)
  end

  defp state_has_key?(key) do
    Map.has_key?(state_all(), key)
  end

  defp state_encode_key(term) do
    :crypto.hash(:sha256, :erlang.term_to_binary(term)) |> Base.encode64()
  end

  def state_uuid() do
    Process.get(:request_cache_id, UUID.uuid4())
  end
end
