defmodule Rumbl.Feed do
  use Rumbl.Web, :model
  require Logger
  @primary_key {:id, Rumbl.Permalink, autogenerate: true}

  schema "feeds" do
    field :url, :string
    field :slug, :string
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
    |> unique_constraint(:url)
    |> put_assoc(:users, [params["user"]])
  end

  defp slugify_url(changeset) do
    url = get_change(changeset, :url)
    if url do
      #if changeset contains url, split URL and only grab the host part
      url = String.split(url, "/") |> Enum.at(2)
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
end

defimpl Phoenix.Param, for: Rumbl.Feed do
  def to_param(%{slug: slug, id: id}) do
    "#{id}-#{slug}"
  end
end
