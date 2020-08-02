defmodule Clan do
    defstruct creator: "", name: "", tag: "", members: ""

    def create_clan(clan_creator, clan_name, clan_tag) do
        clan = %Clan{creator: clan_creator.name, name: clan_name, tag: clan_tag, members: MapSet.new()}
        add_to_clan(clan, clan_creator)
    end

    def remove_from_clan(requester, player, clan) do
        cond do
            requester.name != clan.creator && requester.name != player.name ->
                {:error, :permission_error}
            player.name == clan.creator && MapSet.size(clan.members) > 1 ->
                {:error, :incorrect_clan_creator_deleting}
            requester.name == player.name && MapSet.size(clan.members) == 1 ->
                {:ok, player} = Player.create_player(player.name)
                {:ok, {player, :nil}}
            !(player.name in clan.members) ->
                {:error, :player_does_not_exist_in_clan}
            true ->
                clan = Map.update!(clan, :members, fn members -> MapSet.delete(members, player.name) end)
                {:ok, player} = Player.create_player(player.name)
                {:ok, {player, clan}}
        end
    end

    defp add_to_clan(clan, player) do
        cond do
            clan.name == :nil ->
                {:error, :empty_clan_name}
            player.clan_name != :nil ->
                {:error, :nonempty_player_clan_name}
            player.name == "" ->
                {:error, :empty_player_name}
            true ->
                clan = Map.update!(clan, :members, fn members -> MapSet.put(members, player.name) end)
                player = %{name: player.name, clan_name: clan.name}
                {:ok, {player, clan}}
        end
    end
end