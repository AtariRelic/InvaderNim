#import required libraries
import nico

#initial procedure declaration
proc gameInit() =
    echo "init"

proc gameUpdate(dt: float32) = 
    echo "update: ", dt

proc gameDraw() =
    cls()
    setColor(7)
    print("hello world", 42, 60)

#library initialization
nico.init("nico","test")

nico.createWindow("nico", 128, 128, 4)

nico.run(gameInit, gameUpdate, gameDraw)