
local SVG_TMP=[[
<?xml version="1.0" standalone="no"?>

<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

<svg width="@w@" height="@h@" version="1.1"
xmlns="http://www.w3.org/2000/svg" font-size="@fs@" stroke-width = "3">

    <defs>
         <marker id = "StartMarker" viewBox = "0 0 12 12" refX = "12" refY = "6" markerWidth = "3" markerHeight = "3" stroke = "green" stroke-width = "2" fill = "none" orient = "auto">
             <circle cx = "6" cy = "6" r = "5"/>
         </marker>
         <marker id = "MidMarker" viewBox = "0 0 10 10" refX = "5" refY = "5" markerUnits = "strokeWidth" markerWidth = "3" markerHeight = "3" stroke = "lightblue" stroke-width = "2" fill = "none" orient = "auto">
             <path d = "M 0 0 L 10 10 M 0 10 L 10 0"/>
         </marker>
         <marker id = "EndMarker" viewBox = "0 0 20 20" refX = "20" refY = "10" markerUnits = "strokeWidth" markerWidth = "5" markerHeight = "5" stroke = "black"  fill = "none" orient = "auto">
             <path d = "M 0 0 L 20 10 L 0 20"/>
         </marker>
     </defs>

@VALUE@
</svg>
]]

local convert=function(o,tmp)
	return (string.gsub(tmp,"@%s*(.-)%s*@",o))
end

local o={}
local shapes={
	ellipse=[[<ellipse cx="@cx@" cy="@cy@" rx="@rx@" ry="@ry@" style="fill:@fill@;stroke:@stroke@;stroke-width:@sw@;opacity:@op@" /><text x="@tx@" y="@ty@" text-anchor="middle">@label@</text> ]],
	roundrect=[[<rect x="@x@" y="@y@" rx="@rx@" ry="@ry@" width="@w@" height="@h@" style="fill:@fill@;stroke:@stroke@;stroke-width:@sw@;opacity:@op@"/><text x="@tx@" y="@ty@" text-anchor="middle">@label@</text>]],
	rect=[[<rect x="@x@" y="@y@"  width="@w@" height="@h@" style="fill:@fill@;stroke:@stroke@;stroke-width:@sw@;opacity:@op@"/><text x="@tx@" y="@ty@" text-anchor="middle" >@label@</text>]],

	path=[[<path d = "@path@" fill = "none" stroke = "black"  marker-end = "url(#EndMarker)"/><text x="@tx@" y="@ty@" text-anchor="middle" >@label@</text>]],
	
	
}

local POINT_FMT="%s %d %d"
local format=string.format

local points2path=function(t)
	for i,v in ipairs(t) do
		t[i]= format(POINT_FMT,i==1 and "M" or "L",unpack(v))
	end
	return table.concat(t)
end

SVG=function(X,Y,W,H,font_size)
	X=X or 0
	Y=Y or 0
	W=W or 100
	H=H or 100
	font_size=font_size or 12
	local svg={w=W,h=H,fs=font_size}
	local SVG_TMP,convert,shapes=SVG_TMP,convert,shapes
	local push=table.insert
	local tmp,o
	-- node function
	local node=function (shape,label,x,y,w,h,fill,stroke,sw,op)
		label=label or ""
		x=x and x*W or 0;y=y and y*H or 0; w=w and w*W or 1; h=h and h*H or 1;
		fill=fill or "white";stroke=stroke or "black";sw=sw or 1;op=op or 1;
		tmp=shape and shapes[shape] or shapes.ellipse
		o={label=label, x=x, y=x,w=w, h=h, fill=fill,stroke=stroke,sw=sw,op=op; fz=fz; TMP=tmp}
		o.cx=x+w/2; o.cy=y+h/2; o.tx=x+w/2; o.ty=y+h/2+font_size/2
		if tmp==shapes.ellipse then 
			 o.rx=w/2; o.ry=h/2; 
		elseif shape=="roundrect" then
			o.rx=w*0.2; o.ry=h*0.2
		end
		push(svg,o)
		return #svg
	end
	-- edge functoin
	local edge=function(label,from,to,tp)
		local f,t=svg[from],svg[to]
		local fx,fy,fw,fh=f.cx,f.cy,f.w,f.h
		local tx,ty,tw,th=t.cx,t.cy,t.w,t.h
		local ttx,tty,arrow=(fx+tx)/2,(fy+ty)/2
		local pt={}
		if tp=="-" then
			pt[1]={ fx>tx and fx-fw/2 or fx+fw/2, fy}
			pt[2]={ fx>tx and tx+tw/2 or tx-tw/2,ty}
		elseif tp=="|" then
			pt[1]={ fx, fy>ty and fy-fh/2 or fy+fh/2}
			pt[2]={ tx,fy>ty and ty+th/2 or ty-th/2 }
		elseif tp=="L" then
			ttx,tty=fx,ty+font_size
			pt[1]={ fx, fy>ty and fy-fh/2 or fy+fh/2}
			pt[2]={ fx, ty}
			pt[3]={ fx>tx and tx+tw/2 or tx-tw/2, ty}
		elseif tp=="7" then
			ttx,tty=tx,fy
			pt[1]={ fx>tx and fx-fw/2 or fx+fw/2, fy}
			pt[2]={ tx, fy}
			pt[3]={ tx, fy>ty and ty+th/2 or ty-th/2}
		elseif tp=="[" then
		elseif tp=="]" then
		end
		local o={TMP=shapes.path,path=points2path(pt),label=label or "",tx=ttx,ty=tty}
		push(svg,o)
	end
	-- export function
	local export=function(path)
		for i,v in ipairs(svg) do
			svg[i]=convert(v,v.TMP)
		end
		svg.VALUE=table.concat(svg,"\n")
		local str=convert(svg,SVG_TMP)
		if not path then print(str) return end
		local f=path and io.open(path,"w")
		if f then f:write(str); f:close() end
	end
	return node,edge,export
end


add_edge=function(from,to,tp)
	
end

local push=table.insert
add_obj=function(p,label,tp,cx,cy,rx,ry) -- all cx,cy,rx,ry are in [0,1]
	local x,y,w,h=p.x ,p.y,p.w,p.h
	cx=x+(cx and cx*w or 0);cy=y+(cy and cy*h or 0);
	rx=rx and cx*w or w/2;ry=ry and ry*h or h/2;
	label=label or ""
	tp=tp or "ellipse"
	local n={TYPE=tp,label=label,cx=cx,cy=cy,rx=rx,ry=ry,x=cx-rx,y=cy-ry,w=rx+rx,h=ry+ry}
	push(p,n)
	return n
end

make_svg=function(x,y,w,h)
	return {TYPE="SVG",x=x or 0, y=y or 0, w=w or 500, h=h or 500}
end

local gsub,concat=string.gsub
local obj2str
obj2str=function(obj)
	if #obj>0 then -- a group
		for i,v in ipairs(obj) do
			obj[i]=obj2str(v)
		end
		obj.VALUE=concat(obj,"\n")
	end
	local tp=g.TYPE
	local fmt=tp and shapes[tp] or shapes.group
	return (gsub(fmt,"@%s*(.)%s*@",g))
end

export=function(o,path)
	local str=obj2str(o)
	if not path then print(str) return end
	local f=path and io.open(path,"w")
	if f then f:write(str); f:close() end
end
