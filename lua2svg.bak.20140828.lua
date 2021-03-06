----------------------------------------------------------------------------------------
-- SVG templates
----------------------------------------------------------------------------------------

local templates={
-- base elements
path=[[<path d = "@PATH@" fill = "@BGCOLOR or "none"@" stroke = "@COLOR@"  stroke-linejoin="round" marker-end = "@HEAD@" marker-mid="@MIDDLE@" marker-start="@TAIL@" style="@STYLE or ''@" filter="@FILTER@" />]],
label=[[<text x="@cx+lx@" y="@cy+ly@" stroke-width="0" fill="black" text-anchor="@align@">@LABEL@</text>]],
colorbox=[[<rect x="@cx-rx@" y="@cy-ry@" width="@rx+rx@" height="@ry+ry@" fill="@COLOR or '#ffffff'@" stroke="none"/>]],
-- nodes
rect=[[<rect x="@cx-rx@" y="@cy-ry@" width="@rx+rx@" height="@ry+ry@" filter="@filter@"  style="@STYLE or ''@"/>]],
roundrect=[[<rect x="@cx-rx@" y="@cy-ry@" rx="10" ry="10" width="@rx+rx@" height="@ry+ry@"  style="@STYLE or ''@" filter="@filter@"/>]],
ellipse=[[<ellipse cx="@cx@" cy="@cy@" rx="@rx@" ry="@ry@"   style="@STYLE or ''@" filter="@filter@" />]],
diamond=[[<path d="M @cx-rx@ @cy@ L @cx@ @cy-ry@ L @cx+rx@ @cy@ L @cx@ @cy+ry@ z"   style="@STYLE or ''@"  filter="@filter@" />]],
img=[[<image x="@cx-rx@" y="@cy-ry@" width="@rx+rx@" height="@ry+ry@" xlink:href="@SRC@" filter="@filter@"  style="@STYLE or ''@"/>]],
mulbox=[[<ellipse cx="@cx@" cy="@cy@" rx="@rx@" ry="@ry@"  fill="@COLOR or 'url(#linear0)'@" filter="@filter@"/><path d="M @cx-0.707*rx@ @cy-0.707*ry@ L @cx+0.707*rx@ @cy+0.707*ry@ M @cx-0.707*rx@ @cy+0.707*ry@ L @cx+0.707*rx@ @cy-0.707*ry@" />]],
addbox=[[<ellipse cx="@cx@" cy="@cy@" rx="@rx@" ry="@ry@"  fill="@COLOR or 'url(#linear0)'@" filter="@filter@"/><path d="M @cx-rx@ @cy@ L @cx+rx@ @cy@ M @cx@ @cy-ry@ L @cx@ @cy+ry@" />]],
database=[[
 <ellipse cx="@cx@" cy="@cy+ry@" rx="@rx@" ry="@ry/2@"  style="@STYLE or ''@" filter="@filter@"/>
 <rect x="@cx-rx@" y="@cy-ry@" width="@rx+rx@" height="@ry+ry@" style="@STYLE or ''@" filter="@filter@" stroke="none"/>
 <ellipse cx="@cx@" cy="@cy-ry@" rx="@rx@" ry="@ry/2@"  style="@STYLE or ''@" filter="@filter@"/>
 <path d="M @cx-rx@ @cy-ry@ L @cx-rx@ @cy+ry@ M @cx+rx@ @cy-ry@ L @cx+rx@ @cy+ry@" />
]],
-- colors
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
canvas=[[
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg width="@w or 1000@" height="@h or 1000@" version="1.1" xmlns="http://www.w3.org/2000/svg" font-size="@fs or 20@px" stroke-width = "@lw or 2@" fill="white" stroke="black" viewBox="0 0 @w or 1000@ @h or 1000@">
    <defs>
		<marker id="arrow" viewBox="0 0 20 20" refX="20" refY="10" markerUnits="strokeWidth" fill="black" markerWidth="8" markerHeight="6" orient="auto">
			<path d="M 0 0 L 20 10 L 0 20 L 10 10 z"/>
		</marker>
		<marker id="point2d" viewBox="0 0 20 20" refX="10" refY="10" markerUnits="strokeWidth" fill="orange" markerWidth="6" markerHeight="6" orient="auto">
			<circle cx="10" cy="10" r="9" />
		</marker>
				<marker id="point2d-black" viewBox="0 0 20 20" refX="10" refY="10" markerUnits="strokeWidth" fill="black" markerWidth="6" markerHeight="6" orient="auto">
			<circle cx="10" cy="10" r="9" />
		</marker>
		<marker id="point2d-white" viewBox="0 0 20 20" refX="10" refY="10" markerUnits="strokeWidth" fill="white" markerWidth="6" markerHeight="6" orient="auto">
			<circle cx="10" cy="10" r="9" />
		</marker>
		<marker id="point2d-gray" viewBox="0 0 20 20" refX="10" refY="10" markerUnits="strokeWidth" fill="#888888" markerWidth="6" markerHeight="6" orient="auto">
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
		<linearGradient x1='0%' x2='100%' id='multi0' y1='100%' y2='100%'>
			<stop offset='0%' style='stop-color:rgb(255,255,255);stop-opacity:1'/>
			<stop offset='45%' style='stop-color:rgb(255,255,255);stop-opacity:1'/>
			<stop offset='46%' style='stop-color:rgb(0,0,0);stop-opacity:1'/>
			<stop offset='50%' style='stop-color:rgb(0,0,0);stop-opacity:1'/>
			<stop offset='54%' style='stop-color:rgb(0,0,0);stop-opacity:1'/>
			<stop offset='55%' style='stop-color:rgb(220,220,220);stop-opacity:1'/>
			<stop offset='100%' style='stop-color:rgb(220,220,220);stop-opacity:1'/>
		</linearGradient>
		<linearGradient x1='100%' x2='0%' id='multi1' y1='100%' y2='100%'>
			<stop offset='0%' style='stop-color:rgb(255,255,255);stop-opacity:1'/>
			<stop offset='45%' style='stop-color:rgb(255,255,255);stop-opacity:1'/>
			<stop offset='46%' style='stop-color:rgb(0,0,0);stop-opacity:1'/>
			<stop offset='50%' style='stop-color:rgb(0,0,0);stop-opacity:1'/>
			<stop offset='54%' style='stop-color:rgb(0,0,0);stop-opacity:1'/>
			<stop offset='55%' style='stop-color:rgb(220,220,220);stop-opacity:1'/>
			<stop offset='100%' style='stop-color:rgb(220,220,220);stop-opacity:1'/>
		</linearGradient>
		<linearGradient x1='100%' x2='0%' id='multi2' y1='100%' y2='100%'>
			<stop offset='0%' style='stop-color:rgb(255,255,255);stop-opacity:1'/>
			<stop offset='45%' style='stop-color:rgb(255,255,255);stop-opacity:1'/>
			<stop offset='46%' style='stop-color:rgb(0,0,0);stop-opacity:1'/>
			<stop offset='50%' style='stop-color:rgb(0,0,0);stop-opacity:1'/>
			<stop offset='54%' style='stop-color:rgb(0,0,0);stop-opacity:1'/>
			<stop offset='55%' style='stop-color:rgb(255,255,255);stop-opacity:1'/>
			<stop offset='100%' style='stop-color:rgb(255,255,255);stop-opacity:1'/>
		</linearGradient>
		<radialGradient id="radial0" cx="30%" cy="30%" r="50%">
			<stop offset="0%" style="stop-color:rgb(255,255,255); stop-opacity:0" />
			<stop offset="100%" style="stop-color:rgb(0,0,255);stop-opacity:1" />
     </radialGradient>
	 @DEFS or ""@
     </defs>
	@VALUE or ""@
</svg>
]]
}
local sqrt,abs=math.sqrt,math.abs
local in_range=function(x,min,max)
	return x>=min and x<=max
