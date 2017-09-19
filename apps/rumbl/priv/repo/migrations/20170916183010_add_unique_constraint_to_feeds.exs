defmodule Rumbl.Repo.Migrations.AddUniqueConstraintToFeeds do
  use Ecto.Migration

  def change do
    create unique_index(:feeds, [:url])
  end
end
