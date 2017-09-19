defmodule Rumbl.Repo.Migrations.AddForeignKeysTofeedsAndUsers do
  use Ecto.Migration

  def change do
      alter table(:feeds) do
        add :user_id, :integer
      end
      alter table(:users) do
        add :feed_id, :integer
      end
  end
end
