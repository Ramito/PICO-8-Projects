pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--laser duel
--by oc_ram

function _init()
	cls()
	setup_palette()
	ufos={}
	live_ufos={}
	ufo_respawn_queue={}
	lasers={}
	initialize_random()
	setup_asteroids()
	spawn_asteroids()
	for i=1,450 do
		clear_hash()
		foreach(asteroids,update_asteroid)
		hash_colliders(asteroids)
		resolve_hash_collisions()
		spawn_random_ast(i/60)
	end
	for i=1,1000 do
		alloc_part(0)
	end
	setup_ufos()
	setup_lasers()
	create_ufo(32,32,-0.2)
	create_ufo(96,32,0.7)
	create_ufo(32,96,0.2)
	create_ufo(96,96,-0.7)
end

function _update60()
	clear_hash()
	update_ufo_spawn()
	foreach(explosions,update_explosion)
	hash_explosions()
--ufos and collisions
	foreach(live_ufos,update_ufo)
	foreach(asteroids,update_asteroid)
	hash_colliders(live_ufos)
	hash_colliders(asteroids)
	resolve_hash_collisions()
	resolve_expl_vs_colliders()
	spawn_random_ast(time())
--lasers
	foreach(lasers,update_laser)
	foreach(lasers,update_laser_hit)
	update_particles()
	process_particles()
end

function _draw()
	cls(0)
	draw_particles()
	foreach(explosions,draw_explosion)
	foreach(asteroids,draw_asteroid)
	foreach(lasers,draw_laser)
	foreach(live_ufos,draw_ufo)
	rect(0,0,127,127,1)
end

-->8
--ufo factory

local ufo_drag=-0.0225
function setup_ufos()
--constants
 local attributes = {}
	attributes.acc=0.0175
	attributes.radius=2.5
	ufos.attributes=attributes
end

function create_ufo(x,y,aim)
	local ufo={}
	--register
	add(ufos,ufo)
	ufo.index=#ufos
	--attributes
	ufo.attributes=ufos.attributes
	--hit callback
	ufo.on_hit=on_ufo_hit
	ufo.on_exp=on_exp_hit_ufo
	--position is set on spawn!
	--spawn in world
	spawn_ufo(ufo.index,x,y,aim)
end

function spawn_ufo(index,x,y,aim)
	local ufo=ufos[index]
	ufo.pos=make_vec2(x,y)
	ufo.vel=make_vec2(0,0)
	ufo.integrity=1.0
	make_laser(index,aim)
	add(live_ufos,ufo)
end

function despawn_ufo(index)
	destroy_laser(index)
	del(live_ufos,ufos[index])
end
-->8
--ufo sim

