defmodule OpenStax.TempAuth.Mixfile do
  use Mix.Project

  def project do
    [app: :openstax_tempauth,
     version: "0.1.0",
     elixir: "~> 1.3",
     elixirc_paths: elixirc_paths(Mix.env),
     description: "OpenStack TempAuth client",
     maintainers: ["Marcin Lewandowski"],
     licenses: ["MIT"],
     name: "OpenStax.TempAuth",
     source_url: "https://github.com/mspanc/openstax_tempauth",
     package: package(),
     preferred_cli_env: [espec: :test],
     deps: deps()]
  end


  def application do
    [applications: [:crypto, :httpoison, :logger],
     mod: {OpenStax.TempAuth, []}]
  end


  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib",]


  defp deps do
    [
      {:httpoison, "~> 0.10"},
      {:poison, "~> 2.0" },
      {:connection, "~> 1.0"},
      {:espec, "~> 0.8.17", only: :test},
      {:ex_doc, "~> 0.11.4", only: :dev},
      {:earmark, ">= 0.0.0", only: :dev}
    ]
  end


  defp package do
    [description: "OpenStack TempAuth client",
     files: ["lib",  "mix.exs", "README*", "LICENSE"],
     maintainers: ["Marcin Lewandowski"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/mspanc/openstax_tempauth"}]
  end
end
