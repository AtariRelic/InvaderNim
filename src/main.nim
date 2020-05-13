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

var
    bulletTimer = 0
    bullets: seq[Bullet]
    enemies: seq[Enemy]
    gems: seq[Gem]
    gameOver: bool
    levelComplete: bool
    gameStart: bool
    lives = 3
    cy: float
    enemyTimer: int
    gameStartTimer: int
    levelCompleteTimer: int
    score = 0
    scoreThreshold: int
    levelsCleared = 0
    enemyVelocity = -0.5 + (0.1 * float(levelsCleared))

#game initialization procedure
proc gameInit() =
    setPalette(loadPaletteFromGPL("cga.gpl"))
    loadSpriteSheet(0, "spritesheet.png")
    bullets = newSeq[Bullet]()
    enemies = newSeq[Enemy]()
    gems = newSeq[Gem]()
    gameStart = true
    gameOver = false
    levelComplete = false
    enemyTimer = 60 * 3
    levelCompleteTimer = 60 * 5
    x = 64.0
    y = 96.0
    xv = 0.0
    yv = 0.0
    bulletTimer = 0
    gameStartTimer = 60 * 5
    score = 0
    frame = 0
    cy = 0.0
    scoreThreshold = 2_000 * (levelsCleared + 1)

proc distance(ax, ay, bx, by: float): float =
    return sqrt(pow(ax - bx, 2) + pow(ay - by, 2))

#game updates/inputs
proc gameUpdate(dt: float32) = 

    if gameStart:
        gameStartTimer -= 1
        if gameStartTimer == 0:
            gameStart = false

    frame += 1

    if lives == 0:
        gameOver = true

    # player movement
    if not gameOver and not levelComplete:
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
        levelsCleared = 0
        lives = 3
        return

    x += xv
    y += yv


    #window boundaries
    if x < 8:
        x = 8
    if x > 120:
        x = 120
    if y < cy + 8 and not levelComplete:
        y = cy + 8
    if y > cy + 120 and not gameStart:
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

        #enemy bullet collision
        if bullet.enemy and not levelComplete:
            let distance = distance(x, y, bullet.x, bullet.y)
            if distance < 8:
                bullet.shouldBeDestroyed = true
                lives -= 1
                if lives <= 0:
                    lives = 0
    
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
        if distance < 8 and not gameOver:
            gem.shouldBeDestroyed = true
            score += 100

    # move enemies
    for enemy in mitems(enemies):
        enemy.y += enemy.yv
        enemy.x += enemy.xv

        if enemy.y > cy + 150 and not levelComplete:
            enemy.shouldBeDestroyed = true
            lives -= 1

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
            enemy.bulletTimer = rnd(6, 120)
            bullets.add(Bullet(x: enemy.x, y: enemy.y + 8, xv: 0.0, yv: 1.0, enemy: true))
    
    enemies.keepIf() do(a: Enemy) -> bool:
        a.shouldBeDestroyed == false

    bullets.keepIf() do(a: Bullet) -> bool:
        a.shouldBeDestroyed == false
    
    gems.keepIf() do(a: Gem) -> bool:
        a.shouldBeDestroyed == false

    #spawn enemies
    if not gameStart:
        enemyTimer -= 1
        if enemyTimer == 0 and not gameOver:
            enemyTimer = 60 + rnd(120)
            enemies.add(Enemy(x: rnd(8.0, 120.0), y: cy - 8.0, xv: 0.0, yv: enemyVelocity, bulletTimer: 60 + rnd(60)))
        elif enemyTimer == 0 and gameOver and not gameStart:
            enemyTimer = 30
            enemies.add(Enemy(x: rnd(8.0, 120.0), y: cy - 8.0, xv: 0.0, yv: enemyVelocity, bulletTimer: 60 + rnd(60)))
        elif levelComplete == true:
            enemyTimer = 0

        if score >= scoreThreshold:
            levelComplete = true


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

    if not gameOver:

    #prints score
        setColor(3)
        print("SCORE: ", 1, cy + 2)
        print($score, 25, cy + 2)

    #prints current level
        print("LEVEL: ", 80, cy + 2)
        print($(levelsCleared + 1), 105, cy + 2)

    #prints lives
        spr(6, 98, cy + 117, 2, 2)
        print(" X ", 110, cy + 120)
        print($lives, 120, cy + 120)

    #prints GAME/LEVEL START message
    if gameStart and levelsCleared == 0:
        setColor(15)
        print("INVADER NIM HAS COME", 22, cy + 60)
        print("TO CONQUER EARTH!", 28, cy + 70)
        print("STOP INVADER NIM!", 28, cy + 80)
    elif gameStart and levelsCleared > 0:
        setColor(rnd([14,10,15]))
        print("LEVEL ", 50, cy + 65)
        print($(levelsCleared + 1), 75, cy + 65)

    #prints LEVEL COMPLETE message
    if levelComplete and levelCompleteTimer > 0:
        setColor(rnd([14,10,15]))
        print("LEVEL COMPLETE!", 35, cy + 60)
        levelCompleteTimer -= 1
        if levelCompleteTimer == 0:
            levelsCleared += 1
            gameInit()

    #draws player ship
    if not gameOver and not gameStart:
        spr(0, x - 8, y - 8, 2, 2)

    #prints GAME OVER message
    if gameOver:
        setColor(15)
        print("GAME OVER", 45, cy + 65)
        print("PRESS C TO RESTART", 28, cy + 75)

#initialization
nico.init("nico","test")

#creates the game screen
nico.createWindow("InvaderNim", 128, 128, 4)


#determines font
loadFont(0, "font.png")
setFont(0)

#runs the game
nico.run(gameInit, gameUpdate, gameDraw)