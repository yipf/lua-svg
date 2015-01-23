local props={rx=25,ry=25,cell_gap=100,level_gap=100,style="fill:none;",tp="rect",shape="-",smooth=false}

set_tree_props=function(P)
	for k,v in pairs(P) do
		props[k]=v
	end
	return props
end

local labels2tree
labels2tree=function(labels)
	local label,child=unpack(labels)
	local tr=node{LABEL=label or "node",LPOS="D8M",rx=props.rx,ry=props.ry,TYPE=props.tp}
	if child then
		for i,v in ipairs(child) do
			v=labels2tree(v)
			child[i]=v
			edge{FROM=tr,TO=v,SHAPE=shape or props.shape,SMOOTH=props.smooth,HEAD=""}
		end
		tr.CHILD=child
	end
	return tr
end

build_child_level=function(l)
	local L={}
	local n,v,child=#l
	local push=table.insert
	local have_next=false
	for i=1,n do
		v=l[i]
		child=v.CHILD
		if child then 
			have_next=true
			for ii=1,#child do
				push(L,child[ii])
			end
		else
			push(L,v)
		end
	end
	return L, have_next
end

local get_y=function(n)
	local y=0
	for i,v in ipairs(n.CHILD) do
		y=y+v.cy
	end
	return y/#(n.CHILD)
end

local layout_tree=function(tr,level_gap,cell_gap,left,top)
	local levels={}
	local level,have_next={tr}
	repeat
		table.insert(levels,level)
		level,have_next=build_child_level(level)
	until not have_next
	local n=#levels
	local level=levels[n]
	if level then
		for i,v in ipairs(level) do
			v.cx,v.cy=left+(n-1)*level_gap,top+(i-1)*cell_gap
		end
		if n>1 then
			for i=n-1,1,-1 do
				level=levels[i]
				for ii,v in ipairs(level) do
					v.cx=left+(i-1)*level_gap
					if v.CHILD then	v.cy=get_y(v)	end
				end
			end
		end
	end
	return tr, (n-1)*level_gap, (#(levels[n])-1)*cell_gap
end

-- make a tree from left to right

make_tree_LR=function(labels,left,top)
	local tr=labels2tree(labels)
	return layout_tree(tr,props.level_gap,props.cell_gap,left or 50,top or 50)
end

--~ local rotate
--~ rotate=function(tr)
--~ 	tr.cx,tr.cy=tr.cy,tr.cx
--~ 	if tr.CHILD then
--~ 		for i,v in ipairs(tr.CHILD) do
--~ 			rotate(v)
--~ 		end
--~ 	end
--~ 	return tr
--~ end

--~ -- make a tree from up to down
--~ make_tree_UD=function(labels,left,top,cell_x,cell_y,level_gap,cell_gap)
--~ 	local tr=labels2tree(labels)
--~ 	local tr,x,y=layout_tree(tr,props.cell_gap,props.level_gap,top or 50,left or 50)
--~ 	return rotate(tr),y,x
--~ end

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- another ugly and tricky implemention of function 'make_tree_UD'
--------------------------------------------------------------------------------------------------------------------------------------------------------
make_tree_UD=function(labels,left,top,cell_x,cell_y,level_gap,cell_gap)
	local map=prepare_map()
	local tr=labels2tree(labels,cell_x or 25,cell_y or 25,"N")
	local tr,x,y=layout_tree(tr,cell_gap or 100,level_gap or 100,top or 50,left or 50)
	map(function(o) o.cx,o.cy=o.cy,o.cx end)
	return tr,y,x
end

------------------------------------------------------
-- usage
------------------------------------------------------
--~ require "tree"

--~ local tr,x,y=make_tree_UD{"root",	{
--~ 	{"left"},
--~ 	{"right",{
--~ 		{"r1"},
--~ 		{"r2"},
--~ 		{"r3",{
--~ 			{"rr1"},
--~ 			{"rr2"},
--~ 			{"rr3"},
--~ 		}},
--~ 	}},	

--~ 	}
--~ }

--~ print(x,y)

--~ tr.CHILD[1].STYLE="fill:orange;"
--~ tr.CHILD[2].STYLE="fill:red;"
--~ tr.CHILD[2].CHILD[3].STYLE="fill:grey;"

--~ local p={CLOSE=true,STYLE="fill:orange;",cx=500,cy=500,LABEL="FIVE",MIDDLE="url(#point2d)",TAIL="url(#point2d)",SMOOTH}

--~ local r,a
--~ local cos,sin,pi= math.cos,math.sin,math.pi
--~ for i=1,10 do
--~ 	r=(i%2+1)*50
--~ 	p[i]={500+r*cos((i-1)*pi/5),500+r*sin((i-1)*pi/5)}
--~ end

--~ path(p)

--~ export("tree.svg")


