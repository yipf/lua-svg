
local make_fun=function(o)
	local loadstring,setfenv=loadstring,setfenv
	return function(str)
		local f=loadstring(str)
		f=f and setfenv(f,o)
		if f then f() end
	end
end

local do_tree
do_tree=function(tr,ref)
	local type,tostring=type,tostring
	for i,v in ipairs(tr) do
		tr[i]=type(v)=="table" and do_tree(v,ref) or tostring(tr)
	end
	tr.VALUE=table.concat(tr,"\n")
	local t=tr.TYPE or "text"
	t=ref[t] or ref["text"]
	return type(t)=="function" and t(tr) or (string.gsub(t,"@(.-)@",make_fun(tr)))
end



