pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--laser duel
--by oc_ram

function _init()
	cls()
	ufos={}
	lasers={}
	setup_ufos()
	setup_lasers()
	spawn_ufo(32,32)
	spawn_ufo(96,32)
	spawn_ufo(32,96)
	spawn_ufo(96,96)
end

function _update60()
--ufos and collisions
 foreach(ufos,update_ufo)
 for i=1,#ufos do
 	for j=i+1,#ufos do
 		collide_ufos(ufos[i], ufos[j])
 	end
 end
--lasers
	foreach(lasers,update_laser)
	foreach(lasers,update_laser_hit)
end

function _draw()
 cls(0)
 foreach(lasers,draw_laser)
 foreach(ufos,draw_ufo)
end

-->8
--ufo factory

palettes={}
palettes[1]={}
palettes[2]={{8,10},{2,9},{14,7}}
palettes[3]={{8,12},{2,1},{14,7}}
palettes[4]={{8,11},{2,3},{14,10}}

function apply_pal(indx)
 pal()
	for v in all(palettes[indx]) do
			pal(v[1],v[2])
	end
end

function setup_ufos()
--constants
 local attributes = {}
	attributes.acc=0.0175
	attributes.drag=-0.0225
	attributes.radius=1.5
	ufos.attributes=attributes
end

function spawn_ufo(x,y)
	local ufo={}
	--register
	add(ufos,ufo)
	ufo.index=#ufos
	--attributes
	ufo.attributes=ufos.attributes
	--position
	ufo.pos=make_vec2(x,y)
	--velocity
	ufo.vel=make_vec2(0,0)
	--ufo laser
	make_laser(ufo)
end
-->8
--ufo sim

function thrust(ufo,angle)
	local acc_vec=make_vec2(cos(angle),sin(angle))
	acc_vec:scale(ufo.attributes.acc)
	ufo.vel+=acc_vec
end

function integrate(ufo)
	local sq_vel=ufo.vel:dot(ufo.vel)
	ufo.vel+=ufo.vel:scaled(sqrt(sq_vel)*ufo.attributes.drag)
	--ufo.vel:scale(ufo.attributes.drag)
	ufo.pos+=ufo.vel
end

function screen_bounce(ufo)
	local r=ufo.attributes.radius
	local gap=ufo.pos.x-r
	if (gap<0) ufo.pos.x-=gap ufo.vel.x*=-1
	gap=ufo.pos.x+r-128
	if (gap>0) ufo.pos.x-=gap ufo.vel.x*=-1
	gap = ufo.pos.y-r
	if (gap<0) ufo.pos.y-=gap ufo.vel.y*=-1
	gap = ufo.pos.y+r-128
	if (gap>0) ufo.pos.y-=gap ufo.vel.y*=-1
end

function collide_ufos(u_1,u_2)
	local dp=u_2.pos-u_1.pos
	local dist_sq=dp:dot(dp)
	local tresh=u_1.attributes.radius+u_2.attributes.radius
	if dist_sq > (tresh*tresh) then
		return
	end
	local dist=sqrt(dist_sq)
	dp:scale(1/dist)
	local pt=dp:scaled(0.5*(dist-tresh))
	u_1.pos+=pt
	u_2.pos-=pt
	local dv=u_2.vel-u_1.vel
	local vt=dp:scaled(dv:dot(dp))
	u_1.vel+=vt
	u_2.vel-=vt
	sfx(1)
end

function update_ufo(ufo)
 local index=ufo.index-1
 --x input
	local x_arg=0
	if (btn(➡️,index)) x_arg+=1
	if (btn(⬅️,index)) x_arg-=1
	--y input
	local y_arg=0
	if (btn(⬇️,index)) y_arg-=1
	if (btn(⬆️,index)) y_arg+=1
	--resolve
	local arg=0.25*(1-x_arg)
	if y_arg > 0 then
		arg=0.125*(2-x_arg)
	elseif y_arg < 0 then
		arg=0.125*(6+x_arg)
	end
	if x_arg!=0 or y_arg!=0 then
		thrust(ufo,arg)
	end
	integrate(ufo)
	screen_bounce(ufo)
end
-->8
--ufo render

function draw_ufo(ufo)
	apply_pal(ufo.index)
	local r=ufo.attributes.radius
	spr(1,ufo.pos.x-r,ufo.pos.y-r)
end
-->8
--math
--vec2 metatable
_vec2_mt={
	__add=function(a,b)
			return make_vec2(a.x+b.x,a.y+b.y)
		end,
	__sub=function(a,b)
			return make_vec2(a.x-b.x,a.y-b.y)
		end
}
--api table
_vec2_api={
	dot=function(a,b)
			return a.x*b.x+a.y*b.y
		end,
	scale=function(a,s)
			a.x*=s
			a.y*=s
		end,
	scaled=function(a,s)
			return make_vec2(a.x*s,a.y*s)
		end,
	ort=function(a)
			return make_vec2(a.y,-a.x)
		end
}
--factory
_vec2_mt.__index=_vec2_api

