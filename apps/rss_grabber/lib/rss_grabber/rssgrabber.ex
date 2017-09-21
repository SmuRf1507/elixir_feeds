defmodule RssGrabber.Rssgrabber do
  import SweetXml
  alias RssGrabber.Feeds

  def start_link(url, query_ref, owner, limit) do
    Task.start_link(__MODULE__, :fetch, [url, query_ref, owner, limit])
  end

  def fetch({id, url}, query_ref, owner, limit) do
    try do
      # try to fetch the latest items
      {:ok, xml} = url |> fetch_xml()
      xml
        |> xml_mapping(limit)
        |> sanitize_results([])
        |> send_results(query_ref, owner, url, id)
    rescue
      # or catch error when it fails / Send Error to User
      e in RssGrabber.UrlError ->
        IO.puts(e.message)
        send(owner, {:error, query_ref, e.message})
    end
  end

  # No results, return with :empty
  defp send_results(nil, query_ref, owner, url, id) do
    send(owner, {:results, query_ref, {:empty, []}})
  end

  # Return found items
  defp send_results(items, query_ref, owner, url, id) do
    results = %Feeds{url: url, id: id, items: items}
    send(owner, {:results, query_ref, results})
  end

  # Fetch the XML for a given URL
  defp fetch_xml(url) do
    case :httpc.request(String.to_char_list(url)) do
      {:ok, {_, _, body}} ->
        # Return result
        {:ok, body}
      {:error, _} ->
        # On Error, raise URL Error
        raise RssGrabber.UrlError
    end
  end

  # returns a list of items, parsed from XML
  defp xml_mapping(xml, limit) do
    result = xml |> xpath(
      ~x"//item"l,
      title: ~x"./title/text()",
      link: ~x"./link/text()",
      description: ~x"./description/text()",
      pubDate: ~x"./pubDate/text()")
    |> Enum.sort(&(&1.pubDate >= &2.pubDate))
    |> Enum.take(limit)
    result
  end

  # gets rid of unwanted html in the responses
  defp sanitize_results([item | tail], results) do
    result = %{title: HtmlSanitizeEx.strip_tags(to_string(item.title)),
              link: HtmlSanitizeEx.strip_tags(to_string(item.link)),
              description: HtmlSanitizeEx.markdown_html(to_string(item.description)),
              pubDate: HtmlSanitizeEx.strip_tags(to_string(item.pubDate))}

    sanitize_results(tail, results ++ [result])
  end

  # End recursion and return results
  defp sanitize_results([], results) do
    results
  end

  #defp app_id, do: Application.get_env(:info_sys, :wolfram)[:app_id]
end
