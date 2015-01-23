
-- basic functions
local type=type

local make_eval_f=function(env)
	local f
	local loadstring,setfenv
	return function(str)
		f=loadstring(str)
		return f and setfenv(f,env)()
	end
end

local convert=function(tp,o,p,ref)
	local tmp=tp and ref[tp]
	tp=type(tmp)
	return tp=="function" and tmp(o,p) or (gsub(tmp,"@(.-)@",o)) 
end

local obj2str
obj2str=function(obj,ref)
	if type(obj)~="table" then return obj end
	for i,v in ipairs(obj) do
		obj[i]=obj2str(obj,ref)
	end
	obj.VALUE=#obj>0 and table.concat(obj,"\n")
	return convert(obj.TYPE,obj,nil,ref)
end

export=function(obj,path)
	local str=obj2str(o)
	if not path then print(str) return end
	local f=path and io.open(path,"w")
	if f then f:write(str); f:close() end
end

-- objs




local copy
copy=function(src,dst)
	if type(src)~="table" then return src end
	dst={}
	for k,v in pairs(src) do
		dst[k]=copy(v)
	end
	return dst
end

local match,tonumber=string.match,tonumber
local dir2xy=function(op)
	local x,y,r,d,offset=0,0,0,0
	if op then
		offset=match(op,"U(%-?%d*)"); if offset then y=tonumber(offset) or 0; d=-1 end
		offset=match(op,"D(%-?%d*)"); if offset then y=tonumber(offset) or 0; d=1 end
		offset=match(op,"L(%-?%d*)"); if offset then x=tonumber(offset) or 0; r=-1  end
		offset=match(op,"R(%-?%d*)"); if offset then x=tonumber(offset) or 0; r=1 end
	end
	return x,y,r,d
end

-- make functions

local type=type
make_obj=function(tp,cx,cy,rx,ry)
	local o= type(tp)=="table" and copy(tp) or {TYPE=tp}
	o.cx=cx or o.cx or 0; o.cy=cy or o.cy or 0; o.rx=rx or o.rx or 1; o.ry=ry or o.ry or 1;
	return o
end

make_label=function(label,dir,fs)
	dir=dir or "CM"
	local x,y,r,d=dir2xy(dir)
	align= r==1 and "start" or r==-1 and "end" or "middle"
	y= d==1 and y+fs or d==0 and y+fs/2 or y
	return {TYPE="label",label=label,cx=x,cy=y,align=align}
end

local POINT_FMT="%s %d %d"
local format=string.format
local CUBIC_CURVE_POINT="M %d %d C %d %d %d %d %d %d"
local QUADRATIC_CURVE_POINT="M %d %d Q %d %d %d %d"

local points2path=function(t,curve)
	local n=#t
	if curve and n==4 then return format(CUBIC_CURVE_POINT,t[1][1],t[1][2],t[2][1],t[2][2],t[3][1],t[3][2],t[4][1],t[4][2]) end
	if curve and n==3 then return format(QUADRATIC_CURVE_POINT,t[1][1],t[1][2],t[2][1],t[2][2],t[3][1],t[3][2]) end
	for i,v in ipairs(t) do
		t[i]= format(POINT_FMT,i==1 and "M" or "L",unpack(v))
	end
	return table.concat(t," ")
end

make_path=function(pt,tp)
	local curve,cls=match(tp,"^%s*C:(%S+)%s*$")
	cls=cls or tp or "solid"
	return {TYPE=cls,path=points2path(pt,curve)}
end

-- orgnize  functions

local push=push or table.insert
append=function(p,c)
	c.fs=p.fs
	push(p,c)
	return c
end

rank=function(dir,...)
	local n=#arg
	local ref,to
	local x,y,r,d=dir2xy(dir)
	if n>1 then
		for i=1,n-1 do
			ref=arg[i];to=arg[i+1]
			to.cx=ref.cx+r*(ref.rx+to.rx+x); 
			to.cy=ref.cy+d*(ref.ry+to.ry+y); 
		end
	end
	return to
end

-- generate functions

local make_eval_f=function(t)
	local loadstring,setfenv=loadstring,setfenv
	local eval,f
	eval=function(str)
		f=loadstring("return "..str)
		if f then return setfenv(f,t)() end
	end
	return eval
end

local gsub,concat=gsub or string.gsub,table.concat

local obj2str
obj2str=function(o)
	if type(o)~="table" then return o end
	local cx,cy=o.cx,o.cy
	for i,v in ipairs(o) do
		v.cx=v.cx+cx;v.cy=v.cy+cy;
		o[i]=obj2str(v)
	end
	o.VALUE=#o>0 and concat(o,"\n") or ""
	local tmp=shapes[o.TYPE] or shapes.rect
	return (gsub(tmp,"@(.-)@",make_eval_f(o)))
end

export=function(o,path)
	local str=obj2str(o)
	if not path then print(str) return end
	local f=path and io.open(path,"w")
	if f then f:write(str); f:close() end
end

-- grammer sugars

copy_node=copy

make_svg=function(x,y,w,h,fs)
	x=x or 0;
	y=y or 0;
	w=w or 600;
	h=h or 600;
	return {TYPE="SVG",cx=x+w/2,cy=y+h/2,rx=w/2,ry=h/2, fs=fs or 20}
end

make_node=function(label,tp,cx,cy,rx,ry)
	local n=make_obj(tp,cx,cy,rx,ry)
	n.label=label or n.label
	return n
end

