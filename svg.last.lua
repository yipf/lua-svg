
local gmatch=string.gmatch
local obj={}
local str2args=function(str)
	local n=0
	for w in gmatch(str.."|","(.-)|") do
		n=n+1;obj[n]=w
	end
	return unpack(obj,1,n)
end

--~ add_shape=function(svg,pos,style,rx,ry)
--~ 	local m=svg.m,svg.shapes
--~ 	local r,c=unpack(pos)
--~ 	local shape,arg1,arg2=str2args(style)
--~ 	local mr=m[r]
--~ 	if not mr then mr={}; m[r]=mr end
--~ 	mr[c]={shape=shape or "rect",arg1=arg1, arg2=arg2, rx=rx,ry=ry}
--~ 	return pos
--~ end

local push=table.insert
add_path=function(svg,style,...)
	local paths=svg.paths
	arg.style=style
	push(paths,arg)
	return paths
end

add_label=function(svg,pos,label,dir)
	local labels=svg.labels
	local l={label=label,dir=dir,pos=pos}
	push(labels,l)
	return pos
end

add_shape=function(svg,pos,shape,rx,ry)
	local shapes=svg.shapes
	local s={shape=shape,pos=pos,rx=rx,ry=ry}
	push(shapes,s)
	return pos
end

add_image=function(svg,pos,src,rx,ry)
	local shapes=svg.shapes
	local s={shape="img",src=src,pos=pos,rx=rx,ry=ry}
	push(shapes,s)
	return pos
end

add_unit=function(svg,pos,shape,rx,ry)
	local m=svg.m
	local r,c=unpack(pos)
	local mr=m[r]
	if not mr then mr={}; m[r]=mr end
	mr[c]={shape=shape,rx=rx,ry=ry}
	return pos
end

add_node=function(g,pos,label,shape,rx,ry)
	add_label(g,pos,label,"CM")
	add_unit(g,pos,shape,rx,ry)
	return add_shape(g,pos,shape,rx,ry)
end

add_edge=function(g,from,to,label,shape,style,off)
	local pt={from,to}
	local fr,fc,tr,tc=from[1],from[2],to[1],to[2]
	local lr,lc,dir=(fr+tr)/2,(fc+tc)/2,"CM"
	shape=shape or "-"
	style=style or "solid"
	off=off or 1
	if shape=="-" then
	elseif shape=="7" then
		lr=fr;lc=tc;
		push(pt,2,{lr,lc})
	elseif shape=="L" then
		lr=tr;lc=fc;
		push(pt,2,{lr,lc})
	elseif shape=="Z" then
		push(pt,2,{fr,lc})
		push(pt,3,{tr,lc})
	elseif shape=="N" then
		push(pt,2,{lr,fc})
		push(pt,3,{lr,tc})
	elseif shape=="C" then
		lc= fc>tc and tc-off or tc+off
		push(pt,2,{fr,lc})
		push(pt,3,{tr,lc})
	elseif shape=="U" then
		lr=fr<tr and tr+off or tr-off
		push(pt,2,{lr,fc})
		push(pt,3,{lr,tc})
	end
	local pos={lr,lc}
	if label then
		local fs=g.fs
		add_shape(g,pos,"label_bg",(string.len(label)*fs/4),fs/2)
		add_label(g,pos,label,dir)
	end
	add_path(g,style,unpack(pt))
	return pos
end

make_g=function(x,y,w,h,row,col,fs)
	x=x or 0; y=y or 0; w=w or 600; h=h or 600
	row=row or 2; col=col or 2;
	return {x=x,y=y,w=w,h=h,cw=w/col,ch=h/row,fs=fs,m={},shapes={},paths={},labels={},fs=fs or 16}
end

local SHAPES

local type=type

local make_eval_f=function(env)
	local f
	local loadstring,setfenv=loadstring,setfenv
	return function(str)
		f=loadstring("return "..str)
		return f and setfenv(f,env)()
	end
end

local gsub=string.gsub
local convert=function(tp,o)
	local tmp=SHAPES[tp]
	if not tmp then return "No invalid handle for: "..tp end
	return type(tmp)=="function" and tmp(o) or (gsub(tmp,"@%s*(.-)%s*@",type(o)=="table" and make_eval_f(o) or o))
end



