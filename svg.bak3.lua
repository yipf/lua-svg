
local shapes={
	ellipse=[[<ellipse cx="@cx@" cy="@cy@" rx="@rx@" ry="@ry@" fill="url(#node)"/> ]],
	roundrect=[[<rect x="@x@" y="@y@" rx="10" ry="10" width="@w@" height="@h@" fill="url(#node)"/>]],
	rect=[[<rect x="@cx-rx@" y="@cy-ry@"  width="@rx+rx@" height="@ry+ry@" fill="url(#node)"/>]],
	circle=[[<circle cx="@cx@" cy="@cy@" r="@rx@" fill="url(#point)" />]],
	
	solid=[[<path d = "@path@" fill = "none" stroke = "black"  marker-end = "url(#arrow-head)" />]],
	dashed=[[<path d = "@path@" fill = "none" stroke = "black"  marker-end = "url(#arrow-head)" style="stroke-dasharray:10,3"/>]],
	dotted=[[<path d = "@path@" fill = "none" stroke = "black"  marker-end = "url(#arrow-head)" style="stroke-dasharray:3,3"/>]],
	
	text=[[<text x="@x@" y="@y@" stroke-width="0" fill="black" text-anchor="@align@">@txt@</text>]],
	
	img=[[<image x="@x@" y="@y@" width="@w@" height="@h@" xlink:href="@src@" />]],
	
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
		<radialGradient id="point" cx="30%" cy="30%" r="50%">
			<stop offset="0%" style="stop-color:rgb(255,255,255); stop-opacity:0" />
			<stop offset="100%" style="stop-color:rgb(0,0,255);stop-opacity:1" />
     </radialGradient>
     </defs>
@VALUE@
</svg>
]],
}

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

local type=type

local copy_obj
copy_obj=function(src,dst)
	if type(src)~="table" then return src end
	dst={}
	for k,v in pairs(src) do
		dst[k]=copy_obj(v)
	end
	return dst
end

add_obj=function(p,tp,cx,cy,rx,ry,info) -- all cx,cy,rx,ry are in [0,1]
	local x,y,w,h,fs=p.x,p.y,p.w,p.h,p.fs
	cx=x+(cx or 0);cy=y+(cy or 0);
	rx=rx or w/2;ry=ry or h/2;
	tp=tp or "group"
	local n=type(tp)=="table" and copy_obj(tp) or {TYPE=tp,cx=cx,cy=cy,rx=rx,ry=ry,x=cx-rx,y=cy-ry,w=rx+rx,h=ry+ry,fs=fs}
	push(p,n)
	return n
end

local match=string.match
local dir2xy=function(op)
	local x,y,r,d,offset=0,0,0,0
	offset=match(op,"U(%d*)"); if offset then y=tonumber(offset); d=-1 end
	offset=match(op,"D(%d*)"); if offset then y=tonumber(offset); d=1 end
	offset=match(op,"L(%d*)"); if offset then x=tonumber(offset); r=-1  end
	offset=match(op,"R(%d*)"); if offset then x=tonumber(offset); r=1 end
	return x,y,r,d
end

rank=function(dir,...)
	local n=#arg
	local ref,to,o
	local x,y,r,d=dir2xy(dir)
	if n>1 then
		for i=1,n-1 do
			ref=arg[i];to=arg[i+1]
			to.cx=ref.cx+r*(ref.rx+to.rx+x); to.x=to.cx-to.rx
			to.cy=ref.cy+d*(ref.ry+to.ry+y); to.y=to.cy-to.ry
		end
	end
	return to
end

make_svg=function(x,y,w,h,fs)
	return {TYPE="SVG",x=x or 0, y=y or 0, w=w or 500, h=h or 500,fs=fs or 20}
end

add_text=function(p,str,tx,ty,op)
	off=off or 0
	local x,y,w,h,fs=p.x,p.y,p.w,p.h,p.fs
	tx=x+(tx or 0); ty=y+(ty or 0)
	op=op or ""
	local o={TYPE="text",x=tx,y=ty,txt=str}
	local offset
	offset=match(op,"U(%d*)"); if offset then o.y=o.y-(tonumber(offset) or 0) end
	offset=match(op,"D(%d*)"); if offset then o.y=ty+fs+(tonumber(offset) or 0) end
	offset=match(op,"L(%d*)"); if offset then o.align="end" o.x=o.x-(tonumber(offset) or 0)  end
	offset=match(op,"R(%d*)"); if offset then o.align="start" o.x=o.x+(tonumber(offset) or 0) end
	offset=match(op,"M()"); if offset then o.y=ty+fs/2 end
	offset=match(op,"C()"); if offset then o.align="middle" end
	push(p,o)
	return o
end


local gsub,concat=string.gsub,table.concat

local make_eval_f=function(t)
	local loadstring,setfenv=loadstring,setfenv
	local eval,f
	eval=function(str,nt)
		if nt then t=nt; return eval end
		print(str)
		f=loadstring("return "..str)
		if f then return setfenv(f,t)() end
	end
	return eval
end

local eval=make_eval_f(_G)

local obj2str
obj2str=function(obj,p)
	local x,y=p.x,p.y
	if #obj>0 then -- a group
		for i,v in ipairs(obj) do
			v=obj2str(v,obj)
			obj[i]=v
		end
		obj.VALUE=concat(obj,"\n")
	end
	local tp=obj.TYPE
	local fmt=tp and shapes[tp] or shapes.group
	return (gsub(fmt,"@(.-)@",eval(nil,obj)))
end

export=function(o,path)
	local str=obj2str(o)
	if not path then print(str) return end
	local f=path and io.open(path,"w")
	if f then f:write(str); f:close() end
end

-- extend functions

add_node=function(p,label,tp,cx,cy,rx,ry)
	local n={TYPE="rect"}
	if label then add_text(n,label or "",rx,ry,"CM")
	return add_obj(p,n,cx,cy,rx,ry)
end

local tonumber=tonumber

add_node_r=function(p,label,tp,ref,op) 	-- make a node with same size of ref at dir
	local cx,cy,rx,ry=ref.cx,ref.cy,ref.rx,ref.ry 
	local offset
	offset=match(op,"U(%d*)"); if offset then cy=cy-(tonumber(offset) or 0) end
	offset=match(op,"D(%d*)"); if offset then cy=cy+(tonumber(offset) or 0) end
	offset=match(op,"L(%d*)"); if offset then cx=cx-(tonumber(offset) or 0) end
	offset=match(op,"R(%d*)"); if offset then cx=cx+(tonumber(offset) or 0) end
	return add_node(p,label,tp,cx,cy,rx,ry)
end

add_edge=function(p,from,to,label,tp,cls,is_curve)
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
		pt[1]={fcx>tx and fcx-frx or fcx+frx,fcy}
		pt[2]={tx,fcy}
		pt[3]={tx,tcy}
		pt[4]={tx>tcx and tcx+trx or tcx-trx,tcy}
		add_text(p,label,tx,ty,"R")
	elseif tp=="N"  then 
		pt[1]={fcx,fcy>ty and fcy-fry or fcy+fry}
		pt[2]={fcx,ty}
		pt[3]={tcx,ty}
		pt[4]={tcx,ty>tcy and tcy+try or tcy-try}
		add_text(p,label,tx,ty,"UC")
	end
	return add_path(p,is_curve,cls,pt)
end

add_point=function(p,cx,cy,r,label,dir,off)
	local o=add_obj(p,"circle",cx,cy,r,r)
	off=off or 5
	add_text(p,label,cx,cy,dir,r+off)
	return o
end

print(tonumber(""))

--~ print(get_len_utf8("[[sdfa]]"))
