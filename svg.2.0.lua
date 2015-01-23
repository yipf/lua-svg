
local is_node=function(o)
	return type(o)=='table' and o.TYPE
end

local get_xy=function(o)
	if type(o)~='table' then return end
	if is_node(o) then return o.cx,o.cy end
	return unpack(o)
end

local curve_funcs={
	lines=function(points,t)
		local n=#points
		if n<2 then return end
		local format,tostring,push=string.format,tostring,table.insert
		local x,y=get_xy(points[1]);
		push(t,format("M %s %s",tostring(x),tostring(y)))
		for i=2,n do
			x,y=get_xy(points[i]);
			if x and y then push(t,format("L %s %s",tostring(x),tostring(y))) end
		end
		return t
	end,
	quad=function(points,t)
		local n=#points
		if n<3 then return end
		local format,tostring,push=string.format,tostring,table.insert
		local x,y,x1,y1
		x,y=get_xy(points[1]);
		push(t,format("M %s %s",tostring(x),tostring(y)))
		x,y=get_xy(points[2]);
		x1,y1=get_xy(points[3]);
		push(t,format("Q %s %s %s %s",tostring(x),tostring(y),tostring(x1),tostring(y1)))
		for i=4,n do
			x,y=get_xy(points[i]);
			if x and y then push(t,format("T %s %s",tostring(x),tostring(y))) end
		end
		return t
	end,	
	cubic=function(points,t)
		local n=#points
		if n<4 or n%2==1 then return end
		local format,tostring,push=string.format,tostring,table.insert
		local x,y,x1,y1,x2,y2
		x,y=get_xy(points[1]);
		push(t,format("M %s %s",tostring(x),tostring(y)))
		x,y=get_xy(points[2]);
		x1,y1=get_xy(points[3]);
		x2,y2=get_xy(points[4]);
		push(t,format("C %s %s %s %s %s %s",tostring(x),tostring(y),tostring(x1),tostring(y1),tostring(x2),tostring(y2)))
		for i=5,#points,2 do
			x,y=get_xy(points[i]);
			x1,y1=get_xy(points[i+1]);
			if x and y then push(t,format("S %s %s %s %s",tostring(x),tostring(y),tostring(x1),tostring(y1))) end
		end
		return t
	end,
}

local points2path=function(points,closed,ct)
	local n=#points
	if n<2 then return "" end
	local f=curve_funcs[ct or "lines"] or curve.lines
	local t=f(points,{})
	if not t then return "" end
	if closed then push(t,"z") end
	return table.concat(t," ")
end

local loadstring,setfenv=loadstring,setfenv
local gsub=string.gsub
local make_eval_func=function(o)
	return function(str)
		f=loadstring("return "..str)
		f=f and setfenv(f,o)
		return f and f()
	end
end

local convert=function(o,tp)
	return (type(tp)=="function") and tp(o) or (string.gsub(tp,"@(.-)@",make_eval_func(o)))
end

local copy
copy=function(src,dst)
	if type(src)~="table" then return src end
	dst={};  	
	for k,v in pairs(src) do dst[k]=copy(v) end
	return dst
end

local get_border=function(x,y,cx,cy,rx,ry,tp)
	if tp and x~=cx and y~=cy then
		if tp=="ellipse" or tp=="addbox" or tp=="mulbox" then
			local t,aa,bb=(cy-y)/(cx-x),rx*rx,ry*ry
			local dx=math.sqrt(aa*bb/(t*t*aa+bb))
			local dy=math.abs(t*dx)
			return cx+(x>cx and dx or -dx),cy+(y>cy and dy or -dy)
		end
	end
	return x>cx and cx+rx or x<cx and cx-rx or x, y>cy and cy+ry or y<cy and cy-ry or y
end

local get_outer=function(offset,a,b)
	if offset>0 then
		return a>b and a+offset or b+offset
	else
		return a>b and b+offset or a+offset
	end
end

local apply_offset=function(offset,x,y)
	x=x or 0; y=y or 0;
	local match,tonumber=string.match,tonumber
	v=match(offset,"U(%d*)"); v=v and tonumber(v) or 1; if v then y=y-v end
	v=match(offset,"D(%d*)"); v=v and tonumber(v) or 1; if v then y=y+v end
	v=match(offset,"L(%d*)"); v=v and tonumber(v) or 1; if v then x=x-v end
	v=match(offset,"R(%d*)"); v=v and tonumber(v) or 1; if v then x=x+v end
	return x,y,match(offset,"S") and "start" or match(offset,"E") and "end" or "middle"