local POINT_FMT="%s %d %d"
local format=string.format
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

local offset=function(from,to,rx)
	return from>to and rx or from<to and -rx or 0
end

local match=string.match
local dir2off=function(dir,fs)
	dir=dir or "CM"
	local ox,oy,align,valign=0,0,"middle","middle"
	local off
	off=match(dir,"M()") if off then oy=fs/2 end
	off=match(dir,"C()") if off then align="middle" end
	off=match(dir,"D(%d*)") if off then oy=fs+(tonumber(off) or 0) end
	off=match(dir,"U(%d*)") if off then oy=-(tonumber(off) or 0) end
	off=match(dir,"L(%d*)") if off then align="end";ox=-(tonumber(off) or 0) end
	off=match(dir,"R(%d*)") if off then ox=(tonumber(off) or 0); align="start" end
	return ox,oy,align,valign
end

export=function(svg,path)
	local m,x,y,cw,ch,fs=svg.m,svg.x,svg.y,svg.cw,svg.ch,svg.fs
	local push=table.insert
	local t={}
	local rx,ry,cx,cy=cw/3,ch/6
	-- draw paths
	local paths=svg.paths
	local style,pre,nex,ps,cx,cy
	local pt,mr
	for i,v in ipairs(paths) do
		ps=#v
		if ps>1 then
			pt={}
			for ii,vv in ipairs(v) do
				cy=vv[1]*ch; cx=vv[2]*cw;
				mr=m[vv[1]]
				n=mr and mr[vv[2]]
				if ii==1 and n then -- come from a node
					nex=v[2]
					cx=cx+offset(nex[2],vv[2],n.rx or rx)
					cy=cy+offset(nex[1],vv[1],n.ry or ry)
				elseif ii==ps and n then -- point to a node
					pre=v[ps-1]
					cx=cx+offset(pre[2],vv[2],n.rx or rx)
					cy=cy+offset(pre[1],vv[1],n.ry or ry)
				end
				pt[ii]={cx,cy}
			end
			local style,curve=str2args(v.style)
			print(style)
			push(t,convert(style,points2str(pt,curve)))
		end
	end
	-- draw shapes
--~ 	local n
--~ 	for i,mr in pairs(m) do
--~ 		for j,n in pairs(mr) do
--~ 			n.cx,n.cy=j*cw,i*ch
--~ 			n.rx,n.ry=n.rx or rx, n.ry or ry
--~ 			n.fs=fs
--~ 			push(t,convert(n.shape,n))
--~ 		end
--~ 	end
	local shapes=svg.shapes
	local n,r,c,cx,cy
	for i,v in ipairs(shapes) do
		r,c=unpack(v.pos)
		cx,cy=c*cw,r*ch
		v.cx,v.cy=cx,cy
		v.rx,v.ry=v.rx or rx, v.ry or ry
		v.fs=fs
		push(t,convert(v.shape,v))
	end
	-- draw labels
	local labels=svg.labels
	local dir,r,c,offset,ox,oy,align,valign
	for i,v in ipairs(labels) do
		r,c=unpack(v.pos)
		cx,cy=c*cw,r*ch
		ox,oy,align,valign=dir2off(v.dir,fs)
		v.cx=cx+ox; v.cy=cy+oy; v.align=align;
		push(t,convert("label",v))
	end
	-- draw g
	svg.VALUE=table.concat(t,"\n")
	local str=convert("SVG",svg)
	if not path then print(str) return end
	local f=path and io.open(path,"w")
	if f then f:write(str); f:close() end
end

