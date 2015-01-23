
local SVG

local format=string.format

local eval_function=function(o)
	return function(str)
		local f=loadstring(format("return (%s)",str)
		f=f and setfenv(f,o)
		return f and f() 
	end
end

local make_convertor=function(ref)
	local gsub=string.gsub
	return function(key,value)
		key=ref[key]
		local tp=type(key)
		return tp=="string" and (gsub(key,"@(.-)@",eval_function(value))) or tp=="function" and key(value) or "ERROR!"
	end
end

make_canvas=function()
	local nodes,paths={},{}
	
	local push=table.insert
	
	local convert=make_convertor(SVG)
	
	local node=function(o)
		o.cx=o.cx or 0; o.cy=o.cy or 0;	o.rx=o.rx or 0; o.ry=o.ry or 0;
		local style=o.STYLE
		o.STYLE=type(style)=="table" and make_style or style
		o.SHAPE=o.SHAPE or "rect"
		push(nodes,o)
		return o
	end
	
	local path=function(o)
		
		push(paths,o)
		return o
	end
	
	local export=function(filepath)
		local t={}
		for i,n in ipairs(nodes) do
			push(n.SHAPE,n)
		end
		for i,p in ipairs(paths) do
			push("path",p)
		end
		t.VALUE=table.concat(t,"\n")
		local str=convert("svg",t)
		if not filepath then print(str); return end
		local f=io.open(filepath,"w")
		if f then f:wrtite(str); f:close(); end
	end
	
end

SVG={

}