defmodule Rumbl.Repo.Migrations.FixFeedDescriptionType do
  use Ecto.Migration

  def change do
      alter table(:latest_feed_items) do
        remove :description
      end
      alter table(:latest_feed_items) do
        add :description, :text
      end
  end
end
