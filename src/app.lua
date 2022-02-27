#!/usr/bin/env tarantool


local httpd = require('http.server')
local log = require('log')
local json = require('json')
--local clock = require('clock')
local fiber = require('fiber')

box.cfg{
	log = './tarantool.log'
}

box.once('schema', 
	function()
		box.schema.create_space('kvstorage',
			{ 
				format = {
					{ name = 'key';   type = 'string' },
					{ name = 'value'; type = '*' },
				};
				if_not_exists = true;
			}
		)
		box.space.kvstorage:create_index('primary', 
			{ type = 'hash'; parts = {1, 'string'}; if_not_exists = true; }
		)
	end
)

local function get_port(env_port, default)
    local port = os.getenv(env_port)
    io.write("PORT is " .. port)
    if port == nil then
        return default
    end
    return port
end

server = httpd.new('0.0.0.0', get_port("PORT", 5000))

local function info(req)
	local resp = req:render{json = {
        api = {
            " - POST /kv body: {key: \"test\", \"value\": {SOME ARBITRARY JSON}} - PUT kv/{id} body: {\"value\": {SOME ARBITRARY JSON}} - GET kv/{id} - DELETE kv/{id}"
        },
        info = "hello, this is my test task for Tarantool"
    }}
	resp.status = 200
	log.info("(200) getting info")
	return resp
end

local function invalid_body(req, method_name,  msg)
	local resp = req:render{json = { info = "("..method_name..") "..msg }}
	resp.status = 400
	log.info("(%s) invalid body: %s", method_name, body)
	return resp
end

local function read_json(request)
	local status, body = pcall(function() return request:json() end)
	log.info("pcall(request:json()): %s %s", status, body)

	return body
end
	

local function create(req)
	local body = read_json(req)
	
	if ( type(body) == 'string' ) then
		return invalid_body(req, 'POST', 'invlid json')
	end

	if body['key'] == nil or body['value'] == nil then
		return invalid_body(req, 'POST', 'missing value or key')
	end
		
	local key = body['key']

	local duplicate = box.space.kvstorage:select(key)
	if ( table.getn(duplicate) ~= 0 ) then
		local resp = req:render{json = { info = "this key is already exist" }}
		resp.status = 409
		log.info("(POST) this key is already exist: key=%s", key)
		return resp
	end
	
	box.space.kvstorage:insert{ key, body['value'] }
	local resp = req:render{json = { info = "(POST) key and value were inserted" }}
	resp.status = 201

	log.info("(POST) key and value were inserted: key=%s", key)

	return resp
end


local function delete(req)
	local key = req:stash('key')

	local tuple = box.space.kvstorage:select(key)
	if( table.getn( tuple ) == 0 ) then
		local resp = req:render{json = { info = "(DELETE) this key doesn't exist" }}
		resp.status = 404
		log.info("(DELETE) this key doesn't exist: key=%s", key)
		return resp
	end

	box.space.kvstorage:delete{ key }

	local resp = req:render{json = { info = "(DELETE) key was successfully deleted" }}
	log.info("(DELETE) key was successfully deleted: key=%s", key)
	resp.status = 200

	return resp
end

local function get_tuple(req)

	server:stop()
	fiber.sleep(60)
	server:start()
	local key = req:stash('key')
	local tuple = box.space.kvstorage:select{ key }
	if( table.getn( tuple ) == 0 ) then
		local resp = req:render{json = { info = "(GET) this key doesn't exist" }}
		resp.status = 404
		log.info("(GET) this key doesn't exis: key=%s" , key)
		return resp
	end

	log.info("(GET): key=%s" , key)
	local resp = req:render{json = {key = tuple[1][1], value = tuple[1][2]}}
	resp.status = 200

	return resp
end

local function update(req)
	local body = read_json(req)
	
	if ( type(body) == 'string' ) then
		return invalid_body(req, '(PUT)', 'invlid json')
	end

	if body['value'] == nil then
		return invalid_body(req, '(PUT)', 'missing value')
	end

	local key = req:stash('key')

	if key == nil then
		local resp = req:render{json = { info = msg }}
		resp.status = 400
		log.info("(PUT) invalid key=%s", key)
		return resp
	end

	local tuple = box.space.kvstorage:select{ key }
	if( table.getn( tuple ) == 0 ) then
		local resp = req:render{json = { info = "(PUT) key doesn't exist" }}
		log.info("(PUT) key doesn't exist: key=%s" , key)
		resp.status = 404
		return resp
	end

	log.info("(PUT) value was successfully updated: key=%s, value=%s" , key, body['value'])
	local tuple = box.space.kvstorage:update({key}, {{'=', 2, body['value']}})

	local resp = req:render{json = { info = "(PUT) value was successfully update" }}
	resp.status = 200

	return resp
end


server:route({ path = '/', method = 'GET' }, info)
server:route({ path = '/kv', method = 'POST' }, create)
server:route({ path = '/kv/:key', method = 'DELETE' }, delete)
server:route({ path = '/kv/:key', method = 'GET' }, get_tuple)
server:route({ path = '/kv/:key', method = 'PUT' }, update)
server:start()


