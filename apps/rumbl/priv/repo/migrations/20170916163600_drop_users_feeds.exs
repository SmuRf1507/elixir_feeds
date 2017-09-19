defmodule Rumbl.Repo.Migrations.DropUsersFeeds do
  use Ecto.Migration

  def change do
    drop table(:users_feeds)
  end
end
