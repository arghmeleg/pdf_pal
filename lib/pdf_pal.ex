defmodule PdfPal do
  @opts [
    zoom: 2,
    embed_font: false,
    embed_image: false,
    optimize_text: true,
    bg_format: "jpg"
  ]

  def run(path_to_pdfs \\ "pdfs", destination_dir \\ "htmls", filename \\ "index.html") do
    path_to_pdfs
    |> File.ls!()
    |> Enum.map(&Path.join(path_to_pdfs, &1))
    |> Enum.each(fn path_to_pdf ->
      IO.puts(path_to_pdf)
      process(path_to_pdf, destination_dir, filename)
    end)
  end

  def process(path_to_pdf, destination_dir \\ "htmls", filename \\ "index.html") do
    dest_dir_name = Path.join(destination_dir, to_url_name(path_to_pdf))
    convert(path_to_pdf, dest_dir_name, filename)
    clean(Path.join(dest_dir_name, filename))
  end

  defp convert(path_to_pdf, destination_dir, filename) do
    opts = Keyword.put(@opts, :dest_dir, destination_dir)
    File.mkdir_p(destination_dir)
    Pdf2html.convert(path_to_pdf, filename, opts)
  end

  defp clean(filename) do
    dirname = Path.dirname(filename)

    image_files =
      dirname
      |> File.ls!()
      |> Enum.filter(fn name -> name =~ ~r/\.jpeg|\.jpg/ end)

    if System.find_executable("jpegoptim") do
      Enum.each(image_files, fn name -> System.cmd("jpegoptim", [Path.join(dirname, name)]) end)
    else
      IO.puts "jpegoptim not found, skipping image optimization."
    end

    dup_images =
      image_files
      |> Enum.reduce(%{}, fn name, acc ->
        name = Path.join(dirname, name)
        data = File.read!(name)
        hash = :md5 |> :crypto.hash(data) |> Base.encode16(case: :lower)
        Map.put(acc, hash, (acc[hash] || []) ++ [name])
      end)
      |> Enum.filter(fn {_hash, list} -> Enum.count(list) > 1 end)
      |> Enum.map(fn {_hash, list} -> list end)

    content =
      filename
      |> File.read!()
      |> Floki.filter_out(:comment)
      |> Floki.raw_html()
      |> remove_dup_images(dup_images)
      |> html_replace("style", &strip_comments/1)
      |> html_replace("style", &String.replace(&1, ~r/}\n/, "}"))
      |> html_replace("script", &strip_comments/1)
      |> html_replace("script", &String.replace(&1, ~r/pdf2htmlEX/, "pdfUI"))
      |> html_replace("[name='generator']", fn _e -> "" end)
      |> html_replace("[http-equiv='X-UA-Compatible']", fn _e -> "" end)
      |> html_replace("[src='pdf2htmlEX-64x64.png']", fn _e -> "" end)
      |> String.replace(~r/\n+/, "\n")
      |> add_viewport()
      |> add_html_lang()

    File.write(filename, "<!DOCTYPE html>\n#{content}")

    pdf2html_img = [Path.join(dirname, "pdf2htmlEX-64x64.png")]
    if File.exists?(pdf2html_img) do
      File.rm(pdf2html_img)
    end
  end

  defp add_html_lang(content) do
    if Enum.empty?(Floki.find(content, "html[lang]")) do
      String.replace(content, "<html", "<html lang='en'")
    else
      content
    end
  end

  defp add_viewport(content) do
    if Enum.empty?(Floki.find(content, "meta[name='viewport']")) do
      String.replace(content, "</head>", "<meta name='viewport' content='width=device-width, initial-scale=1'></head>")
    else
      content
    end
  end

  defp remove_dup_images(content, dup_images) do
    Enum.reduce(dup_images, content, fn [first_image | rest_of_images], acc ->
      first_image = Path.basename(first_image)
      Enum.reduce(rest_of_images, acc, fn image, acc2 ->
        File.rm(image)
        image = Path.basename(image)
        String.replace(acc2, image, first_image)
      end)
    end)
  end

  defp strip_comments(element) do
    element
    |> String.replace(~r/\/\*.*\*\//s, "")
    |> String.replace(~r/^\s*\/\/.*$/m, "")
  end

  defp to_url_name(name) do
    name
    |> Path.basename()
    |> String.trim_trailing(Path.extname(name))
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.replace(~r/download/, "")
    |> String.trim()
  end

  defp html_replace(content, selector, fun) do
    elements = Floki.find(content, selector)
    Enum.reduce(elements, content, fn element, acc ->
      raw_element = Floki.raw_html(element)
      new_element = fun.(raw_element)
      String.replace(acc, raw_element, new_element)
    end)
  end

end
