pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
function _init()
 init_dog()
end

function _update60()
 if (btnp(❎)) dog_bark()
	local dir_x=0
	local dir_y=0
 if (btn(⬅️)) dir_x=-1
 if (btn(➡️)) dir_x=1
 if (btn(⬆️)) dir_y=-1
 if (btn(⬇️)) dir_y=1
 local norm=dir_x*dir_x+dir_y*dir_y
 if (norm==0) then
  dog_idle()
  return
 end
 dog_run()
 norm=1/(60*sqrt(norm))
 dir_x=dir_x*dog.speed*norm
 dir_y=dir_y*dog.speed*norm
 dog.dx=dir_x
 dog.dy=dir_y
 dog.x+=dir_x
 dog.y+=dir_y
end

function _draw()
 cls(1)
 camera()
 map()
 spr(dog.sprite
 ,dog.x,dog.y
 ,1,1
 ,dog.dx<0)
end
-->8
--doggy

dog={}

function init_dog()
 dog = {}
 dog.speed=40
 dog.x=0
 dog.y=0
 dog.dx=0
 dog.dy=0
 dog.anim=0
 dog.sprite=1
end

function dog_idle()
 dog.anim=0
 dog.sprite=1
end

function dog_run()
 dog.anim+=1
 if (dog.anim%10==0) sfx(0)
 dog.anim%=20
 dog.sprite=1+dog.anim/10
end

function dog_bark()
 sfx(1)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000004040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000404000005450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000054500000444e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000400444e04444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700044444400444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000044440804000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000040040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbb8bbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbb8a8bbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbb8bbbbbbbabbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbabbbbb5bbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbabbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbb3bbbbabbabbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbb3b3bbbbbbbbbbbbbbbabb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbabbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b3b3b3bbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb3b3bbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbabbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2220202020202020202022202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020303020202120202030202030302000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020302000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020212032202020202021202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202023202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020302020202020303120202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020222020312320202020312020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2030202020323020202020212020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202021202020203020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2120202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020203320202020202030202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2320222020202232312120202022202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202021202023202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020222320202021202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2021202020202020302020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000d0100e0300f0401003011010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
51010000155101a5301c5501e560205601a5500c51000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
