local SVG
-- function to get border point
local sqrt,abs=math.sqrt,math.abs
local ft={
	['ellipse']=function(cx,cy,rx,ry,x,y)
		local t,aa,bb=(cy-y)/(cx-x),rx*rx,ry*ry
		local dx=sqrt(aa*bb/(t*t*aa+bb))
		local dy=abs(t*dx)
		return cx+(x>cx and dx or -dx),cy+(y>cy and dy or -dy)
	end,
}
local get_border_point=function(node,x,y)
	local tp,cx,cy,rx,ry=node.TYPE,node.cx,node.cy,node.rx,node.ry
	local f=ft[tp or 'ellipse'] or ft['ellipse']
	return f(cx,cy,rx,ry,x,y)
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
	noborder="stroke-width:0;"
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
local format,concat=string.format,table.concat
local pos2str=function(pos,pre)
	local x,y
	if pos.TYPE then  x,y=pos.cx,pos,cy else x,y=unpack(pos) end
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
local str2offsets=function(str) 
	local x,y,v=0,0
	if not str then return x,y end
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
local get_properties=function(src,dst) -- copy properties of src, except its children
	dst=dst or {}
	local type,rawset=type,rawset
	for k,v in pairs(src) do
		if type(k)~="number" then rawset(dst,k,v)	end
	end
	return dst
end
-- the main function which return functions for generating an svg file
make_canvas=function(w,h,cols,rows,fontsize,linewidth)
	-- variables
	local SVG, str2offsets, format_str, get_center, get_properties, STYLE_FMTS, get_border_point, style2str=SVG, str2offsets, format_str, get_center, get_properties, STYLE_FMTS, get_border_point, style2str
	local convert=make_convert_func(SVG,"")
	local NODES,EDGES={},{}
	local push,pop,concat=table.insert,table.remove,table.concat
	local type,tostring,format=type,tostring,string.format
	w,h,cols,rows,fontsize,linewidth=w or 800, h or 600, cols or 8, rows or 6, fontsize or 20, linewidth or 2
	local RX,RY,DEFAULT_STYLE=0.6*w/cols,0.6*h/rows,style2str{fill="none"}
-- functions for define nodes and edges
	local node
	node=function(n,ox,oy)
		n.TYPE=n.TYPE or "ellipse"
		n.rx,n.ry=n.rx or RX, n.ry or RY
		push(NODES,n) -- push current node into the list 'nodes'
		ox,oy=ox or 0, oy or 0
		local cx,cy=n.cx or 0, n.cy or 0
		cx,cy=cx+ox,cy+oy
		for i,child in ipairs(n) do node(child,cx,cy) end -- compute absolute positions of childs
		n.cx,n.cy=cx,cy -- update the position of 'n'
		return n
	end
	local link=function(l) -- define edges like 'a->b->c->...'
		local from,to,edge=l[1]
		for i=2,#l do
			to=l[i]
			if not to then break end
			if from~=to then
				edge=get_properties(l)
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
					edge=get_properties(es)
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
		-- convert node to string
		str=str or convert(node,node.TYPE)
		if node.LABEL then -- if the node has a label
			node.tx,node.ty,node.align=str2offsets(node.LPOS)
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
			fx,fy=get_border_point(from,to.cx,from.cy)
			tx,ty=get_border_point(to,from.cx,to.cy)
			lx,ly=(fx+tx)/2+ox,(fy+ty)/2+oy
			path[1],path[2],path[3],path[4]={fx,fy},{lx,fy},{lx,ty},{tx,ty}
		elseif shape=="N" then
			fx,fy=get_border_point(from,from.cx,to.cy)
			tx,ty=get_border_point(to,to.cx,from.cy)
			lx,ly=(fx+tx)/2+ox,(fy+ty)/2+oy
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
	return export,node,link,edges
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