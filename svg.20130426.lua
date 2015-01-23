


























-- utils

local gmatch=string.gmatch
local obj={}
local str2args=function(str)
	local n=0
	for w in gmatch(str.."|","(.-)|") do
		n=n+1;obj[n]=w
	end
	return unpack(obj,1,n)
end

local make_eval_func=function(o)
	local loadstring,setfenv=loadstring,setfenv
	return function(str)
		local f=loadstring("return "..str)
		if f then return setfenv(f,o)() end
	end
end

local gsub=string.gsub
local eval_tmp=function(tmp,o)
	str=gsub(tmp,"@(.-)@",make_eval_func(o))
	return str
end

local format=string.format
local convert=function(tmp,o)
	if not tmp then return "ERROR!" end
	return type(tmp)=="function" and f(tmp) or eval_tmp(tmp,o)
end

local concat= table.concat
local pos2key=function(pos)
	return concat(pos,";")
end

local match,tonumber=string.match,tonumber
local dir2offset=function(dir)
	local ox,oy=0,0
	local offset
	offset=match(dir,"U(%d*)"); offset=offset and tonumber(offset) or 0; if offset then oy=oy+offset end;
	offset=match(dir,"D(%d*)"); offset=offset and tonumber(offset) or 0; if offset then oy=oy-offset end;
	offset=match(dir,"L(%d*)"); offset=offset and tonumber(offset)  or 0; if offset then ox=ox-offset end;
	offset=match(dir,"R(%d*)"); offset=offset and tonumber(offset) or 0; if offset then ox=ox+offset end;
	return ox,oy
end

local push=push or table.insert

local offset=function(from,to,rx)
	return from>to and rx or from<to and -rx or 0
end

local POINT_FMT="%s %d %d"
local CUBIC_CURVE_POINT="M %d %d C %d %d %d %d %d %d"
local QUADRATIC_CURVE_POINT="M %d %d Q %d %d %d %d"
local points2str=function(t,curve)
	local n=#t
	if curve and n==4 then return format(CUBIC_CURVE_POINT,t[1][1],t[1][2],t[2][1],t[2][2],t[3][1],t[3][2],t[4][1],t[4][2]) end
	if curve and n==3 then return format(QUADRATIC_CURVE_POINT,t[1][1],t[1][2],t[2][1],t[2][2],t[3][1],t[3][2]) end
	for i,v in ipairs(t) do
		t[i]= format(POINT_FMT,i==1 and "M" or "L",unpack(v))
	end
	return table.concat(t," ")
end


