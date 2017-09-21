defmodule RssGrabber.FeedChannel do
  use Phoenix.Channel

  def join("feeds:" <> feed_id, params, socket) do
    feed_id = String.to_integer(feed_id)
    # TODO add logic to retrieve latest item for post
    resp = %{"feed" => %{
      "url" => ""
    }}
    {:ok, resp, assign(socket, :feed_id, feed_id)}
  end

  # assing user to handle event
  def handle_in(event, params, socket) do
    user = Repo.get(Rumbl.User, socket.assigns.user_id)
    handle_in(event, params, user, socket)
  end

  def handle_in("new_post", params, user, socket) do
    {:reply, :ok, socket}
  end

  def broadcast_new_post(post) do
    IO.puts "### Broadcast new Post #{post.link}"
    payload = %{
      "link" =>  to_string(post.link),
      "title" =>  to_string(post.title),
      "description" =>  to_string(post.description),
      "pubDate" => to_string(post.pubDate)
    }

    Rumbl.Endpoint.broadcast("feeds:#{post.id}", "new_post", payload)
  end

end
