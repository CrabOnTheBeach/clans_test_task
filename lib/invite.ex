defmodule Invite do
    defstruct inviter: "", receiver: "", clan_name: ""

    def new(inviter, receiver) do
        cond do
            inviter.clan_name == :nil ->
                {:error, :empty_inviter_clan_name}
            receiver.clan_name != :nil ->
                {:error, :nonempty_receiver_clan_name}
            true ->
                {:ok, %Invite{inviter: inviter, receiver: receiver, clan_name: inviter.clan_name}}
        end
    end

    def reply_to_invite(invite, receiver, clan, reply) do
        if invite.clan_name != clan.name do
            {:error, :clan_tag_mismatch}
        else
            case reply do
                :accept -> accept(invite, receiver, clan)
                :decline -> {:ok, {receiver, clan}}
                _ -> {:error, :reply_type_mismatch}
            end
        end
    end
    
    defp accept(invite, receiver, clan) do
        if invite.receiver.clan_name != :nil || receiver.clan_name != :nil do
            {:error, :nonempty_receiver_clan_name}
        else
            receiver = %{name: invite.receiver.name, clan_name: clan.name}
            clan = Map.update!(clan, :members, fn members -> MapSet.put(members, receiver.name) end)
            {:ok, {receiver, clan}}
        end
    end
end