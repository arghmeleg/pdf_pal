defmodule PdfPal.MixProject do
  use Mix.Project

  @description "Easy PDF to HTML conversion."
  @version "0.1.0"

  def project do
    [
      app: :pdf_pal,
      name: "PdfPal",
      version: @version,
      description: @description,
      elixir: "~> 1.8",
      package: package(),
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/arghmeleg/pdf_pal",
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
      {:floki, "~> 0.20.4"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp package do
    %{
      maintainers: ["Steve DeGele"],
      licenses: ["MIT"],
      files: [
        "lib",
        "test",
        "mix.exs",
        "README.md",
        "LICENSE"
      ],
      links: %{
        "GitHub" => "https://github.com/arghmeleg/pdf_pal"
      }
    }
  end
end
