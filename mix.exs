defmodule PdfPal.MixProject do
  use Mix.Project

  def project do
    [
      app: :pdf_pal,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:floki, "~> 0.20.4"}
    ]
  end
end