function destroy_ufo(ufo)
	despawn_ufo(ufo.index)
	--note we pass ufo position. could cause issues if explosions moved
	make_exp(ufo.pos,ufo.vel,ufo.index)
	local radius=get_radius(ufo)
	local particles=85
	local p_i=flr(rnd(#random_arg_vec2-particles))
	for i=1,particles do
		local normpos=random_arg_vec2[p_i+i]
		local pos=get_cached_vec2(1):set(normpos)
		pos:add(ufo.pos)
		make_spark_particle(pos,ufo.vel,ufo.index)
	end
	ufo_respawn_queue[ufo.index]=600
end

function on_ufo_hit(ufo,hit)
	ufo.integrity-=(0.05*hit.angle)
	if (ufo.integrity>0) return
	destroy_ufo(ufo)
end

local exp_impact_prop=0.5
local exp_vs_col_str=0.325
function explosion_vs_collider(exp,col)
	local diff=get_cached_vec2(1):set(col.pos):sub(exp.pos)
	local dist_sq=diff:dot(diff)
	local exp_rad=exp.radius
	local col_rad=get_radius(col)
	local rad_sum=exp_rad+col_rad
	if dist_sq<=rad_sum*rad_sum then
		local push=exp_vs_col_str*explode_strength(exp)
		diff:scale(push/(sqrt(dist_sq)*col_rad*col_rad*col_rad))
		col.vel:add(diff)
		local hit_dist=exp_impact_prop*exp_rad+col_rad
		if (col.on_exp and dist_sq<=hit_dist*hit_dist and 0.1>rnd(1)) col:on_exp(exp)
	end
end

function on_exp_hit_ufo(ufo,exp)
	destroy_ufo(ufo)
end

function on_exp_hit_asteroid(ast,exp)
	destroy_asteroid(ast,-1)
end

function destroy_asteroid(ast, spark_index)
	del(asteroids,ast)
	local ast_rad=get_radius(ast)
	local smaller = ast
	local smaller_rad=0
	local rad_accum=0
	local consumed_area=0
	while smaller and 0.6666*rad_accum<ast_rad do
		local allowed_rad=ast_rad-0.6666*rad_accum
		smaller = create_smaller_asteroid(0,0,allowed_rad, rad_accum!=0)
		if smaller then
			smaller_rad=get_radius(smaller)
			rad_accum+=smaller_rad
			consumed_area+=(smaller_rad*smaller_rad)

			local random=random_arg_vec2[flr(rnd(#random_arg_vec2))+1]
			smaller.pos:set(random):scale(rnd(ast_rad-smaller_rad)):add(ast.pos)

			local random=random_arg_vec2[flr(rnd(#random_arg_vec2))+1]
			smaller.vel:set(random):scale(0.05):add(ast.vel)
		end
	end
	local total_area=ast_rad*ast_rad
	local particles=flr(1.1*(total_area - consumed_area)) + flr(rnd(4))
	local p_i=flr(rnd(#random_arg_vec2-particles))
	local v_i=flr(rnd(#random_arg_vec2-particles))
	for i=1,particles do
		local normpos=random_arg_vec2[p_i+i]
		local pos=get_cached_vec2(1):set(normpos)
		pos:scale(rnd(ast_rad))
		pos:add(ast.pos)
		local vel=get_cached_vec2(2):set(random_arg_vec2[v_i+i]):scale(rnd(0.025))
		vel:add(ast.vel)
		make_asteroid_particle(pos,vel,1,90+rnd(1500))
	end
	if (spark_index<1) return
	local sparks=flr(0.22*total_area) + flr(rnd(2))
	p_i=flr(rnd(#random_arg_vec2-sparks))
	v_i=flr(rnd(#random_arg_vec2-sparks))
	for i=1,sparks do
		local normpos=random_arg_vec2[p_i+i]
		local pos=get_cached_vec2(1):set(normpos)
		pos:scale(rnd(ast_rad))
		pos:add(ast.pos)
		local vel=get_cached_vec2(2):set(random_arg_vec2[v_i+i]):scale(rnd(1.5))
		vel:add(ast.vel)
		local palette=5
		if (i>=0.9*sparks) palette=spark_index
		make_spark_particle(pos,vel,palette)
	end
end

function on_asteroid_hit(ast,hit)
	local kill_prob=0.45*hit.angle*hit.angle
	if (kill_prob<(rnd(0.5)+rnd(0.5))) return
	destroy_asteroid(ast, hit.index)
end

local _vec2_cache={}
function get_cached_vec2(index)
	if (_vec2_cache[index]==nil) _vec2_cache[index]=make_vec2(0,0)
	return _vec2_cache[index]
end

function thrust(ufo,angle)
	local thrust=get_cached_vec2(1)
	thrust:set_arg(angle):scale(ufo.attributes.acc)
	ufo.vel:add(thrust)
end

function integrate(ufo)
	local sq_vel=ufo.vel:dot(ufo.vel)
	ufo.vel:scale(1+sqrt(sq_vel)*ufo_drag)
	ufo.pos:add(ufo.vel)
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
	return o.radius or o.attributes.radius
end

function get_mass(o)
	local r=get_radius(o)
	return r*r*r
end

function collide(u_1,u_2)
	local r1=get_radius(u_1)
	local r2=get_radius(u_2)
	local tresh=r1+r2
	local dp=get_cached_vec2(1)
	dp:set(u_2.pos):sub(u_1.pos)
	local dist_sq=dp:dot(dp)
	if (dist_sq>(tresh*tresh))	return
	local dist=sqrt(dist_sq)
	dp:scale(1/dist)
	local pt=get_cached_vec2(2)
	pt:set(dp):scale(0.5*(dist-tresh))
	u_1.pos:add(pt)
	u_2.pos:sub(pt)
	local dv=pt--pt no longer used
	dv:set(u_2.vel):sub(u_1.vel)
	local	vel_p=dv:dot(dp)
	if (vel_p>=0) return
	dp:scale(vel_p)--velocity projection vp
	local m1=get_mass(u_1)
	local m2=get_mass(u_2)
	local tm=m1+m2
	m1/=tm
	m2=1-m1
	local vc1=dv--dv no longer used
	vc1:set(u_1.vel):scale(m1)
	local vc2=get_cached_vec2(3)
	vc2:set(u_2.vel):scale(m2)
	vc1:add(vc2)
	u_1.vel:set(vc1)
	u_2.vel:set(vc1)
	vc1:set(dp):scale(m2)
	u_1.vel:add(vc1)
	vc1:set(dp):scale(m1)
	u_2.vel:sub(vc1)
	sfx(1)
end

function update_ufo(ufo)
	ufo.integrity+=0.001
	if (ufo.integrity>1) ufo.integrity=1
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

col_hash_id={}
col_sp_hash={}


exp_hash_id={}
exp_sp_hash={}

local grid_offset=16
local grid_cells_side=16

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

function hash_objects(objects, id_map, object_hash)
	for i=1,#objects do
		local collider=objects[i]
		add(id_map,collider)
		local offset=get_cached_vec2(1)
		local r=get_radius(collider)
		offset:set_coords(-r,-r):add(collider.pos)
		local iminx,iminy=grid_coords(offset)
		offset:set_coords(r,r):add(collider.pos)
		local imaxx,imaxy=grid_coords(offset)
		for ix=iminx,imaxx do
			for iy=iminy,imaxy do
				local cellid=hash_cell(ix,iy)
				cell=object_hash[cellid] or {}
				add(cell,#id_map)
				object_hash[cellid]=cell
			end
		end
	end
end

function hash_colliders(colliders)
	hash_objects(colliders,col_hash_id,col_sp_hash)
end

function hash_explosions()
	hash_objects(explosions,exp_hash_id,exp_sp_hash)
end

function clear_hash()
	col_hash_id={}
	col_sp_hash={}
	exp_hash_id={}
	exp_sp_hash={}
end

function resolve_hash_collisions()
	local checked={}
	for id,cell in pairs(col_sp_hash) do
		for i=1,#cell-1 do
			local ci=cell[i]
			local check=checked[ci] or {}
			for j=i+1,#cell do
				local cj=cell[j]
				if not check[cj] then
					check[cj]=true
					collide(col_hash_id[ci],col_hash_id[cj])
				end
			end
			checked[i]=check
		end
	end
end

function resolve_expl_vs_colliders()
	for id,ecell in pairs(exp_sp_hash) do
		ccell=col_sp_hash[id]
		if (ccell) then
			for i=1,#ecell do
				local ei=ecell[i]
				for j=1,#ccell do
					explosion_vs_collider(exp_hash_id[ei],col_hash_id[ccell[j]])
				end
			end
		end
	end
end
-->8
--ufo render & explosions

function draw_ufo(ufo)
	apply_pal(ufo.index)
	local r=ufo.attributes.radius
	local ix=flr(ufo.pos.x-r+0.5)
	local iy=flr(ufo.pos.y-r+0.5)
	spr(1,ix,iy)
	local offset=4
	local from_x=ix-offset+r
	local raw_length=2*ufo.integrity*offset
	local bar_length=flr(raw_length)
	local to_x=from_x+bar_length
	local bar_y=iy+offset+r
	line(from_x,bar_y,to_x,bar_y,8)
	local bleed=raw_length-bar_length
	if (bleed>=0.925) then 
		pset(to_x+1,bar_y,14)
	elseif (bleed>=0.25) then
		pset(to_x+1,bar_y,2)
	end
end

explosions={}

function make_exp(pos,vel,palette)
	local expl={}
	expl.pos=pos
	expl.vel=vel
	expl.radius=0
	expl.max_radius=50
	expl.strength=0.0025
	expl.palette=palette
	add(explosions,expl)
	return expl
end

function explode_strength(expl)
	local mr=expl.max_radius
	local r=expl.radius
	local diff=mr-r
	return expl.strength*diff*diff
end

function update_explosion(expl)
	local growth=explode_strength(expl)
	if (growth<=0.25) del(explosions,expl) return
	integrate(expl)
	expl.radius+=growth
end

function draw_explosion(exp)
	pal()
	local pos=exp.pos
	circfill(pos.x,pos.y,0.5*exp.radius,map_color(5,get_spark_base_color()))
	circfill(pos.x,pos.y,0.25*exp.radius,map_color(exp.palette,get_spark_base_color()))
end
-->8
--math
--vec2
--vec2--api table
_vec2_api={
	add=function(a,b)
			a.x+=b.x
			a.y+=b.y
			return a
		end,
	sub=function(a,b)
			a.x-=b.x
			a.y-=b.y
			return a
		end,
	set_coords=function(a,x,y)
			a.x=x
			a.y=y
			return a
		end,
	set_arg=function(a,arg)
			a.x=cos(arg)
			a.y=sin(arg)
			return a
		end,
	set=function(a,b)
			a.x=b.x
			a.y=b.y
			return a
		end,
	copy=function(a)
			return make_vec(a.x,a.y)
		end,
	dot=function(a,b)
			return a.x*b.x+a.y*b.y
		end,
	scale=function(a,s)
			a.x*=s
			a.y*=s
			return a
		end,
	ort=function(a)
			return make_vec2(a.y,-a.x)
		end,
	ort_dot=function(a,b)
			return a.y*b.x-a.x*b.y
		end,
	normalize=function(a)
			local norm=sqrt(a:dot(a))
			a:scale(1/norm)
			return a
		end
}
--vec2--metatable
_vec2_mt={
	__index=_vec2_api
}
--vec2--factory
function make_vec2(x,y)
	local v={x=x,y=y}
	setmetatable(v,_vec2_mt)
	return v
end
function copy_vec2(v)
	return make_vec2(v.x,v.y)
end
function arg_vec2(arg)
	return make_vec2(cos(arg),sin(arg))
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
		 closest:sub(vec2) --gap
		 return closest:dot(closest)
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

random_arg_vec2={}
function initialize_random()
	for i=1,1000 do
		add(random_arg_vec2,arg_vec2(rnd(2)))
	end
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
 attrs.reload_ticks=60
 attrs.discharge_ticks=40
	lasers.attrs=attrs
end

function make_laser(index,aim)
	local laser={
		aim=aim,
		aim_speed=0,
		discharging=false,
		beam_active=false,
		ticks=0,
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
	if(laser.ticks <= 0) then
		if (laser.discharging) then
			laser.discharging=false
			laser.ticks=attrs.reload_ticks
		else
			if (❎ and 🅾️) then
				laser.discharging=true
				sfx(0)
				laser.ticks=attrs.discharge_ticks
			end
		end
	else
		laser.ticks-=1
	end
	local ticks_mod = laser.ticks % 8
	laser.beam_active = laser.discharging and ticks_mod>=3
	if (laser.discharging and ticks_mod==7) sfx(0)
end

function compute_hit(laser,col)
	local hit=laser.hit
	local ld=get_cached_vec2(1)
	ld:set_arg(laser.aim)
	local lp=ufos[laser.index].pos
	local tocenter=get_cached_vec2(2)
	tocenter:set(col.pos):sub(lp)
	local dist=ld:dot(tocenter)
	if (dist<0) return
	local h=abs(ld:ort_dot(tocenter))
	local r = col.attributes.radius
	if (h>r) return
	local w=sqrt(r*r-h*h)
	local hit_dist=dist-w
	if (hit.object and (hit.distance<hit_dist)) return
	hit.distance=hit_dist
	hit.point:set(ld):scale(hit_dist):add(lp)
	hit.normal:set(hit.point):sub(col.pos):normalize()
	hit.object=col
	hit.angle=-hit.normal:dot(ld)
	hit.index=laser.index
end

function make_hit(laser)
	laser.hit={
		distance=0,
		point=make_vec2(0,0),
		normal=make_vec2(0,0),
		object=nil,
		angle=0
	}
	return laser.hit
end

function update_laser_hit(laser)
	local hit=laser.hit or make_hit(laser)
	hit.object=nil
	for k,ufo in pairs(live_ufos) do
		if ufo.index!=laser.index then
			compute_hit(laser,ufo)
		end
	end
	for i=1,#asteroids do
		compute_hit(laser,asteroids[i])
	end
	if (not laser.beam_active) return
	local hit_object=hit.object
	if (not hit_object or not hit_object.on_hit) return
	hit_object:on_hit(hit)
end

function spawn_hit_particles(hit,index)
	local part_count=rnd(1.5)
	local rnd_i=flr(rnd(#random_arg_vec2))
	for i=1,part_count do
		local vel=get_cached_vec2(4):set(hit.normal):scale(0.225+rnd(0.25))
		local offset=get_cached_vec2(5):set(random_arg_vec2[1+rnd_i])
		offset:scale(rnd(0.2))
		vel:add(offset)
		make_spark_particle(hit.point,vel,index)
	end
end

function draw_laser(laser)
	apply_pal(laser.index)
	local origin=ufos[laser.index].pos
	local dest=get_cached_vec2(1)
	if (laser.hit.object) then
	 dest:set(laser.hit.point)
	 if (laser.beam_active) spawn_hit_particles(laser.hit,laser.index)
	else
		dest:set_arg(laser.aim)
			:scale(180):add(origin)
	end
	if laser.beam_active then
		line(origin.x,origin.y,dest.x,dest.y,8)
		circfill(dest.x,dest.y,2,8)
	elseif not laser.discharging then
		local o_d=get_cached_vec2(2)
		o_d:set(origin):sub(dest)
		local max_pts=0.175*sqrt(o_d:dot(o_d))
		local reload_ticks=laser.attrs.reload_ticks
		local laser_ticks=laser.ticks
		local reload_mod=(reload_ticks - laser_ticks)/reload_ticks
		max_pts*=(reload_mod*reload_mod);
		local gleam=0.06
		if (laser_ticks==0) then
			max_pts*=1.5
			gleam=0.2
		elseif (laser_ticks<=10) then
			max_pts*=10
			gleam=1
			circ(origin.x,origin.y,5*(10-laser_ticks)/10,8)
		end
		local points=rnd(max_pts)
		for i=1,points do
			local alpha=rnd(1)
			local c=2
			if (rnd(1)<gleam) c=8
			local to=get_cached_vec2(3)
			to:set(dest):scale(1-alpha)
			o_d:set(origin):scale(alpha):add(to)
			draw_pixel(o_d.x,o_d.y,map_color(laser.index,c))
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
	local prot_ind=flr(rnd(#ast_prot_map))+1
	return create_asteroid_prot_ind(x,y,prot_ind)
end

function get_smaller_index(radius,allow_same)
	local index=0
	while ast_prot_map[index+1].radius<radius do
		index+=1
	end
	while allow_same and ast_prot_map[index+1].radius==radius do
		index+=1
	end
	return index
end

function create_smaller_asteroid(x,y,radius,allow_same)
	local index = get_smaller_index(radius,allow_same)
	if (index==0) return
	local prot_ind=flr(rnd(index))+1
	return create_asteroid_prot_ind(x,y,prot_ind)
end

function create_asteroid_prot_ind(x,y,prot_ind)
	local pos=make_vec2(x,y)
	local ast={}
	ast.pos=pos
	ast.vel=arg_vec2(rnd(1)):scale(0.1)
	ast.attributes=ast_prot_map[prot_ind]
	ast.on_hit=on_asteroid_hit
	ast.on_exp=on_exp_hit_asteroid
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

local random_detail=16
local ast_offset=12
function spawn_random_ast(time)
	if (time%0.125!=0 or rnd(1)>=0.375) return
	local side=rnd(1)
	local loc=-ast_offset+(128+2*ast_offset)*rnd(1)
	local pos=get_cached_vec2(1)
	local axis
	if (side<0.25) then
		pos:set_coords(128+ast_offset,loc)
		axis=0.5
	elseif (side<0.5) then
		pos:set_coords(loc,-ast_offset)
		axis=0.75
	elseif (side<0.75) then
		pos:set_coords(-ast_offset,loc)
		axis=0
	else
		pos:set_coords(loc,128+ast_offset)
		axis=0.25
	end
	axis+=(rnd(0.5)-0.25)
	local vel=get_cached_vec2(2)
	local dieroll=0
	for i=1,random_detail do
		dieroll+=rnd(1/random_detail)
	end
	vel:set_arg(axis):scale(9.5*dieroll)
	local ast=create_asteroid(pos.x,pos.y)
	local radius=get_radius(ast)
	ast.vel:set(vel):scale(1.0/(radius*radius))
end

function update_asteroid(ast)
	ast.pos:add(ast.vel)
	local ast_pos=ast.pos
	local diff=screen_rect:closest_to(ast_pos):sub(ast_pos)
	local dist_sq=diff:dot(diff)
	if (dist==0) return
	if (diff:dot(ast.vel)>=0) return
	local ast_r=get_radius(ast)
	if (dist_sq>4*ast_r*ast_r) then
		del(asteroids,ast)
	end
end

function draw_asteroid(ast)
 local attrs=ast.attributes
	spr(attrs.sprite
	,flr(ast.pos.x-attrs.radius+0.5)
	,flr(ast.pos.y-attrs.radius+0.5)
	,attrs.sprite_w
	,attrs.sprite_w)
end
-->8
--palette & particles

palettes={}
function setup_palette()
	local pl = {}
	pl[8]=11
	pl[2]=3
	pl[14]=7
	palettes[1]=pl
	local pl = {}
	pl[8]=10
	pl[2]=9
	pl[14]=7
	palettes[2]=pl
	local pl = {}
	pl[8]=12
	pl[2]=1
	pl[14]=7
	palettes[3]=pl
	palettes[4]={}
	local pl = {}
	pl[8]=4
	pl[2]=9
	pl[14]=10
	palettes[5]=pl
end

function map_color(pal_idx,color)
	local palette = palettes[pal_idx]
	return palette[color] or color
end

function apply_pal(indx)
	pal()
	for k,v in pairs(palettes[indx]) do
		pal(k,v)
	end
end

allocated_particles=0
active_particles=0
particles={}

function alloc_part()
	if(active_particles==allocated_particles) allocated_particles+=1 add(particles,create_part())
	active_particles+=1
	return particles[active_particles]
end

function create_part()
	local part = {
		life=0,
		pos=make_vec2(),
		vel=make_vec2(),
		spark_palette=-1,
		color=7
	}
	return part
end

function make_spark_particle(pos,vel,palette)
	local part=alloc_part()
	part.life=120+rnd(300),
	part.pos:set(pos)
	part.vel:set(vel)
	part.spark_palette=palette
	part.color=8
end

function make_asteroid_particle(pos,vel)
	local part=alloc_part()
	part.life=300+rnd(900),
	part.pos:set(pos)
	part.vel:set(vel)
	part.spark_palette=-1
	part.large=0.425>rnd(1)
	if (part.large) part.life*=(0.5-rnd(0.45))
	color=13
	if (0.25>rnd(1)) then
		color=5
		if(0.5>rnd(1)) color=6
	end
	part.color=color
end

function update_particles()
	local i=1
	while i<=active_particles do
		local part=particles[i]
		part.life-=1
		if part.life >= 0 then
			local vel=part.vel
			part.pos:add(vel)
			vel:scale(1+sqrt(vel:dot(vel))*(-0.035))
			i+=1
		else
			particles[i]=particles[active_particles]
			particles[active_particles]=part
			active_particles-=1
		end
	end
end

function part_vs_col(part,col)
		local radius=get_radius(col)
		local dp=get_cached_vec2(1)
		dp:set(col.pos):sub(part.pos)
		distsq = dp:dot(dp)
		if (distsq> radius*radius) return	
		local dv=get_cached_vec2(2)
		dv:set(col.vel):sub(part.vel)
		local vel_p=dp:dot(dv)
		if (vel_p>=0) return
		dp:scale(vel_p/distsq)
		part.vel:set(col.vel):add(dp)
end

local part_exp_str_mod=0.22
function part_vs_exp(part,exp)
	local radius=exp.radius
	local dp=get_cached_vec2(1)
	dp:set(part.pos):sub(exp.pos)
	distsq = dp:dot(dp)
	if (distsq>radius*radius) return		
	local exp_vel=part_exp_str_mod*explode_strength(exp)
	dp:scale(exp_vel/sqrt(distsq))
	part.vel:add(dp)
end

local frame=0
function process_particles()
	frame+=1
	local frame_mod=frame%3	--Particle collision are done at half tick rate
	for index=1,active_particles do
		if (frame_mod==(index%3)) then
			local part=particles[index]
			local ix,iy=grid_coords(part.pos)
			local cellid=hash_cell(ix,iy)
			local colliders=col_sp_hash[cellid]
			if colliders then
				for k,i in pairs(colliders) do
					local col=col_hash_id[i]
					part_vs_col(part,col)
				end
			end
			local expls=exp_sp_hash[cellid]
			if expls then
				for k,i in pairs(expls) do
					local exp=exp_hash_id[i]
					part_vs_exp(part,exp)
				end
			end
		end
	end
end

function draw_pixel(x,y,color)
	local x=flr(x+0.5)
	if (x<0 or x>=128) return
	local y=flr(y+0.5)
	if (y<0 or y>=128) return
	local xdiv=flr(x/2)
	local xmod=x%2
	color=(1+15*xmod)*color
	local addr=xdiv+(y*64)
	poke(0x6000+addr,color)
end

function draw_large_pixel(x,y,color)
	local x=flr(x+0.25)
	if (x<0 or x>=127) return
	local y=flr(y+0.25)
	if (y<0 or y>=127) return
	local xdiv=flr(x/2)
	color=17*color
	local addr=xdiv+(y*64)
	poke(0x6000+addr,color)
	y+=1
	addr=xdiv+(y*64)
	poke(0x6000+addr,color)
end

function get_spark_base_color()
	local base_color = 8
	local color_die=rnd(1)
	if (color_die<0.19) then
		base_color=14
	elseif (color_die<0.3) then
		base_color=2
	end
	return base_color
end

function draw_particles()
	for i=1,active_particles do
		local part = particles[i]
		if (part.spark_palette > 0) then
			if (0.825>rnd(1)) then
				local base_color = get_spark_base_color()
				local color = map_color(part.spark_palette,base_color)
				if (0.175>rnd(1)) then
					draw_large_pixel(part.pos.x,part.pos.y,color)
				else
					draw_pixel(part.pos.x,part.pos.y,color)
				end
			end
		else
			if (part.large) then
				if (0.5>=rnd(1))draw_large_pixel(part.pos.x,part.pos.y,part.color)
			else
				draw_pixel(part.pos.x,part.pos.y,part.color)
			end
		end
	end
end
__gfx__
000000000667000005dd00000d66000000dd660000d6660000000666dd6600000060000000000000000000000000000000000000000000000000000000000000
00000000d8ee70005dd60000d5ddd6000ddddd600ddddd600000ddd5dddd600005d5000000000000000000000000000000000000000000000000000000000000
00700700d88e6000d5d600006dd5d600dd6dddd6ddd6ddd60066ddddddddd6006d8d600000000000000000000000000000000000000000000000000000000000
00077000588860000d6000005dddd000d5d6d5565d5d5dd605dddddddddddd6005d5000000000000000000000000000000000000000000000000000000000000
0007700005dd00000000000005d60000dd5dd65d5dd5ddd60dddddddddddddd60060000000000000000000000000000000000000000000000000000000000000
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
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000dd6600000000000000000000000000000000000000000001
1000000000000000000000000000000000000000000000000000000000000000000000000000000ddddd60000000000000000000000000000000000000000001
100000000000000000000000000000000000000000000000000000000000000000000000000000dd6dddd6000000000000000000000000000000000000000001
100000000000000000000000000000000000000000000000000000000000000000000000000000d5d6d556000000000000000000000000000000000000000001
100000000000000000000000000000000000000000000000000000000000000000000000000000dd5dd65d000000000000000000000000000000000000000001
1000000000000000000000000000000000000000000000000000000000000000000000000000005ddddddd000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000005dd66dd000000000000000000000000000000000000000001
100000000000000000000000000000000000000000000000000000000000000000000000000000005d5600000000000000000000000000000000000000000001
10000000000000000000000000000000000000dd6600000000000000000000000000000000000000000000000000000000000000000000000000000000000001
1000000000000000000000000000000000000ddddd60000000000000000000000000000000000000000000000000000000000000000000000000000000000001
100000000000000000000000000000000000dd6dddd6000000000000000000000000000000000000000000000000000000000000000000000000000000000001
100000000000000000000000000000000000d5d6d556000000000000000000000000000000000000000000000000000000000000000000000000000000000001
100000000000000000000000000000000000dd5dd65d000000000000000000000000000000000000000000000000000000000000000000000000000000000001
1000000000000000000000000000000000005ddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000005dd66dd000000000000000000000000000000000000000000000000000000000000000000000000000000000001
100000000000000000000000000000000000005d5600000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000055ddd600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
1000000000000000000000000005dd66d60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000dddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
100000000000000000000000005dd5dd660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
100000000000000000000000000dd5dd500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000660000000000000000000055ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10005d56000000000000000000000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
100005dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
100000000d6600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000d5ddd6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
100000006dd5d6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
100000005dddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
1000000005d6000000000000000000000000000000000000000000000000000000000000000000000d6600000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000d5ddd6000000000000000000000000000000000000000001
100000000000000000000000000000000000000000000000000000000000000d66600000000000006dd5d6000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000ddddd60000000000005dddd0000000000000000000000000000000000000000001
1000000000000000000000000000000000000000000000000000000000000ddd6ddd60000000000005d600000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000005d5d5dd600000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000005dd5ddd600000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000005ddddd500000000000000000000000000000000bbb6000000000000000000000001
100000000000000000000000000000000000000000000000000000000000005ddd600000000000000000000000000000000bbbbb600000000000000000000001
100000000000000000000000000000000000000000000000000000000000000555000000000000000000000000000000000bbbbbd00000000000000000000001
1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbb000000000000000000000001
100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbb000bbb0000000000000000000000001
100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbb00000000000000000000000000000000001
100000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbb00000000000000000000000000000000000001
100000000000000000000000000000000000000000000000000000000000000000000000000000000000bbb00000000000000000000000000000000000000001
100000000000000000000000000000000000000000000000000000000000000000000000000000000bbb000000000000000000000000000d6660000000000001
10000660000000000000000000000000000000000000000000000000000000000000000000000bbbb00000000000000000000000000000ddddd6000000000001
1000d8e6000000000000000000000000000000000000000000000000000000000000000000bbb00000000000000000000000000000000ddd6ddd600000000001
1000d886000000000000000000000000000000000000000000000000000000000000000bbb000000000000000000000660000000000005d5d5dd600000000001
10000dd000006ddd0000000000000000000000000000000000000000000000000000bbb000000000000000000000005d56000000000005dd5ddd600000000001
10000000665ddddd600000000000000000000000000000000000000000000000bbbb0000000000000000000000000005dd000000000005ddddd5000660000001
10000005ddddddddd60000000000000000000000000000000000000000000bbb00000000000000000000000000000000500000000000005ddd6000dc76000001
10000005dddddddddd60000000000000000000000aaaaa000000000000bbb000000000000000000000000000000000000000000000000005550000dcc6000001
100000ddddd6ddd5dd6000000000000000000000aaaaaaa00000000bbb0000000000000000000000000000000000000000000000000000000000000dd0000001
100005dddd5d6ddd5dd60000000000000000000aaaaaaaaa000bbbb00000000000000000000000000000000000000000000000000000000000000b0000000001
10000dd6ddd5dddddddd000000000000000000aaaaaaaaaaabb000b0000000000000000000000000000000000000000000000000000000000000000000000001
10000d5d6ddddddddddd00000000000000000aaaaaaaaaaaaa0000000000000000000000000000000000d6000000000000000000000000000000000000000001
100005dd6ddddddddddd60000000000000000aaaaaaaaaaaaa000000000000000000000000000000000ddd600000000000000000000000000000000000000001
1000005dd6dddddddddd60000000000000000aaaaaaaaaaaaa00000000000000000000000000000000555dd00000000000000000000000000000000000000001
1000005d5dddd56ddddd000000000660000bbaaaaaaaaaaaaa0000000b0000000000000000000000005dd6000000000000000000000000000000000000000001
1000005ddddd5dd6dd5500000000dba6bbb00aaaaaaaaaaaaa000000000000000000000000000000000560000000000000000000000000000000000000000001
1000005dddddd5d5dd5000000000dbb6000000aaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000001
10000005dddddd5dddd0000000000dd00000000aaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000001
100000005ddddddddd0000000000000000000000aaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000001
1000000000055dd60000000000000000000000000aaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
100000000000000000000000000000000000000000000b0000000000b00000000000000000000000000000000000000000000000000000660000000000000001
1000000000000000000000000000000000000000000000000000000000000000000005dd0000000b000000000000000000000000000055ddd600000000000001
100000000000000000000000000000000000000000000000000000000000000000005dd60000000000000000000000000000000000005dd66d60000000000001
1000000000000000000000000000000000000000000000000000000000005dd00000d5d60bb000000b0000000000000000000000000dddddddd0000000000001
100000000000000000000000000000000000000000000000000000000005dd6000000d60000000000000000000000000000000000005dd5dd660000000000001
10000000000000000000000000000000000000000000000000000000000d5d60000000000b0000b00000000000000000000000000000dd5dd500000000000001
100000000000000000000000000000000000000000000000000000000000d600000003bb00000000000000000000000000000000000055ddd000000000000001
1000000000000000000000000000000000000000000000000000000000000000000000b000000000000000000000000000000000000000550000000000000001
100000000000000000000000000000000000000000000000000000000000000006ddbb0000000000000000000000000000000000000000000000000000000001
1000000000000000000000000000000000000000000000000000000000000665ddddd60000000000000000000000000000000000000000000000000000000001
1000000000000000000000000000000000000000000000000000000000005ddddddddd6000000000000000000000000000000000000000000000000000000001
1000000000000000000000000000000000000000000000000000000000005dddddddddd600000000000000000000000000000000000000000000000000000001
10000000000000000000000000000000000000000000000000000000000ddddd6ddd5dd600000000000000000000000000000000000000000000000000000001
100000000000000000000000000000000000000005dd000000000000005dddd5d6ddd5dd60000000000000000000000000000000000000000000000000000001
1000000000000000000000000d666000000000005dd600000000000000dd6ddd5dddddddd0000000000000000000000000000000000000000000000000000001
100000000000000000000000ddddd60000000000d5d600000000000000d5d6ddddddddddd0000000000000000000000000000000000000000000000000000001
10000000000000000000000ddd6ddd60000000000d60000000000000005dd6ddddddddddd6000000000000000000000000000000000000000000000000000001
100000000000000000000005d5d5dd600000000000000000000000000005dd6dddddddddd6000000000000000000000000000000000000000000000000000001
100000000000000000000005dd5ddd600000000000000000000000000005d5dddd56ddddd0000000000000000000000000000000000000000000000000000001
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__sfx__
000100000f5701157013570175601d5502253025520285202a5202d52031510355103652000000000000000000000015000150000500015000450006500005000050000500005000050000500005000050000500
0011000003730007200071000700007001d7001d7001a70018700127000c7000b7000c7000c7000d700107001170014700127000f7000f7000f7000f7000f7000f7000f7000f7000f7000f7000f7000f70011700
001400000331005300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
