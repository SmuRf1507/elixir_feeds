defmodule Rumbl.Repo.Migrations.DropFeedTableCreateFeedsTable do
  use Ecto.Migration

  def change do
    drop table(:users_feeds)
    drop table(:feed)
    drop table(:feeds)

    create table(:feeds) do
      add :url, :string
      add :title, :string
      add :description, :string
      add :slug, :string

      timestamps()
    end

    create table(:users_feeds) do
      add :feed_id, references(:feeds)
      add :user_id, references(:users)
    end

    create unique_index(:users_feeds, [:feed_id, :user_id])





  end
end
