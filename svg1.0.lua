
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

local match,tonumber=string.match,tonumber
local config=function(dir,o,fontsize)
	local ox,oy,align,offset=0,0,"middle"
	dir=dir or "M"
	offset=match(dir,"U(%d+)"); if offset then oy=oy-tonumber(offset) end
	offset=match(dir,"D(%d+)"); if offset then oy=oy+tonumber(offset)+fontsize end
	offset=match(dir,"L(%d+)"); if offset then ox=ox-tonumber(offset) align="end" end
	offset=match(dir,"R(%d+)"); if offset then ox=ox+tonumber(offset) align="start"  end
	offset=match(dir,"M()"); if offset then oy=oy+fontsize/3 end
	o.lx=ox; o.ly=oy; o.align=align; 
	return o
end

local get_border=function(node,p)
	local cx,cy,rx,ry=unpack(node)
	local x,y=unpack(p)
	return {cx<x and cx+rx or cx>x and cx-rx or cx, cy<y and cy+ry or cy>y and cy-ry or cy}
end

local push=push or table.insert
local make_path=function(from,to,shape,dw,dh)
	local cx,cy,dir=(from[1]+to[1])/2,(from[2]+to[2])/2,"M"
	local path={}
	local p1,p2
	if shape=="-" then 
		push(path, from.TYPE and get_border(from,to) or from)
		push(path,to.TYPE and get_border(to,from) or to)
	elseif shape=="7" then
		cx,cy=to[1],from[2]
		p1={cx,cy}
		push(path,from.TYPE and get_border(from,p1) or from)
		push(path,p1)
		push(path,to.TYPE and get_border(to,p1) or to)
		dir=cy>to[2] and "D1" or "U1"
	elseif shape=="L" then 
		cx,cy=from[1],to[2]
		p1={cx,cy}
		push(path,from.TYPE and get_border(from,p1) or from)
		push(path,p1)
		push(path,to.TYPE and get_border(to,p1) or to)
		dir=cy>from[2] and "D1" or "U1" 
	elseif shape=="Z" then 
		p1={cx,from[2]};		p2={cx,to[2]}
		push(path,from.TYPE and get_border(from,p1) or from)
		push(path,p1)
		push(path,p2)
		push(path,to.TYPE and get_border(to,p2) or to)
	elseif shape=="N" then
		p1={from[1],cy};		p2={to[1],cy}
		push(path,from.TYPE and get_border(from,p1) or from)
		push(path,p1)
		push(path,p2)
		push(path,to.TYPE and get_border(to,p2) or to)
	elseif shape=="C" then 
		cx=from[1]>to[1] and from[1]+dw or to[1]+dw
		p1={cx,from[2]};		p2={cx,to[2]}
		push(path,from.TYPE and get_border(from,p1) or from)
		push(path,p1)
		push(path,p2)
		push(path,to.TYPE and get_border(to,p2) or to)
	elseif shape=="U" then 
		cy=from[2]>to[2] and from[2]+dh or to[2]+dh
		p1={from[1],cy};		p2={to[1],cy}
		push(path,from.TYPE and get_border(from,p1) or from)
		push(path,p1)
		push(path,p2)
		push(path,to.TYPE and get_border(to,p2) or to)
	end
	return path,cx,cy,dir
end

local format=string.format
local POINT_FMT="%s %d %d"
local CUBIC_CURVE_POINT="M %d %d C %d %d %d %d %d %d"
local QUADRATIC_CURVE_POINT="M %d %d Q %d %d %d %d"
local pt2path=function(t,curve)
	local n=#t
	if curve and n==4 then return format(CUBIC_CURVE_POINT,t[1][1],t[1][2],t[2][1],t[2][2],t[3][1],t[3][2],t[4][1],t[4][2]) end
	if curve and n==3 then return format(QUADRATIC_CURVE_POINT,t[1][1],t[1][2],t[2][1],t[2][2],t[3][1],t[3][2]) end
	for i,v in ipairs(t) do
		t[i]= format(POINT_FMT,i==1 and "M" or "L",unpack(v))
	end
	return table.concat(t," ")
