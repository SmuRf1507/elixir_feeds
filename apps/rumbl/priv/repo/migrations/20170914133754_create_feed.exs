defmodule Rumbl.Repo.Migrations.CreateFeed do
  use Ecto.Migration

  def change do
    create table(:feed) do
      add :url, :string
      add :title, :string
      add :description, :string
      add :slug, :string

      timestamps()
    end

  end
end