function make_vec2(x,y)
	local v={x=x,y=y}
	setmetatable(v,_vec2_mt)
	return v
end

function arg_vec2(arg)
	return make_vec2(cos(arg),sin(arg))
end
-->8
--laser

function setup_lasers()
--constants
 local attrs = {}
 attrs.aim_acc=0.0001
 attrs.aim_drag=0.99925
 attrs.aim_brake=0.9
	lasers.attrs=attrs
end

function make_laser(ufo)
	local laser={
		aim=0,
		aim_speed=0,
		trigger=false,
		index=ufo.index,
		attrs=lasers.attrs
	}
	add(lasers,laser)
end

function update_laser(laser)
	local attrs=lasers.attrs
	local la=attrs.aim_acc
 local index=laser.index-1
 local ❎=btn(❎,index)
 local 🅾️=btn(🅾️,index)
 local speed=laser.aim_speed
 acc=0
 if (❎) acc-=la
 if (🅾️) acc+=la
 local drag=attrs.aim_brake
 if acc~=0 and acc*speed>=0 then
 	drag=attrs.aim_drag
 end
 speed+=acc
 speed*=drag
 if (speed == laser.aim_speed) speed=0
 laser.aim_speed=speed
 laser.aim+=speed
	if (laser.trigger) then
		laser.trigger=❎ or 🅾️
	else
		if (❎ and 🅾️) laser.trigger=true sfx(0)
	end
end

function compute_hit(laser,ufo)
	if (ufo.index==laser.index) return nil
	local ld=arg_vec2(laser.aim)
	local lp=ufos[laser.index].pos
	local tocenter=ufo.pos-lp
	local dist=ld:dot(tocenter)
	if (dist<0) return nil
	local h=abs(ld:ort():dot(tocenter))
	local r = ufo.attributes.radius
	if (h>r) return nil
	local w=sqrt(r*r-h*h)
	local hit_dist=dist-w
	local hit_point=lp+ld:scaled(hit_dist)
	local hit_normal=hit_point-ufo.pos
	local hit={
			distance=hit_dist,
			point=hit_point,
			normal=hit_normal
		}
	return hit
end

function update_laser_hit(laser)
	laser.hit=nil
	for ufo in all(ufos) do
		local hit=compute_hit(laser,ufo)
		if (hit!=nil) then
			if (not laser.hit or laser.hit.distance > hit.distance) then
				laser.hit=hit
			end
		end
	end
end

function draw_laser(laser)
	apply_pal(laser.index)
	local origin=ufos[laser.index].pos
	local dest
	if (laser.hit) then
	 dest=laser.hit.point
	else
		dest=origin+arg_vec2(laser.aim):scaled(180)
	end
	if laser.trigger then
		line(origin.x,origin.y,dest.x,dest.y,8)
		circfill(dest.x,dest.y,2,8)
	else
		local o_d=origin-dest
		local max_pts=0.175*sqrt(o_d:dot(o_d))
		local points=rnd(max_pts)
		for i=1,points do
			local alpha=rnd(1)
			local c=2
			if (rnd(1)<0.025) c=8
			local point=origin:scaled(alpha)+dest:scaled(1-alpha)
		 pset(point.x,point.y,c)
		end
	end
end
__gfx__
00000000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d8e600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700d88600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d666d00000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d699a6d0000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d69996d0400000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d69996d0000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d666d00000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000200000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000008000000200000000000000000000000000000000000000000000000000000000ddd000000000000000000
0000000000000000000000000000000000000000000000000000000000000000020000200000000000000000000000000000000000d666d00000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000020000020000000200000000000000d688e6d0000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d68886d0000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d68886d0000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d666d00000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000ddd000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000d666d00000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000d6bba6d0000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000d6bbb6d0030000000000000000003000003000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000d6bbb6d0000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000d666d00000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000ddd000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000ddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000d666d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000d6cc76d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000d6ccc6d00000000010000000000000000000000000000000000000000000001000000000000000000000100000000000000
00000000000000000000000000000d6ccc6d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000d666d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000ddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
010100000f5701157013570175601d5502253025520285202a5202d52031510355103652000000000000000000000015000150000500015000450006500005000050000500005000050000500005000050000500
0014000002660016200061001600006001d6001d6001a60018600126000c6000b6000c6000c6000d600106001160014600126000f6000f6000f6000f6000f6000f6000f6000f6000f6000f6000f6000f60011600