end
local ellipse_f=function(cx,cy,rx,ry,x,y)
	local dx,dy=x-cx,y-cy
	if cx==x then return cx,cy+(dy>=ry and ry or dy<=-ry and -ry or 0) end
	local t,aa,bb=(cy-y)/(cx-x),rx*rx,ry*ry
	dx=sqrt(aa*bb/(t*t*aa+bb))
	dy=abs(t*dx)
	return cx+(x>cx and dx or -dx),cy+(y>cy and dy or -dy)
end
local rect_f=function(cx,cy,rx,ry,x,y)
	local atan2,tan,pi=math.atan2,math.tan,math.pi
	local dx,dy=x-cx,y-cy
	local a1,a=atan2(dy,dx),atan2(ry,rx)  
	if a1>=a and a1<=pi-a then
		x,y=ry*dx/dy,ry
	elseif a1>=a-pi and a1<=-a then
		x,y=-ry*dx/dy,-ry
	elseif a1>=-a and a1<=a then
		x,y=rx,rx*dy/dx
	else
		x,y=-rx,-rx*dy/dx
	end
	return cx+x,cy+y
end
local diamond_f=function(cx,cy,rx,ry,x,y)
	local abs=math.abs
	local dx,dy=x-cx,y-cy
	local a=ry*abs(dx)/(rx*abs(dy)+ry*abs(dx))
	x,y=a*rx,(1-a)*ry
	x,y=dx<0 and -x or x, dy<0 and -y or y
	return cx+x,cy+y
