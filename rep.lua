-- Prompt the user for the name of the new application
-- and create a new directory for it.
-- This script is intended to be run from the command line.

local lfs = require("lfs")

-- Prompt the user for the application name
print("Enter the name of the new application:")
local app_name = io.read()

-- Validate the input
if app_name == nil or app_name == "" then
	print("Invalid application name. Please try again.")
	return
end

-- Copy the template_service directory to the new application directory with the name of the new application
local template_service = "template_service"
local copy_command = "cp -r " .. template_service .. " " .. app_name
local result = os.execute(copy_command)
if result then
	print("Copied template service to: " .. app_name)
else
	print("Failed to copy template service.")
end

-- Find and replace all occurrences of "applicationName" in the new service directory with the actual application name
local function replace_application_name_in_files(directory, old_name, new_name)
	for file in lfs.dir(directory) do
		if file ~= "." and file ~= ".." then
			local file_path = directory .. "/" .. file
			local attr = lfs.attributes(file_path)
			if attr.mode == "file" then
				local content = ""
				local f = io.open(file_path, "r")
				if f then
					content = f:read("*all")
					f:close()
				end
				content = content:gsub(old_name, new_name)
				f = io.open(file_path, "w")
				if f then
					f:write(content)
					f:close()
				end
			elseif attr.mode == "directory" then
				replace_application_name_in_files(file_path, old_name, new_name)
			end
		end
	end
end

-- Replace "applicationName" with the actual application name in the new service directory

replace_application_name_in_files(app_name, "applicationName", app_name)
print("Replaced 'applicationName' with '" .. app_name .. "' in files of: " .. app_name)

-- Generate a random secret key for the application
local function generate_secret_key(length)
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local secret = ""
	for i = 1, length do
		local index = math.random(1, #chars)
		secret = secret .. chars:sub(index, index)
	end
	return secret
end

-- Create a new .env file for the application in the new application directory
local envFile = [[
# Environment variables for the application
APP_NAME=]] .. app_name .. [[
# Database configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=password
DB_NAME=mydatabase
# Secret key for the application
SECRET=]] .. generate_secret_key(126) .. [[
]]
local envFilePath = app_name .. "/.env"
local f = io.open(envFilePath, "w")
if f then
	f:write(envFile)
	f:close()
	print("Created .env file for the application in: " .. envFilePath)
else
	print("Failed to create .env file.")
	return
end

-- Create a new docker compose .yaml file for the application in the new application directory
local composeFile = [[version: "3.8"
services:
  postgres:
    image: postgres:latest
    container_name: ]] .. app_name .. [[_postgres
    restart: always
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
      POSTGRES_DB: mydatabase
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
]]

local composeFilePath = app_name .. "/docker-compose.yaml"
local f = io.open(composeFilePath, "w")
if f then
	f:write(composeFile)
	f:close()
	print("Created docker-compose.yaml for the application in: " .. composeFilePath)
else
	print("Failed to create docker-compose.yaml.")
	return
end

-- Copy the entire application to the parent folder, the projects directory
os.execute("mv " .. app_name .. " ../")

-- Start the application database with docker compose up -d
-- and tell the user that they can start the server with air

print("You can now start the server with 'air' in the application directory: " .. app_name)
