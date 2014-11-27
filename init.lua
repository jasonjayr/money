--[[
	Mod by Kotolegokot and Xiong
	Version 2012.8.12.0
	Edited by TenPlus1 (27 Nov 2014)
]]

-- Default settings

INITIAL_MONEY = 100
PREFIX = "~"
POSTFIX = " coin"

-- Loading accounts

local accounts = {}
local input = io.open(minetest.get_worldpath() .. "/accounts", "r")

if input then
	accounts = minetest.deserialize(input:read("*l"))
	io.close(input)
end

-- Global functions.

money = {}

function money.save_accounts()
	local output = io.open(minetest.get_worldpath() .. "/accounts", "w")
	output:write(minetest.serialize(accounts))
	io.close(output)
end

function money.set_money(name, amount)
	accounts[name].money = amount
	money.save_accounts()
end

function money.get_money(name)
	return accounts[name].money
end

function money.freeze(name)
	accounts[name].frozen = true
	money.save_accounts()
end

function money.unfreeze(name)
	accounts[name].frozen = false
	money.save_accounts()
end

function money.is_frozen(name)
	return accounts[name].frozen or false
end

function money.exist(name)
	return accounts[name] ~= nil
end

-- Creates player's account, if the player doesn't have it.

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if not money.exist(name) then
		accounts[name] = {money = INITIAL_MONEY}
	end
end)

-- Registration privileges.

minetest.register_privilege("money", "Can use /money [pay <account> <amount>] command")
minetest.register_privilege("money_admin", {
	description = "Can use /money <account> | freeze/unfreeze <account> | take/set/inc/dec <account> <amount>",
	give_to_singleplayer = false,})

-- Registration "money" command.

