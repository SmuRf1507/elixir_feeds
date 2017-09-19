defmodule Rumbl.Repo.Migrations.CreateUsersFeedsTable do
  use Ecto.Migration

  def change do
    create table(:users_feeds) do
      add :feed_id, references(:feeds)
      add :user_id, references(:users)
    end

    create unique_index(:users_feeds, [:feed_id, :user_id])
  end
end
