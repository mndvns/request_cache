defmodule RequestCache.MixProject do
  use Mix.Project

  def project do
    [
      app: :request_cache,
      version: "0.1.3",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      description: "A cache local to Plug requests",
      package: package(),
      deps: deps(),
    ]
  end

  defp package do
    [
      name: :request_cache,
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mndvns/request_cache"}
    ]
  end

  def application do
    [
      extra_applications: [:logger, :con_cache]
    ]
  end

  defp deps do
    [
      {:con_cache, "~> 0.13.1"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:uuid, "~> 1.1"}
    ]
  end
end