minetest.register_chatcommand("money", {
	privs = {money=true},
	params = "[<account> | freeze/unfreeze <account> | pay/take/set/inc/dec <account> <amount>]",
	description = "Operations with money",
	func = function(name,  param)

		-- /money
		if param == "" then
			local text = ""
			text = name.." has "..PREFIX..money.get_money(name)..POSTFIX
			if money.is_frozen(name) then
				text = text.." (account frozen)"
			end
			minetest.chat_send_player(name, text)
			return true
		end

		local m = string.split(param, " ")
		local param1, param2, param3 = m[1], m[2], m[3]

		-- /money <account>
		if param1 and not param2 then
			if minetest.get_player_privs(name)["money_admin"] then
				if money.exist(param1) then
					local text = ""
					text = param1.." has "..PREFIX..money.get_money(param1)..POSTFIX
					if money.is_frozen(param1) then
						text = text.." (account frozen)"
					end
					minetest.chat_send_player(name, text)
				else
					minetest.chat_send_player(name, "\"" .. param1 .. "\" account does not exist.")
				end
			else
				minetest.chat_send_player(name, "You don't have permission to run this command (missing privileges: money_admin)")
			end
			return true
		end

		-- /money freeze|unfreeze <account>
		if param1 and param2 and not param3 then
			if param1 == "freeze" or param1 == "unfreeze" then
				if minetest.get_player_privs(name)["money_admin"] then
					if money.exist(param2) then
						if param1 == "freeze" then
							money.freeze(param2)
							minetest.chat_send_player(name, "\"" .. param2 .. "\" account is frozen.")
						else
							money.unfreeze(param2)
							minetest.chat_send_player(name, "\"" .. param2 .. "\" account isn't frozen.")
						end
					else
						minetest.chat_send_player(name, "\"" .. param2 .. "\" account don't exist.")
					end
					return true
				else
					minetest.chat_send_player(name, "You don't have permission to run this command (missing privileges: money_admin)")
				end
			end
		end

		-- /money pay|take|set|inc|dec <ccount> <amount>
		if param1 and param2 and param3 then
			if param1 == "pay" or param1 == "take" or param1 == "set" or param1 == "inc" or param1 == "dec" then
				if money.exist(param2) then
					if tonumber(param3) then
						if tonumber(param3) >= 0 then
							param3 = tonumber(param3)
							if param1 == "pay" then
								if not money.is_frozen(name) then
									if not money.is_frozen(param2) then
										if money.get_money(name) >= param3 then
											money.set_money(param2, money.get_money(param2) + param3)
											money.set_money(name, money.get_money(name) - param3)
											minetest.chat_send_player(param2, name .. " sent you " .. PREFIX .. param3 .. POSTFIX .. ".")
											minetest.chat_send_player(name, param2 .. " took your " .. PREFIX .. param3 .. POSTFIX .. ".")
										else
											minetest.chat_send_player(name, "You don't have enough " .. PREFIX .. param3 - money.get_money(name) .. POSTFIX .. ".")
										end
									else
										minetest.chat_send_player(name, "\"" .. param2 .. "\" account is frozen.")
									end
								else
									minetest.chat_send_player(name, "Your account is frozen.")
								end
								return true
							end
							if minetest.get_player_privs(name)["money_admin"] then
								if money.is_frozen(param2) then
									minetest.chat_send_player(name, "Note: \"" .. param2 .. "\" account is frozen.")
								end
								if param1 == "take" then
									if money.get_money(param2) >= param3 then
										money.set_money(param2, money.get_money(param2) - param3)
										money.set_money(name, money.get_money(name) + param3)
										minetest.chat_send_player(param2, name .. " took your " .. PREFIX .. param3 .. POSTFIX .. ".")
										minetest.chat_send_player(name, "You took " .. param2 .. "'s " .. PREFIX .. param3 .. POSTFIX .. ".")
									else
										minetest.chat_send_player(name, "Player named \""..param2.."\" do not have enough " .. PREFIX .. param3 - money.get_money(player) .. POSTFIX .. ".")
									end
								elseif param1 == "set" then
									money.set_money(param2, param3)
									minetest.chat_send_player(name, param2 .. " " .. PREFIX .. param3 .. POSTFIX)
								elseif param1 == "inc" then
									money.set_money(param2, money.get_money(param2) + param3)
									minetest.chat_send_player(name, param2 .. " " .. PREFIX .. money.get_money(param2) .. POSTFIX)
								elseif param1 == "dec" then
									if money.get_money(param2) >= param3 then
										money.set_money(param2, money.get_money(param2) - param3)
										minetest.chat_send_player(name, param2 .. " " .. PREFIX .. money.get_money(param2) .. POSTFIX)
									else
										minetest.chat_send_player(name, "Player named \""..param2.."\" do not have enough " .. PREFIX .. param3 - money.get_money(player) .. POSTFIX .. ".")
									end
								end
							else
								minetest.chat_send_player(name, "You don't have permission to run this command (missing privileges: money_admin)")
							end
						else
							minetest.chat_send_player(name, "Amount must be greater than -1.")
						end
					else
						minetest.chat_send_player(name, "Amount must be a number.")
					end
				else
					minetest.chat_send_player(name, "\"" .. param2 .. "\" account don't exist.")
				end
				return true
			end
		end
		minetest.chat_send_player(name, "Invalid parameters (see /help money)")
	end,
})

-- Does player have permissions for this shop?

local function has_shop_privilege(meta, player)
	return player:get_player_name() == meta:get_string("owner") or minetest.get_player_privs(player:get_player_name())["money_admin"]
end

--Shop.

--[[
	Shop buys  : player sells : at costbuy  : with buttonsell
	Shop sells : player buys  : at costsell : with buttonbuy
]]

