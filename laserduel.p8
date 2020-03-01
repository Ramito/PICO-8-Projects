pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--laser duel
--by oc_ram

function _init()
	cls()
	ufos={}
	live_ufos={}
	ufo_respawn_queue={}
	lasers={}
	setup_ufos()
	setup_lasers()
	create_ufo(32,32,-0.2)
	create_ufo(96,32,0.7)
	create_ufo(32,96,0.2)
	create_ufo(96,96,-0.7)
	setup_asteroids()
	spawn_asteroids()
end

function _update60()
	update_ufo_spawn()
--ufos and collisions
	foreach(live_ufos,update_ufo)
	foreach(asteroids,update_asteroid)
	--timer_start=stat(1)
	clear_hash()
	hash_colliders(live_ufos)
	hash_colliders(asteroids)
	resolve_hash_collisions()
 --print("collisions:"..stat(1)-timer_start)
	if (time()%0.25==0 and rnd(1)<0.3333) spawn_random_ast()
--lasers
	foreach(lasers,update_laser)
	foreach(lasers,update_laser_hit)
	update_particles()
	foreach(particles,collide_particle)
	foreach(explosions,update_explosion)
end

function _draw()
 cls(0)
 foreach(asteroids,draw_asteroid)
 foreach(lasers,draw_laser)
 foreach(live_ufos,draw_ufo)
 pal()
 foreach(particles,draw_particle)
 foreach(explosions,draw_explosion)
 rect(0,0,127,127,1)
end

-->8
--ufo factory

function setup_ufos()
--constants
 local attributes = {}
	attributes.acc=0.0175
	attributes.drag=-0.0225
	attributes.radius=2
	ufos.attributes=attributes
end

function create_ufo(x,y,aim)
	local ufo={}
	--register
	add(ufos,ufo)
	ufo.index=#ufos
	--attributes
	ufo.attributes=ufos.attributes
	--velocity
	ufo.vel=make_vec2(0,0)
	--hit callback
	ufo.on_hit=on_ufo_hit
	--position is set on spawn!
	--spawn in world
	spawn_ufo(ufo.index,x,y,aim)
end

function spawn_ufo(index,x,y,aim)
	local ufo=ufos[index]
	ufo.pos=make_vec2(x,y)
	make_laser(index,aim)
	add(live_ufos,ufo)
end

function despawn_ufo(index)
	destroy_laser(index)
	del(live_ufos,ufos[index])
end
-->8
--ufo sim

function on_ufo_hit(ufo,hit)
	local kill_prob=0.1*hit.hit_angle*hit.hit_angle
	if (kill_prob<(rnd(0.5)+rnd(0.5))) return
	despawn_ufo(ufo.index)
	make_exp(ufo.pos,0,24,0.225)
	ufo_respawn_queue[ufo.index]=600
end

function on_asteroid_hit(ast,hit)
	local kill_prob=0.06*hit.hit_angle*hit.hit_angle
	if (kill_prob<(rnd(0.5)+rnd(0.5))) return
	del(asteroids,ast)
end

function thrust(ufo,angle)
	local acc_vec=make_vec2(cos(angle),sin(angle))
	acc_vec:scale(ufo.attributes.acc)
	ufo.vel+=acc_vec
end

function integrate(ufo)
	local sq_vel=ufo.vel:dot(ufo.vel)
	ufo.vel+=ufo.vel:scaled(sqrt(sq_vel)*ufo.attributes.drag)
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

function get_radius(o)
	return o.attributes.radius
end

function get_mass(o)
	local r=get_radius(o)
	return r*r*r
end

function collide(u_1,u_2)
	local r1=get_radius(u_1)
	local r2=get_radius(u_2)
	local dp=u_2.pos-u_1.pos
	local tresh=r1+r2
	local dist_sq=dp:dot(dp)
	if (dist_sq>(tresh*tresh))	return
	local dist=sqrt(dist_sq)
	dp:scale(1/dist)
	local pt=dp:scaled(0.5*(dist-tresh))
	u_1.pos+=pt
	u_2.pos-=pt
	local dv=u_2.vel-u_1.vel
	local	vel_p=dv:dot(dp)
	if (vel_p>=0) return
	local vp=dp:scaled(vel_p)
	local m1=get_mass(u_1)
	local m2=get_mass(u_2)
	local tm=m1+m2
	m1/=tm
	m2=1-m1
	local vc=u_1.vel:scaled(m1)+u_2.vel:scaled(m2)
	u_1.vel=vc+vp:scaled(m2)
	u_2.vel=vc-vp:scaled(m1)
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