SHAPES={
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
	
	
['round2-shadow']=[[<path d="M @cx-rx-ry@ @cy-ry@  Q @cx-rx@ @cy-ry@ @cx-rx@ @cy@ T @cx-rx-ry@ @cy+ry@ L @cx+rx+ry@ @cy+ry@ Q @cx+rx@ @cy+ry@ @cx+rx@ @cy@ T @cx+rx+ry@ @cy-ry@ z "  fill="url(#node)"  filter='url(#shadow)' /><path d="M @cx-rx-ry@ @cy-ry@  Q @cx-rx@ @cy-ry@ @cx-rx@ @cy@ T @cx-rx-ry@ @cy+ry@ L @cx+rx+ry@ @cy+ry@ Q @cx+rx@ @cy+ry@ @cx+rx@ @cy@ T @cx+rx+ry@ @cy-ry@ z "  fill="url(#node)" /> ]],
['point-shadow']=[[<circle cx="@cx@" cy="@cy@" r="@rx@" fill="url(#point)"  filter='url(#shadow)' /><circle cx="@cx@" cy="@cy@" r="@rx@" fill="url(#point)" /> ]],
['label-shadow']=[[<text x="@cx@" y="@cy@" stroke-width="0" fill="black" text-anchor="@align@" vertical-align="@valign@">@label@</text>]],
['ellipse-shadow']=[[<ellipse cx="@cx@" cy="@cy@" rx="@rx@" ry="@ry@" fill="url(#node)" filter='url(#shadow)'/><ellipse cx="@cx@" cy="@cy@" rx="@rx@" ry="@ry@" fill="url(#node)" />]],
['label_bg-shadow']=[[<rect x="@cx-rx@" y="@cy-ry@" rx="10" ry="10" width="@rx+rx@" height="@ry+ry@" fill="#ffffff" stroke="none" filter='url(#shadow)' /><rect x="@cx-rx@" y="@cy-ry@" rx="10" ry="10" width="@rx+rx@" height="@ry+ry@" fill="#ffffff" stroke="none"/> ]],
['diamond-shadow']=[[<path d="M @cx-rx@ @cy@ L @cx@ @cy-ry@ L @cx+rx@ @cy@ L @cx@ @cy+ry@ z"  fill="url(#node)"  filter='url(#shadow)' /><path d="M @cx-rx@ @cy@ L @cx@ @cy-ry@ L @cx+rx@ @cy@ L @cx@ @cy+ry@ z"  fill="url(#node)" /> ]],
['case1-shadow']=[[<path d="M @cx-rx+ry@ @cy-ry@  L @cx-rx@ @cy@ L @cx-rx+ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ L @cx+rx@ @cy@ L @cx+rx-ry@ @cy-ry@ z "  fill="url(#node)"  filter='url(#shadow)' /><path d="M @cx-rx+ry@ @cy-ry@  L @cx-rx@ @cy@ L @cx-rx+ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ L @cx+rx@ @cy@ L @cx+rx-ry@ @cy-ry@ z "  fill="url(#node)" /> ]],
['dashed-shadow']=[[<path d = "@path@" fill = "none" stroke = "black"  stroke-linejoin="round" marker-end = "url(#arrow-head)" style="stroke-dasharray:10,3" filter='url(#shadow)' /><path d = "@path@" fill = "none" stroke = "black"  stroke-linejoin="round" marker-end = "url(#arrow-head)" style="stroke-dasharray:10,3"/> ]],
['round3-shadow']=[[<path d="M @cx-rx+ry@ @cy-ry@  Q @cx-rx@ @cy-ry@ @cx-rx@ @cy@ T @cx-rx+ry@ @cy+ry@ L @cx+rx+ry@ @cy+ry@ Q @cx+rx@ @cy+ry@ @cx+rx@ @cy@ T @cx+rx+ry@ @cy-ry@ z "  fill="url(#node)"  filter='url(#shadow)' /><path d="M @cx-rx+ry@ @cy-ry@  Q @cx-rx@ @cy-ry@ @cx-rx@ @cy@ T @cx-rx+ry@ @cy+ry@ L @cx+rx+ry@ @cy+ry@ Q @cx+rx@ @cy+ry@ @cx+rx@ @cy@ T @cx+rx+ry@ @cy-ry@ z "  fill="url(#node)" /> ]],
['dotted-shadow']=[[<path d = "@path@" fill = "none" stroke = "black"  stroke-linejoin="round" marker-end = "url(#arrow-head)" style="stroke-dasharray:3,3" filter='url(#shadow)' /><path d = "@path@" fill = "none" stroke = "black"  stroke-linejoin="round" marker-end = "url(#arrow-head)" style="stroke-dasharray:3,3"/> ]],
['case4-shadow']=[[<path d="M @cx-rx+ry@ @cy-ry@  L @cx-rx@ @cy-ry@ L @cx-rx+ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ L @cx+rx@ @cy+ry@ L @cx+rx-ry@ @cy-ry@ z "  fill="url(#node)"  filter='url(#shadow)' /><path d="M @cx-rx+ry@ @cy-ry@  L @cx-rx@ @cy-ry@ L @cx-rx+ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ L @cx+rx@ @cy+ry@ L @cx+rx-ry@ @cy-ry@ z "  fill="url(#node)" /> ]],
['solid-shadow']=[[<path d = "@path@" fill = "none" stroke = "black"  stroke-linejoin="round" marker-end = "url(#arrow-head)"  filter='url(#shadow)' /><path d = "@path@" fill = "none" stroke = "black"  stroke-linejoin="round" marker-end = "url(#arrow-head)" /> ]],
['rect-shadow']=[[<rect x="@cx-rx@" y="@cy-ry@"  width="@rx+rx@" height="@ry+ry@" fill="url(#node)" filter='url(#shadow)' /><rect x="@cx-rx@" y="@cy-ry@"  width="@rx+rx@" height="@ry+ry@" fill="url(#node)"/> ]],
['case2-shadow']=[[<path d="M @cx-rx+ry@ @cy-ry@  L @cx-rx@ @cy-ry@ L @cx-rx+ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ L @cx+rx@ @cy+ry@ L @cx+rx-ry@ @cy-ry@ z "  fill="url(#node)"  filter='url(#shadow)' /><path d="M @cx-rx+ry@ @cy-ry@  L @cx-rx@ @cy-ry@ L @cx-rx+ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ L @cx+rx@ @cy+ry@ L @cx+rx-ry@ @cy-ry@ z "  fill="url(#node)" /> ]],
['roundrect-shadow']=[[<rect x="@cx-rx@" y="@cy-ry@" rx="10" ry="10" width="@rx+rx@" height="@ry+ry@" fill="url(#node)" filter='url(#shadow)' /><rect x="@cx-rx@" y="@cy-ry@" rx="10" ry="10" width="@rx+rx@" height="@ry+ry@" fill="url(#node)"/> ]],
['round1-shadow']=[[<path d="M @cx-rx+ry@ @cy-ry@  Q @cx-rx@ @cy-ry@ @cx-rx@ @cy@ T @cx-rx+ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ Q @cx+rx@ @cy+ry@ @cx+rx@ @cy@ T @cx+rx-ry@ @cy-ry@ z "  fill="url(#node)"  filter='url(#shadow)' /><path d="M @cx-rx+ry@ @cy-ry@  Q @cx-rx@ @cy-ry@ @cx-rx@ @cy@ T @cx-rx+ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ Q @cx+rx@ @cy+ry@ @cx+rx@ @cy@ T @cx+rx-ry@ @cy-ry@ z "  fill="url(#node)" /> ]],
['case3-shadow']=[[<path d="M @cx-rx+ry@ @cy-ry@  L @cx-rx@ @cy-ry@ L @cx-rx+ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ L @cx+rx@ @cy+ry@ L @cx+rx-ry@ @cy-ry@ z "  fill="url(#node)"  filter='url(#shadow)' /><path d="M @cx-rx+ry@ @cy-ry@  L @cx-rx@ @cy-ry@ L @cx-rx+ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ L @cx+rx@ @cy+ry@ L @cx+rx-ry@ @cy-ry@ z "  fill="url(#node)" /> ]],
['round4-shadow']=[[<path d="M @cx-rx-ry@ @cy-ry@  Q @cx-rx@ @cy-ry@ @cx-rx@ @cy@ T @cx-rx-ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ Q @cx+rx@ @cy+ry@ @cx+rx@ @cy@ T @cx+rx-ry@ @cy-ry@ z "  fill="url(#node)"  filter='url(#shadow)' /><path d="M @cx-rx-ry@ @cy-ry@  Q @cx-rx@ @cy-ry@ @cx-rx@ @cy@ T @cx-rx-ry@ @cy+ry@ L @cx+rx-ry@ @cy+ry@ Q @cx+rx@ @cy+ry@ @cx+rx@ @cy@ T @cx+rx-ry@ @cy-ry@ z "  fill="url(#node)" /> ]],
['img-shadow']=[[<image x="@cx+rx@" y="@cy+ry@" width="@rx+rx@" height="@ry+ry@" xlink:href="@src@"  filter='url(#shadow)' /><image x="@cx+rx@" y="@cy+ry@" width="@rx+rx@" height="@ry+ry@" xlink:href="@src@" /> ]],

	
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
