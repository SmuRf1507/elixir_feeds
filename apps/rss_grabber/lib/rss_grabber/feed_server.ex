defmodule RssGrabber.FeedServer do
  use GenServer
  require Logger

  # initial values {feed url, last feed link, feed db id, new feed tupl}
  # {feed, link, feed_id, newfeed}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(state) do
    # Start to check for new feed
    IO.puts "### Feed Server: Started"
    Process.send_after(self(), :check_for_update, 3000)
    {:ok, state}
  end

  def handle_call(:val, _from, state) do
    IO.puts "### Current Process state is: #{state}"
    {:reply, state, state}
  end

  def handle_cast(:incoming_feed, status) do
    {:noreply, status}
  end

  # Check for new feed on url
  def handle_info(:check_for_update, {feed_url, link, feed_id, newfeed}) do
    feed = RssGrabber.getXML({feed_id, feed_url}, [limit: 1])
    item = List.first(feed.items)

    Process.send_after(self(), :check_for_update, 3000)

    new_link = to_string(item.link)
    if(to_string(link) == new_link) do
      # no new entry
      IO.puts "### Feed Server: No new feed for #{feed_url}"
      {:noreply, {feed_url, link, feed_id, newfeed}}
    else
      # notify of new entry for feed
      IO.puts "### Feed Server: New feed for #{feed_url}"
      IO.puts "### Feed Server: New feed link #{item.link}"

      RssGrabber.FeedChannel.broadcast_new_post(%{id: feed.id, link: new_link, title: item.title, description: item.description, pubDate: item.pubDate})
      # update process state to new feed entry
      {:noreply, {feed_url, new_link, feed_id, item}}
    end
  end
end
