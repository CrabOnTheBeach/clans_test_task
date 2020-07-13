defmodule ClanSet do
    def new() do 
        Map.new()
    end

    def put(clan_set, clan) do
        if clan != :nil && !(clan.name in clan_set) do
            Map.put(clan_set, clan.name, clan)
        else
            clan_set
        end
    end

    def update(clan_set, clan) do
        Map.update!(clan_set, clan.name, fn _old_clan -> clan end)
    end
end