local SVG
-- function to get border point
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
--~ 	
--~ 	return rect_f(cx,cy,rx,ry+ry/2,x,y)
	
end
local ft={ ['ellipse']=ellipse_f, ['diamond']=diamond_f, ['rect']=rect_f, ['img']=rect_f, ['roundrect']=rect_f,['database']=database_f}
local get_border_point=function(node,x,y)
	local cx,cy,rx,ry=node.cx,node.cy,node.rx,node.ry
	if rx>0 and ry>0 then
		local f=ft[node.TYPE] or ft['ellipse']
		return f(cx,cy,rx,ry,x,y)
	end
	return cx,cy
end
-- function to convert a table to string according to 'tp'
local make_convert_func=function(refs,default)
	refs,default=refs or SVG,default or ""
	local loadstring,setfenv,gsub=loadstring,setfenv,string.gsub
	local make_eval_func=function(o)
		return function(str)
			f=loadstring("return "..str)
			f=f and setfenv(f,o)
			return f and f()
		end
	end
	return function(obj,tp)
		tp=refs[tp] or default
		return (type(tp)=="function") and tp(obj) or (gsub(tp,"@(.-)@",make_eval_func(obj)))
	end
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
-- fucntion to generate path from a table
local format,concat,unpack=string.format,table.concat,unpack
local pos2str=function(pos,pre)
	local x,y
	if pos.TYPE then  x,y=pos.cx,pos.cy else x,y=unpack(pos) end
	return format("%s %f %f",pre,x,y)
end
local path2str=function(path)
	local o={}
	for i,pos in ipairs(path) do
		o[i]=pos2str(pos,i==1 and "M" or "L")
	end
	return concat(o," ")..(path.CLOSED and " Z" or "")
end
-- get offsets in x,y and align from a string
local str2offsets=function(str,fontsize) 
	local x,y,v=0,fontsize and 0.3*fontsize or 0
	if not str then return x,y,"middle" end
	local match,tonumber=string.match,tonumber
	v=match(str,"L(%d+)"); x=v and x-tonumber(v) or x
	v=match(str,"R(%d+)"); x=v and x+tonumber(v) or x
	v=match(str,"U(%d+)"); y=v and y-tonumber(v) or y
	v=match(str,"D(%d+)"); y=v and y+tonumber(v) or y
	return x,y,match(str,"S") and "start" or match(str,"E") and "end" or "middle"
end
-- format a string containing 'super' and 'sub' fonts
local format_=function(tp,str)
	str=string.match(str,"^{(.-)}$")
	return string.format("<tspan font-size='60%%' baseline-shift='%s'>%s</tspan>",tp=="^" and "super" or "sub",str)
end
local format_str=function(str)
	str=string.gsub(str,"([_%^])(%b{})",format_)
	return str
end
-- get properties form an object ignoring its childs
local copy_properties=function(src,dst) -- copy properties of src, except its children
	dst=dst or {}
	local type,rawset=type,rawset
	for k,v in pairs(src) do
		if type(k)~="number" then rawset(dst,k,v)	end
	end
	return dst
end
-- the main function which return functions for generating an svg file
make_canvas=function(w,h,dw,dh,fontsize,linewidth)
	-- variables
	local SVG, str2offsets, format_str, get_center, copy_properties, STYLE_FMTS, get_border_point, style2str=SVG, str2offsets, format_str, get_center, copy_properties, STYLE_FMTS, get_border_point, style2str
	local convert=make_convert_func(SVG,"")
	local NODES,EDGES={},{}
	local push,pop,concat=table.insert,table.remove,table.concat
	local type,tostring,format=type,tostring,string.format
	w,h,cols,rows,fontsize,linewidth=w or 1000, h or 800, cols or 10, rows or 8, fontsize or 20, linewidth or 2
	local dw,dh=dw or 100,dh or 100
	local RX,RY,DEFAULT_STYLE=0.3*dw,0.3*dh,style2str{fill="none"}
-- functions for define nodes and edges
	node=function(n)
		n.TYPE,n.rx,n.ry,n.cx,n.cy=n.TYPE or "ellipse", n.rx or RX, n.ry or RY, n.cx or 0, n.cy or 0
		local key=tostring(n)
		if not NODES[key] then push(NODES,n); NODES[key]=n; end 
		return n
	end
	local link=function(l) -- define edges like 'a->b->c->...'
		local from,to,edge=l[1]
		for i=2,#l do
			to=l[i]
			if not to then break end
			if from~=to then
				edge=copy_properties(l)
				edge.FROM,edge.TO=from,to
				push(EDGES,edge)
				from=to
			end
		end
		return l
	end
	local edges=function(es) -- define edges like 'A->B' and for every node 'a' in 'A' and 'b' in 'B' there exists an edge 'a->b'
		local FROM,TO,edge=es.FROM,es.TO
		for i,from in ipairs(FROM) do
			for j,to in ipairs(TO) do
				if from~=to then
					edge=copy_properties(es)
					edge.FROM,edge.TO=from,to
					push(EDGES,edge)
				end
			end
		end
		return es
	end
