defmodule Rumbl.Repo.Migrations.AddUserFeedTable do
  use Ecto.Migration

  def change do
    create table(:users_feeds, primary_key: false) do
      add :user_id, references(:users)
      add :feed_id, references(:feeds)
    end
  end
end