local TMPS
make_svg=function(w,h,r,c,fs)
	w=w or 800;	h=h or 600;	r=r or 8;	c=c or 6;	fs=fs or 20;
	local cw,ch=w/c,h/r
	local paths,shapes,labels={},{},{}
	local push=table.insert
	--- add a label
	local label=function(pos,ll,opt,dir)
		local ox,oy=dir2offset(dir or "")
		local l={label=ll,pos=pos,ox=ox,oy=oy,opt=opt or ""}
		push(labels,l)
		return pos
	end
	-- add a shape
	local shape=function(pos,style,opt,rx,ry)
		local s={pos=pos,shape=style,opt=opt or "",rx=rx or cw/3,ry=ry or ch/3}
		push(shapes,s)
		return #shapes
	end
	-- add a path
	local path=function(style,opt,...)
		local linetype,curve=str2args(style or "solid")
		local p={linetype=linetype,opt=opt or "",curve= curve=="C",points=arg}
		push(paths,p)
		return p
	end
	-- extend
	local node=function(pos,l,style,dir,rx,ry)
		label(pos,l,dir)
		return shape(pos,style,rx,ry)
	end
	local edge=function(fid,tid,shape,label,style,opt)
		form,to=shapes[fid].pos,shape[tid].pos
		shape=shape or "-"
		local pt={from,to}
		local fr,fc,tr,tc=from[1],from[2],to[1],to[2]
		local lr,lc,dir=(fr+tr)/2,(fc+tc)/2,"CM"
		shape=shape or "-"
		style=style or "solid"
		off=off or 1
		if shape=="-" then
		elseif shape=="7" then lr=fr;lc=tc; push(pt,2,{lr,lc})
		elseif shape=="L" then lr=tr;lc=fc; push(pt,2,{lr,lc})
		elseif shape=="Z" then push(pt,2,{fr,lc}); push(pt,3,{tr,lc})
		elseif shape=="N" then push(pt,2,{lr,fc}); push(pt,3,{lr,tc})
		elseif shape=="C" then lc= fc>tc and tc-off or tc+off; push(pt,2,{fr,lc}); push(pt,3,{tr,lc})
		elseif shape=="U" then	lr=fr<tr and tr+off or tr-off; push(pt,2,{lr,fc});push(pt,3,{lr,tc})
		end
		path(style,opt,fid,tid,unpack(pt))
		return {lc,lr}
	end
	
	local get_pos=function(pos)
		pos= type(pos)~="table" and shapes[pos].pos or pos
		return {pos[2]*cw,pos[1]*ch}
	end
	
	export=function(filepath)
		local g={w=w,h=h,fs=fs}
		-- draw paths
		local pos,s,n
		for i,p in ipairs(paths) do
			local n=#p
			if n>2 then
				for i,v in ipairs(p) do
					if (i==1 or i==n) and type(v)~="table" then  -- head and tail
							s=shapes[v]
							c=get_pos(p[i==1 and 2 or n-1])
							v=get_pos(v)
							v[1]=v[1]+offset(c[1],v[1],s.rx)
							v[2]=v[2]+offset(c[2],v[2],s.ry)
					else
						v=get_pos(v)
					end
					p[i]=v
				end
				p.path=points2str(p)
				push(g,convert(TMPS["path"],p))
			end
		end
		-- draw shapes
		for i,v in ipairs(shapes) do
			pos,s=v.pos,v.shape
			v.cx,v.cy=pos[2]*cw,pos[1]*ch
			push(g,convert(TMPS[s],v))
		end
		-- draw labels
		local ox,oy
		for i,v in ipairs(labels) do
			pos,ox,oy=v.pos,v.ox,v.oy
			v.align=ox>0 and "start" or ox<0 and "end" or "middle"
			v.cx,v.cy=pos[2]*cw+ox,pos[1]*ch+oy+fs/4 
			push(g,convert(TMPS["label"],v))
		end
		-- draw graph
		g.VALUE=concat(g,"\n")
		local str=convert(TMPS["SVG"],g)
		if not filepath then print(str) end
		local f=filepath and io.open(filepath,"w")
		if f then f:write(str); f:close() end
	end
	return export,node,edge,label,shape,path
end