end

local utf8flags={0,0xc0,0xe0,0xf0,0xf8,0xfc}
local get_charlen=function(ch)
	local flags=utf8flags
	for i=6,1,-1 do if ch>=flags[i] then return i end  end
end

function utf8strlen(str)
	local left,cnt,arr,i= string.len(str),0, {0,0xc0,0xe0,0xf0,0xf8,0xfc}
	local byte=string.byte
	while left>0 do
		i=get_charlen(byte(str,-left))
		left=left-i
		cnt=cnt+(i>1 and 2 or 1)
	end
	return cnt;
end

local format_=function(tp,str)
	print(tp,str)
	str=string.match(str,"^{(.-)}$")
	return string.format("<tspan font-size='60%%' baseline-shift='%s'>%s</tspan>",tp=="^" and "super" or "sub",str)
end

local format_str=function(str)
	print(str)
	str=string.gsub(str,"([_%^])(%b{})",format_)
	return str
end

local SVG

local LINE_STYLES={	dashed="stroke-dasharray:10,3",	dotted="stroke-dasharray:3,3",}

local STYLE_FMTS={
	dashed="stroke-dasharray:10,3;",	
	dotted="stroke-dasharray:3,3;",
	fill="fill:%s;",
	stroke_width="stroke-width:%s;",
	stroke="stroke:%s;",
	noboder="stroke-width:0;"
}


