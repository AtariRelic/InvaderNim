#import required libraries
import nico
import sequtils
import math

#variable  declaration
var frame = 0

var
    x = 64.0    #player x position
    xv = 0.0    #player x velocity
    y = 64.0    #player y position
    yv = 0.0    #player y velocity
    bulletTimer = 0
    score = 0

type Bullet = object
    x,y: float
    xv,yv: float
    shouldBeDestroyed: bool
    enemy: bool

type Enemy = object
    x,y: float
    xv,yv: float
    bulletTimer: int
    shouldBeDestroyed: bool

type Gem = object
    x,y: float
    xv,yv: float
    shouldBeDestroyed: bool
    ttl: int

var bullets: seq[Bullet]
var enemies: seq[Enemy]
var gems: seq[Gem]
var gameOver: bool
var cy: float

var enemyTimer: int

#game initialization procedure
proc gameInit() =
    setPalette(loadPaletteFromGPL("cga.gpl"))
    loadSpriteSheet(0, "spritesheet.png")
    bullets = newSeq[Bullet]()
    enemies = newSeq[Enemy]()
    gems = newSeq[Gem]()
    gameOver = false
    enemyTimer = 180
    x = 64.0
    y = 96.0
    xv = 0.0
    yv = 0.0
    bulletTimer = 0
    score = 0
    frame = 0
    cy = 0.0

proc distance(ax, ay, bx, by: float): float =
    return sqrt(pow(ax - bx, 2) + pow(ay - by, 2))

#game updates/inputs
proc gameUpdate(dt: float32) = 

    frame += 1

    # player movement
    if not gameOver:
        if btn(pcLeft):
            xv -= 0.1
        if btn(pcRight):
            xv += 0.1
        if btn(pcUp):
            yv -= 0.1
        if btn(pcDown):
            yv += 0.1
    
    # binds shoot to 'Z'
    if bulletTimer > 0:
        bulletTimer -= 1

    if btn(pcA) and bulletTimer == 0 and not gameOver:
        bullets.add(Bullet(x: x, y: y, xv: 0.0, yv: -4.0))
        bulletTimer = 30

    if btnp(pcY) and gameOver:
        gameInit()
        return

    x += xv
    y += yv


    #window boundaries
    if x < 8:
        x = 8
    if x > 120:
        x = 120
    if y < cy + 8:
        y = cy + 8
    if y > cy + 120:
        y = cy + 120

    #deacceleration
    xv *= 0.97  #reduces xv to slow movement if no input
    yv *= 0.97  #reduces yv to slow movement if no input

    cy -= 1.0
    y -= 1.0

    #move bullets
    for bullet in mitems(bullets):
        bullet.y += bullet.yv
        bullet.x += bullet.xv

        if bullet.y < cy:
            bullet.shouldBeDestroyed = true

        if bullet.enemy:
            let distance = distance(x, y, bullet.x, bullet.y)
            if distance < 8:
                bullet.shouldBeDestroyed = true
                gameOver = true
    
     #move gems
    for gem in mitems(gems):
        gem.y += gem.yv
        gem.x += gem.xv

        gem.xv *= 0.98
        gem.yv *= 0.98

        if gem.y < cy:
            gem.shouldBeDestroyed = true

        gem.ttl -= 1
        if gem.ttl <= 0:
            gem.shouldBeDestroyed = true

        let distance = distance(x, y, gem.x, gem.y)
        if distance < 8:
            gem.shouldBeDestroyed = true
            score += 100

    # move enemies
    for enemy in mitems(enemies):
        enemy.y += enemy.yv
        enemy.x += enemy.xv

        if enemy.y > cy + 150:
            enemy.shouldBeDestroyed = true

        # bullet collision
        for bullet in mitems(bullets):
            if bullet.enemy == false:
                let distance = distance(bullet.x, bullet.y, enemy.x, enemy.y)
                if distance < 8:
                    # enemy hit by bullet
                    enemy.shouldBeDestroyed = true
                    bullet.shouldBeDestroyed = true
                    for i in 0..5:
                        gems.add(Gem(x: enemy.x, y: enemy.y, xv: rnd(2.0) - 1.0, yv: rnd(2.0) - 1.0, ttl: 60 * 5))
                    break

        # enemy shooting
        enemy.bulletTimer -= 1
        if enemy.bulletTimer <= 0:
            enemy.bulletTimer = rnd(60, 180)
            bullets.add(Bullet(x: enemy.x, y: enemy.y + 8, xv: 0.0, yv: 1.0, enemy: true))
    
    enemies.keepIf() do(a: Enemy) -> bool:
        a.shouldBeDestroyed == false

    bullets.keepIf() do(a: Bullet) -> bool:
        a.shouldBeDestroyed == false
    
    gems.keepIf() do(a: Gem) -> bool:
        a.shouldBeDestroyed == false

    #spawn enemies
    enemyTimer -= 1
    if enemyTimer == 0 and not gameOver:
        enemyTimer = 60 + rnd(120)
        enemies.add(Enemy(x: rnd(8.0, 120.0), y: cy - 8.0, xv: 0.0, yv: -0.5, bulletTimer: 60 + rnd(60)))
    elif enemyTimer == 0 and gameOver:
        enemyTimer = 30
        enemies.add(Enemy(x: rnd(8.0, 120.0), y: cy - 8.0, xv: 0.0, yv: -0.5, bulletTimer: 60 + rnd(60)))


#the animation loop
proc gameDraw() =
    #clears the screen
    cls()

    setCamera(0, cy)

    #draw enemies
    for enemy in enemies:
        spr(2, enemy.x - 8, enemy.y - 8, 2, 2)

    #draw gems
    for gem in gems:
        spr(4, gem.x - 8, gem.y - 8, 1, 1)

    #draw bullets
    for bullet in bullets:
        if bullet.enemy:
            setColor(if frame mod 10 < 5: 3 else: 4)
            circfill(bullet.x, bullet.y, 1)
        else:
            spr(5, bullet.x - 4, bullet.y, 1, 1)

    setColor(3)
    print("SCORE: ", 1, cy + 2)
    print($score, 25, cy + 2)

    #draws the player ship
    if not gameOver:
        spr(0, x - 8, y - 8, 2, 2)

    if gameOver:
        setColor(rnd([14,10,15]))
        print("GAME OVER", 42, cy + 60)
        print("PRESS C TO RESTART", 25, cy + 70)

#initialization
nico.init("nico","test")

#creates the game screen
nico.createWindow("InvaderNim", 128, 128, 4)


#determines font
loadFont(0, "font.png")
setFont(0)

#runs the game
nico.run(gameInit, gameUpdate, gameDraw)