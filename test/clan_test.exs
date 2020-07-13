defmodule ClanTest do
  use ExUnit.Case
  doctest Clan

  #test "greets the world" do
  #  assert Clan.hello() == :world
  #end
  test "creates a player" do
    name = "Sergey"
    {:ok, player} = Player.create_player(name)
    assert player == %{name: "Sergey", clan_name: :nil}
  end

  test "creates a clan" do
    name = "Sergey"
    {:ok, player} = Player.create_player(name)
    {:ok, {player, clan}} = Clan.create_clan(player, "Kaliningrad","KGD")
    assert player == %{name: "Sergey", clan_name: "Kaliningrad"}
    assert clan == %{creator: "Sergey", tag: "KGD", members: MapSet.new() |> MapSet.put("Sergey"), name: "Kaliningrad"}
  end

  test "fails to create an invite to a clan when inviter's clan tag is :nil" do
    {:ok, sergey} = Player.create_player("Sergey")
    {:ok, misha} = Player.create_player("Misha")
    invite = Invite.create_invite(sergey, misha)
    assert invite == {:error, :empty_inviter_clan_name}
  end

  test "fails to create an invite to a clan when receiver's clan tag is not :nil" do
    {:ok, sergey} = Player.create_player("Sergey")
    {:ok, misha} = Player.create_player("Misha")
    {:ok, {sergey, _}} = Clan.create_clan(sergey, "Kaliningrad1", "KGD")
    {:ok, {misha, _}} = Clan.create_clan(misha, "Kaliningrad2", "KDG")
    invite = Invite.create_invite(sergey, misha)
    assert invite == {:error, :nonempty_receiver_clan_name}
  end

  test "creates an invite to a clan" do
    {:ok, sergey} = Player.create_player("Sergey")
    {:ok, misha} = Player.create_player("Misha")
    {:ok, {sergey, _}} = Clan.create_clan(sergey, "Kaliningrad", "KGD")
    {:ok, invite} = Invite.create_invite(sergey, misha)
    assert invite == %{inviter: sergey, receiver: misha, clan_name: "Kaliningrad"}
  end

  test "replies to an invite with the :decline" do
    {:ok, sergey} = Player.create_player("Sergey")
    {:ok, misha} = Player.create_player("Misha")
    {:ok, {sergey, clan}} = Clan.create_clan(sergey, "Kaliningrad", "KGD")
    {:ok, invite} = Invite.create_invite(sergey, misha)
    {:ok, {new_misha_state, new_clan_state}} = Invite.reply_to_invite(invite, misha, clan, :decline)
    assert misha == new_misha_state
    assert clan == new_clan_state
  end

  test "replies to an invite with the :accept" do
    {:ok, sergey} = Player.create_player("Sergey")
    {:ok, misha} = Player.create_player("Misha")
    {:ok, {sergey, clan}} = Clan.create_clan(sergey, "Kaliningrad", "KGD")
    {:ok, invite} = Invite.create_invite(sergey, misha)
    {:ok, {misha, clan}} = Invite.reply_to_invite(invite, misha, clan, :accept)
    assert misha == %{name: "Misha", clan_name: "Kaliningrad"}
    members = MapSet.new() |> MapSet.put("Misha") |> MapSet.put("Sergey")
    assert clan == %{name: "Kaliningrad", creator: "Sergey", tag: "KGD", members: members }
  end

  test "fails to accept an invite when already has clan" do
    {:ok, sergey} = Player.create_player("Sergey")
    {:ok, misha} = Player.create_player("Misha")
    {:ok, {sergey, clan}} = Clan.create_clan(sergey, "Kaliningrad", "KGD")
    {:ok, invite1} = Invite.create_invite(sergey, misha)
    {:ok, invite2} = Invite.create_invite(sergey, misha)
    {:ok, {misha, clan}} = Invite.reply_to_invite(invite1, misha, clan, :accept)
    reply = Invite.reply_to_invite(invite2, misha, clan, :accept)
    assert reply == {:error, :nonempty_receiver_clan_name}
  end

  test "remove clan creator from clan that contains only creator" do
    {:ok, sergey} = Player.create_player("Sergey")
    {:ok, {sergey, clan}} = Clan.create_clan(sergey, "Kaliningrad", "KGD")
    {:ok, {sergey, clan}} = Clan.remove_from_clan(sergey, sergey, clan)
    assert sergey == %{name: "Sergey", clan_name: :nil}
    assert clan == :nil
  end

  test "fails to remove clan creator from clan that contains more than only creator" do
    {:ok, sergey} = Player.create_player("Sergey")
    {:ok, misha} = Player.create_player("Misha")
    {:ok, {sergey, clan}} = Clan.create_clan(sergey, "Kaliningrad", "KGD")
    {:ok, invite} = Invite.create_invite(sergey, misha)
    {:ok, {_misha, clan}} = Invite.reply_to_invite(invite, misha, clan, :accept)
    result = Clan.remove_from_clan(sergey, sergey, clan)
    assert result == {:error, :incorrect_clan_creator_deleting}
  end

  test "fails to remove player from clan when have no permission" do
    {:ok, sergey} = Player.create_player("Sergey")
    {:ok, misha} = Player.create_player("Misha")
    {:ok, vanya} = Player.create_player("Vanya")
    {:ok, {sergey, clan}} = Clan.create_clan(sergey, "Kaliningrad", "KGD")
    {:ok, invite_misha} = Invite.create_invite(sergey, misha)
    {:ok, invite_vanya} = Invite.create_invite(sergey, vanya)
    {:ok, {_misha, clan}} = Invite.reply_to_invite(invite_misha, misha, clan, :accept)
    {:ok, {_vanya, clan}} = Invite.reply_to_invite(invite_vanya, vanya, clan, :accept)

    result = Clan.remove_from_clan(vanya, misha, clan)
    assert result == {:error, :permission_error}
  end

  test "fails to remove player that doesn't exist in clan" do
    {:ok, sergey} = Player.create_player("Sergey")
    {:ok, misha} = Player.create_player("Misha")
    {:ok, vanya} = Player.create_player("Vanya")
    {:ok, {sergey, clan}} = Clan.create_clan(sergey, "Kaliningrad", "KGD")
    {:ok, invite_misha} = Invite.create_invite(sergey, misha)
    {:ok, {_misha, clan}} = Invite.reply_to_invite(invite_misha, misha, clan, :accept)

    result = Clan.remove_from_clan(sergey, vanya, clan)
    assert result == {:error, :player_does_not_exist_in_clan}
  end

  test "clan creator removes a regular user from a clan" do
    {:ok, sergey} = Player.create_player("Sergey")
    {:ok, misha} = Player.create_player("Misha")
    {:ok, {sergey, clan}} = Clan.create_clan(sergey, "Kaliningrad", "KGD")
    {:ok, invite_misha} = Invite.create_invite(sergey, misha)
    {:ok, {misha, clan}} = Invite.reply_to_invite(invite_misha, misha, clan, :accept)

    {:ok, {misha, clan}} = Clan.remove_from_clan(sergey, misha, clan)
    assert misha == %{name: "Misha", clan_name: :nil}
    assert clan == %{creator: "Sergey", tag: "KGD", name: "Kaliningrad", members: MapSet.new() |> MapSet.put("Sergey")}
  end

  test "regular user removes himself from a clan" do
    {:ok, sergey} = Player.create_player("Sergey")
    {:ok, misha} = Player.create_player("Misha")
    {:ok, {sergey, clan}} = Clan.create_clan(sergey, "Kaliningrad", "KGD")
    {:ok, invite_misha} = Invite.create_invite(sergey, misha)
    {:ok, {misha, clan}} = Invite.reply_to_invite(invite_misha, misha, clan, :accept)

    {:ok, {misha, clan}} = Clan.remove_from_clan(misha, misha, clan)
    assert misha == %{name: "Misha", clan_name: :nil}
    assert clan == %{creator: "Sergey", tag: "KGD", name: "Kaliningrad", members: MapSet.new() |> MapSet.put("Sergey")}
  end

  test "big clan_set test" do
    clan_set = ClanSet.new
    {:ok, sergey} = Player.create_player("Sergey")
    {:ok, misha} = Player.create_player("Misha")
    {:ok, vanya} = Player.create_player("Vanya")
    players = PlayerSet.new |> PlayerSet.put(sergey) |> PlayerSet.put(misha) |> PlayerSet.put(vanya)

    #Creating a new clan
    clan_name = "Kaliningrad"
    creator_name = "Sergey"
    {:ok, {creator, clan}} = Clan.create_clan(players[creator_name], clan_name, "KGD")
    clan_set = clan_set |> ClanSet.put(clan)
    players = players |> PlayerSet.update(creator)
    assert players[creator_name].clan_name == clan_name
    assert clan_set == %{clan_name => clan}

    #Creating an invite to the clan
    creator_name = "Sergey"
    receiver_name = "Misha"
    {:ok, invite} = Invite.create_invite(players[creator_name], players[receiver_name])
    assert invite == %{inviter: players[creator_name], receiver: players[receiver_name], clan_name: clan_name}

    #Declining an invite
    {:ok, {player, new_clan_state}} = Invite.reply_to_invite(invite, players[receiver_name], clan_set[clan_name], :decline)
    assert player == players[receiver_name]
    assert new_clan_state == clan_set[clan_name]

    #Accepting an invite
    {:ok, {player, new_clan_state}} = Invite.reply_to_invite(invite, players[receiver_name], clan_set[clan_name], :accept)
    assert player == %{name: receiver_name, clan_name: clan_name}
    assert new_clan_state == %{
      creator: clan_set[clan_name].creator, 
      name: clan_set[clan_name].name, 
      tag: clan_set[clan_name].tag, 
      members: clan_set[clan_name].members |> MapSet.put(receiver_name)}

    clan_set = clan_set |> ClanSet.update(new_clan_state)
    players = players |> PlayerSet.update(player)

    #Removing from a clan
    {:ok, {player, new_clan_state}} = Clan.remove_from_clan(players[creator_name], players[receiver_name], clan_set[clan_name])
    assert player == %{name: players[receiver_name].name, clan_name: :nil}
    assert new_clan_state == Map.update!(clan_set[clan_name], :members, fn members -> MapSet.delete(members, receiver_name) end)
  end
end
