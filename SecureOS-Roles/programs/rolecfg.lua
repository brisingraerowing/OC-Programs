--[[

  rolecfg.lua - Configuration program for the SecureOS User Roles implementation
  Author: Brisingr Aerowing

]]

-- Taken from auth.lua
local function split(str,sep)
  local array = {}
  local reg = string.format("([^%s]+)",sep)
  for mem in string.gmatch(str,reg) do
    table.insert(array, mem)
  end
  return array
end

local argparse = require("argparse")
--local roles = require("roles")
--local internal = require("roles.internal")

local parser = argparse():name("rolecfg"):description("Configuration program for user roles")
parser:command_target("command")

local cmd_add_role = parser:command("add-role"):description("Adds a new role")
cmd_add_role:argument("name"):description("The name of the new role")
cmd_add_role:argument("description"):description("The description of the new role")

local cmd_remove_role = parser:command("remove-role"):description("Removes an existing role")
cmd_remove_role:argument("name"):description("The name of the role to remove")

local cmd_update_description = parser:command("update-description"):description("Updates the description of a role")
cmd_update_description:argument("role"):description("The role to update the description of")
cmd_update_description:argument("new-description"):description("The new description for the role")

local cmd_role_exists = parser:command("role-exists"):description("Gets whether a role exists")
cmd_role_exists:argument("name"):description("The name of the role you want to check")

local cmd_role_info = parser:command("role-info"):description("Gets general information about a role")
cmd_role_info:argument("name"):description("The name of the role you want information on")

local cmd_rename_role = parser:command("rename-role"):description("Renames a role")
cmd_rename_role:argument("old-name"):description("The current name of the role")
cmd_rename_role:argument("new-name"):description("The new name for the role")
cmd_rename_role:flag("--no-alias"):description("Prevent adding an alias for backwards compatability")

local cmd_add_user_role = parser:command("add-user-role"):description("Adds a role to a user")
cmd_add_user_role:argument("user"):description("The name of the user to add a role to")
cmd_add_user_role:argument("role"):description("The role to add")

local cmd_remove_user_role = parser:command("remove-user-role"):description("Removes a role from a user")
cmd_remove_user_role:argument("user"):description("The name of the user to remove a role from")
cmd_remove_user_role:argument("role"):description("The role to remove")

local cmd_user_has_role = parser:command("user-has-role"):description("Gets whether the specified user has a role")
cmd_user_has_role:argument("user"):description("The name of the user to check for a role")
cmd_user_has_role:argument("role"):description("The role to check for")

local cmd_update_users = parser:command("update-users"):description("Updates the user database with new users")

local cmd_add_alias = parser:command("add-alias"):description("Adds an alias to a role.")
cmd_add_alias:argument("role"):description("The role to add an alias for")
cmd_add_alias:argument("alias"):description("The alias to add")

local cmd_remove_alias = parser:command("remove-alias"):description("Removes an alias")
cmd_remove_alias:argument("alias"):description("The alias to remove")

local cmd_is_alias = parser:command("is-alias"):description("Returns whether a role is actually an alias")
cmd_is_alias:argument("name"):description("The name of the role to check")

local arguments = parser:parse(split(..., " "))

local ser = require("serialization")

print(ser.serialize(arguments, true))

