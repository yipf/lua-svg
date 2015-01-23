local parser=function(str,x,y,dir)
	x=x or 0
	y=y or 0
	dir=dir or "v"
	for n,e in string.gmatch(str.."-->","([^%-]+)%-(.-)%->") do
		print(n,"|",e)
	end
end

local str=[[  asdf f  sdf asf a - asdfa-> asdfsfsdf - afasdfa-> asdfasfasdfaf  ]]

parser(str)