end

local line_style={
	dashed="stroke-dasharray:10,3",
	dotted="stroke-dasharray:3,3",
}

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

local copy=function(src,dst)
	dst=dst or {}
	for k,v in pairs(src) do
		dst[k]=v
	end
	return dst
end

local fprint=function(tmp,...)
	print(format(temp,...))
end

local rank_funcs={
	['v']=function(x,y,i,dx,dy) return x,y+i*dy end,
	['h']=function(x,y,i,dx,dy) return x+i*dx,y end,	
	['-v']=function(x,y,i,dx,dy) return x,y-i*dy end,
	['-h']=function(x,y,i,dx,dy) return x-i*dx,y end,

}

make_canvas=function(w,h,c,r,fontsize)
	w,h,r,c,fontsize=w or 800, h or 600, r or 5, c or 5, fontsize or 18
	local dw,dh=w/c,h/r
	local cw,ch=dw/4,dh/4
	-- nodes
	local push,concat,type=table.insert,table.concat,type
	local nodes,edges,labels,defs={},{},{},{}
	-- basic elements
	local label=function(o,xydefined)
		if not xydefined then
			local x,y=unpack(o)
			o.cx=x or 0; o.cy=y or 0;
		end
		config(o.DIR,o,fontsize)
		push(labels,o)
		return #labels
	end
	local node=function(o)
		local cx,cy,rx,ry=o[1] or o.cx or 0, o[2] or o.cy or 0, o[3] or o.rx or cw, o[4] or o.ry or ch
		o[1]=cx;	o[2]=cy;	o[3]=rx;	o[4]=ry;
		o.cx=cx;	o.cy=cy;	o.rx=rx;	o.ry=ry;
		if o.LABEL then label(o,true)  end
		o.TYPE=o.TYPE or "rect"
		push(nodes,o)
		return #nodes
	end
	local edge=function(o)
		local path=o.path
		if not path then
			local from,to,shape = unpack(o)
			from=type(from)=="number" and nodes[from] or {from[1],from[2]}
			to=type(to)=="number" and nodes[to] or {to[1],to[2]}
			local cx,cy,dir
			path,cx,cy,dir=make_path(from,to,shape,dw,dh)
			local l=o.LABEL
			if l then 
				local t={cx,cy,utf8strlen(l)*fontsize/4,fontsize/2,TYPE="lbox",LABEL=l,DIR="M"} 
				node(t)
			end
		end
		local s=o.STYLE
		o.STYLE=s and line_style[s] or ""
		o.HEAD=o.HEAD or "none"
		o.MIDDLE=o.MIDDLE or "none"
		o.TAIL=o.TAIL or "none"
		o.path=pt2path(path,o.IS_CURVE)
		push(edges,o)
		return #edges
	end
	local color=function(o)
		local tp,c1,c2=unpack(o)
		tp=tp or "linear"
		c1=c1 or "#ffffff"
		c2=c2 or c1
		o.color1=c1; o.color2=c2
		local id=#defs+1
		local key=tp..id
		o.KEY=key
		defs[id]=convert(o,tp)
		return format("url(#%s)",key)
	end
	marker=function(o)
		-- generate element
		local tp,w,h=unpack(o)
		tp=tp or "ellipse"; w=w and w or 10; h=h and h or 10;
		rx=w/2; ry=h/2;
		o.cx=rx;	o.cy=ry;	o.rx=rx-1;	o.ry=ry-1;
		o.ELEMENT=convert(o,tp or "rect")
		-- generate "marker"
		local id=#defs+1
		local key="marker"..id
		o.KEY=key
		o.w=w; o.h=h;
		defs[id]=convert(o,"marker")
		return format("url(#%s)",key)
	end
	export=function(path)
		local t={}
		for i,e in ipairs(edges) do push(t,convert(e,"edge")) end
		for i,n in ipairs(nodes) do 
			if n.SHADOW then
				n.filter="url(#shadow)"; 
				push(t,convert(n,n.TYPE)) 
				n.filter=""; 
			end
			push(t,convert(n,n.TYPE)) 
		end
		for i,l in ipairs(labels) do push(t,convert(l,"label")) end
		t.VALUE=concat(t,"\n")
		t.w=w;		t.h=h;	t.fs=fontsize;
		t.DEFS=concat(defs,"\n")
		local str=convert(t,"SVG")
		if path then
			path=io.open(path,"w")
			if path then path:write(str); path:close() end
		else
			print(str)
		end
	end