make_edge=function(label,p,from,to,shape,cls)
	local fcx,fcy,frx,fry=from.cx,from.cy,from.rx,from.ry
	local tcx,tcy,trx,try=to.cx,to.cy,to.rx,to.ry
	local fs=from.fs
	local pt={}
	local tx,ty,align=(fcx+tcx)/2,(fcy+tcy)/2
	shape=shape or "-"
	cls=cls or "solid"
	if shape=="-" then
		pt[1]={fcx>tcx and fcx-frx or fcx+frx,fcy}
		pt[2]={fcx>tcx and tcx+trx or tcx-trx,tcy}
		align="middle";
	elseif shape=="|"  then 
		pt[1]={fcx,fcy>tcy and fcy-fry or fcy+fry}
		pt[2]={tcx,fcy>tcy and tcy+try or tcy-try}
		ty=ty+fs/2
		align="start"
	elseif shape=="7"  then 
		tx,ty=tcx,fcy
		pt[1]={fcx>tcx and fcx-frx or fcx+frx,fcy}
		pt[2]={tcx,fcy}
		pt[3]={tcx,fcy>tcy and tcy+try or tcy-try}
		align="start"
	elseif shape=="L"  then 
		tx,ty=fcx,tcy
		pt[1]={fcx,fcy>tcy and fcy-fry or fcy+fry}
		pt[2]={fcx,tcy}
		pt[3]={fcx>tcx and tcx+trx or tcx-trx,tcy}
		ty=ty+fs
		align="end"
	elseif shape=="Z"  then 
		pt[1]={fcx>tx and fcx-frx or fcx+frx,fcy}
		pt[2]={tx,fcy}
		pt[3]={tx,tcy}
		pt[4]={tx>tcx and tcx+trx or tcx-trx,tcy}
		ty=ty+fs/2
		align="start"
	elseif shape=="N"  then 
		pt[1]={fcx,fcy>ty and fcy-fry or fcy+fry}
		pt[2]={fcx,ty}
		pt[3]={tcx,ty}
		pt[4]={tcx,ty>tcy and tcy+try or tcy-try}
		align="middle"
	end
	local e=make_path(pt,cls)
	e.cx=tx; e.cy=ty; e.align=align;
	e.label=label
	return e
end


-- shape templates

shapes={
	ellipse=[[<ellipse cx="@cx@" cy="@cy@" rx="@rx@" ry="@ry@" fill="url(#node)"/><text x="@cx@" y="@cy+fs/2@" stroke-width="0" fill="black" text-anchor="middle">@label or ""@</text> ]],
	roundrect=[[<rect x="@cx-rx@" y="@cy-ry@" rx="10" ry="10" width="@rx+rx@" height="@ry+ry@" fill="url(#node)"/><text x="@cx@" y="@cy+fs/2@" stroke-width="0" fill="black" text-anchor="middle">@label or ""@</text>]],
	rect=[[<rect x="@cx-rx@" y="@cy-ry@"  width="@rx+rx@" height="@ry+ry@" fill="url(#node)"/><text x="@cx@" y="@cy+fs/2@" stroke-width="0" fill="black" text-anchor="middle">@label or ""@</text>]],
	
	point=[[<circle cx="@cx@" cy="@cy@" r="@rx@" fill="url(#point)" />]],
	
	solid=[[<path d = "@path@" fill = "none" stroke = "black"  marker-end = "url(#arrow-head)" /><text x="@cx@" y="@cy@" stroke-width="0" fill="black" text-anchor="@align@">@label or ""@</text>]],
	dashed=[[<path d = "@path@" fill = "none" stroke = "black"  marker-end = "url(#arrow-head)" style="stroke-dasharray:10,3"/>]],
	dotted=[[<path d = "@path@" fill = "none" stroke = "black"  marker-end = "url(#arrow-head)" style="stroke-dasharray:3,3"/>]],
	
	text=[[<text x="@cx@" y="@cy@" stroke-width="0" fill="black" text-anchor="@align@">@txt@</text>]],
	
	img=[[<image x="@cx+rx@" y="@cy+ry@" width="@rx+rx@" height="@ry+ry@" xlink:href="@src@" />]],
	
	group=[[@VALUE@]],
	
	SVG=[[
<?xml version="1.0" standalone="no"?>

<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

<svg width="@rx+rx@" height="@ry+ry@" version="1.1"
xmlns="http://www.w3.org/2000/svg" font-size="@fs@" stroke-width = "3" fill="white" stroke="black">

    <defs>
         <marker id = "arrow-head" viewBox = "0 0 20 20" refX = "20" refY = "10" markerUnits = "strokeWidth" markerWidth = "5" markerHeight = "5" stroke = "black"  fill = "none" orient = "auto">
             <path d = "M 0 0 L 20 10 L 0 20"/>
         </marker>
		 <linearGradient id="node" x1="0%" y1="0%" x2="100%" y2="0%">
		   <stop offset="0%" style="stop-color:rgb(255,255,0);stop-opacity:1" />
		   <stop offset="100%" style="stop-color:rgb(255,0,0);stop-opacity:1" />
		</linearGradient>
		<radialGradient id="point" cx="30%" cy="30%" r="50%">
			<stop offset="0%" style="stop-color:rgb(255,255,255); stop-opacity:0" />
			<stop offset="100%" style="stop-color:rgb(0,0,255);stop-opacity:1" />
     </radialGradient>
     </defs>
@VALUE@
</svg>
]],
}

