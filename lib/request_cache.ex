defmodule RequestCache do
  # get all ConCache functions
  omit = ~w(__struct__ start_link start)a
  funs = ConCache.__info__(:functions) |> Keyword.drop(omit)

  # rewrite functions here, setting `__MODULE__` as first argument for all
  for {fun, arity} <- funs do
    args = 1..arity |> Enum.map(&Macro.var(:"arg_#{&1 - 1}", nil)) |> tl()
    def unquote(fun)(unquote_splicing(args)) do
      ConCache.unquote(fun)(__MODULE__, unquote_splicing(args))
    end
    defoverridable [{fun, arity - 1}]
  end

  def start_link(gen_server_options \\ []) do
    [
      global_ttl: Application.get_env(:request_cache, :global_ttl, 1_000),
      ttl_check_interval: Application.get_env(:request_cache, :global_ttl, 250),
      ets_options: Application.get_env(:request_cache, :ets_options, [read_concurrency: true])
    ]
    |> Keyword.put(:name, __MODULE__)
    |> Keyword.merge(gen_server_options)
    |> ConCache.start_link()
  end

  def get(key) do
    super({request_uuid(), key})
  end

  def get_or_store(key, fun) do
    super({request_uuid(), key}, fun)
  end

  def put(key, value) do
    super({request_uuid(), key}, value)
  end

  def update(key, fun) do
    super({request_uuid(), key}, fun)
  end

  def delete(key) do
    super({request_uuid(), key})
  end

  def touch(key) do
    super({request_uuid(), key})
  end

  def all() do
    uuid = request_uuid()
    ets()
    |> :ets.tab2list()
    |> Enum.reduce(%{}, fn
      {{^uuid, key}, value}, acc -> Map.put(acc, key, value)
      _, acc -> acc
    end)
  end

  def list() do
    all() |> Enum.into([])
  end

  def size() do
    all() |> map_size()
  end

  def keys() do
    all() |> Map.keys()
  end

  def values() do
    all() |> Map.values()
  end

  def clear() do
    keys() |> Enum.map(&delete/1)
    :ok
  end

  defp request_uuid() do
    Process.get(:request_cache_id, UUID.uuid3(:oid, inspect(self())))
  end
end
