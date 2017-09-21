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

  # Manage Feeds Page
  def index(conn, _params, user) do
    feeds = get_user_feeds(user)
    render(conn, "index.html", feeds: feeds)
  end

  # Feeds Page
  def list(conn, _params, user) do
    # get the users accociated feeds and their items
    u = get_user_feed_items(user)

    render(conn, "list.html", feeds: u.feeds)
  end

  # New Feed Page
  def new(conn, _params, user) do
    changeset = Feed.changeset(%Feed{})
    render(conn, "new.html", changeset: changeset)
  end

  # Feed Page
  def show(conn, %{"id" => id}, user) do
    feed = Repo.get!(Feed, id) |> Repo.preload(:latest_feed_item)
    render(conn, "show.html", feed: feed)
  end

  # User creates a new Feed, if feed already exsists - Only the association is build
  def create(conn, %{"feed" => feed_params}, user) do
    # Get User record and preload feeds
    u = Repo.get(User, user.id) |> Repo.preload(:feeds)

    # Check if Feed URL already exsists
    feed = Repo.get_by(Feed, url: feed_params["url"])
    if feed do
      # URL already on record, update user feed association
      case save_new_user_feed_assoc(u, feed) do
        {:ok, resp} ->
          conn
            |> put_flash(:info, "Feed successfully saved.")
            |> redirect(to: feed_path(conn, :index))
        {:error, changeset} ->
          render(conn, "new.html", changeset: changeset)
      end
    else
      # Feed not on record, create changeset for new feed
      feed_changeset = Feed.creation_changeset(%Feed{}, Map.put(feed_params, "user", u))
      # check if feed returns valid results
      case get_latest_posts(feed_changeset.changes.url, 3) do
        {:ok, item_list} ->
          # Received valid result
          # Insert new feet into db
          case Repo.insert(feed_changeset) do
            {:ok, feed} ->
              # After Feed is created, save all the returned results as LatestFeedItems
              case create_and_save_posts(item_list, feed) do
                {:ok} ->
                  conn
                    |> put_flash(:info, "Feed created successfully.")
                    |> redirect(to: feed_path(conn, :index))
                {:error} ->
                  render(conn, "new.html", changeset: feed_changeset)
              end
            # Display Error
            {:error, feed_changeset} ->
              render(conn, "new.html", changeset: feed_changeset)
          end
      end
    end
  end

  # When a User deletes a Feed, only the association is deleted, not the feed itself
  def delete(conn, %{"id" => id}, user) do
    # Cast into ID from Permalink
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
    #Logger.debug "### Feed: #{inspect(feed_url)}"
    case RssGrabber.getXML({0, feed_url}, [limit: limit]) do
      {:ok, feed} ->
        # return only items
        {:ok, feed.items}
      {:error, reason} ->
        # return error
        {:error, reason}
    end
  end

  # Recursive function to list all item changesets for creation
  defp create_and_save_posts([head | tail], feed, i \\ 1) do
    item = %{
      link: head.link,
      title: head.title,
      description: head.description,
      pubDate: head.pubDate,
      sort_order: to_string(i)
    }

    # Build association with feed on item struct and insert item
    feed_item = Ecto.build_assoc(feed, :latest_feed_item, item)
    Repo.insert!(feed_item)

    # Recursion to insert all remaining
    create_and_save_posts(tail, feed, i + 1)
  end

  # End recursion, save all items
  defp create_and_save_posts([], feed, i) do
    # after all changesets are created, save the list
    {:ok}
  end

  # Update the User-Feed association
  defp save_new_user_feed_assoc(user, feed) do
    user_changeset = user
                  |> Ecto.Changeset.change
                  |> Ecto.Changeset.put_assoc(:feeds, user.feeds ++ [feed])

    Repo.update(user_changeset)
  end

  # Delete all Feeds, only for testing purposes.. only works when all associations are gone
  def delete_all(struct_list) do
    for struct <- struct_list do
      Repo.delete(struct)
    end
  end

  # preload the users feeds
  defp get_user_feed_items(user) do
    user |> Repo.preload([{:feeds, :latest_feed_item}])
  end  

end