function update_ufo_spawn()
	for k,count in pairs(ufo_respawn_queue) do
		count-=1
		if (count>0) then
			ufo_respawn_queue[k]=(count-1)
		else
			ufo_respawn_queue[k]=nil
			spawn_ufo(k,rnd(127), rnd(127),rnd(2))
		end
	end
end

all_col={}
sp_hash={}

local grid_offset=12
local grid_cells_side=8

function coord_to_grid(coord)
	return grid_cells_side*(coord+grid_offset)/(128+2*grid_offset)
end

function grid_coords(vec2)
	local ix=coord_to_grid(vec2.x)
	local iy=coord_to_grid(vec2.y)
	return flr(ix),flr(iy)
end

function hash_cell(ix,iy)
	return ix+grid_cells_side*iy 
end

function hash_colliders(colliders)
	for i=1,#colliders do
		local collider=colliders[i]
		add(all_col,collider)
		local r=get_radius(collider)
		local offset=make_vec2(r,r)
		local minp=collider.pos-offset
		local maxp=collider.pos+offset
		local iminx,iminy=grid_coords(minp)
		local imaxx,imaxy=grid_coords(maxp)
		for ix=iminx,imaxx do
			for iy=iminy,imaxy do
				local cellid=hash_cell(ix,iy)
				cell=sp_hash[cellid] or {}
				add(cell,#all_col)
				sp_hash[cellid]=cell
			end
		end
	end
end

function clear_hash()
	all_col={}
	sp_hash={}
end

function resolve_hash_collisions()
	local checked={}
	for id,cell in pairs(sp_hash) do
		for i=1,#cell-1 do
			local ci=cell[i]
			local check=checked[ci] or {}
			for j=i+1,#cell do
				local cj=cell[j]
				if not check[cj] then
					check[cj]=true
					collide(all_col[ci],all_col[cj])
				end
			end
			checked[i]=check
		end
	end
end
-->8
--ufo render & explosions

function draw_ufo(ufo)
	apply_pal(ufo.index)
	local r=ufo.attributes.radius
	spr(1,ufo.pos.x-r,ufo.pos.y-r)
end

explosions={}

function make_exp(pos,radius,max_radius,strength)
	local expl={}
	expl.pos=cpy_vec2(pos)
	expl.radius=radius
	expl.max_radius=max_radius
	expl.strength=strength
	add(explosions,expl)
end

function update_explosion(expl)
	local growth=expl.strength*(expl.max_radius-expl.radius)
	local radius=expl.radius
	expl.radius=radius+growth
	if (expl.radius-radius<0.1) del(explosions,expl)
end

function draw_explosion(exp)
	local pos=exp.pos
	circ(pos.x,pos.y,exp.radius,9)
end
-->8
--math
--vec2
--vec2--metatable
_vec2_mt={
	__add=
		function(a,b)
			return make_vec2(a.x+b.x,a.y+b.y)
		end,
	__sub=
		function(a,b)
			return make_vec2(a.x-b.x,a.y-b.y)
		end,
	__eq=
		function(a,b)
			return a.x==b.x and a.y==b.y
		end
}
--vec2--api table
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
		end,
	normalized=function(a)
		local norm=sqrt(a:dot(a))
		return a:scaled(1/norm)
	end
}
_vec2_mt.__index=_vec2_api
--vec2--factory
function make_vec2(x,y)
	local v={x=x,y=y}
	setmetatable(v,_vec2_mt)
	return v
end
function arg_vec2(arg)
	return make_vec2(cos(arg),sin(arg))
end
function cpy_vec2(v)
	return make_vec2(v.x,v.y)