-- fucntions for export svg files
	local gen_label=function(node)
		local label,cx,cy=node.LABEL,node.cx,node.cy
		node.tx,node.ty,node.align=str2offsets(node.LPOS,fontsize)
		if type(label)~="table" then return convert(node,'label') end
		local o=copy_properties(node)
		local n=#label/2
		for i,v in ipairs(label) do
			o.cy=cy+(i-n-0.5)*fontsize
			o.LABEL=format_str(v)
			o[i]=convert(o,'label')
		end
		return concat(o,"\n")
	end
	local node2str=function(node,str)
		-- apply style
		node.STYLE=style2str(node.STYLE or DEFAULT_STYLE)
		-- process nodes of special types
		if node.TYPE=='path' then
			node.PATH=path2str(node.points)
		end
		-- convert node to string
		str=str or convert(node,node.TYPE)
		if node.LABEL then -- if the node has a label
			str=str..gen_label(node)
		end
		return str
	end
	local edge2str
	edge2str=function(e)
		-- apply style
		e.STYLE=style2str(e.STYLE or DEFAULT_STYLE)
		-- convert edge to path
		local from,to,shape=e.FROM,e.TO,e.SHAPE
		shape=shape or "I"
		local ox,oy=str2offsets(e.OFFSET)
		local path,fx,fy,tx,ty,lx,ly={}
		if shape=="I" then
			fx,fy=get_border_point(from,to.cx,to.cy)
			tx,ty=get_border_point(to,from.cx,from.cy)
			lx,ly=(fx+tx)/2,(fy+ty)/2
			path[1],path[2]={fx,fy},{tx,ty}
		elseif shape=="L" then
			lx,ly=from.cx,to.cy
			fx,fy=get_border_point(from,lx,ly)
			tx,ty=get_border_point(to,lx,ly)
			path[1],path[2],path[3]={fx,fy},{lx,ly},{tx,ty}
		elseif shape=="7" then
			lx,ly=to.cx,from.cy
			fx,fy=get_border_point(from,lx,ly)
			tx,ty=get_border_point(to,lx,ly)
			path[1],path[2],path[3]={fx,fy},{lx,ly},{tx,ty}
		elseif shape=="Z" then
			lx,ly=(from.cx+to.cx)/2+ox,(from.cy+to.cy)/2+oy
			fx,fy=get_border_point(from,lx,from.cy)
			tx,ty=get_border_point(to,lx,to.cy)
			path[1],path[2],path[3],path[4]={fx,fy},{lx,fy},{lx,ty},{tx,ty}
		elseif shape=="N" then
			lx,ly=(from.cx+to.cx)/2+ox,(from.cy+to.cy)/2+oy
			fx,fy=get_border_point(from,from.cx,ly)
			tx,ty=get_border_point(to,to.cx,ly)
			path[1],path[2],path[3],path[4]={fx,fy},{fx,ly},{tx,ly},{tx,ty}
		end
		-- generate path object
		e.PATH=path2str(path)
		local str=convert(e,'path')
		if e.LABEL then 
			e.cx,e.cy=lx,ly
			str=str..gen_label(e)
		end
		return str
	end
	local export=function(filepath)
		local body={w=w,h=h,fs=fontsize,lw=linewidth,DEFS="",VALUE=""}
		for i,node in ipairs(NODES) do push(body,node2str(node)) end -- convert nodes
		for i,edge in ipairs(EDGES) do push(body,edge2str(edge)) end -- convert edges
		body.VALUE=concat(body,"\n")
		local str=convert(body,'CANVAS')
		-- export 'str' according to file or screen
		if filepath then
			local file=io.open(filepath,"w")
			if file then print("wrtitting to:",filepath) file:write(str); file:close() end
		else
			print(str)
		end
		return str
	end
-- extension functions
	local translate -- update absolute positions of nodes according to the relationship between nodes
	translate=function(node,ox,oy)
		ox,oy=ox or 0, oy or 0
		local cx,cy=node.cx or 0, node.cy or 0
		cx,cy=cx+ox,cy+oy
		node.cx,node.cy=cx,cy
		for i,child in ipairs(node) do 
			if child.TYPE then translate(child,cx,cy) end -- if the child is a node, then update the position
		end
		return node
	end
	return export,node,link,edges,translate,style2str
end

-- customize

SVG={
	path=[[<path d = "@PATH@" fill = "@BGCOLOR or "none"@" stroke = "@COLOR@"  stroke-linejoin="round" marker-end = "@HEAD@" marker-mid="@MIDDLE@" marker-start="@TAIL@" style="@STYLE or ''@" filter="@filter@" />]],
	label=[[<text x="@cx+tx@" y="@cy+ty@" stroke-width="0" fill="black" text-anchor="@align@">@LABEL@</text>]],
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
	CANVAS=[[
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

<svg width="@w@" height="@h@" version="1.1" xmlns="http://www.w3.org/2000/svg" font-size="@fs@px" stroke-width = "@lw@" fill="white" stroke="black" viewBox="0 0 @w@ @h@">

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
	 
	 @DEFS@
	 
     </defs>
	@VALUE@
</svg>
]]
}