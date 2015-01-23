
local SVG={}

local make_eval_func=function(o)
	local loadstring=loadstring
	local f
	return function(str)
		f=loadstring("return "..str)
		f=f and setfenv(f,o)
		return f and f() or ""
	end
end

local gsub=string.gsub
local convert=function(o,tp,ref)
	tp=tp or o.TYPE 
	ref=ref or SVG
	tp=tp and SVG[tp]
	if not tp then return end
	return type(tp)=='func' and tp(o) or (gsub(tp,"@(.-)@",make_eval_func(o)))
end

local utf8flags={0,0xc0,0xe0,0xf0,0xf8,0xfc}
local get_charlen=function(ch)
	local flags=utf8flags
	for i=6,1,-1 do if ch>=flags[i] then return i end  end
end

function utf8strlen(str)
	local left = string.len(str)
	local cnt = 0
	local arr={0,0xc0,0xe0,0xf0,0xf8,0xfc}
	local byte=string.byte
	local i
	while left>0 do
		i=get_charlen(byte(str,-left))
		left=left-i
		cnt=cnt+(i>1 and 2 or 1)
	end
	return cnt;
end

local shape2points=function(o,shape,nodes)
	local points,x,y={}
	if shape=="-" then
		points={o.PATH[1],o.PATH[#o.PATH]}
		x,y=200,200
	elseif shape=="7" then
	end
	return points,x,y
end

local tostring=tostring
local format=string.format
local points2str=function(points,closed)
	local x,y
	for i,v in ipairs(points) do
		x,y=unpack(v)
		points[i]=format( i==1 and "M %s %s" or "L %s %s",tostring(x),tostring(y))
	end
	if closed then table.insert(points,"z") end
	return table.concat(points," ")
end

local line_style={
	dashed="stroke-dasharray:10,3",
	dotted="stroke-dasharray:3,3",
}

SVG={}

local tonumber=tonumber
local offset=function(str,ox,oy,dx,dy)
	ox=ox or 0; oy=oy or 0; dx=dx or 1; dy=dy;
	local offset
	offset=match(str,"U(%d*)"); offset=offset and (tonumber(offset) or 1); if offset then oy=oy-offset*dy end
	offset=match(str,"D(%d*)"); offset=offset and (tonumber(offset) or 1); if offset then oy=oy+offset*dy end
	offset=match(str,"L(%d*)"); offset=offset and (tonumber(offset) or 1); if offset then ox=ox-offset*dx end
	offset=match(str,"R(%d*)"); offset=offset and (tonumber(offset) or 1); if offset then ox=ox+offset*dx end
	return ox,oy
end

make_canvas=function(w,h,cols,rows,fontsize)
	-- define constants
	
	local dw,dh=w/cols,h/rows;
	local cw,ch=cw or dw/4,dh/4;
	local labels,nodes,paths,defs={},{},{},{}
	local push=table.insert
	-- basic functions
	local define_xy=function(o)
		local cx,cy,rx,ry=unpack(o)
		o.cx=o.cx or cx or 0; o.cy=o.cy or cy or 0; o.rx=o.rx or rx or cw; o.ry=o.ry or ry or ch;
		return o
	end
	local label=function(o)
		o=define_xy(o)
		o.fontsize=fontsize
		push(labels,o)
		return #labels
	end
	local node=function(o)
		o=define_xy(o)
		o.TYPE=o.TYPE or "rect"
		if o.LABEL then print(o.LABEL) o.fontsize=fontsize; push(labels,o) end
		push(nodes,o)
		return #nodes
	end
	local path=function(o)
		local s,p,x,y
		s=o.STYLE or "solid"
		s=line_style[s]
		o.STYLE=s or ""
		local p=o.PATH
		if o.SHAPE then
			p,x,y=shape2points(o,o.SHAPE,nodes)
			if o.LABEL then node{TYPE="lbox",LABEL=o.LABEL,cx=x,cy=y,rx=utf8strlen(o.LABEL)*fontsize/4, ry=fontsize/2} end
		end
		o.PATH=points2str(p,o.CLOSED,o.IS_CURVE)
		push(paths,o)
		return #paths
	end
	local export=function(filepath)
		local t={}
		for i,p in ipairs(paths) do push(t,convert(p,"path")) end
		for i,n in ipairs(nodes) do 
			if n.SHADOW then
				n.filter="url(#shadow)"; 
				push(t,convert(n,n.TYPE))
				n.filter=""; 
			end
			push(t,convert(n,n.TYPE)) 
		end
		for i,l in ipairs(labels) do 
			print(l.LABEL)
			push(t,convert(l,"label")) 
		end
		t.VALUE=table.concat(t,"\n")
		t.w=w;		t.h=h;	t.fs=fontsize;
		t.DEFS=table.concat(defs,"\n")
		local str=convert(t,"canvas")
		if filepath then
			filepath=io.open(filepath,"w")
			if filepath then filepath:write(str); filepath:close() end
		else
			print(str)
		end
	end
	-- extern functions
	return node,label,path,export
end

-------------------------------------------------------------------------------------------------------------------------------
----- for custom shapes and test
-------------------------------------------------------------------------------------------------------------------------------


SVG={
	canvas=[[<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

<svg width="@w@" height="@h@" version="1.1" xmlns="http://www.w3.org/2000/svg" font-size="@fs@px" stroke-width = "1.5" fill="white" stroke="black">

    <defs>

		<marker id="arrow" viewBox="0 0 20 20" refX="20" refY="10" markerUnits="strokeWidth" fill="black" markerWidth="8" markerHeight="6" orient="auto">
			<path d="M 0 0 L 20 10 L 0 20 L 10 10 z"/>
		</marker>
		
		<marker id="point2d" viewBox="0 0 20 20" refX="10" refY="10" markerUnits="strokeWidth" fill="orange" markerWidth="6" markerHeight="6" orient="auto">
			<circle cx="10" cy="10" r="9" />
		</marker>
		 
		 <filter id='shadow' filterRes='50' x='0' y='0'>
			<feGaussianBlur stdDeviation='2 2'/>
			<feOffset dx='2' dy='2'/>
		</filter>
		 
		<linearGradient x1='0%' x2='100%' id='linear0' y1='0%' y2='100%'>
			<stop offset='0%' style='stop-color:rgb(255,255,255);stop-opacity:1'/>
			<stop offset='100%' style='stop-color:rgb(220,220,220);stop-opacity:1'/>
		</linearGradient>
		
		<radialGradient id="radial0" cx="30%" cy="30%" r="50%">
			<stop offset="0%" style="stop-color:rgb(255,255,255); stop-opacity:0" />
			<stop offset="100%" style="stop-color:rgb(0,0,255);stop-opacity:1" />
     </radialGradient>
	 
	 @DEFS@
	 
     </defs>
	@VALUE@
</svg>]],

	label=[[ <text x="@cx@" y="@cy+fontsize/3@" stroke-width="0" fill="black" text-anchor="middle">@LABEL@</text> ]],
	lbox=[[ <rect x="@cx-rx@" y="@cy-ry@" width="@rx+rx@" height="@ry+ry@" fill="#ffffff" stroke="none"/> ]],
	path=[[ <path d = "@PATH@" fill = "@BGCOLOR or "none"@" stroke = "black"  stroke-linejoin="round" marker-end = "@HEAD@" marker-mid="@MIDDLE@" marker-start="@TAIL@" style="@STYLE@" filter="@filter@"/> ]],
}

local node,label,path,export=make_canvas()

path{PATH={ {100,100}, {100,500}, {800,500}  },STYLE="dotted", CLOSED=true}

export("test.svg")
