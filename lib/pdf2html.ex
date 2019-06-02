defmodule Pdf2html do
  def convert(pdf, html, opts \\ []) do
    pdf = String.replace(pdf, " ", "\ ")
    cmd = Application.get_env(:pdf2html, :executable, System.find_executable("pdf2htmlEX"))
    opts = parse_opts(opts) ++ [pdf, html]
    {msg, exit_status} = System.cmd(cmd, opts)
    if exit_status != 0 do
      raise RuntimeError, message: "The command line tool reported an error: #{msg}"
    end
  end

  defp parse_opts(opts) do
    Enum.flat_map(opts, fn {name, arg} ->
      parse_opt(name, arg)
    end)
  end

  @bool_opt_name [
    :embed_font,
    :embed_image,
    :optimize_text
  ]

  defp parse_opt(opt_name, bool) when opt_name in @bool_opt_name do
    [parse_opt_name(opt_name), parse_bool_opt(bool)]
  end

  defp parse_opt(opt_name, opt_value) do
    [parse_opt_name(opt_name), to_string(opt_value)]
  end

  defp parse_bool_opt(bool) do
    if bool do
      "1"
    else
      "0"
    end
  end

  defp parse_opt_name(opt_name) do
    dash_name =
      opt_name
      |> to_string()
      |> String.replace("_", "-")
    "--#{dash_name}"
  end
end
