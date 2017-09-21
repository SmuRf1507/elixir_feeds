defmodule Rumbl.Repo.Migrations.AddAccountnameToFeeds do
  use Ecto.Migration

  def change do
    alter table(:feeds) do
      add :account_name, :string
    end
  end
end
