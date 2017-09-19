defmodule Rumbl.FeedController do
  use Rumbl.Web, :controller
  import Ecto.Query
  require Logger
  alias Rumbl.Feed
  alias Rumbl.LatestFeedItem
  alias Rumbl.User
  alias Rumbl.Permalink, as: P

  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
  end

  def index(conn, _params, user) do
    feeds = get_user_feeds(user)
    render(conn, "index.html", feeds: feeds)
  end

  def list(conn, _params, user) do
    feeds = get_user_feeds(user)
    #Logger.debug "Var user: #{inspect(curuser)}"
    xml = RssGrabber.getXMLbatch(create_url_list(feeds, []))
    render(conn, "list.html", items: xml, feeds: feeds)
  end

  def new(conn, _params, user) do
    changeset = Feed.changeset(%Feed{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"feed" => feed_params}, user) do
    # Get User record and preload feeds
    u = Repo.get(User, user.id) |> Repo.preload(:feeds)

    # Check if Feed URL already exsists
    feed = Repo.get_by(Feed, url: feed_params["url"])
    if feed do
      # URL already on record, update user feed association
      user_changeset = u
                    |> Ecto.Changeset.change
                    |> Ecto.Changeset.put_assoc(:feeds, u.feeds ++ [feed])

      case Repo.update(user_changeset) do
        {:ok, feed} ->
          conn
            |> put_flash(:info, "Feed successfully saved.")
            |> redirect(to: feed_path(conn, :index))
        {:error, changeset} ->
          render(conn, "new.html", changeset: changeset)
      end
    else
      # check if feed returns valid results
      case get_latest_posts(feed_params["url"], 3) do
        {:ok, item_list} ->
          # Feed is valid, it can be parsed
          # Insert Feed and procceed to add items

          # Feed not on record, create changeset for new feed
          feed_changeset = Feed.creation_changeset(%Feed{}, Map.put(feed_params, "user", u))
          case Repo.insert(feed_changeset) do
            {:ok, feed} ->
              case create_and_save_posts(item_list, feed) do
                {:ok} ->
                  conn
                    |> put_flash(:info, "Feed created successfully.")
                    |> redirect(to: feed_path(conn, :index))
                {:error} ->
                  render(conn, "new.html", changeset: feed_changeset)
              end
            {:error, feed_changeset} ->
              render(conn, "new.html", changeset: feed_changeset)
          end
      end

    end
  end

  def show(conn, %{"id" => id}, user) do
    feed = Repo.get!(Feed, id)
    render(conn, "show.html", feed: feed)
  end

  def delete(conn, %{"id" => id}, user) do
    #Logger.debug "### DELETE: #{inspect(id)}"
    # cast id to integer
    {:ok, feed_id} = P.cast(id)

    # query and delete the associative record for the user feed
    query = from e in "users_feeds", where: e.feed_id == ^feed_id and e.user_id == ^user.id
    case Repo.delete_all(query) do
        {count, _} ->
          conn
          |> put_flash(:info, "Feed deleted successfully.")
          |> redirect(to: feed_path(conn, :index))
        nil ->
          conn
          |> put_flash(:info, "Error.")
          |> redirect(to: feed_path(conn, :index))
      end
  end


  ##################################
  #####                        #####
  #####   Private functions    #####
  #####                        #####
  ##################################

  defp create_url_list([head|tail], accum) do
    # recursive function to create a list with all of users feed urls
    create_url_list(tail, accum ++ [{head.id, head.url}])
  end

  defp create_url_list([], accum) do
    # return list with urls after feed list is looped
    accum
  end

  defp add_to_params(params, name, new_param) do
    Map.put(params, name, new_param)
  end

  defp user_feeds(user) do
    # associates the user with feeds
    # returns query object
    assoc(user, :feeds)
  end

  defp get_user_feeds(user) do
    # returns all feeds associated with a user
    Repo.all(assoc(user, :feeds))
  end

  # Get the [limit] amount of posts for a given feed, return found results or nil
  defp get_latest_posts(feed_url, limit) do
    feed = RssGrabber.getXML({0, feed_url}, [limit: limit])
    Logger.debug "### Feed: #{inspect(feed)}"
    case feed.items do
      [h|t] ->
        {:ok, feed.items}
      _ ->
        {:error, feed}
    end
  end

  # Recursive function to list all item changesets for creation
  defp create_and_save_posts([head | tail], feed, i \\ 1) do
    item = %{
      link: to_string(head.link),
      title: to_string(head.title),
      description: to_string(head.description),
      pubDate: to_string(head.pubDate),
      sort_order: to_string(i)
    }

    feed_item = Ecto.build_assoc(feed, :latest_feed_item, item)
    Repo.insert!(feed_item)


    #Logger.debug("### Changeset Debug: #{inspect(params["feed"])}")
    #item_changeset = LatestFeedItem.changeset(%LatestFeedItem{}, Map.put(item, "feed", post))

    create_and_save_posts(tail, feed, i + 1)
  end

  # End recursion, save all items
  defp create_and_save_posts([], feed, i) do
    # after all changesets are created, save the list
      {:ok}
  end

end