end
local database_f=function(cx,cy,rx,ry,x,y)
	local atan2,tan,pi=math.atan2,math.tan,math.pi
	local dx,dy=x-cx,y-cy
	local a1,a=atan2(dy,dx),atan2(ry,rx)  
	if a1>0 and a1>a and a1<pi-a then
		return ellipse_f(cx,cy+ry,rx,ry/2,x,y)
	elseif a1<0 and a1<-a and a1>a-pi then
		return ellipse_f(cx,cy-ry,rx,ry/2,x,y)
	else
		return rect_f(cx,cy,rx,ry,x,y)
	end
--~ 	return rect_f(cx,cy,rx,ry+ry/2,x,y)
	
end
local border_funcs={ ['ellipse']=ellipse_f, ['diamond']=diamond_f, ['rect']=rect_f, ['img']=rect_f, ['roundrect']=rect_f,['database']=database_f}

----------------------------------------------------------------------------------------
-- draw functions
--  source code --(build, include define and modifies)--> draw stack --(export)--> svg figures
----------------------------------------------------------------------------------------
SVG={}
--~ local node_stack,edge_stack={},{}
local draw_stack={}
--~ local G={nodes=node_stack,edges=edge_stack}
local push,pop=table.insert,table.remove

local copy_props=function(src,dst)
	dst=dst or {}
	for k,v in pairs(src) do
		if type(k)~="number" then
			dst[k]=v
		end
	end
	return dst
end
copy_node=function(n)
	local nn=copy_props(n)
	for i,v in ipairs(n) do
		nn[i]=copy_node(v)
	end
	return nn
end
local mult_v=function(a1,a2,a3,	b1,b2,b3)
	return a1*b1+a2*b2+a3*b3
end
mult=function(A,B)
	local a1,a2,a3,	a4,a5,a6,	a7,a8,a9=unpack(A)
	local b1,b2,b3,	b4,b5,b6,	b7,b8,b9=unpack(B)
	return { 
		mult_v(a1,a2,a3,	b1,b4,b7),		mult_v(a1,a2,a3,	b2,b5,b8),		mult_v(a1,a2,a3,	b3,b6,b9),
		mult_v(a4,a5,a6,	b1,b4,b7),		mult_v(a4,a5,a6,	b2,b5,b8),		mult_v(a4,a5,a6,	b3,b6,b9),
		mult_v(a7,a8,a9,	b1,b4,b7),		mult_v(a7,a8,a9,	b2,b5,b8),		mult_v(a7,a8,a9,	b3,b6,b9),
	}
end
translate=function(x,y)
	return {1,0,x or 0,	0,1,y or 0,	0,0,1}
end
rotate=function(ang,is_rad)
	ang=is_rad and ang or math.rad(ang)
	local c,s=math.cos(ang),math.sin(ang)
	return {c,s,0,	-s,c,0,	0,0,1}
end
update=function(n,mat)
	n.matrix=n.matrix or translate(0,0)
	mat=mat or translate(0,0)
	mat=mult(mat,n.matrix)
	n.cx,n.cy=mat[3],mat[6]
	for i,v in ipairs(n) do
		update(v,mat)
	end
	return n
end
-- define functions
node=function(n)
	n.rx,n.ry=n.rx or 0,n.ry or 0
	n.cx,n.cy=n.cx or 0,n.cy or 0
	n.TYPE=n.TYPE or "circle"
	n.matrix=n.matrix or translate(0,0)
	push(draw_stack,n)
	return n,#draw_stack
