

local props={rx=50,ry=25,dw=150,dh=100,style="fill:none;"}

set_flowchart_props=function(P)
	for k,v in pairs(P) do
		props[k]=v
	end
	return props
end

local default_taget={cx=0,cy=0}

local get_pos=function(str,target)
	target=target or default_taget
	local x,y=target.cx,target.cy
	local dw,dh=props.dw,props.dh
	local match,tonumber=string.match,tonumber
	v=match(str,"L(%d*)"); x=v and x-(tonumber(v) or 1)*dw or x
	v=match(str,"R(%d*)"); x=v and x+(tonumber(v) or 1)*dw or x
	v=match(str,"U(%d*)"); y=v and y-(tonumber(v) or 1)*dh or y
	v=match(str,"D(%d*)"); y=v and y+(tonumber(v) or 1)*dh or y
	return x,y
end

unit=function(tp,label,pos_str,target)
	local x,y=get_pos(pos_str,target)
	return node{TYPE=tp or "rect",STYLE=props.style,cx=x,cy=y,rx=props.rx,ry=props.ry,LABEL=label,LPOS="D8M"}
end

process=function(label,pos_str,target)
	return unit("rect",label,pos_str,target)
end

condition=function(label,pos_str,target)
	return unit("diamond",label,pos_str,target)
end

state=function(label,pos_str,target)
	return unit("roundrect",label,pos_str,target)
end

point_to=function(from,to,label,lpos,shape,reverse,smooth)
	local offset= shape=="C" and (reverse and -dw or dw) or shape=="U" and (reverse and -dh or dh)
	return edge{FROM=from,TO=to,LABEL=label,LPOS=label and (lpos or ""),SHAPE=shape,OFFSET=offset,SMOOTH=smooth,HEAD="url(#arrow)"}
end

------------------------------------------------------------
-- usage
------------------------------------------------------------

--~ require "flowchart"

--~ local start=state("start","DR3")
--~ local p1=process("p1","D",start)
--~ local p2=process("p2","D",p1)
--~ local c=condition("c?","D",p2)
--~ local p3=process("p3","D",c)
--~ local p4=process("p4","R",p3)
--~ local _end=state("end","D",p3)

--~ point_to(start,p1)
--~ point_to(p1,p2)
--~ point_to(p2,c)
--~ point_to(c,p3,"no","R5S","-")
--~ point_to(c,p4,"yes","U5M","7")
--~ point_to(p3,_end)
--~ point_to(p4,_end,"","","N")

--~ export("test-flowchart.svg")
