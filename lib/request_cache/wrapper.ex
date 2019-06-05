defmodule RequestCache.Wrapper do
  @omit ~w(__struct__ start_link start)a
  @funs ConCache.__info__(:functions) |> Keyword.drop(@omit)

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [funs: @funs, opts: opts], location: :keep do
      @opts opts

      for {fun, arity} <- funs do
        args = 1..arity |> Enum.map(&Macro.var(:"arg_#{&1}", nil)) |> tl()

        def unquote(fun)(unquote_splicing(args)) do
          ConCache.unquote(fun)(__MODULE__, unquote_splicing(args))
        end

        defoverridable [{fun, arity - 1}]
      end

      def start_link(gen_server_options \\ []) do
        [
          global_ttl: 1_000,
          ttl_check_interval: 250,
          ets_options: [read_concurrency: true]
        ]
        |> Keyword.merge(@opts)
        |> Keyword.merge(gen_server_options)
        |> Keyword.put(:name, __MODULE__)
        |> ConCache.start_link()
      end
    end
  end
end
