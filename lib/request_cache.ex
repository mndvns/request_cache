defmodule RequestCache do
  use RequestCache.Wrapper

  def clear() do
    delete(state_uuid())
  end

  def find(%{__struct__: mod} = var) do
    find(mod, Map.from_struct(var))
  end

  def find(mod) do
    find(mod, %{})
  end

  def find(mod, args) do
    find(mod, args, nil)
  end

  def find(mod, args, ident) do
    handle = fn {mod, args, _ident, _key} -> struct(mod, args) end
    find(mod, args, ident, handle)
  end

  def find(mod, args, ident, handle) do
    key_parts = {mod, args, ident}
    key = state_encode_key(key_parts)

    case state_has_key?(key) do
      true -> state_get(key)
      false ->
        value = handle.({mod, args, ident, key})
        state_put(key, value)
        value
    end
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

  defp state_put(key, val) do
    state = state_all()
    updated = Map.put(state, key, val)
    put(state_uuid(), updated)
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
    Process.get(:request_cache_id, UUID.uuid3(:oid, inspect(self)))
  end
end
