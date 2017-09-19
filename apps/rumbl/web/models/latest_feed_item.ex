defmodule Rumbl.LatestFeedItem do
  use Rumbl.Web, :model
  require Logger
  #@primary_key {:id, Rumbl.Permalink, autogenerate: true}

  schema "latest_feed_items" do
    field :link, :string
    field :title, :string
    field :description, :string
    field :pubDate, :string
    field :sort_value, :integer

    belongs_to :feed, Rumbl.Feed
    timestamps()
  end



  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  @optional_fields ~w()
  def changeset(struct, params \\ %{}) do
    # Changeset for Updates
    #Logger.debug("### Changeset Debug: #{inspect(params["feed"])}")
    struct
    |> cast(params, ["link", "title", "description", "pubDate", "sort_value"])
    |> put_assoc(:feed, [params["feed"]])

  end

end