-- extent functions
	local rank=function(o)
		local no=#o
		if no<2 then fprint("There should be at least 2 nodes to rank!") end
		local ref,dir=nodes[o[1]],o.DIR or "h"
		if not ref then return fprint("Invalid node %q",tostring(ref)) end
		local bx,by=unpack(ref)
		local n,nx,ny
		local f=dir and rank_funcs[dir] or rank_funcs["h"]
		for i=2,no do
			n=nodes[o[i]]
			if n then nx,ny=f(bx,by,i-1,dw,dh); n[1]=nx; n[2]=ny; n.cx=nx; n.cy=ny end
		end
		return unpack(o,2,no)
	end
	local link=function(o)
		local no=#o
		if no<2 then fprint("There should be at least 2 nodes to link!") end
		for i=2,no do
			edge{o[i-1],o[i],o.SHAPE;HEAD=o.HEAD,TAIL=o.TAIL,MIDDLE=o.MIDDLE}
		end
		return unpack(o,2,no)
	end
	
	return export,label,node,edge,rank,link,color,marker,copy
end

SVG={
	ellipse=[[<ellipse cx="@cx@" cy="@cy@" rx="@rx@" ry="@ry@" fill="@BGCOLOR@" filter="@filter@"/>]],
	roundrect=[[<rect x="@cx-rx@" y="@cy-ry@" rx="10" ry="10" width="@rx+rx@" height="@ry+ry@" fill="@BGCOLOR@" filter="@filter@"/>]],
	rect=[[<rect x="@cx-rx@" y="@cy-ry@"  width="@rx+rx@" height="@ry+ry@" fill="@BGCOLOR@" filter="@filter@"/>]],
	circle=[[<circle cx="@cx@" cy="@cy@"  r="@rx@" fill="@BGCOLOR@" filter="@filter@"/>]],
	
	lbox=[[<rect x="@cx-rx@" y="@cy-ry@" width="@rx+rx@" height="@ry+ry@" fill="#ffffff" stroke="none"/>]], -- label box
	label=[[<text x="@cx+lx@" y="@cy+ly@" stroke-width="0" fill="black" text-anchor="@align@">@LABEL@</text>]],
	
	img=[[<image x="@cx-rx@" y="@cy-ry@" width="@rx+rx@" height="@ry+ry@" xlink:href="@SRC@" filter="@filter@" />]],

	
	edge=[[<path d = "@path@" fill = "@BGCOLOR or "none"@" stroke = "black"  stroke-linejoin="round" marker-end = "@HEAD@" marker-mid="@MIDDLE@" marker-start="@TAIL@" style="@STYLE@" filter="@filter@"/>]],
	
-- color

	linear=	[[<linearGradient x1='0%' x2='100%' id='@KEY@' y1='0%' y2='100%'>
			<stop offset='0%' style='stop-color:@color1@;stop-opacity:1'/>
			<stop offset='100%' style='stop-color:@color2@;stop-opacity:1'/>
		</linearGradient>]],
	
	radial=	[[<radialGradient id="@KEY@" cx="30%" cy="30%" r="50%">
			<stop offset="0%" style="stop-color:@color1@; stop-opacity:0" />
			<stop offset="100%" style="stop-color:@color2@;stop-opacity:1" />
     </radialGradient>]],
	
	marker=[[<marker id="@KEY@" viewBox="0 0 @w@ @h@" refX="@cx@" refY="@cy@" markerUnits="strokeWidth"  stroke-width="0.5" markerWidth="@w@" markerHeight="@h@" orient="auto">
			@ELEMENT@
		</marker>]],
-- complex shapes
	["<>"]=[[<path d="M @cx-rx@ @cy@ L @cx@ @cy-ry@ L @cx+rx@ @cy@ L @cx@ @cy+ry@ z"  fill="@BGCOLOR@"  filter="@filter@"/>]],
	["(=)"]=[[<path d="M @cx-rx+ry@ @cy-ry@  Q @cx-rx@ @cy-ry@ @cx-rx@ @cy@ T @cx-rx+ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ Q @cx+rx@ @cy+ry@ @cx+rx@ @cy@ T @cx+rx-ry@ @cy-ry@ z "  fill="@BGCOLOR@"  filter="@filter@"/>]],
	[")=("]=[[<path d="M @cx-rx-ry@ @cy-ry@  Q @cx-rx@ @cy-ry@ @cx-rx@ @cy@ T @cx-rx-ry@ @cy+ry@ L @cx+rx+ry@ @cy+ry@ Q @cx+rx@ @cy+ry@ @cx+rx@ @cy@ T @cx+rx+ry@ @cy-ry@ z "  fill="@BGCOLOR@"  filter="@filter@"/>]],
	round3=[[<path d="M @cx-rx+ry@ @cy-ry@  Q @cx-rx@ @cy-ry@ @cx-rx@ @cy@ T @cx-rx+ry@ @cy+ry@ L @cx+rx+ry@ @cy+ry@ Q @cx+rx@ @cy+ry@ @cx+rx@ @cy@ T @cx+rx+ry@ @cy-ry@ z "  fill="@BGCOLOR@"  filter="@filter@"/>]],
	round4=[[<path d="M @cx-rx-ry@ @cy-ry@  Q @cx-rx@ @cy-ry@ @cx-rx@ @cy@ T @cx-rx-ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ Q @cx+rx@ @cy+ry@ @cx+rx@ @cy@ T @cx+rx-ry@ @cy-ry@ z "  fill="@BGCOLOR@"  filter="@filter@"/>]],
	
	["<=>"]=[[<path d="M @cx-rx+ry@ @cy-ry@  L @cx-rx@ @cy@ L @cx-rx+ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ L @cx+rx@ @cy@ L @cx+rx-ry@ @cy-ry@ z "  fill="@BGCOLOR@" filter="@filter@"/>]],
	case2=[[<path d="M @cx-rx+ry@ @cy-ry@  L @cx-rx@ @cy-ry@ L @cx-rx+ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ L @cx+rx@ @cy+ry@ L @cx+rx-ry@ @cy-ry@ z "  fill="@BGCOLOR@" filter="@filter@"/>]],
	case3=[[<path d="M @cx-rx+ry@ @cy-ry@  L @cx-rx@ @cy-ry@ L @cx-rx+ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ L @cx+rx@ @cy+ry@ L @cx+rx-ry@ @cy-ry@ z "  fill="@BGCOLOR@" filter="@filter@"/>]],
	case4=[[<path d="M @cx-rx+ry@ @cy-ry@  L @cx-rx@ @cy-ry@ L @cx-rx+ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ L @cx+rx@ @cy+ry@ L @cx+rx-ry@ @cy-ry@ z "  fill="@BGCOLOR@"filter="@filter@" />]],
	
	
	SVG=[[
<?xml version="1.0" standalone="no"?>

<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

<svg width="@w@" height="@h@" version="1.1"
xmlns="http://www.w3.org/2000/svg" font-size="@fs@px" stroke-width = "1.5" fill="white" stroke="black">

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
</svg>
]],
}

