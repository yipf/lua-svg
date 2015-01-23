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
<svg width="@w or 800@" height="@h or 600@" version="1.1" xmlns="http://www.w3.org/2000/svg" font-size="@fs or 20@px" stroke-width = "@lw or 2@" fill="white" stroke="black" viewBox="0 0 @w or 800@ @h or 600@">
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

local draw_stack={}
local push,pop=table.insert,table.remove
CHILD_KEY="child"

-- define functions
node=function(n)
	n[1],n[2]=n[1] or 0, n[2] or 0
	n.rx,n.ry=n.rx or 0,n.ry or 0
	n.TYPE=n.TYPE or "circle"
	push(draw_stack,n)
	return n,#draw_stack
end
edge=function(e)
	e.TYPE="EDGE"
	push(draw_stack,e)
	return e,#draw_stack
end
-- modify functions
copy_node=function(n)
	local nn=node{}
	for k,v in pairs(n) do 
		if k==CHILD_KEY then
			local child={}
			for i,c in ipairs(v) do
				child[i]=copy_node(c)
			end
			nn[k]=child
		else
			nn[k]=v
		end
	end
	return nn
end
put=function(node)
	local pos_f=node.pos_f
	if node.child then
		local cx,cy=node[1] or 0,node[2] or 0
		local dx,dy
		for i,c in ipairs(node.child) do
			dx,dy=pos_f(i,c)
			c[1],c[2]=cx+(dx or 0),cy+(dy or 0)
			put(c)
		end
	end
end
change=function(n,mat2D,x,y) 	-- change nodes with 2D matrix 'mat2D'
	x,y=x or 0,y or 0
	local m11,m12,m21,m22=unpack(mat2D)
	local dx,dy=n[1],n[2]
	dx,dy=dx-x,dy-y
	n[1],n[2]=x+(m11*dx+m12*dy),y+(m21*dx+m22*dy)
	if n[CHILD_KEY] then
		for i,c in ipairs(n[CHILD_KEY]) do change(c,mat2D,x,y) end
	end
	return n
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
		return f(n[1],n[2],n.rx,n.ry,x,y)
	end
end
local shape2points=function(shape,from,to,offset)
	local points,cx,cy,x,y={}
	local fx,fy,tx,ty=from[1],from[2],to[1],to[2]
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
		if shape=="C" then cx=(offset>0 and max(fx,tx) or min(fx,tx))+offset end
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
export=function(filepath,png)
	local push=table.insert
	local t,str={}
	local d,points,label,loffset
	for i=1,#draw_stack do
		d=draw_stack[i]
		d.STYLE=style2str(d.STYLE)
		if d.TYPE=="EDGE" then
			points,d.cx,d.cy=shape2points(d.SHAPE,d.FROM or d[1],d.TO or d[2],d.OFFSET)
			d.PATH=points2str(points,d.SMOOTH,d.CLOSE)
			str=obj2str(d,"path")
		elseif d.TYPE~="label" then 	-- if not a 'label' node 
			d.cx,d.cy=d[1],d[2]
			str=obj2str(d,d.TYPE)
		end
		push(t,str)
		-- process label of the node
		label=d.LABEL
		if label then
			local lx,ly,align=str2xya(d.LPOS)
			d.align=align
			if type(label)="table" then
				for i=1,#label do
					d.LABEL=label[i]
					d.lx.d.ly=lx,ly
					str=obj2str(d,"label")
				end
			else
				d.lx.d.ly=lx,ly
				str=obj2str(d,"label")
			end
			push(t,str)
		end
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

if filepath then
	dofile(filepath)
else
	print("Need valid file path!")
end

----------------------------------------------------------------------------------------
-- test
----------------------------------------------------------------------------------------

--~ local g=node{400,300}

--~ local nodes={}
--~ for i=1,3 do
--~ 	nodes[i]=node{rx=10,ry=10,TYPE="ellipse",LABEL=i,LPOS="D8M",STYLE={fill="orange"}}
--~ end

--~ g[CHILD_KEY]=nodes
--~ local cos,sin,rad=math.cos,math.sin,math.rad
--~ g.pos_f=function(i)
--~ 	return 80*i,80*sin(rad(i*90))
--~ end

--~ put(g)

--~ local a,c,s
--~ local mat={}

--~ for i=60,360,60 do
--~ 	a=rad(i)
--~ 	c,s=cos(a),sin(a)
--~ 	mat[1],mat[2],mat[3],mat[4]=c,s,-s,c
--~ 	change(copy_node(g),mat,400,300)
--~ end

--~ for i=1,#nodes-1 do
--~ 	edge{nodes[i],nodes[i+1],HEAD="url(#arrow)",SHAPE="C",OFFSET=-10,STYLE={dashed=true},LABEL="test",LPOS="U10",SMOOTH=true}
--~ end

--~ export("test.svg")