# sokoboot
[![The GPL license](https://img.shields.io/badge/license-GPL-blue.svg?style=flat-square)](http://opensource.org/licenses/GPL-3.0)
[![Travis CI](https://img.shields.io/travis/Jacajack/sokoboot/master.svg?style=flat-square)](https://travis-ci.org/Jacajack/sokoboot)
<br>Sokoboot is a Sokoban type game bootable from floppy, written completely in i386 assembly (don't mind the 12% of C - it's only the level creator).

I develop Sokoboot in my free time, just for fun. Surprisingly, I managed to develop it into a rather functional game, but there are still tons of things to improve.<br>
**Any suggestions and contributions are welcome, especially those according graphical design.** :eyes:

<br><img src=resources/demo.gif></img><br>
*I know these sprites are ugly.*


### How to build Sokoboot?
 - Firstly, install necessary packages - `sudo apt-get install moreutils nasm python`
 - And then the Python packages - `sudo pip install Image` (sometimes `sudo pip install --upgrade pip` may be necessary beforehand)
 - Then, you need to build the level builder - `make -C mklvl`
 - After that you should be able to run `make` without any errors

Alternatively, you can download `sokoboot.img` already built by Travis. Go to Sokoboot's [Travis site](https://travis-ci.org/Jacajack/sokoboot), scroll to the bottom of the build log and you should see something like this:
<br><img src=http://i.imgur.com/RwOB1UT.png></img><br>
The address (in this case, from line 656) should lead you to proper download.

### How to run Sokoboot?
 - If you've got Linux - just write `img` file to floppy disk using `dd` command.
 - If you've got Windows - use a cool piece of software called [rawwrite](http://www.chrysocome.net/rawwrite) 
 - If you don't want to waste floppy disk, you can use `make run` in order to launch game in Qemu emulator.
 

### How to play?
 - At the very beginning the game will display a splash screen - you can dismiss by pressing any key
 - When you are prompted to enter level location on the disk, you have to enter number of sector (LBA) where level is located. On the game disk level data usually starts at 342 or 324 (depending on your game version). On disks which contain only levels, first level will likely start at sector 0.
 - If you've done everything right, game should start - default keybindings are:
 - - <kbd>W</kbd> <kbd>A</kbd> <kbd>S</kbd> <kbd>D</kbd> or arrows - player movement
 - - <kbd>I</kbd> <kbd>J</kbd> <kbd>K</kbd> <kbd>L</kbd> - camera movement (free mode)
 - - <kbd>Q</kbd> - make camera follow player again
 - - <kbd>Esc</kbd> - abandon game
 - Have fun!