end
edge=function(e)
	if not e.FROM or not e.TO then return end
	e.SHAPE=e.SHAPE or "-"
	push(draw_stack,e)
	return e,#draw_stack
end
-- export function
local make_eval_func=function(env)
	local loadstring,setfenv,gsub=loadstring,setfenv,string.gsub
	local func=function(str)
		local f=loadstring("return "..str)
		if f then 
			setfenv(f,env)
			return f() 
		end
	end
	return func
end
local REPLACE_PAT="@(.-)@"
local gsub=string.gsub
local obj2str=function(obj,key)
	local template=key and templates[key]
	return template and gsub(template,REPLACE_PAT,make_eval_func(obj))
end
local str2xya=function(str)
	local x,y,align=0,0,"middle"
	if not str then return x,y,align end
	local match,tonumber=string.match,tonumber
	v=match(str,"L(%d+)"); x=v and x-tonumber(v) or x
	v=match(str,"R(%d+)"); x=v and x+tonumber(v) or x
	v=match(str,"U(%d+)"); y=v and y-tonumber(v) or y
	v=match(str,"D(%d+)"); y=v and y+tonumber(v) or y
	return x,y, match(str,"S") and "start" or match(str,"E") and "end" or align
end
local get_border=function(n,x,y)
	local f=border_funcs[n.TYPE]
	if f then
		return f(n.cx,n.cy,n.rx,n.ry,x,y)
	end
end
local shape2points=function(shape,from,to,offset)
	local points,cx,cy,x,y={}
	local fx,fy,tx,ty=from.cx,from.cy,to.cx,to.cy
	cx,cy=(fx+tx)/2,(fy+ty)/2
	local max,min=math.max,math.min
	offset=offset or 100
	shape=shape or "-"
	if shape=="-" then
		x,y=get_border(from,tx,ty);	points[1]={x,y}
		x,y=get_border(to,fx,fy);	points[2]={x,y}
	elseif shape=="L" then
		cx,cy=fx,ty
		x,y=get_border(from,cx,cy);	points[1]={x,y}
		points[2]={cx,cy}
		x,y=get_border(to,cx,cy);	points[3]={x,y}
	elseif shape=="7" then
		cx,cy=tx,fy
		x,y=get_border(from,cx,cy);	points[1]={x,y}
		points[2]={cx,cy}
		x,y=get_border(to,cx,cy);	points[3]={x,y}
	elseif shape=="Z" or shape=="C" then
		if shape=="C" then cx=(offset<0 and max(fx,tx) or min(fx,tx))-offset end
		x,y=get_border(from,cx,fy);	points[1]={x,y}
		points[2]={cx,fy}
		points[3]={cx,ty}
		x,y=get_border(to,cx,ty);	points[4]={x,y}
	elseif shape=="N" or shape=="U" then
		if shape=="U" then cy=(offset>0 and max(fy,ty) or min(fy,ty))+offset end
		x,y=get_border(from,fx,cy);	points[1]={x,y}
		points[2]={fx,cy}
		points[3]={tx,cy}
		x,y=get_border(to,tx,cy);	points[4]={x,y}
	end
	return points,cx,cy
end
local point2str=function(pre,point)
	return string.format("%s%d %d",pre,unpack(point))
end
local points2str=function(points,smooth,close)
	local t={point2str("M",points[1])}
	local pre,n="L",#points
	local push=table.insert
	local n,s=#points
	if smooth and n>2 then
		if (n-4)%2==0 then
			push(t,point2str("C",points[2])); push(t,point2str("",points[3])); push(t,point2str("",points[4]))
			for i=5,n,2 do	push(t,point2str("S",points[i])); push(t,point2str("",points[i+1]))	end
		else
			push(t,point2str("Q",points[2])); push(t,point2str("",points[3]))
			for i=4,n do	push(t,point2str("T",points[i]))		end
		end
	else
		for i=2,n do t[i]=point2str(pre,points[i])	end
	end
	if close then push(t,"Z") end
	return table.concat(t," ")
end
-- function to convert a style object to string
local type,tostring,push,concat,format=type,tostring,table.insert,table.concat,string.format
local STYLE_FMTS={
	dashed="stroke-dasharray:10,3;",	
	dotted="stroke-dasharray:3,3;",
	fill="fill:%s;",
	stroke_width="stroke-width:%s;",
	stroke="stroke:%s;",
	noborder="stroke-width:0;",
	nofill="fill:none;",
	opacity="opacity:%f",
}
local style2str=function(style)
	if type(style)~="table" then return tostring(style) end
	local t={}
	for k,v in pairs(style) do
		k=STYLE_FMTS[k]
		if k then push(t,format(k,tostring(v))) end
	end
	return concat(t)
