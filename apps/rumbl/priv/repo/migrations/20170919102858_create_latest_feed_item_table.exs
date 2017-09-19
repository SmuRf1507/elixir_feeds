defmodule Rumbl.Repo.Migrations.CreateLatestFeedItemTable do
  use Ecto.Migration

  def change do
    create table(:latest_feed_items) do
      add :feed_id, references(:feeds, on_delete: :delete_all)

      add :link, :string
      add :title, :string
      add :description, :string
      add :pubDate, :string

      add :sort_value, :integer

      timestamps()
    end
    create index(:latest_feed_items, [:feed_id])
  end
end