end
--rect
--rect--metatable
_rect_mt={
	__add=
		function(a,b)
			local min=a.min+b.min
			local max=a.max+b.max
			return make_rect(min,max)
		end,
	__sub=
		function(a,b)
			local min=a.min-b.max
			local max=a.max-b.min
			return make_rect(min,max)
		end
}
--rect--api table
_rect_api={
	closest_to=
		function(rec,vec2)
			local min=rec.min
			local max=rec.max
			local x=clamp(vec2.x,min.x,max.x)
			local y=clamp(vec2.y,min.y,max.y)
			return make_vec2(x,y)
		end,
	vec2_dist_sq=
		function(rec,vec2)
		 local closest=rec:closest_to(vec2)
		 local gap=closest-vec2
		 return gap:dot(gap)
		end,
	overlaps_rect=
		function(a,b)
			local diff=a-b
			local zero=make_vec2(0,0)
			local shortest=diff:closest_to(zero)
			return shortest==zero
		end
}
_rect_mt.__index=_rect_api
--rect--factory
function make_rect(min_v2,max_v2)
	local rec={min=min_v2,max=max_v2}
	setmetatable(rec,_rect_mt)
	return rec
end
function circ_bb(center,radius)
	local offset=make_vec2(radius,radius)
	return make_rect(center-offset,center+offset)
end

--general math
function clamp(val,min,max)
	if (val<min) return min
	if (val>max) return max
	return val
end


local screen_rect=make_rect(make_vec2(0,0),make_vec2(128,128))
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

function make_laser(index,aim)
	local laser={
		aim=aim,
		aim_speed=0,
		trigger=false,
		index=index,
		attrs=lasers.attrs
	}
	add(lasers,laser)
end

function destroy_laser(index)
 for i,laser in pairs(lasers) do
 	if (laser.index==index) del(lasers,laser) return
 end
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
	local ld=arg_vec2(laser.aim)
	local lp=ufos[laser.index].pos
	local tocenter=ufo.pos-lp
	local dist=ld:dot(tocenter)
	if (dist<0) return
	local h=abs(ld:ort():dot(tocenter))
	local r = ufo.attributes.radius
	if (h>r) return
	local w=sqrt(r*r-h*h)
	local hit_dist=dist-w
	if (laser.hit and (laser.hit.distance<hit_dist)) return
	local hit_point=lp+ld:scaled(hit_dist)
	local hit_normal=hit_point-ufo.pos
	
	local normal=hit_normal:normalized()
	local hit={
			distance=hit_dist,
			point=hit_point,
			normal=normal,
			hit_object=ufo,
			hit_angle=-normal:dot(ld)
		}
	laser.hit=hit
end

function update_laser_hit(laser)
	laser.hit=nil
	for k,ufo in pairs(live_ufos) do
		if ufo.index!=laser.index then
			compute_hit(laser,ufo)
		end
	end
	for i=1,#asteroids do
		compute_hit(laser,asteroids[i])
	end
	if (not laser.trigger) return
	local hit=laser.hit
	if (not hit) return
	local hit_object=hit.hit_object
	if (not hit_object or not hit_object.on_hit) return
	hit_object:on_hit(hit)
end

function spawn_hit_particles(hit,index)
	 local part_count=rnd(3)
	 local c=8
	 if (rnd(1)<0.2) c=2
	 for i=1,part_count do
	 	local vel=hit.normal:scaled(0.55+rnd(0.45))
	 	local offset=arg_vec2(rnd(2))
	 	offset:scale(rnd(0.2))
	 	make_particle(hit.point,vel+offset,index,c,20+rnd(280))
	 end
end

function draw_laser(laser)
	apply_pal(laser.index)
	local origin=ufos[laser.index].pos
	local dest
	if (laser.hit) then
	 dest=laser.hit.point
	 if (laser.trigger) spawn_hit_particles(laser.hit,laser.index)
	else
		dest=origin+arg_vec2(laser.aim):scaled(180)
	end
	if laser.trigger then
		line(origin.x,origin.y,dest.x,dest.y,8)
		circfill(dest.x,dest.y,2,8)
	else
		local o_d=origin-dest
		local max_pts=0.172*sqrt(o_d:dot(o_d))
		local points=rnd(max_pts)
		for i=1,points do
			local alpha=rnd(1)
			local c=2
			if (rnd(1)<0.06) c=8
			local point=origin:scaled(alpha)+dest:scaled(1-alpha)
		 pset(point.x,point.y,c)
		end
	end
