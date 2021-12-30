pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
function _init()
 init_dog(0)
 init_dog(1)
end

function _update60()
 for dog in all(dogs) do
  if (btnp(🅾️,dog.player)) dog_jump(dog)
  if dog.dh!=0 or dog.h!=0 then
   dog.h+=(dog.dh/60)
   dog.dh-=100/60
   if dog.dh>0 then
    dog.sprite=3+dog.player*16
   else
    dog.sprite=4+dog.player*16
   end
  end
  if (dog.h<0) then
   dog.h=0
   dog.dh=0
  end
 
  if (btnp(❎,dog.player)) dog_bark(dog)
	 local dir_x=0
	 local dir_y=0
  if (btn(⬅️,dog.player)) dir_x=-1
  if (btn(➡️,dog.player)) dir_x=1
  if (btn(⬆️,dog.player)) dir_y=-1
  if (btn(⬇️,dog.player)) dir_y=1
  local norm=dir_x*dir_x+dir_y*dir_y
  if (norm==0) then
   dog_idle(dog)
   goto continue
  end
  dog_run(dog)
  norm=1/(60*sqrt(norm))
  dir_x=dir_x*dog.speed*norm
  dir_y=dir_y*dog.speed*norm
  dog.dx=dir_x
  dog.dy=dir_y
  dog.x+=dir_x
  dog.y+=dir_y
  if (dog.x<0) dog.x=0
  if (dog.y<0) dog.y=0
  if (dog.x>15*8) dog.x=15*8
  if (dog.y>15*8) dog.y=15*8
  ::continue::
 end
end

function _draw()
 cls(1)
 camera()
 map()
 for dog in all(dogs) do
  spr(dog.sprite
   ,dog.x,dog.y-dog.h
   ,1,1
   ,dog.dx<0)
 end
end
-->8
--doggy

dogs={}

function init_dog(player)
 local dog = {}
 dog.speed=40
 dog.x=player*15*8
 dog.y=player*15*8
 dog.h=0
 dog.dh=0
 dog.dx=0
 dog.dy=0
 dog.anim=0
 dog.sprite=1+player*16
 dog.player=player
 add(dogs,dog)
end

function dog_jump(dog)
 if (dog.h!=0) return
 sfx(2)
 dog.dh=50
end

function dog_idle(dog)
 dog.anim=0
 if (dog.h!=0) return
 dog.sprite=1+dog.player*16
end

function dog_run(dog)
 if (dog.h!=0) return
 dog.anim+=1
 if (dog.anim%10==0) sfx(0)
 dog.anim%=20
 dog.sprite=1+dog.anim/10+dog.player*16
end

function dog_bark(dog)
 sfx(1)
end
__gfx__
000000000000000000000000000000000000d0d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000d0d000000d0d00000cdc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000d0d00000cdc000000cdc00d00ddde0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000cdc00000ddde00000ddde0dddd44d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000d00ddde0dddd44d00d00d48d044444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000ddd44d00444400000ddd440040004400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000044440804000040000444044440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000040040000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
51000000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4c0000000000000000010100000010100000a1a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e400000000010100000a1a000000a1a00c0011140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88000000000a1a00000111400000111401111ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ca000000c0011140c111ccc00c001c8c011ccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000001111cc0011cc00000111cc001000cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000011cc00010000c000011c0cc110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000100c0000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbb8bbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbb8a8bbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbb8bbbbbbbabbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbabbbbb5bbbbbbbb1111bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbabbbbbbbbbbbb0bb0bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbb3bbbbabbabbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbb3b3bbbbbbbbbbbbbbbabb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbabbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b3b3b3bbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb3b3bbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbabbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00009b9099909b900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099988099999880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999990009999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09990900999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99009000009990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0099000000aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
4a0100000d0100e0300f0401003011010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50010000155101a5301c5501e560205601a5500c51000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000d0500d0500e0501005012050160502305025050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