TMPS={
	ellipse=[[<ellipse cx="@cx@" cy="@cy@" rx="@rx@" ry="@ry@" fill="url(#node)"/>]],
	roundrect=[[<rect x="@cx-rx@" y="@cy-ry@" rx="10" ry="10" width="@rx+rx@" height="@ry+ry@" fill="url(#node)"/>]],
	rect=[[<rect x="@cx-rx@" y="@cy-ry@"  width="@rx+rx@" height="@ry+ry@" fill="url(#node)"/>]],
	
	label=[[<text x="@cx@" y="@cy@" stroke-width="0" fill="black" text-anchor="@align@" vertical-align="@valign@">@label@</text>]],
	label_bg=[[<rect x="@cx-rx@" y="@cy-ry@" rx="10" ry="10" width="@rx+rx@" height="@ry+ry@" fill="#ffffff" stroke="none"/>]],
	
	img=[[<image x="@cx+rx@" y="@cy+ry@" width="@rx+rx@" height="@ry+ry@" xlink:href="@src@" />]],
	
	point=[[<circle cx="@cx@" cy="@cy@" r="@rx@" fill="url(#point)" />]],
	
	solid=[[<path d = "@path@" fill = "none" stroke = "black"  stroke-linejoin="round" marker-end = "url(#arrow-head)" marker-mid="url(#middle)"/>]],
	dashed=[[<path d = "@path@" fill = "none" stroke = "black"  stroke-linejoin="round" marker-end = "url(#arrow-head)" style="stroke-dasharray:10,3"/>]],
	dotted=[[<path d = "@path@" fill = "none" stroke = "black"  stroke-linejoin="round" marker-end = "url(#arrow-head)" style="stroke-dasharray:3,3"/>]],
	
-- complex shapes
	diamond=[[<path d="M @cx-rx@ @cy@ L @cx@ @cy-ry@ L @cx+rx@ @cy@ L @cx@ @cy+ry@ z"  fill="url(#node)" />]],
	round1=[[<path d="M @cx-rx+ry@ @cy-ry@  Q @cx-rx@ @cy-ry@ @cx-rx@ @cy@ T @cx-rx+ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ Q @cx+rx@ @cy+ry@ @cx+rx@ @cy@ T @cx+rx-ry@ @cy-ry@ z "  fill="url(#node)" />]],
	round2=[[<path d="M @cx-rx-ry@ @cy-ry@  Q @cx-rx@ @cy-ry@ @cx-rx@ @cy@ T @cx-rx-ry@ @cy+ry@ L @cx+rx+ry@ @cy+ry@ Q @cx+rx@ @cy+ry@ @cx+rx@ @cy@ T @cx+rx+ry@ @cy-ry@ z "  fill="url(#node)" />]],
	round3=[[<path d="M @cx-rx+ry@ @cy-ry@  Q @cx-rx@ @cy-ry@ @cx-rx@ @cy@ T @cx-rx+ry@ @cy+ry@ L @cx+rx+ry@ @cy+ry@ Q @cx+rx@ @cy+ry@ @cx+rx@ @cy@ T @cx+rx+ry@ @cy-ry@ z "  fill="url(#node)" />]],
	round4=[[<path d="M @cx-rx-ry@ @cy-ry@  Q @cx-rx@ @cy-ry@ @cx-rx@ @cy@ T @cx-rx-ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ Q @cx+rx@ @cy+ry@ @cx+rx@ @cy@ T @cx+rx-ry@ @cy-ry@ z "  fill="url(#node)" />]],
	
	case1=[[<path d="M @cx-rx+ry@ @cy-ry@  L @cx-rx@ @cy@ L @cx-rx+ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ L @cx+rx@ @cy@ L @cx+rx-ry@ @cy-ry@ z "  fill="url(#node)" />]],
	case2=[[<path d="M @cx-rx+ry@ @cy-ry@  L @cx-rx@ @cy-ry@ L @cx-rx+ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ L @cx+rx@ @cy+ry@ L @cx+rx-ry@ @cy-ry@ z "  fill="url(#node)" />]],
	case3=[[<path d="M @cx-rx+ry@ @cy-ry@  L @cx-rx@ @cy-ry@ L @cx-rx+ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ L @cx+rx@ @cy+ry@ L @cx+rx-ry@ @cy-ry@ z "  fill="url(#node)" />]],
	case4=[[<path d="M @cx-rx+ry@ @cy-ry@  L @cx-rx@ @cy-ry@ L @cx-rx+ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ L @cx+rx@ @cy+ry@ L @cx+rx-ry@ @cy-ry@ z "  fill="url(#node)" />]],
	
	
	SVG=[[
<?xml version="1.0" standalone="no"?>

<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

<svg width="@w@" height="@h@" version="1.1"
xmlns="http://www.w3.org/2000/svg" font-size="@fs@" stroke-width = "1.5" fill="white" stroke="black">

    <defs>

		<marker id="arrow-head" viewBox="0 0 20 20" refX="20" refY="10" markerUnits="strokeWidth" fill="black" markerWidth="8" markerHeight="6" orient="auto">
			<path d="M 0 0 L 20 10 L 0 20 L 10 10 z"/>
		</marker>
		
				<marker id="middle" viewBox="0 0 20 20" refX="10" refY="10" markerUnits="strokeWidth" fill="orange" markerWidth="6" markerHeight="6" orient="auto">
			<circle cx="10" cy="10" r="10" />
		</marker>
		 
		 <filter id='shadow' filterRes='50' x='0' y='0'>
			<feGaussianBlur stdDeviation='2 2'/>
			<feOffset dx='2' dy='2'/>
		</filter>
		 
		<linearGradient x1='0%' x2='100%' id='node' y1='0%' y2='100%'>
			<stop offset='0%' style='stop-color:rgb(255,255,255);stop-opacity:1'/>
			<stop offset='100%' style='stop-color:rgb(220,220,220);stop-opacity:1'/>
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


--~ for k,v in pairs(SHAPES) do
--~ 	if k~="SVG" then
--~ 		print(string.format("['%s-shadow']=[[%s]],",k,(gsub(v,"^(.-)(/>)$","%1 filter='url(#shadow)' %2%1%2 "))))
--~ 	end
--~ end
