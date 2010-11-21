
hooks = {}

function add_hook(hookname,f)
	if hooks[hookname] == nil then
		hooks[hookname] = {}
	end
	hooks[hookname][f] = true
end

function remove_hook(hookname, f)
	if hooks[hookname] == nil then
		hooks[hookname] = {}
	end
	hooks[hookname][f] = nil
end

function remove_hooks(hookname)
	if hooks[hookname] == nil then
		return
	else
		hooks[hookname] = nil
	end
end

function do_hook(hookname,data)
	if hooks[hookname] ~= nil then
		for k,v in pairs(hooks[hookname]) do
			k(data)
		end
	end
end