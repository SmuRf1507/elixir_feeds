defmodule Rumbl.Repo.Migrations.RemoveFieldFromFeedsTable do
  use Ecto.Migration

  def change do
      alter table(:feeds) do
        remove :title
        remove :description
      end
  end
end