minetest.register_node("money:shop", {
	description = "Shop",
	tiles = {"default_chest_top.png", "default_chest_top.png", "default_chest_side.png",
		"default_chest_side.png", "default_chest_side.png", "default_chest_front.png^money_shop_front.png"},
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
	sounds = default.node_sound_wood_defaults(),
	paramtype2 = "facedir",
	after_place_node = function(pos, placer)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("owner", placer:get_player_name())
		meta:set_string("infotext", "Untuned Shop (owned by " .. placer:get_player_name() .. ")")
	end,
	on_construct = function(pos)
	-- Shop buys at costbuy
	-- Shop sells at costsell
		local meta = minetest.env:get_meta(pos)
		meta:set_string("formspec", "size[8,6.6]"..
			"field[0.256,0.5;8,1;shopname;Name of your shop:;]"..
			"field[0.256,1.5;8,1;action;Do you want buy(B) or sell(S) or buy and sell(BS):;]"..
			"field[0.256,2.5;8,1;nodename;Name of node to buy or/and sell:;]"..
			"field[0.256,3.5;8,1;amount;Quantity of these nodes per lot:;]"..
			"field[0.256,4.5;8,1;costbuy;Shop buys lots for this amount:;]"..
			"field[0.256,5.5;8,1;costsell;Shop sells lots for this amount:;]"..
			"button_exit[3.1,6;2,1;button;Tune]")
		meta:set_string("infotext", "Untuned Shop")
		meta:set_string("owner", "")
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
		meta:set_string("form", "yes")
	end,

--retune

	on_punch = function( pos, node, player )
	-- Shop buys at costbuy
	-- Shop sells at costsell
		local meta = minetest.env:get_meta(pos)
		--~ minetest.chat_send_all("Shop punched.")
		--~ minetest.chat_send_all(name)

		if player:get_player_name() == meta:get_string("owner") then
			meta:set_string("formspec", "size[8,6.6]"..
				"field[0.256,0.5;8,1;shopname;Name of your shop:;${shopname}]"..
				"field[0.256,1.5;8,1;action;Do you want buy(B) or sell(S) or buy and sell(BS):;${action}]"..
				"field[0.256,2.5;8,1;nodename;Name of node, that you want buy or/and sell:;${nodename}]"..
				"field[0.256,3.5;8,1;amount;Quantity of nodes per lot:;${amount}]"..
				"field[0.256,4.5;8,1;costbuy;Shop buys lots for this amount:;${costbuy}]"..
				"field[0.256,5.5;8,1;costsell;Shop sells lots for this amount:;${costsell}]"..
				"button_exit[3.1,6;2,1;button;Retune]")
			meta:set_string("infotext", "Detuned Shop")
			meta:set_string("form", "yes")

			minetest.chat_send_player( player:get_player_name(), "Shop detuned.")
		end
	end,

--end retune

	can_dig = function(pos,player)
		local meta = minetest.env:get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main") and (meta:get_string("owner") == player:get_player_name() or minetest.get_player_privs(player:get_player_name())["money_admin"])
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.env:get_meta(pos)
		if not has_shop_privilege(meta, player) then
			minetest.log("action", player:get_player_name()..
					" tried to access a shop belonging to "..
					meta:get_string("owner").." at "..
					minetest.pos_to_string(pos))
			return 0
		end
		return count
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.env:get_meta(pos)
		if not has_shop_privilege(meta, player) then
			minetest.log("action", player:get_player_name()..
					" tried to access a shop belonging to "..
					meta:get_string("owner").." at "..
					minetest.pos_to_string(pos))
			return 0
		end
		return stack:get_count()
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = minetest.env:get_meta(pos)
		if not has_shop_privilege(meta, player) then
			minetest.log("action", player:get_player_name()..
					" tried to access a shop belonging to "..
					meta:get_string("owner").." at "..
					minetest.pos_to_string(pos))
			return 0
		end
		return stack:get_count()
	end,
	on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		minetest.log("action", player:get_player_name()..
				" moves stuff in shop at "..minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name()..
				" moves stuff to shop at "..minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_take = function(pos, listname, index, count, player)
		minetest.log("action", player:get_player_name()..
				" takes stuff from shop at "..minetest.pos_to_string(pos))
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.env:get_meta(pos)
		if meta:get_string("form") == "yes" then
			if fields.shopname ~= "" and (fields.action == "B" or fields.action == "S" or fields.action == "BS") and minetest.registered_items[fields.nodename] and tonumber(fields.amount) and tonumber(fields.amount) >= 1 and (meta:get_string("owner") == sender:get_player_name() or minetest.get_player_privs(sender:get_player_name())["money_admin"]) then
				if fields.action == "B" then
					if not tonumber(fields.costbuy) then
						return
					end
					if not (tonumber(fields.costbuy) >= 0) then
						return
					end
				end
				if fields.action == "S" then
					if not tonumber(fields.costsell) then
						return
					end
					if not (tonumber(fields.costsell) >= 0) then
						return
					end
				end
				if fields.action == "BS" then
					if not tonumber(fields.costbuy) then
						return
					end
					if not (tonumber(fields.costbuy) >= 0) then
						return
					end
					if not tonumber(fields.costsell) then
						return
					end
					if not (tonumber(fields.costsell) >= 0) then
						return
					end
				end
				local s, ss
				if fields.action == "B" then
				-- Shop buys, player sells: at costbuy
					s = " sell "
					ss = "button[1,5;2,1;buttonsell;Sell("..fields.costbuy..")]"
				elseif fields.action == "S" then
				-- Shop sells, player buys: at costsell
					s = " buy "
					ss = "button[1,5;2,1;buttonbuy;Buy("..fields.costsell..")]"
				else
					s = " buy and sell "
					ss = "button[1,5;2,1;buttonbuy;Buy("..fields.costsell..")]" .. "button[5,5;2,1;buttonsell;Sell("..fields.costbuy..")]"
				end
				local meta = minetest.env:get_meta(pos)
				meta:set_string("formspec", "size[8,10;]"..
					"list[context;main;0,0;8,4;]"..
					"label[0.256,4.5;You can"..s..fields.amount.." "..fields.nodename.."]"..
					ss..
					"list[current_player;main;0,6;8,4;]")
				meta:set_string("shopname", fields.shopname)
				meta:set_string("action", fields.action)
				meta:set_string("nodename", fields.nodename)
				meta:set_string("amount", fields.amount)
				meta:set_string("costbuy", fields.costbuy)
				meta:set_string("costsell", fields.costsell)
				meta:set_string("infotext", "Shop \"" .. fields.shopname .. "\" (owned by " .. meta:get_string("owner") .. ")")
				meta:set_string("form", "no")
			end
		elseif fields["buttonbuy"] then
		-- Shop sells, player buys: at costsell: with buttonbuy
			local sender_name = sender:get_player_name()
			local inv = meta:get_inventory()
			local sender_inv = sender:get_inventory()
			if not inv:contains_item("main", meta:get_string("nodename") .. " " .. meta:get_string("amount")) then
				minetest.chat_send_player(sender_name, "In the shop is not enough goods.")
				return true
			elseif not sender_inv:room_for_item("main", meta:get_string("nodename") .. " " .. meta:get_string("amount")) then
				minetest.chat_send_player(sender_name, "In your inventory is not enough space.")
				return true
			elseif money.get_money(sender_name) - tonumber(meta:get_string("costsell")) < 0 then
				minetest.chat_send_player(sender_name, "You do not have enough money.")
				return true
			elseif not money.exist(meta:get_string("owner")) then
				minetest.chat_send_player(sender_name, "The owner's account does not currently exist; try again later.")
				return true
			end
			money.set_money(sender_name, money.get_money(sender_name) - meta:get_string("costsell"))
			money.set_money(meta:get_string("owner"), money.get_money(meta:get_string("owner")) + meta:get_string("costsell"))
			sender_inv:add_item("main", meta:get_string("nodename") .. " " .. meta:get_string("amount"))
			inv:remove_item("main", meta:get_string("nodename") .. " " .. meta:get_string("amount"))
			minetest.chat_send_player(sender_name, "You bought " .. meta:get_string("amount") .. " " .. meta:get_string("nodename") .. " at a price of " .. PREFIX .. meta:get_string("costsell") .. POSTFIX .. ".")
		elseif fields["buttonsell"] then
			-- Shop buys, player sells: at costbuy: with buttonsell
			local sender_name = sender:get_player_name()
			local inv = meta:get_inventory()
			local sender_inv = sender:get_inventory()
			if not sender_inv:contains_item("main", meta:get_string("nodename") .. " " .. meta:get_string("amount")) then
				minetest.chat_send_player(sender_name, "You do not have enough product.")
				return true
			elseif not inv:room_for_item("main", meta:get_string("nodename") .. " " .. meta:get_string("amount")) then
				minetest.chat_send_player(sender_name, "In the shop is not enough space.")
				return true
			elseif money.get_money(meta:get_string("owner")) - meta:get_string("costbuy") < 0 then
				minetest.chat_send_player(sender_name, "The buyer is not enough money.")
				return true
			elseif not money.exist(meta:get_string("owner")) then
				minetest.chat_send_player(sender_name, "The owner's account does not currently money.exist; try again later.")
				return true
			end
			money.set_money(sender_name, money.get_money(sender_name) + meta:get_string("costbuy"))
			money.set_money(meta:get_string("owner"), money.get_money(meta:get_string("owner")) - meta:get_string("costbuy"))
			sender_inv:remove_item("main", meta:get_string("nodename") .. " " .. meta:get_string("amount"))
			inv:add_item("main", meta:get_string("nodename") .. " " .. meta:get_string("amount"))
			minetest.chat_send_player(sender_name, "You sold " .. meta:get_string("amount") .. " " .. meta:get_string("nodename") .. " at a price of " .. PREFIX .. meta:get_string("costbuy") .. POSTFIX .. ".")
		end
	end,
 })

-- Shop recipe

minetest.register_craft({
	output = "money:shop",
	recipe = {
		{"default:chest_locked"},
		{"default:sign_wall"},
	},
})

--Barter shop.

minetest.register_node("money:barter_shop", {
	description = "Barter Shop",
	tiles = {"default_chest_top.png", "default_chest_top.png", "default_chest_side.png",
		"default_chest_side.png", "default_chest_side.png", "default_chest_front.png^money_barter_shop_front.png"},
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
	sounds = default.node_sound_wood_defaults(),
	paramtype2 = "facedir",
	after_place_node = function(pos, placer)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("owner", placer:get_player_name())
		meta:set_string("infotext", "Untuned Barter Shop (owned by " .. placer:get_player_name() .. ")")
	end,
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("formspec", "size[8,5.6]"..
			"field[0.256,0.5;8,1;bartershopname;Name of your barter shop:;]"..
			"field[0.256,1.5;8,1;nodename1;Name node (A) shop will give to player:;]"..
			"field[0.256,2.5;8,1;nodename2;Name node (B) player will give to shop:;]"..
			"field[0.256,3.5;8,1;amount1;Quantity of node A per swap:;]"..
			"field[0.256,4.5;8,1;amount2;Quantity of node B per swap:;]"..
			"button_exit[3.1,5;2,1;button;Tune]")
		meta:set_string("infotext", "Untuned Barter Shop")
		meta:set_string("owner", "")
		meta:set_string("form", "yes")
	end,

--retune

	on_punch = function( pos, node, player )
		local meta = minetest.env:get_meta(pos)
		--~ minetest.chat_send_all("Barter Shop punched.")
		--~ minetest.chat_send_all(name)

		if player:get_player_name() == meta:get_string("owner") then
		meta:set_string("formspec", "size[8,5.6]"..
			"field[0.256,0.5;8,1;bartershopname;Name of your barter shop:;${bartershopname}]"..
			"field[0.256,1.5;8,1;nodename1;Name node (A) shop will give to player:;${nodename1}]"..
			"field[0.256,2.5;8,1;nodename2;Name node (B) player will give to shop:;${nodename2}]"..
			"field[0.256,3.5;8,1;amount1;Quantity of node A per swap:;${amount1}]"..
			"field[0.256,4.5;8,1;amount2;Quantity of node B per swap:;${amount2}]"..
			"button_exit[3.1,5;2,1;button;Retune]")
			meta:set_string("infotext", "Detuned Barter Shop")
			meta:set_string("form", "yes")

			minetest.chat_send_player( player:get_player_name(), "Barter Shop detuned.")
		end
	end,

--end retune

	can_dig = function(pos,player)
		local meta = minetest.env:get_meta(pos);
		local inv = meta:get_inventory()
		return inv:is_empty("main") and (meta:get_string("owner") == player:get_player_name() or minetest.get_player_privs(player:get_player_name())["money_admin"])
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.env:get_meta(pos)
		if not has_shop_privilege(meta, player) then
			minetest.log("action", player:get_player_name()..
					" tried to access a barter shop belonging to "..
					meta:get_string("owner").." at "..
					minetest.pos_to_string(pos))
			return 0
		end
		return count
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.env:get_meta(pos)
		if not has_shop_privilege(meta, player) then
			minetest.log("action", player:get_player_name()..
					" tried to access a barter shop belonging to "..
					meta:get_string("owner").." at "..
					minetest.pos_to_string(pos))
			return 0
		end
		return stack:get_count()
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = minetest.env:get_meta(pos)
		if not has_shop_privilege(meta, player) then
			minetest.log("action", player:get_player_name()..
					" tried to access a barter shop belonging to "..
					meta:get_string("owner").." at "..
					minetest.pos_to_string(pos))
			return 0
		end
		return stack:get_count()
	end,
	on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		minetest.log("action", player:get_player_name()..
				" moves stuff in barter shop at "..minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name()..
				" moves stuff to barter shop at "..minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_take = function(pos, listname, index, count, player)
		minetest.log("action", player:get_player_name()..
				" takes stuff from barter shop at "..minetest.pos_to_string(pos))
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.env:get_meta(pos)
		if meta:get_string("form") == "yes" then
			if fields.bartershopname ~= "" and minetest.registered_items[fields.nodename1] and minetest.registered_items[fields.nodename2] and tonumber(fields.amount1) and tonumber(fields.amount1) >= 1 and tonumber(fields.amount2) and tonumber(fields.amount2) >= 1 and (meta:get_string("owner") == sender:get_player_name() or minetest.get_player_privs(sender:get_player_name())["money_admin"]) then
				meta:set_string("formspec", "size[8,10;]"..
					"list[context;main;0,0;8,4;]"..
					--~ "label[0.256,4.5;Shop takes "..fields.amount2.." "..fields.nodename2.." \n and gives "..fields.amount1.." "..fields.nodename1.."]"..
					"label[0.256,4.2;Shop takes "..fields.amount2.." "..fields.nodename2.."]" ..
					"label[0.256,4.5;and gives "..fields.amount1.." "..fields.nodename1.."]"..
					"button[3.1,5;2,1;button;Swap]"..
					"list[current_player;main;0,6;8,4;]")
				meta:set_string("bartershopname", fields.bartershopname)
				meta:set_string("nodename1", fields.nodename1)
				meta:set_string("nodename2", fields.nodename2)
				meta:set_string("amount1", fields.amount1)
				meta:set_string("amount2", fields.amount2)
				meta:set_string("infotext", "Barter Shop \"" .. fields.bartershopname .. "\" (owned by " .. meta:get_string("owner") .. ")")
				local inv = meta:get_inventory()
				inv:set_size("main", 8*4)
				meta:set_string("form", "no")
			end
		elseif fields["button"] then
			local sender_name = sender:get_player_name()
			local inv = meta:get_inventory()
			local sender_inv = sender:get_inventory()
			if not inv:contains_item("main", meta:get_string("nodename1") .. " " .. meta:get_string("amount1")) then
				minetest.chat_send_player(sender_name, "In the barter shop is not enough goods.")
				return
			elseif not sender_inv:contains_item("main", meta:get_string("nodename2") .. " " .. meta:get_string("amount2")) then
				minetest.chat_send_player(sender_name, "In your inventory is not enough goods.")
				return
			elseif not inv:room_for_item("main", meta:get_string("nodename2") .. " " .. meta:get_string("amount2")) then
				minetest.chat_send_player(sender_name, "In the barter shop is not enough space.")
				return
			elseif not sender_inv:room_for_item("main", meta:get_string("nodename1") .. " " .. meta:get_string("amount1")) then
				minetest.chat_send_player(sender_name, "In your inventory is not enough space.")
				return
			end
			inv:remove_item("main", meta:get_string("nodename1") .. " " .. meta:get_string("amount1"))
			sender_inv:remove_item("main", meta:get_string("nodename2") .. " " .. meta:get_string("amount2"))
			inv:add_item("main", meta:get_string("nodename2") .. " " .. meta:get_string("amount2"))
			sender_inv:add_item("main", meta:get_string("nodename1") .. " " .. meta:get_string("amount1"))
			minetest.chat_send_player(sender_name, "You exchanged " .. meta:get_string("amount2") .. " " .. meta:get_string("nodename2") .. " for " .. meta:get_string("amount1") .. " " .. meta:get_string("nodename1") .. ".")
		end
	end,
})

-- Barter Shop recipe

minetest.register_craft({
	output = "money:barter_shop",
	recipe = {
		{"default:sign_wall"},
		{"default:chest_locked"},
	},
})

--Admin shop.

minetest.register_node("money:admin_shop", {
	description = "Admin Shop",
	tiles = {"default_chest_top.png", "default_chest_top.png", "default_chest_side.png",
		"default_chest_side.png", "default_chest_side.png", "default_chest_front.png^money_admin_shop_front.png"},
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
	sounds = default.node_sound_wood_defaults(),
	paramtype2 = "facedir",
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("infotext", "Untuned Admin Shop")
		meta:set_string("formspec", "size[8,5.6]"..
			"field[0.256,0.5;8,1;action;Do you want buy(B) or sell(S) or buy and sell(BS):;]"..
			"field[0.256,1.5;8,1;nodename;Name of node, that you want buy or/and sell:;]"..
			"field[0.256,2.5;8,1;amount;Amount of these nodes:;]"..
			"field[0.256,3.5;8,1;costbuy;Cost of purchase, if you buy nodes:;]"..
			"field[0.256,4.5;8,1;costsell;Cost of sales, if you sell nodes:;]"..
			"button_exit[3.1,5;2,1;button;Proceed]")
		meta:set_string("form", "yes")
	end,
	can_dig = function(pos,player)
		return minetest.get_player_privs(player:get_player_name())["money_admin"]
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.env:get_meta(pos)
		if meta:get_string("form") == "yes" then
			if (fields.action == "B" or fields.action == "S" or fields.action == "BS") and minetest.registered_items[fields.nodename] and tonumber(fields.amount) and tonumber(fields.amount) >= 1 and (meta:get_string("owner") == sender:get_player_name() or minetest.get_player_privs(sender:get_player_name())["money_admin"]) then
				if fields.action == "B" then
					if not tonumber(fields.costbuy) then
						return
					end
					if not (tonumber(fields.costbuy) >= 0) then
						return
					end
				end
				if fields.action == "S" then
					if not tonumber(fields.costsell) then
						return
					end
					if not (tonumber(fields.costsell) >= 0) then
						return
					end
				end
				if fields.action == "BS" then
					if not tonumber(fields.costbuy) then
						return
					end
					if not (tonumber(fields.costbuy) >= 0) then
						return
					end
					if not tonumber(fields.costsell) then
						return
					end
					if not (tonumber(fields.costsell) >= 0) then
						return
					end
				end
				local s, ss
				if fields.action == "B" then
					s = " sell "
					ss = "button[1,0.5;2,1;buttonsell;Sell("..fields.costbuy..")]"
				elseif fields.action == "S" then
					s = " buy "
					ss = "button[1,0.5;2,1;buttonbuy;Buy("..fields.costsell..")]"
				else
					s = " buy and sell "
					ss = "button[1,0.5;2,1;buttonbuy;Buy("..fields.costsell..")]" .. "button[5,0.5;2,1;buttonsell;Sell("..fields.costbuy..")]"
				end
				local meta = minetest.env:get_meta(pos)
				meta:set_string("formspec", "size[8,5.5;]"..
					"label[0.256,0;You can"..s..fields.amount.." "..fields.nodename.."]"..
					ss..
					"list[current_player;main;0,1.5;8,4;]")
				meta:set_string("nodename", fields.nodename)
				meta:set_string("amount", fields.amount)
				meta:set_string("costbuy", fields.costsell)
				meta:set_string("costsell", fields.costbuy)
				meta:set_string("infotext", "Admin Shop")
				meta:set_string("form", "no")
			end
		elseif fields["buttonbuy"] then
			local sender_name = sender:get_player_name()
			local sender_inv = sender:get_inventory()
			if not sender_inv:room_for_item("main", meta:get_string("nodename") .. " " .. meta:get_string("amount")) then
				minetest.chat_send_player(sender_name, "In your inventory is not enough space.")
				return true
			elseif money.get_money(sender_name) - tonumber(meta:get_string("costbuy")) < 0 then
				minetest.chat_send_player(sender_name, "You do not have enough money.")
				return true
			end
			money.set_money(sender_name, money.get_money(sender_name) - meta:get_string("costbuy"))
			sender_inv:add_item("main", meta:get_string("nodename") .. " " .. meta:get_string("amount"))
			minetest.chat_send_player(sender_name, "You bought " .. meta:get_string("amount") .. " " .. meta:get_string("nodename") .. " at a price of " .. PREFIX .. meta:get_string("costbuy") .. POSTFIX .. ".")
		elseif fields["buttonsell"] then
			local sender_name = sender:get_player_name()
			local sender_inv = sender:get_inventory()
			if not sender_inv:contains_item("main", meta:get_string("nodename") .. " " .. meta:get_string("amount")) then
				minetest.chat_send_player(sender_name, "You do not have enough product.")
				return true
			end
			money.set_money(sender_name, money.get_money(sender_name) + meta:get_string("costsell"))
			sender_inv:remove_item("main", meta:get_string("nodename") .. " " .. meta:get_string("amount"))
			minetest.chat_send_player(sender_name, "You sold " .. meta:get_string("amount") .. " " .. meta:get_string("nodename") .. " at a price of " .. PREFIX .. meta:get_string("costsell") .. POSTFIX .. ".")
		end
	end,
 })

--Admin barter shop.

minetest.register_node("money:admin_barter_shop", {
	description = "Admin Barter Shop",
	tiles = {"default_chest_top.png", "default_chest_top.png", "default_chest_side.png",
		"default_chest_side.png", "default_chest_side.png", "default_chest_front.png^money_admin_barter_shop_front.png"},
	groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2},
	sounds = default.node_sound_wood_defaults(),
	paramtype2 = "facedir",
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("formspec", "size[8,4.6]"..
			"field[0.256,0.5;8,1;nodename1;What kind of a node do you want to exchange:;]"..
			"field[0.256,1.5;8,1;nodename2;for:;]"..
			"field[0.256,2.5;8,1;amount1;Amount of first kind of node:;]"..
			"field[0.256,3.5;8,1;amount2;Amount of second kind of node:;]"..
			"button_exit[3.1,4;2,1;button;Proceed]")
		meta:set_string("infotext", "Untuned Admin Barter Shop")
		meta:set_string("form", "yes")
	end,
	can_dig = function(pos,player)
		return minetest.get_player_privs(player:get_player_name())["money_admin"]
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.env:get_meta(pos)
		if meta:get_string("form") == "yes" then
			if minetest.registered_items[fields.nodename1] and minetest.registered_items[fields.nodename2] and tonumber(fields.amount1) and tonumber(fields.amount1) >= 1 and tonumber(fields.amount2) and tonumber(fields.amount2) >= 1 and (meta:get_string("owner") == sender:get_player_name() or minetest.get_player_privs(sender:get_player_name())["money_admin"]) then
				meta:set_string("formspec", "size[8,6;]"..
					"label[0.256,0.0;"..fields.amount2.." "..fields.nodename2.." --> "..fields.amount1.." "..fields.nodename1.."]"..
					"button[3.1,0.5;2,1;button;Exchange]"..
					"list[current_player;main;0,1.5;8,4;]")
				meta:set_string("nodename1", fields.nodename1)
				meta:set_string("nodename2", fields.nodename2)
				meta:set_string("amount1", fields.amount1)
				meta:set_string("amount2", fields.amount2)
				meta:set_string("infotext", "Admin Barter Shop")
				meta:set_string("form", "no")
			end
		elseif fields["button"] then
			local sender_name = sender:get_player_name()
			local sender_inv = sender:get_inventory()
			if not sender_inv:contains_item("main", meta:get_string("nodename2") .. " " .. meta:get_string("amount2")) then
				minetest.chat_send_player(sender_name, "In your inventory is not enough goods.")
				return
			elseif not sender_inv:room_for_item("main", meta:get_string("nodename1") .. " " .. meta:get_string("amount1")) then
				minetest.chat_send_player(sender_name, "In your inventory is not enough space.")
				return
			end
			sender_inv:remove_item("main", meta:get_string("nodename2") .. " " .. meta:get_string("amount2"))
			sender_inv:add_item("main", meta:get_string("nodename1") .. " " .. meta:get_string("amount1"))
			minetest.chat_send_player(sender_name, "You exchanged " .. meta:get_string("amount2") .. " " .. meta:get_string("nodename2") .. " on " .. meta:get_string("amount1") .. " " .. meta:get_string("nodename1") .. ".")
		end
	end,
})