end
-->8
--asteroid

ast_prot_map={}
asteroids={}

function register_ast(rad,spr_ind,spr_w)
	local asteroid={}
	asteroid.radius=rad
	asteroid.sprite=spr_ind
	asteroid.sprite_w=spr_w
	add(ast_prot_map,asteroid)
end

function setup_asteroids()
	register_ast(2,2,1)
	register_ast(2,18,1)
	register_ast(2,34,1)
	register_ast(3,3,1)
	register_ast(3,19,1)
	register_ast(4,4,1)
	register_ast(4,5,1)
	register_ast(4,20,1)
	register_ast(4,21,1)
	register_ast(8,6,2)
	register_ast(8,38,2)
end

function create_asteroid(x,y)
	local pos=make_vec2(x,y)
	local ast={}
	ast.pos=pos
	ast.vel=arg_vec2(rnd(1)):scaled(0.08)
	local prot_ind=flr(rnd(#ast_prot_map))+1
	ast.attributes=ast_prot_map[prot_ind]
	ast.on_hit=on_asteroid_hit
	add(asteroids,ast)
	return ast
end

function spawn_asteroids()
	for i=1,9 do
		local x=rnd(128)
		local y=rnd(128)
		create_asteroid(x,y)
	end
end

function spawn_random_ast()
	local loc=rnd(1)
	local pos
	local axis
	if (loc<0.25) then
		pos=make_vec2(132,4*128*loc)
		axis=0.5
	elseif (loc<0.5) then
		pos=make_vec2(4*128*(loc-0.25),-4)
		axis=0.75
	elseif (loc<0.75) then
		pos=make_vec2(-4,4*128*(loc-0.5))
		axis=0
	else
		pos=make_vec2(4*128*(loc-0.75),132)
		axis=0.25
	end
	axis+=(rnd(0.4)-0.2)
	local vel=arg_vec2(axis):scaled(0.025+rnd(0.3))
	create_asteroid(pos.x,pos.y).vel=vel
end

function update_asteroid(ast)
	ast.pos+=ast.vel
	local screen_dist_sq=screen_rect:vec2_dist_sq(ast.pos)
	local r_sq=ast.attributes.radius*ast.attributes.radius
	if (screen_dist_sq>4*r_sq) then
		del(asteroids,ast)
	end
end

function draw_asteroid(ast)
 local attrs=ast.attributes
	spr(attrs.sprite
	,ast.pos.x-attrs.radius
	,ast.pos.y-attrs.radius
	,attrs.sprite_w
	,attrs.sprite_w)
end
-->8
--palette & particles

palettes={}
palettes[4]={}
palettes[2]={{8,10},{2,9},{14,7}}
palettes[3]={{8,12},{2,1},{14,7}}
palettes[1]={{8,11},{2,3},{14,10}}

function apply_pal(indx)
 pal()
	for v in all(palettes[indx]) do
			pal(v[1],v[2])
	end
end

particles={}

function make_particle(pos,vel,palette,col,life)
	local part={}
	part.pos=cpy_vec2(pos)
	part.vel=cpy_vec2(vel)
	part.col=col
	part.palette=palette
	part.life=life
	add(particles,part)
end

function update_particles()
	for i,part in pairs(particles) do
		part.pos+=part.vel
		part.vel:scale(0.99)
		part.life-=1
		if part.life<=0 then
			del(particles,part)
		end
	end
end

function part_vs_col(part,col)
		local radius=get_radius(col)
		local dp=col.pos-part.pos
		distsq = dp:dot(dp)
		if (distsq> radius*radius) return	
		dp:scale(1/sqrt(distsq))
		local dv=col.vel-part.vel
		local vel_p=dp:dot(dv)
		if (vel_p>=0) return
		local vp=dp:scaled(vel_p)
		part.vel=col.vel+vp
end

function collide_particle(part)
	local ix,iy=grid_coords(part.pos)
	local cellid=hash_cell(ix,iy)
	local colliders=sp_hash[cellid]
	if (not colliders) return
	for k,i in pairs(colliders) do
		local col=all_col[i]
		part_vs_col(part,col)
	end
end

function draw_particle(part)
	apply_pal(part.palette)
	pset(part.pos.x,part.pos.y,part.col)
end
__gfx__
000000000660000005dd00000d66000000dd660000d6660000000666dd6600000060000000000000000000000000000000000000000000000000000000000000
00000000d8e600005dd60000d5ddd6000ddddd600ddddd600000ddd5dddd600005d5000000000000000000000000000000000000000000000000000000000000
00700700d8860000d5d600006dd5d600dd6dddd6ddd6ddd60066ddddddddd6006d8d600000000000000000000000000000000000000000000000000000000000
000770000dd000000d6000005dddd000d5d6d5565d5d5dd605dddddddddddd6005d5000000000000000000000000000000000000000000000000000000000000
00077000000000000000000005d60000dd5dd65d5dd5ddd60dddddddddddddd60060000000000000000000000000000000000000000000000000000000000000
007007000000000000000000000000005ddddddd5ddddd50dddddddd6dddddd60000006000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000005dd66dd05ddd600ddd6ddd5d6dddddd00000d8600000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000005d560000555000dd556dd5dd6ddddd000000d000000000000000000000000000000000000000000000000000000000
00000000000000000660000000d6000000066000000dd6005dd5dddd55ddd6dd0000000000000000000000000000000000000000000000000000000000000000
000000000000000055dd00000ddd6000055ddd600d5ddd605ddddddddddd5ddd0000000000000000000000000000000000000000000000000000000000000000
0000000000000000ddd60000555dd00005dd66d65dddd5665dddddddddddddd50000000000000000000000000000000000000000000000000000000000000000
0000000000000000556000005dd60000dddddddd5d56dd5d05d56ddddddddd500000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000056000005dd5dd665d55ddd6005d56d56ddddd000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000dd5dd5005ddddd6005dd5dd56d660000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000055ddd00005dd5500005dddd556000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000550000005560000005556000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000660000000000000000000000000000000000006ddd000000000000000000000000000000000000000000000000000000000000000000000
00000000000000005d560000000000000000000000000000000665ddddd600000000000000000000000000000000000000000000000000000000000000000000
000000000000000005dd0000000000000000000000000000005ddddddddd60000000000000000000000000000000000000000000000000000000000000000000
000000000000000000500000000000000000000000000000005dddddddddd6000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000ddddd6ddd5dd6000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000005dddd5d6ddd5dd600000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000dd6ddd5dddddddd00000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000d5d6ddddddddddd00000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000005dd6ddddddddddd60000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005dd6dddddddddd60000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005d5dddd56ddddd00000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005ddddd5dd6dd5500000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005dddddd5d5dd5000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000005dddddd5dddd000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000005ddddddddd0000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000055dd6000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006600000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006600000000dc760000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000da760000000dcc60000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000daa600000000dd00000000000000000000
00000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000dd0000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0000000000000000000000000000000000000000000000000000000000000666dd66000000000020000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000ddd5dddd600000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000066ddddddddd60000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000005dddddddddddd6000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000dddddddddddddd600000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000dddddddd6dddddd600000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000ddd6ddd5d6dddddd00000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000dd556dd5dd6ddddd00000000020000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000005dd5dddd55ddd6dd00000000000000000000000000000000000000000000000000000000
000000000000000000300000000000000000000000000000000000005ddddddddddd5ddd00000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000005dddddddddddddd500000000000800000000000000000000000000000000000000000000
0000000000000000003000000000000000000000000000000000000005d56ddddddddd5000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005d56d56ddddd0000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000005dd5dd56d6600000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000005dddd5560000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000055560000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000900000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d8e600000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d88600000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dd000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000dba600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000dbb600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000900000000000000000000000000000000000000000000000000000000
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
000100000f5701157013570175601d5502253025520285202a5202d52031510355103652000000000000000000000015000150000500015000450006500005000050000500005000050000500005000050000500
0011000003730007200071000700007001d7001d7001a70018700127000c7000b7000c7000c7000d700107001170014700127000f7000f7000f7000f7000f7000f7000f7000f7000f7000f7000f7000f70011700
001400000331005300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