end

make_map=function(key,on)
	local all=key and stack[key]
	if all then
		local s=#all
		return function(f)
			local e=#all
			if s<e and type(f)=="function" then 
				for i=s+1,e do
					
				end
			end
		end
	end
	return draw_stack
end

local add_label=function(d)
	local label,str=d.LABEL
	if label then
		local lx,ly,align=str2xya(d.LPOS)
		d.align=align
		if type(label)=="table" then
			local n,offset=#label,d.LOFFSET or 20
			for i,v in ipairs(label) do
				d.LABEL=v
				d.lx,d.ly=lx,ly+(i-(n+1)/2)*offset
				label[i]=obj2str(d,"label")
			end
			str=table.concat(label)
		else
			d.lx,d.ly=lx,ly
			str=obj2str(d,"label")
		end
		return str
	end
end

export=function(filepath,png)
	local push=table.insert
	local t,str={}
	local d,points,label,loffset
	for i=1,#draw_stack do
		d=draw_stack[i]
		d.STYLE=style2str(d.STYLE)
		if d.TYPE==EDGE_KEY then
			points,d.cx,d.cy=shape2points(d.SHAPE,d.FROM,d.TO,d.OFFSET)
			d.PATH=points2str(points,d.SMOOTH,d.CLOSE)
			str=obj2str(d,"path")
		elseif d.TYPE~="label" then 	-- if not a 'label' node 
			d.cx,d.cy=d.cx or d.matrix[3], d.cy or d.matrix[6]
			str=obj2str(d,d.TYPE)
		end
		push(t,str)
		-- process label of the node or the edge
		str=add_label(d)
		if str then push(t,str) end
--~ 		if label then
--~ 			local lx,ly,align=str2xya(d.LPOS)
--~ 			d.align=align
--~ 			if type(label)=="table" then
--~ 				local n,offset=#label,d.LOFFSET or 20
--~ 				for i,v in ipairs(label) do
--~ 					d.LABEL=v
--~ 					d.lx,d.ly=lx,ly+(i-(n+1)/2)*offset
--~ 					label[i]=obj2str(d,"label")
--~ 				end
--~ 				str=table.concat(label)
--~ 			else
--~ 				d.lx,d.ly=lx,ly
--~ 				str=obj2str(d,"label")
--~ 			end
--~ 			push(t,str)
--~ 		end
	end
	SVG.VALUE=table.concat(t,"\n")
	-- export to svg file
	str=obj2str(SVG,"canvas")
	if filepath then
		local f=io.open(filepath,"w")
		f:write(str)
		f:close()
		if png then
			print(io.popen(string.format([[inkscape -e "%s.png" -z -D %q]],string.match(filepath,"(.*)%..-") or filepath,filepath)):read("*a"))
		end
	else
		print(str)
	end
end

----------------------------------------------------------------------------------------
-- input
----------------------------------------------------------------------------------------
local filepath=...

package.path="/home/yipf/lua-svg/plugins/?.lua;"..package.cpath

if filepath then
	dofile(filepath)
else
	print("Need valid file path!")
end

----------------------------------------------------------------------------------------
-- test
----------------------------------------------------------------------------------------

--~ local nodes=node{matrix=translate(400,300),LABEL={"","many","points"}}
--~ local push,sin,cos,rad=table.insert,math.sin,math.cos,math.rad
--~ for i=0,330,30 do
--~ 	local group,n=node{matrix=rotate(i)}
--~ 	for j=1,3 do
--~ 		n=node{rx=10,ry=10,TYPE="ellipse",LABEL=j,LPOS="D8M",STYLE={fill="orange"},matrix=translate(80*(j),80*sin(rad((j-1)*45)))}
--~ 		push(group,n)
--~ 		if j>1 then
--~ 			edge{FROM=group[j-1],TO=n,HEAD="url(#arrow)",SHAPE="-"}
--~ 		end
--~ 	end
--~ 	push(nodes,group)
--~ end

--~ update(nodes)

--~ export("test.svg")