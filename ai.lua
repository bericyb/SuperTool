local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("dkjson")
local os = require("os")
local io = require("io")

-- Get API keys from environment variables
local API_KEYS = {
	OPENAI = os.getenv("OPENAI_API_KEY"),
	ANTHROPIC = os.getenv("ANTHROPIC_API_KEY"),
	MISTRAL = os.getenv("MISTRAL_API_KEY"),
	ELEVENLABS = os.getenv("ELEVENLABS_API_KEY"),
	GROK = os.getenv("GROK_API_KEY"),
	GOOGLE = os.getenv("GOOGLE_API_KEY"),
	DEEPSEEK = os.getenv("DEEPSEEK_API_KEY"),
}

-- Function to make HTTP requests
local function make_request(url, method, headers, body)
	local response_body = {}
	local result, response_code = http.request({
		url = url,
		method = method,
		headers = headers,
		source = body and ltn12.source.string(body) or nil,
		sink = ltn12.sink.table(response_body),
	})
	return table.concat(response_body), response_code
end

-- Function to debug API responses
local function debug_response(response, model_name)
	print("\nDEBUG: " .. model_name .. " API Response:")
	print(response)
end

-- OpenAI API call
local function get_openai_response(prompt)
	local url = "https://api.openai.com/v1/chat/completions"
	local payload = json.encode({
		model = "gpt-4o",
		messages = { { role = "user", content = prompt } },
		max_tokens = 300,
	})

	local headers = {
		["Authorization"] = "Bearer " .. API_KEYS.OPENAI,
		["Content-Type"] = "application/json",
		["Content-Length"] = tostring(#payload),
	}

	local response, code = make_request(url, "POST", headers, payload)
	debug_response(response, "OpenAI")

	local decoded = json.decode(response)
	return decoded and decoded.choices and decoded.choices[1] and decoded.choices[1].message.content or ""
end

local function get_openai_structured_response(prompt)
	local url = "https://api.openai.com/v1/chat/completions"
	local payload = json.encode({
		model = "gpt-4o-2024-08-06",
		messages = {
			{
				role = "system",
				content = "You are an expert at structured data extraction. You will be given unstructured text and should convert it into an array of objects with 'title', 'description', and 'code' fields.",
			},
			{ role = "user", content = prompt },
		},
		response_format = {
			type = "json_schema",
			json_schema = {
				name = "structured_code_extraction",
				schema = {
					type = "object",
					properties = {
						title = { type = "string" },
						description = { type = "string" },
						code = { type = "string" },
					},
					required = { "title", "description", "code" },
					additionalProperties = false,
				},
				strict = true,
			},
		},
		max_tokens = 300,
	})

	local headers = {
		["Authorization"] = "Bearer " .. API_KEYS.OPENAI,
		["Content-Type"] = "application/json",
		["Content-Length"] = tostring(#payload),
	}

	local response, code = make_request(url, "POST", headers, payload)
	debug_response(response, "OpenAI")

	local decoded = json.decode(response)
	return decoded and decoded.choices and decoded.choices[1] and decoded.choices[1].message.content or "[]"
end
-- Anthropic API call
local function get_anthropic_response(prompt)
	local url = "https://api.anthropic.com/v1/messages"
	local payload = json.encode({
		model = "claude-3-7-sonnet-20250219",
		max_tokens = 300,
		temperature = 1,
		messages = { { role = "user", content = { { type = "text", text = prompt } } } },
	})

	local headers = {
		["Authorization"] = "Bearer " .. API_KEYS.ANTHROPIC,
		["Content-Type"] = "application/json",
		["Content-Length"] = tostring(#payload),
	}

	local response, code = make_request(url, "POST", headers, payload)
	debug_response(response, "Anthropic")

	local decoded = json.decode(response)
	return decoded and decoded.content and decoded.content[1] and decoded.content[1].text or ""
end

-- Mistral API call
local function get_mistral_response(prompt)
	local url = "https://api.mistral.ai/v1/chat/completions"
	local payload = json.encode({
		model = "mistral-large-latest",
		messages = { { role = "user", content = prompt } },
	})

	local headers = {
		["Authorization"] = "Bearer " .. API_KEYS.MISTRAL,
		["Content-Type"] = "application/json",
		["Content-Length"] = tostring(#payload),
	}

	local response, code = make_request(url, "POST", headers, payload)
	debug_response(response, "Mistral")

	local decoded = json.decode(response)
	return decoded and decoded.choices and decoded.choices[1] and decoded.choices[1].message.content or ""
end

-- Grok API call
local function get_grok_response(prompt)
	local url = "https://api.x.ai/v1/chat/completions"
	local payload = json.encode({
		model = "grok-2-latest",
		messages = {
			{ role = "system", content = "You are an AI assistant." },
			{ role = "user", content = prompt },
		},
		temperature = 0.7,
		max_tokens = 300,
	})

	local headers = {
		["Authorization"] = "Bearer " .. API_KEYS.GROK,
		["Content-Type"] = "application/json",
		["Content-Length"] = tostring(#payload),
	}

	local response, code = make_request(url, "POST", headers, payload)
	debug_response(response, "Grok")

	local decoded = json.decode(response)
	return decoded and decoded.choices and decoded.choices[1] and decoded.choices[1].message.content or ""
end

-- Google API call
local function get_google_response(prompt)
	local url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key="
		.. API_KEYS.GOOGLE
	local payload = json.encode({
		contents = { {
			parts = { { text = prompt } },
		} },
	})

	local headers = {
		["Content-Type"] = "application/json",
		["Content-Length"] = tostring(#payload),
	}

	local response, code = make_request(url, "POST", headers, payload)
	debug_response(response, "Google")

	local decoded = json.decode(response)
	if decoded and decoded.candidates and decoded.candidates[1] and decoded.candidates[1].content then
		return decoded.candidates[1].content.parts[1].text or ""
	else
		return "Error: No valid response from Google API"
	end
end

local function get_google_structured_response(prompt, schema)
	local url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key="
		.. API_KEYS.GOOGLE
	local structured_prompt = prompt

	local payload = json.encode({
		contents = { {
			parts = { { text = structured_prompt } },
		} },
		generationConfig = {
			response_mime_type = "application/json",
		},
	})

	local headers = {
		["Content-Type"] = "application/json",
		["Content-Length"] = tostring(#payload),
	}

	local response, code = make_request(url, "POST", headers, payload)
	debug_response(response, "Google Structured")

	local decoded = json.decode(response)
	if decoded and decoded.candidates and decoded.candidates[1] and decoded.candidates[1].content then
		return decoded.candidates[1].content.parts[1].text or "{}"
	else
		return "Error: No valid structured response from Google API"
	end
end

-- Deepseek API call
local function get_deepseek_response(prompt)
	local url = "https://api.deepseek.com/beta/completions"
	local payload = json.encode({
		model = "deepseek-chat",
		prompt = prompt,
		max_tokens = 300,
	})

	local headers = {
		["Authorization"] = "Bearer " .. API_KEYS.DEEPSEEK,
		["Content-Type"] = "application/json",
		["Content-Length"] = tostring(#payload),
	}

	local response, code = make_request(url, "POST", headers, payload)
	debug_response(response, "Deepseek")

	local decoded = json.decode(response)
	return decoded and decoded.choices and decoded.choices[1] and decoded.choices[1].text or ""
end

-- Function to save responses
local function save_response(response, model_name)
	local timestamp = os.date("%Y%m%d_%H%M%S")
	local filename = OUTPUT_DIR .. "/" .. model_name .. "_" .. timestamp .. ".txt"
	local file = io.open(filename, "w")
	if file then
		file:write(response)
		file:close()
	end
	return filename
end

-- Table of model functions
local models = {
	OpenAI = get_openai_response,
	OpenAI_Structured = get_openai_structured_response,
	Anthropic = get_anthropic_response,
	Mistral = get_mistral_response,
	Grok = get_grok_response,
	Google = get_google_response,
	Google_Structured = get_google_structured_response,
	Deepseek = get_deepseek_response,
}

-- Main function
local function main()
	io.write("Enter a prompt: ")
	local prompt = io.read()

	print("\nAvailable models:")
	for model, _ in pairs(models) do
		print("- " .. model)
	end

	io.write("\nEnter the model name to use (or type 'all' to use all models): ")
	local model_choice = io.read()

	if model_choice == "all" then
		for model, func in pairs(models) do
			local response = func(prompt)
			print("\n" .. model .. " Response:\n" .. response)
			save_response(response, model)
		end
	elseif models[model_choice] then
		local response = models[model_choice](prompt)
		print("\n" .. model_choice .. " Response:\n" .. response)
		save_response(response, model_choice)
	else
		print("\nERROR: Invalid model name.")
	end

	print("\nResponses saved successfully.")
end

-- Run the script
-- main()
return models
