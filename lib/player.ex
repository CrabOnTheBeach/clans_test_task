defmodule Player do
    defstruct player_name: "", clan_name: :nil

    def new(player_name, clan_name \\ :nil) do
        if player_name == "" do
            {:error, :incorrect_name}
        else
            {:ok, %{name: player_name, clan_name: clan_name}}
        end
    end
end