defmodule Rumbl.Feed do
  use Rumbl.Web, :model
  require Logger
  @primary_key {:id, Rumbl.Permalink, autogenerate: true}

  schema "feeds" do
    field :url, :string
    field :slug, :string
    field :account_name, :string
    many_to_many :users, Rumbl.User, join_through: "users_feeds", on_delete: :delete_all
    has_many :latest_feed_item, Rumbl.LatestFeedItem
    timestamps()
  end



  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  @optional_fields ~w()
  def changeset(struct, params \\ %{}) do
    # Changeset for Updates
    struct
    |> cast(params, [:url])
    |> unique_constraint(:url)
    |> slugify_url()
    |> put_assoc(:users, [params["user"]])

  end

  def creation_changeset(struct, params \\ %{}) do
    # Changeset for the creation of new Feeds
    struct
    |> cast(params, [:url])
    |> slugify_url()
    |> set_feed_name() # determine and set the feed account name
    |> update_url_if_twitter() # replaces the given twitter url with the twitrss.me link
    |> unique_constraint(:url)
    |> put_assoc(:users, [params["user"]])
  end

  # delete all given feeds, only used for testing !
  def delete_all(struct_list) do
    for struct <- struct_list do
      Repo.delete(struct)
    end
  end

  defp slugify_url(changeset) do
    url = get_change(changeset, :url)
    if url do
      #if changeset contains url, split URL and only grab the host part
      url = String.split(url, "/") |> List.first
      put_change(changeset, :slug, slugify(url))
    else
      changeset
    end
  end

  defp slugify(str) do
    str
    |> String.downcase()
    |> String.replace(~r/[^\w-]+/u, "-")
  end

  # transform the url if needed
  defp update_url_if_twitter(changeset) do
    url = get_change(changeset, :url)
    if url do
      #if twitter account
      if url =~ "twitter.com" do
        # if twitter url, set new url to twittrss with account name
        name = "https://twitrss.me/twitter_user_to_rss/?user="
        <> get_change(changeset, :account_name)
        # update the changeset
        put_change(changeset, :url, name)
      else
        changeset
      end
    end
  end

  # Set the account_name field, depending on url
  defp set_feed_name(changeset) do
    url = get_change(changeset, :url)
    if url do
      #if twitter account
      if url =~ "twitter.com" do
        # if twitter url, only grab account name from url
        name = Regex.run(~r/^(https|http):\/\/(www.twitter.com|twitter.com)\/(((@)(\w+))|(\w+))/, url) |> List.last
      else
        name = url |> String.replace(~r/^(https|http):\/\//,"")
      end
      put_change(changeset, :account_name, name)
    else
      changeset
    end
  end



end



defimpl Phoenix.Param, for: Rumbl.Feed do
  def to_param(%{slug: slug, id: id}) do
    "#{id}-#{slug}"
  end
end