make_canvas=function(w,h,cols,rows,fontsize,linewidth)
	w=w or 800;	h=h or 600;	cols=cols or 10;	rows=rows or 10; fontsize=fontsize or 20; linewidth=linewidth or 1.5;
	local dw,dh=w/cols,h/rows
	local labels,nodes,paths,defs={},{},{},{}
	local push,format,concat=table.insert,string.format,table.concat
	local SVG,convert=SVG,convert
	
	local convert_label=function(o)
		local label=o.LABEL
		local cy=o.cy
		if type(label)=="table" then
			local n=#label/2
			for i,v in ipairs(label) do
				o.cy=cy+(i-n-0.5)*fontsize
				o.LABEL=format_str(v)
				o[i]=convert(o,SVG['label'])
			end
			return concat(o,"\n")
		else
			o.LABEL=format_str(label)
		end
		return convert(o,SVG['label'])
	end
	
	local make_label=function(o)
		local tx,ty,align
		if o.LPOS then tx,ty,align=apply_offset(o.LPOS,x,y) end
		o.tx=tx or 0 ; o.ty=(ty or 0)+fontsize/3 or 0; o.align=align or "middle";
		o.fontsize=o.fontsize or fontsize
		return o
	end
	
	local label=function(o)
		o=make_label(o)
		push(labels,o)
		return o
	end
	
	local node=function(o)
		o.cx=o.cx or 0; o.cy=o.cy or 0; o.rx=o.rx or dw/3; o.ry=o.ry or dh/3; 
		o.TYPE=o.TYPE or "rect"
		push(nodes,o)
		return o
	end
	
	local path=function(o)
		o.PATH=points2path(o,o.CLOSED,o.CURVE,nodes)
		if o.STYLE then  o.STYLE= LINE_STYLES[o.STYLE] end
		push(paths,o)
		return o
	end
	
	local fill_pattern=function(tp,c1,c2)
		tp=tp or "linear";		c1=c1 or "#ffffff";		c2=c2 or c1;
		local id=#defs+1
		local key=tp..id
		local o={KEY=key,color1=c1,color2=c2}
		o.KEY=key
		defs[id]=convert(o,SVG[tp])
		return format("url(#%s)",key)
	end
	
	local marker=function(o)
		-- generate element
		local tp,w,h=o.TYPE,o.W,o.H
		tp=tp or "ellipse"; w=w and w or 10; h=h and h or 10;
		rx=w/2; ry=h/2;
		o.cx=rx;	o.cy=ry;	o.rx=rx-linewidth;	o.ry=ry-linewidth;
		o.ELEMENT=convert(o,SVG[tp or "rect"])
		-- generate "marker"
		local id=#defs+1
		local key="marker"..id
		o.KEY=key
		o.w=w; o.h=h;
		defs[id]=convert(o,SVG["marker"])
		return format("url(#%s)",key)
	end
	
	local export=function(filepath)
		local t={w=w,h=h,fs=fontsize,lw=linewidth}
		for i,n in ipairs(nodes) do 
			if n.SHADOW then n.filter="url(#shadow)"; push(t,convert(n,SVG[n.TYPE or "rect"] or SVG['rect'])); end
			n.filter=""
			push(t,convert(n,SVG[n.TYPE or "rect"] or SVG['rect']))
			if n.LABEL then push(t,convert_label(make_label(n))) end
		end
		for i,p in ipairs(paths) do push(t,convert(p,SVG['path'])) end
		for i,l in ipairs(labels) do
			push(t,convert_label(l))  
		end
		t.VALUE=table.concat(t,"\n")
		t.DEFS=table.concat(defs,"\n")
		str=convert(t,SVG['CANVAS'])
		if filepath then
			filepath=io.open(filepath,"w")
			if filepath then filepath:write(str); filepath:close() end
		else
			print(str)
		end
	end
	
	-- extend functions
	local edge=function(o)
		local from,to,shape=o.FROM,o.TO,o.SHAPE
		shape=shape or "I"
		if not from or not to or from==to then return end
		local mx,my,sx,sy,ex,ey
		if shape=="I" then
			mx,my=(from.cx+to.cx)/2,(from.cy+to.cy)/2
			o[1]={get_border(to.cx,to.cy,from.cx,from.cy,from.rx,from.ry,from.TYPE)}; 
			o[2]={get_border(from.cx,from.cy,to.cx,to.cy,to.rx,to.ry,to.TYPE)};
		elseif shape=="7" then
			mx,my=to.cx,from.cy
			o[1]={get_border(mx,my,from.cx,from.cy,from.rx,from.ry)}
			o[2]={mx,my}
			o[3]={get_border(mx,my,to.cx,to.cy,to.rx,to.ry)}
		elseif shape=="L" then
			mx,my=from.cx,to.cy
			o[1]={get_border(mx,my,from.cx,from.cy,from.rx,from.ry)}
			o[2]={mx,my}
			o[3]={get_border(mx,my,to.cx,to.cy,to.rx,to.ry)}
		elseif shape=="N" then
			mx,my=(from.cx+to.cx)/2,(from.cy+to.cy)/2
			o[1]={get_border(from.cx,my,from.cx,from.cy,from.rx,from.ry)}
			o[2]={from.cx,my}
			o[3]={to.cx,my}
			o[4]={get_border(to.cx,my,to.cx,to.cy,to.rx,to.ry)}
		elseif shape=="Z" then
			mx,my=(from.cx+to.cx)/2,(from.cy+to.cy)/2
			o[1]={get_border(mx,from.cy,from.cx,from.cy,from.rx,from.ry)}
			o[2]={mx,from.cy}
			o[3]={mx,to.cy}
			o[4]={get_border(mx,to.cy,to.cx,to.cy,to.rx,to.ry)}
		elseif shape=="U" then
			mx,my= (from.cx+to.cx)/2,get_outer(o.DIR=="U" and -dh or dh,from.cy,to.cy)
			o[1]={get_border(from.cx,my,from.cx,from.cy,from.rx,from.ry)}
			o[2]={from.cx,my}
			o[3]={to.cx,my}
			o[4]={get_border(to.cx,my,to.cx,to.cy,to.rx,to.ry)}
		elseif shape=="C" then
			mx,my= get_outer(o.DIR=="L" and -dw or dw,from.cx,to.cx),(from.cy+to.cy)/2
			o[1]={get_border(mx,from.cy,from.cx,from.cy,from.rx,from.ry)}
			o[2]={mx,from.cy}
			o[3]={mx,to.cy}
			o[4]={get_border(mx,to.cy,to.cx,to.cy,to.rx,to.ry)}
		end
		if o.LABEL then node{LABEL=o.LABEL,TYPE="colorbox",COLOR="#ffffff",cx=mx,cy=my,rx=utf8strlen(o.LABEL)*fontsize/4,ry=fontsize/2} end
		
		print(from.LABEL,to.LABEL,#o)
		return path(o)
	end

	local translate=function(lst)
		local n=#lst
		if n<1 then return lst end
		local ref=lst.REF or lst[1]
		local x,y=get_xy(ref)
		x=x or 0; y=y or 0
		local dx,dy=lst.DX or dw,lst.DY or dh
		for i,v in ipairs(lst) do
			if is_node(v) then v.cx=x+(i-1)*dx; v.cy=y+(i-1)*dy; end
		end
		return lst
	end
	
	local rotate=function(lst)
		local n,angle=#lst,lst.ANGLE
		if n<2 or not angle then return lst end
		local s,c=math.sin(angle),math.cos(angle)
		local ref=lst.REF or lst[1]
		local x,y=get_xy(ref,nodes)
		x=x or 0; y=y or 0
		local rx,ry
		for i,v in ipairs(lst) do
			if is_node(v)  then
				rx,ry=v.cx-x,v.cy-y
				v.cx=x+rx*c-ry*s
				v.cy=y+rx*s+ry*c
			end
		end
		return lst
	end
	
	local link=function( lst)
		local n=#lst
		if n<2 then return lst end
		local shape,style,head= lst.SHAPE, lst.STYLE, lst.HEAD
		shape=shape or "-"
		local first=lst[1]
		local v
		for i=2,n do
			v= lst[i]
			if is_node(v) then
				edge{FROM=first,TO=v,STYLE=style,HEAD=head,shape=shape}
				first=v
			end
		end
		return lst
	end
	
	local edges=function(o)
		local to=o.TO
		local e
		for i,v in ipairs(to) do
			if is_node(v) then
				e=copy(o); e.TO=v
				edge(e)
			end
		end
		return o
	end
	
	local copy_node=function(n)
		local nn={}
		for k,v in pairs(n) do
			nn[k]=v
		end
		return node(nn)
	end
	
	local style=function(o)
		local t={}
		for k,v in pairs(o) do
			k=STYLE_FMTS[k]
			if k then push(t,format(k,tostring(v))) end
		end
		return concat(t)
	end
	
	return export,node,edge,rotate,translate,link,edges,label,path,marker,fill_pattern,copy_node,style
end

SVG={
	path=[[<path d = "@PATH@" fill = "@BGCOLOR or "none"@" stroke = "@COLOR@"  stroke-linejoin="round" marker-end = "@HEAD@" marker-mid="@MIDDLE@" marker-start="@TAIL@" style="@STYLE@" filter="@filter@"/>]],
	label=[[<text x="@cx+tx@" y="@cy+ty@" stroke-width="0" fill="black" text-anchor="@align@">@LABEL@</text>]],
	colorbox=[[<rect x="@cx-rx@" y="@cy-ry@" width="@rx+rx@" height="@ry+ry@" fill="@COLOR or '#ffffff'@" stroke="none"/>]],
	
	-- nodes
	
	rect=[[<rect x="@cx-rx@" y="@cy-ry@" width="@rx+rx@" height="@ry+ry@" fill="@COLOR or 'url(#linear0)'@" filter="@filter@" stroke="@STROKE or ''@"/>]],
	roundrect=[[<rect x="@cx-rx@" y="@cy-ry@" rx="10" ry="10" width="@rx+rx@" height="@ry+ry@" fill="@COLOR or 'url(#linear0)'@" filter="@filter@" stroke="@STROKE or ''@"/>]],
	ellipse=[[<ellipse cx="@cx@" cy="@cy@" rx="@rx@" ry="@ry@"  fill="@COLOR or 'url(#linear0)'@" filter="@filter@" stroke="@STROKE or ''@"/>]],
	diamond=[[<path d="M @cx-rx@ @cy@ L @cx@ @cy-ry@ L @cx+rx@ @cy@ L @cx@ @cy+ry@ z"  fill="@COLOR or 'url(#linear0)'@"  filter="@filter@" stroke="@STROKE or ''@"/>]],
	img=[[<image x="@cx-rx@" y="@cy-ry@" width="@rx+rx@" height="@ry+ry@" xlink:href="@SRC@" filter="@filter@" stroke="@STROKE or ''@"/>]],

	mulbox=[[<ellipse cx="@cx@" cy="@cy@" rx="@rx@" ry="@ry@"  fill="@COLOR or 'url(#linear0)'@" filter="@filter@"/><path d="M @cx-0.707*rx@ @cy-0.707*ry@ L @cx+0.707*rx@ @cy+0.707*ry@ M @cx-0.707*rx@ @cy+0.707*ry@ L @cx+0.707*rx@ @cy-0.707*ry@" />]],
	addbox=[[<ellipse cx="@cx@" cy="@cy@" rx="@rx@" ry="@ry@"  fill="@COLOR or 'url(#linear0)'@" filter="@filter@"/><path d="M @cx-rx@ @cy@ L @cx+rx@ @cy@ M @cx@ @cy-ry@ L @cx@ @cy+ry@" />]],
	
	database=[[
	 <ellipse cx="@cx@" cy="@cy+ry/2@" rx="@rx@" ry="@ry/2@"  fill="@COLOR or 'url(#linear0)'@" filter="@filter@"/>
	 <rect x="@cx-rx@" y="@cy-ry@" width="@rx+rx@" height="@ry+ry/2@" fill="@COLOR or 'url(#linear0)'@" filter="@filter@" stroke="none"/>
	 <ellipse cx="@cx@" cy="@cy-ry@" rx="@rx@" ry="@ry/2@"  fill="@COLOR or 'url(#linear0)'@" filter="@filter@"/>
	 <path d="M @cx-rx@ @cy-ry@ L @cx-rx@ @cy+ry/2@ M @cx+rx@ @cy-ry@ L @cx+rx@ @cy+ry/2@" />
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
}

SVG['CANVAS']=[[
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
		
		
		<radialGradient id="radial0" cx="30%" cy="30%" r="50%">
			<stop offset="0%" style="stop-color:rgb(255,255,255); stop-opacity:0" />
			<stop offset="100%" style="stop-color:rgb(0,0,255);stop-opacity:1" />
     </radialGradient>
	 
	 @DEFS@
	 
     </defs>
	@VALUE@
</svg>
]]


--~ local export,node,edge1,rank,link,label,path=make_canvas(800,600)

--~ local edge=function(o)
--~ 	o.HEAD="url(#arrow)"
--~ 	return edge1(o)
--~ end

--~ local process=function(str)
--~ 	return node{TYPE="ellipse",LABEL=str}
--~ end

--~ n1=node{cx=100,cy=100,TYPE="rect",LABEL="n1",LPOS=""}
--~ n2=node{cx=200,cy=200,TYPE="rect",LABEL="n2" }

--~ edge{FROM=n1,TO=n2,LABEL="test",SHAPE="-"}
--~ edge{FROM=n1,TO=n2,LABEL="test",SHAPE="7"}
--~ edge{FROM=n1,TO=n2,LABEL="test",SHAPE="L"}

--~ n3=node{cx=300,cy=300,TYPE="rect",LABEL="n3" }

--~ edge{FROM=n2,TO=n3,LABEL="test",SHAPE="N"}

--~ edge{FROM=n2,TO=n3,LABEL="test",SHAPE="C",DIR="R"}

--~ n4=node{cx=600,cy=400,TYPE="img",LABEL="n4",SRC="http://www.baidu.com/img/%E5%85%AD%E4%B8%80logo_c422541ebf75af6b274d7de5cbf79d49.gif",rx=200, ry=200 }
--~ n4=node{cx=400,cy=400,TYPE="rect",LABEL="n4" }

--~ edge{FROM=n3,TO=n4,LABEL="test",SHAPE="Z"}
--~ -- edge{FROM=n3,TO=n4,LABEL="test",SHAPE="U",DIR="U"}
--~ edge{FROM=n3,TO=n4,LABEL="test",SHAPE="U",DIR="D"}

--~ local f=function()
--~ 	local p={}
--~ 	local push,sin=table.insert,math.sin
--~ 	for i=1,800 do
--~ 		p[i]={i,200*sin(i/100-1)+300}
--~ 	end
--~ 	return p
--~ end

--~ s=path(f())

--~ local list=rank{process("t1"),process("t2"),process("t3"); dy=100,dx=100,x=350,y=100};

--~ list.HEAD="url(#arrow)"; list.SHAPE="-"; list.STYLE="dashed"

--~ print(link(list))

--~ export("test.svg")
--~ export()

