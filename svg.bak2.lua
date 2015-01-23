
local shapes={
	ellipse=[[<ellipse cx="@cx@" cy="@cy@" rx="@rx@" ry="@ry@" fill="url(#node)"/> ]],
	roundrect=[[<rect x="@x@" y="@y@" rx="10" ry="10" width="@w@" height="@h@" fill="url(#node)"/>]],
	rect=[[<rect x="@x@" y="@y@"  width="@w@" height="@h@" fill="url(#node)"/>]],

	solid=[[<path d = "@path@" fill = "none" stroke = "black"  marker-end = "url(#arrow-head)" />]],
	dashed=[[<path d = "@path@" fill = "none" stroke = "black"  marker-end = "url(#arrow-head)" style="stroke-dasharray:10,3"/>]],
	dotted=[[<path d = "@path@" fill = "none" stroke = "black"  marker-end = "url(#arrow-head)" style="stroke-dasharray:3,3"/>]],
	
	text=[[<text x="@x@" y="@y@" stroke-width="0" fill="black">@txt@</text>]],
	
	group=[[@VALUE@]],
	
	SVG=[[
<?xml version="1.0" standalone="no"?>

<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

<svg width="@w@" height="@h@" version="1.1"
xmlns="http://www.w3.org/2000/svg" font-size="@fs@" stroke-width = "3" fill="white" stroke="black">

    <defs>
         <marker id = "arrow-head" viewBox = "0 0 20 20" refX = "20" refY = "10" markerUnits = "strokeWidth" markerWidth = "5" markerHeight = "5" stroke = "black"  fill = "none" orient = "auto">
             <path d = "M 0 0 L 20 10 L 0 20"/>
         </marker>
		 <linearGradient id="node" x1="0%" y1="0%" x2="100%" y2="0%">
		   <stop offset="0%" style="stop-color:rgb(255,255,0);stop-opacity:1" />
		   <stop offset="100%" style="stop-color:rgb(255,0,0);stop-opacity:1" />
		</linearGradient>
     </defs>
@VALUE@
</svg>
]],
}


--  UTF-8
--~ 0xxxxxxx
--~ 110xxxxx 10xxxxxx
--~ 1110xxxx 10xxxxxx 10xxxxxx
--~ 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
--~ 111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
--~ 1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx

local gsub,concat,len=string.gsub,table.concat,string.len

local get_len_utf8=function(str)
	local _, c1 = gsub(str, "[\192-\223].", "")
	local _, c2 = gsub(_, "[\224-\239]..", "")
	local _, c3 = gsub(_, "[\240-\247]...", "")
	local _, c4 = gsub(_, "[\248-\251]....", "")
	local _, c5 = gsub(_, "[\252-\253].....", "")
	return c1+c2*2+c3*3+c4*4+c5*5+len(_)
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

local push=table.insert

add_path=function(p,is_curve,cls,pt)
	local o={TYPE=cls or "solid",path=points2path(pt,is_curve)}
	push(p,o)
	return o
end

add_obj=function(p,tp,cx,cy,rx,ry) -- all cx,cy,rx,ry are in [0,1]
	local x,y,w,h,fs=p.x,p.y,p.w,p.h,p.fs
	cx=x+(cx or 0);cy=y+(cy or 0);
	rx=rx or w/2;ry=ry or h/2;
	tp=tp or "group"
	local n={TYPE=tp,cx=cx,cy=cy,rx=rx,ry=ry,x=cx-rx,y=cy-ry,w=rx+rx,h=ry+ry,fs=fs}
	push(p,n)
	return n
end

make_svg=function(x,y,w,h,fs)
	return {TYPE="SVG",x=x or 0, y=y or 0, w=w or 500, h=h or 500,fs=fs or 20}
end


local obj2str
obj2str=function(obj)
	if #obj>0 then -- a group
		for i,v in ipairs(obj) do
			v=obj2str(v)
			obj[i]=v
		end
		obj.VALUE=concat(obj,"\n")
	end
	local tp=obj.TYPE
	local fmt=tp and shapes[tp] or shapes.group
	return (gsub(fmt,"@%s*(.-)%s*@",obj))
end

add_text=function(p,str,tx,ty,dir)
	local x,y,w,h,fs=p.x,p.y,p.w,p.h,p.fs
	tx=x+(tx or 0); ty=y+(ty or 0)
	local n=get_len_utf8(str)/2
	dir=dir or ""
	local o={TYPE="text",x=tx,y=ty,txt=str}
	if string.match(dir,"L") then o.x=tx-n*fs end
	if string.match(dir,"C") then o.x=tx-n*fs/2 end
	if string.match(dir,"M") then o.y=ty+fs/2 end
	if string.match(dir,"D") then o.y=ty+fs end
	push(p,o)
	return o
end

export=function(o,path)
	local str=obj2str(o)
	if not path then print(str) return end
	local f=path and io.open(path,"w")
	if f then f:write(str); f:close() end
end


-- extend functions

add_node=function(p,label,tp,cx,cy,rx,ry)
	local o=add_obj(p,tp or "rect",cx,cy,rx,ry)
	add_text(p,label or "",cx,cy,"CM")
	return o
end

add_edge=function(p,from,to,label,tp,off,cls,is_curve)
	local fcx,fcy,frx,fry=from.cx,from.cy,from.rx,from.ry
	local tcx,tcy,trx,try=to.cx,to.cy,to.rx,to.ry
	local fs=from.fs
	local pt={}
	local tx,ty=(fcx+tcx)/2,(fcy+tcy)/2
	tp=tp or "-"
	if tp=="-" then
		pt[1]={fcx>tcx and fcx-frx or fcx+frx,fcy}
		pt[2]={fcx>tcx and tcx+trx or tcx-trx,tcy}
		add_text(p,label,tx,ty,"C")
	elseif tp=="|"  then 
		pt[1]={fcx,fcy>tcy and fcy-fry or fcy+fry}
		pt[2]={tcx,fcy>tcy and tcy+try or tcy-try}
		add_text(p,label,tx,ty,"R")
	elseif tp=="7"  then 
		tx,ty=tcx,fcy
		pt[1]={fcx>tcx and fcx-frx or fcx+frx,fcy}
		pt[2]={tcx,fcy}
		pt[3]={tcx,fcy>tcy and tcy+try or tcy-try}
		add_text(p,label,tx,ty,"UR")
	elseif tp=="L"  then 
		tx,ty=fcx,tcy
		pt[1]={fcx,fcy>tcy and fcy-fry or fcy+fry}
		pt[2]={fcx,tcy}
		pt[3]={fcx>tcx and tcx+trx or tcx-trx,tcy}
		add_text(p,label,tx,ty,"LD")
	elseif tp=="Z"  then 
		off=off and off*(p.w) or 0
		tx=tx+off
		pt[1]={fcx>tx and fcx-frx or fcx+frx,fcy}
		pt[2]={tx,fcy}
		pt[3]={tx,tcy}
		pt[4]={tx>tcx and tcx+trx or tcx-trx,tcy}
		add_text(p,label,tx,ty,"R")
	elseif tp=="N"  then 
		off=off and off*(p.h) or 0
		ty=ty+off
		pt[1]={fcx,fcy>ty and fcy-fry or fcy+fry}
		pt[2]={fcx,ty}
		pt[3]={tcx,ty}
		pt[4]={tcx,ty>tcy and tcy+try or tcy-try}
		add_text(p,label,tx,ty,"C")
	end
	return add_path(p,is_curve,cls,pt)
end

--~ print(get_len_utf8("[[sdfa]]"))
