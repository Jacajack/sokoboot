# sokoboot
Sokoboot is a Sokoban type game bootable from floppy, written compeletly in i386 assembly.

I develop Sokoboot in my free time, just for fun. Surprisingly, I managed to develop it into a rather functional game, but there are still tons of things to improve.<br>
**Any suggestions and contributions are welcome, especially ones according graphical design.** :heart:

<br><img src=https://media.giphy.com/media/3oKIPec4ADPFjKOIHS/giphy.gif></img><br>
*I know these sprites are ugly.*


### How do I build Sokoboot?
 - Firstly, install necessary packages - `sudo apt-get install moreutils nasm python`
 - And then the Python packages - `sudo pip install Image` (sometimes `sudo pip install --upgrade pip` may be neccessary before)
 - Then, you need to build the level builder - `make -C mklvl`
 - After that you should be able to run `make` without any errors

Alternatively, you can download `sokoboot.img` already built by Travis. Go to Sokoboot's [Travis site](https://travis-ci.org/Jacajack/sokoboot), scroll to the bottom of the build log and you should see something like this:
<br><img src=http://i.imgur.com/RwOB1UT.png></img><br>
The address (in this case, from line 656) should lead you to proper download.

### How do I run Sokoboot?
 - If you've got Linux - just write `img` file to floppy disk using `dd` command.
 - If you've got Windows - use a cool piece of software called [rawwrite](http://www.chrysocome.net/rawwrite) 
 - If you don't want to waste floppy disk, you can use `make run` in order to launch game in Qemu emulator.
  
