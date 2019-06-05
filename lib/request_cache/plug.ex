defmodule RequestCache.Plug do
  def init(_opts), do: []

  def call(conn, _opts) do
    Process.put(:request_cache_id, UUID.uuid4())
    conn
  end
end
