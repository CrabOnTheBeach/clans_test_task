defmodule Player do
    def create_player(player_name, clan_name \\ :nil) do
        if player_name == "" do
            {:error, :incorrect_name}
        else
            {:ok, %{name: player_name, clan_name: clan_name}}
        end
    end
end