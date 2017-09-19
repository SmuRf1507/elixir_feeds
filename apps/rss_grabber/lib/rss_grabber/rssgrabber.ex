defmodule RssGrabber.Rssgrabber do
  import SweetXml
  alias RssGrabber.Feeds

  def start_link(url, query_ref, owner, limit) do
    Task.start_link(__MODULE__, :fetch, [url, query_ref, owner, limit])
  end

  def fetch({id, url}, query_ref, owner, limit) do
    url
    |> fetch_xml()
    |> xml_mapping(limit)
    |> send_results(query_ref, owner, url, id)
  end

  defp send_results(nil, query_ref, owner, url, id) do
    send(owner, {:results, query_ref, []})
  end

  defp send_results(items, query_ref, owner, url, id) do
    results = [%Feeds{url: url, id: id, items: items}]
    send(owner, {:results, query_ref, results})
  end

  defp fetch_xml(url) do
    {:ok, {_, _, body}} = :httpc.request(
      String.to_char_list(url))
      body
  end

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

  #defp app_id, do: Application.get_env(:info_sys, :wolfram)[:app_id]
end
