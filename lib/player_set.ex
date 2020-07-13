defmodule PlayerSet do
    def new() do 
        Map.new()
    end

    def put(player_set, player) do
        if player != :nil && !(player.name in player_set) do
            Map.put(player_set, player.name, player)
        else
            player_set
        end
    end

    def update(player_set, player) do
        Map.update!(player_set, player.name, fn _old_player -> player end)
    end
end