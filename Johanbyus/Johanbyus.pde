/*Este juego fue desarrollado para la clase de computación visual de la universidad nacional de 
 colombia por Johann triana
 *JOHANBYUS versión 0.01 un juego basado en la leyenda urbana Polybius.
 *Da uso de las librerias de Proscene para la interacción y optimización del juego y Minim para la 
 música 
 
 Modo de juego: Con el mouse se mueve la pantalla sobre el eje Z, es el único movimiento con el que 
 se dispone para acabar con lsos asteroides que nacen de la nave matriz del centro, con la tecla 
 'SPACE' se disparan los misiles que destruiran a los asteroides. Posees de 500 de armadura para 
 llegar lo más lejos posible en el juego pero ¡CUIDADO! no todos los asteroides hacen el mismo daño, 
 no dejes que toquen a tu nave aprovechando el movimiento de la pantalla.
 
 El juego termina sólo hasta que tu armadura llege a 0, cada nivel tendrá una mayor dificultad, ten 
 cuidado con los efectos alarmantes que exigen una mayor concentración y no juegues durante mucho 
 tiempo.
 
 Teclas Extra: 
 *'m' activa y desactiva la música de fondo.
 *'1' Sube un nivel la dificultad.
 *'2' Baja un nivel la dificultad.
 *'3' Te da 500 de armadura extra y reanuda el juego cuando este se ha perdido.
 
 ---------------
 Próximas versiones:
 Música: Aunque actualmente la música no es original en una versión futura se pretende crear música 
 original o usar música libre de derechos.
 Código: Mejorar la arquitectura en el codigo y documentar adecuadamente. Esta versión inicial presenta la 
 propuesta básica para concluir el curso de Computación visual de la Universidad Nacional de 
 Colombia.
 
 ---------------
 Experiencia:
 ¡Con la introducción de la librería proScene pude realizar el primer juego en la carrera y justo a 
 tiempo para el grado! Me voy con la satisfacción de que programe un juego aprovechando las clases y 
 librerías que nos ha ofrecido computación visual y llevandome una buena experiencia con Processing 
 para adecuarlo a los diferentes proyectos que aparezcan de ahora en adelante.
 ¡Nos vemos en una próxima entrega!
 */

import java.util.ArrayList;

import ddf.minim.AudioPlayer;
import ddf.minim.Minim;
import processing.core.PApplet;
import processing.core.PShape;
import remixlab.dandelion.geom.Vec;
import remixlab.proscene.InteractiveFrame;
import remixlab.proscene.Scene;


//Los shaders para la iluminación, el primero crea la iluminación apartir del centr y el segundo es un shader de texturas para recuperar la forma de las letras
PShader textShader, lightShader;

PShader none;
Minim minim;
AudioPlayer player, explosion, gameOver, shoot, hit, regame;

/**
 * Entero para determinar la posición de los disparos, booleando para
 * comprobar si se encuentra actualmente disparando
 */
int shootCount = 0;
boolean shooting;

/**
 * Dadas las constantes calculadas la variable Pantalla debe manternerse en
 * 600
 */
public static final int PANTALLA = 600;

/**
 * Constantes KANGLE Y KDESFASE se usan para ubicar el segundo
 * InteractiveFrame para la parte de la nave
 */
public static final float KANGLE = 1.2990408676091881737917494594727f;
public static final float BULLETSPEED = PANTALLA / 90;
public static final float KDESFASE = 69.2820282f;

Scene scene;

/**
 * Instancia de Shapes
 */
public static ArrayList<PShape> asteroids = new ArrayList<PShape>();
public static PShape icosaedro;
public static PShape octaedro;
public static PShape evilShip;
public static ArrayList<PShape> ship = new ArrayList<PShape>();

/**
 * Banderas
 */
boolean octaedroActivo = false;
boolean pressed;
boolean icosaedroActivo = false;
boolean txtShader = true;

/**
 * Cuenta el tiempo de la partida
 */
public static int oleadaTiempo = 0;
public static int puntos = 0;
public static int level = 1;
public static int life = 500;

public void settings() {
  size(PANTALLA, PANTALLA, P3D);
}

public void setup() {
  asteroid();
  buildShapes();
  scene = new Scene(this);
  SceneWorld.init(scene);
  scene.showAll();
  scene.setGridVisualHint(false);
  scene.setAxesVisualHint(false);
  minim = new Minim(this);
  player = minim.loadFile("theme.mp3");
  player.play();
  explosion = minim.loadFile("explosion.wav");
  gameOver = minim.loadFile("gameover.wav");
  regame = minim.loadFile("regame.wav");
  lightShader = loadShader("textLightfrag.glsl", "textLightvert.glsl");
  textShader = loadShader("lightfrag.glsl", "lightvert.glsl");
}

public void draw() {
  //se carga el shader de iluminación pero esto provoca que las letras se deformen, por eso se usa un shader de texturas un tiempo después de generar la iluminación para recuperar las texturas
  shader(lightShader);
  // init ambiente
  background(0);
  fill(204, 102, 0, 150);

  if (life > 0) {
    // Control de la escena y la interacción
    oleadas();
    continuosPressed();
    scene.drawFrames();

    // trabajo fuera de escena que ambienta el juego
    animaciones();

    // espacio para el InteractiveFrame de la nave
    pushMatrix();
    scene.applyTransformation(scene.eyeFrame());
    pushMatrix();
    scene.applyTransformation(SceneWorld.shipScene);
    scene.drawAxes();
    popMatrix();
    popMatrix();

    pointLight(255, 255, 255, 0, 0, -30);



    impactShapes();

    // Control de los disparos
    if (shooting) {
      SceneWorld.bullet.translate(-BULLETSPEED, 0, 0);
      shootCount += BULLETSPEED;
      if (shootCount >= 240) {
        shootCount = 0;
        //pointLight(255, 255, 255, SceneWorld.shipScene.position().x(), SceneWorld.shipScene.position().y(), SceneWorld.shipScene.position().z());
        SceneWorld.bullet.setPosition(SceneWorld.shipScene.position());
        shooting = false;
      }
    }

    // Movimiento de escena para los objetos
    shapeMovement(SceneWorld.asteroids, SceneWorld.asteroidsVec);
    if (octaedroActivo) {
      shapeMovement(SceneWorld.octaedros, SceneWorld.octaedrosVec);
    }
    if (icosaedroActivo) {
      shapeMovement(SceneWorld.icosaedros, SceneWorld.icosaedroVec);
    }

    oleadaTiempo++;
    if (oleadaTiempo>30) { //<>//
      //acá se recuperan las texturas de las letras
      shader(textShader);
    }
    scene.beginScreenDrawing();

    pushStyle();
    fill(160, 0, 0);
    text("Armadura: " + String.format("%4d", life), 455, 560);
    fill(255, 255, 255);
    text("Puntos: " + String.format("%04d", puntos) + " " + "Nivel: " + String.format("%02d", level), 455, 580);
    popStyle();
    scene.endScreenDrawing();
  } else {
    shader(lightShader);
    scene.beginScreenDrawing();
    pushStyle();
    fill(160, 0, 0);
    textSize(72);
    text("GAME OVER", 100, 300);
    popStyle();
    scene.endScreenDrawing();
  }
}

/**
 *Metodo para cuando se pierde el juego
 */
public void gameOver() {
  if (player.isPlaying()) {
    player.pause();
  }
  if (!gameOver.isPlaying()) {
    gameOver.rewind();
    gameOver.play();
  }
}

/**
 * Define el movimiento de un grupo de InteractiveFrames segun un vector de
 * posición
 * 
 * @param figures
 * @param vecs
 */
public static void shapeMovement(InteractiveFrame figures[], Vec[] vecs) {
  int limit = figures.length;
  for (int i = 0; i < limit; i++) {
    if (vecs[i].x() < 160)
      figures[i].translate(vecs[i]);
  }
}

/**
 * Define de que manera se interactua con el ambiente
 */
private void animaciones() {
  if (puntos >= (level * 50)) {
    level += 1;
  }
  animacionesNivel(level);
}

public void animacionesNivel(int nivel) {
  switch (nivel) {
  case 1:

    break;
  case 2:
    lineas();
    break;
  case 3:
    circulos();
    break;
  case 4:
    cone();
    break;
  case 5:
    web();
    break;
  case 6:
    lineas();
    web();
    break;
  case 7:
    circulos();
    cone();
    lineas();
    break;
  case 8:
    circulos();
    cone();
    lineas();
    web();
    break;
  default:
    animacionesNivel((int) random(8));
    break;
  }
}

public void lineas() {
  scene.drawTorusSolenoid(100f);
}

public void circulos() {
  pushStyle();
  noFill();
  stroke(random(255), random(255), random(255));
  strokeWeight(5);
  // ellipse(0, 0, oleadaTiempo%450, oleadaTiempo%450);
  int period = oleadaTiempo % 100;
  ellipse(0, 0, period, period);
  ellipse(0, 0, period + 100, period + 100);
  ellipse(0, 0, period + 200, period + 200);
  ellipse(0, 0, period + 300, period + 300);
  popStyle();
}

public void cone() {
  pushStyle();
  noFill();
  stroke(0, 0, 255);
  strokeWeight(5);
  int period = oleadaTiempo / 2 % 150;
  scene.drawCone(period, period, -20);
  popStyle();
}

public void web() {
  pushStyle();
  noFill();
  stroke(0, random(255), 0, 122);
  strokeWeight(5);
  int period = oleadaTiempo % 50;
  scene.drawCylinder(period, period);
  scene.drawCylinder(period + 50, period + 50);
  scene.drawCylinder(period + 100, period + 100);
  popStyle();
}

/**
 * Ciclo para generar objetos
 */
public void oleadas() {
  if (oleadaTiempo % 550 == 0) {
    SceneWorld.asteroid(scene);
  }

  if ((oleadaTiempo % 500 == 0 && oleadaTiempo > 0)) {
    octaedroActivo = true;
    SceneWorld.octaedros(scene);
  }

  if ((oleadaTiempo % 600 == 0 && oleadaTiempo > 0)) {
    icosaedroActivo = true;
    SceneWorld.icosaedros(scene);
  }
}

/**
 * Controla las colisiones
 */
public void impactShapes() {
  impactShapes(SceneWorld.asteroids);
  if (octaedroActivo) {
    impactShapes(SceneWorld.octaedros);
  }
  if (icosaedroActivo) {
    impactShapes(SceneWorld.icosaedros);
  }
}

/**
 * Metodo que controla las colisiones con un determinado grupo de objetos
 * 
 * @param figures
 */
public void impactShapes(InteractiveFrame figures[]) {
  for (int i = 0; i < figures.length; i++) {
    if (figures[i].isVisitEnabled()) {
      if (impact(figures[i].position())) {
        figures[i].disableVisit();
        figures[i].translate(SceneWorld.REMOVE);
        shootCount = 250;
        puntos++;
      }
    }
  }
}

/**
 * Controla las colisiones con un objeto
 * 
 * @param shape
 * @return
 */
public boolean impact(Vec shape) {

  float yShip = SceneWorld.shipScene.position().y();
  float xShip = SceneWorld.shipScene.position().x();
  float yShape = shape.y();
  float xShape = shape.x();
  float hypotenuse = pow(pow(xShape, 2) + pow(yShape, 2), 0.5f);

  float bulletMoves = 230 / BULLETSPEED;
  float xBullet = 115 - bulletMoves * shootCount / bulletMoves;

  float windowAngle = ((-xShip + KDESFASE) * KANGLE * (PI / 180));
  windowAngle = yShip < 0 ? (TWO_PI + (-windowAngle)) : windowAngle;

  float sceneAngle = acos(xShape / hypotenuse);
  sceneAngle = yShape < 0 ? (sceneAngle) : (TWO_PI - sceneAngle);

  float totalAngleX = cos((windowAngle + sceneAngle) % TWO_PI);
  float totalAngleY = sin((windowAngle + sceneAngle) % TWO_PI);
  float xPosition = hypotenuse * totalAngleX;
  float yPosition = hypotenuse * totalAngleY;

  if (yPosition > 25 || yPosition < -25) {
    return false;
  } else {
    if (xPosition >= 100) {
      life--;
      if (life <= 0) {
        gameOver();
      }
    }
  }
  for (int i = -3; i < 4; i++) {
    if ((int) xBullet - i == (int) xPosition) {
      explosion.rewind();
      explosion.play();
      return true;
    }
  }
  return false;
}

public void impactShip() {
  impactShapes(SceneWorld.asteroids);
  if (octaedroActivo) {
    impactShapes(SceneWorld.octaedros);
  }
  if (icosaedroActivo) {
    impactShapes(SceneWorld.icosaedros);
  }
}

/**
 * Se encarga de generar las Shapes instanciadas para su uso
 */
public void buildShapes() {
  buildEvilShip();
  buildBullet();
  buildShip();
  buildIcosaedros();
  buildOctaedro();
}

/**
 * crea la forma de el proyectil
 */
public void buildBullet() {
  PShape shape = new PShape();
  pushStyle();

  shape = createShape();

  shape.beginShape(TRIANGLE);
  shape.fill(255,0,0);
  shape.noStroke();
  int a = 3;
  int b = 6;
  int c = 12;
  shape.vertex(0, 0, -b);
  shape.vertex(-a, -a, -a);
  shape.vertex(-a, a, -a);
  shape.vertex(0, 0, -b);
  shape.vertex(-a, a, -a);
  shape.vertex(a, a, -a);
  shape.vertex(0, 0, -b);
  shape.vertex(a, a, -a);
  shape.vertex(a, -a, -a);
  shape.vertex(0, 0, -b);
  shape.vertex(a, -a, -a);
  shape.vertex(-a, -a, -a);

  shape.vertex(0, b, 0);
  shape.vertex(-a, a, -a);
  shape.vertex(-a, a, a);
  shape.vertex(0, b, 0);
  shape.vertex(-a, a, a);
  shape.vertex(a, a, a);
  shape.vertex(0, b, 0);
  shape.vertex(a, a, a);
  shape.vertex(a, a, -a);
  shape.vertex(0, b, 0);
  shape.vertex(a, a, -a);
  shape.vertex(-a, a, -a);

  shape.vertex(0, 0, b);
  shape.vertex(-a, -a, -a);
  shape.vertex(-a, a, -a);
  shape.vertex(0, 0, b);              
  shape.vertex(a, -a, -a);
  shape.vertex(-a, -a, -a);

  shape.vertex(0, -b, 0);
  shape.vertex(-a, -a, -a);
  shape.vertex(-a, -a, a);
  shape.vertex(0, -b, 0);
  shape.vertex(-a, -a, a);
  shape.vertex(a, -a, a);
  shape.vertex(0, -b, 0);
  shape.vertex(a, -a, a);
  shape.vertex(a, -a, -a);
  shape.vertex(0, -b, 0);
  shape.vertex(a, -a, -a);
  shape.vertex(-a, -a, -a);

  shape.vertex(-c, 0, 0);
  shape.vertex(-a, -a, -a);
  shape.vertex(-a, a, -a);
  shape.vertex(-c, 0, 0);
  shape.vertex(-a, a, -a);
  shape.vertex(-a, a, a);
  shape.vertex(-c, 0, 0);
  shape.vertex(-a, a, a);
  shape.vertex(-a, -a, a);
  shape.vertex(-c, 0, 0);
  shape.vertex(-a, -a, a);
  shape.vertex(-a, -a, -a);

  shape.endShape();
  popStyle();
  ship.add(shape);
}

/**
 * Crea la forma de la Nave
 */
public void buildShip() {
  PShape shape = new PShape();

  pushStyle();
  noStroke();
  shape = createShape();
  shape.beginShape(TRIANGLE);
  int a = 5;
  int b = 6;
  int c = 12;

  shape.fill(128, 0, 0);
  shape.vertex(-b, -b, 0);
  shape.vertex(-c, 0, 0);
  shape.vertex(-b, b, 0);
  shape.vertex(-b, -b, 0);
  shape.vertex(-b, b, 0);
  shape.fill(150, 0, 0);
  shape.vertex(b, b, 0);
  shape.vertex(-b, -b, 0);
  shape.vertex(b, b, 0);
  shape.vertex(b, -b, 0);
  shape.vertex(0, b, 0);
  shape.vertex(0, c, 0);
  shape.vertex(a, b, 0);
  shape.fill(170, 0, 0);
  shape.vertex(a, -b, 0);
  shape.vertex(0, -c, 0);
  shape.vertex(0, -b, 0);
  shape.vertex(b, 0, 0);
  shape.vertex(c, a, 0);
  shape.vertex(c, -a, 0);

  shape.endShape();
  pushStyle();
  ship.add(shape);
}

/**
 * Se encarga de generar 13 asteroides aleatorios para su proyección
 */
public void asteroid() {
  float radius = 5;
  PShape shape = new PShape();
  for (int i = 0; i < 13; i++) {
    shape = createShape();
    shape.beginShape(TRIANGLE_STRIP);
    shape.stroke(122);
    shape.fill(random(180, 255));
    for (int j = 0; j < 10; j++) {
      shape.vertex(random(-radius, radius), random(-radius, radius), random(-radius, radius));
    }
    shape.endShape();
    asteroids.add(shape);
  }
}

/**
 * Crea un icosaedro
 */
public void buildIcosaedros() {
  float m = 340.2603233f / 25;
  float a = 0.5f * m;
  float b = 0.309016994f * m;
  PShape shape = createShape();
  shape.beginShape(TRIANGLE);
  shape.stroke(150);
  shape.vertex(0, b, -a);
  shape.vertex(b, a, 0);
  shape.vertex(-b, a, 0);
  shape.vertex(0, b, a);
  shape.vertex(-b, a, 0);
  shape.vertex(b, a, 0);
  shape.vertex(0, b, a);
  shape.vertex(0, -b, a);
  shape.vertex(-a, 0, b);
  shape.vertex(0, b, a);
  shape.vertex(a, 0, b);
  shape.vertex(0, -b, a);
  shape.vertex(0, b, -a);
  shape.vertex(0, -b, -a);
  shape.vertex(a, 0, -b);
  shape.vertex(0, b, -a);
  shape.vertex(-b, -a, 0);
  shape.vertex(0, -b, -a);
  shape.vertex(-b, -a, 0);
  shape.vertex(b, -a, 0);
  shape.vertex(-b, a, 0);
  shape.vertex(-a, 0, b);
  shape.vertex(-a, 0, -b);
  shape.vertex(-b, -a, 0);
  shape.vertex(-a, 0, -b);
  shape.vertex(-a, 0, b);
  shape.vertex(b, a, 0);
  shape.vertex(a, 0, -b);
  shape.vertex(a, 0, b);
  shape.vertex(b, -a, 0);
  shape.vertex(a, 0, b);
  shape.vertex(a, 0, -b);
  shape.vertex(0, b, a);
  shape.vertex(-a, 0, b);
  shape.vertex(-b, a, 0);
  shape.vertex(0, b, a);
  shape.vertex(b, a, 0);
  shape.vertex(a, 0, b);
  shape.vertex(0, b, -a);
  shape.vertex(-b, a, 0);
  shape.vertex(-a, 0, -b);
  shape.vertex(0, b, -a);
  shape.vertex(a, 0, -b);
  shape.vertex(b, a, 0);
  shape.vertex(0, -b, -a);
  shape.vertex(-a, 0, -b);
  shape.vertex(-b, -a, 0);
  shape.vertex(0, -b, -a);
  shape.vertex(b, -a, 0);
  shape.vertex(a, 0, -b);
  shape.vertex(0, -b, a);
  shape.vertex(-b, -a, 0);
  shape.vertex(-a, 0, b);
  shape.vertex(0, -b, a);
  shape.vertex(a, 0, b);
  shape.vertex(b, -a, 0);
  shape.endShape(CLOSE);
  icosaedro = shape;
}

/**
 * Crea un octaedro
 */
public void buildOctaedro() {
  float m = 400f / 30;
  float a = 0.353553391f * m;
  float b = 0.5f * m;
  PShape shape = createShape();
  shape.beginShape(TRIANGLE);
  shape.stroke(120);
  shape.vertex(-a, 0, a);
  shape.vertex(-a, 0, -a);
  shape.vertex(0, b, 0);

  shape.vertex(-a, 0, -a);
  shape.vertex(a, 0, -a);
  shape.vertex(0, b, 0);

  shape.vertex(a, 0, -a);
  shape.vertex(a, 0, a);
  shape.vertex(0, b, 0);

  shape.vertex(a, 0, a);
  shape.vertex(-a, 0, a);
  shape.vertex(0, b, 0);

  shape.vertex(a, 0, -a);
  shape.vertex(-a, 0, -a);
  shape.vertex(0, -b, 0);

  shape.vertex(-a, 0, -a);
  shape.vertex(-a, 0, a);
  shape.vertex(0, -b, 0);

  shape.vertex(a, 0, a);
  shape.vertex(a, 0, -a);
  shape.vertex(0, -b, 0);

  shape.vertex(-a, 0, a);
  shape.vertex(a, 0, a);
  shape.vertex(0, -b, 0);

  shape.endShape(CLOSE);

  octaedro = shape;
}

public void buildEvilShip() {

  int a = 6;
  int b = 14;
  int c = 15;
  pushStyle();
  noStroke();
  PShape shape = createShape();

  shape.beginShape(TRIANGLE);
  shape.fill(0, 255, 0, 120);
  shape.vertex(0, 0, 0);
  shape.vertex(-b, a, 0);
  shape.vertex(-a, b, 0);
  shape.vertex(0, 0, 0);
  shape.vertex(-a, b, 0);
  shape.vertex(a, b, 0);
  shape.vertex(0, 0, 0);
  shape.vertex(a, b, 0);
  shape.vertex(b, a, 0);
  shape.vertex(0, 0, 0);
  shape.vertex(b, a, 0);
  shape.fill(0, 122, 0, 120);
  shape.vertex(b, -a, 0);
  shape.vertex(0, 0, 0);
  shape.vertex(b, -a, 0);
  shape.vertex(a, -b, 0);
  shape.vertex(0, 0, 0);
  shape.vertex(a, -b, 0);
  shape.vertex(-a, b, 0);
  shape.vertex(0, 0, 0);
  shape.vertex(-a, b, 0);
  shape.vertex(-b, -a, 0);
  shape.vertex(0, 0, 0);
  shape.vertex(-b, -a, 0);
  shape.fill(0, 60, 0, 120);
  shape.vertex(-b, a, 0);
  shape.vertex(b, 0, 0);
  shape.vertex(c, a, 0);
  shape.vertex(c, -a, 0);
  shape.vertex(0, b, 0);
  shape.vertex(a, c, 0);
  shape.vertex(-a, c, 0);
  shape.vertex(-b, 0, 0);
  shape.vertex(-c, a, 0);
  shape.vertex(-c, -a, 0);
  shape.vertex(0, -b, 0);
  shape.vertex(a, -c, 0);
  shape.vertex(-a, -c, 0);
  shape.endShape(CLOSE);
  popStyle();
  evilShip = shape;
}

/**
 * Metodo que se encarga de generar el movimiento y los disparos cuando se
 * presiona una tecla, basado en el booleando pressed crea un movimiento
 * continuo mientras se tenga presionada la tecla
 */
public void continuosPressed() {
  if (pressed == true) {
    if (key == ' ') {
      shooting = true;
    }
  }
}

public void keyReleased() {
  pressed = false;
}

public void keyTyped() {
  pressed = true;
}

// Trampas. Con '1' se sube de nivel con '2' se baja de nivel y con '3' se
// reciben 500 de armadura y se regresa al juego
@Override
  public void keyPressed() {
  // TODO Auto-generated method stub
  super.keyPressed();
  if (key == 'm' || key == 'M') {
    if (player.isPlaying()) {
      player.pause();
    } else {
      player.rewind();
      player.play();
    }
  }
  if (key == '1') {
    level++;
    puntos += 50;
  }
  if (key == '2') {
    level--;
    puntos -= 50;
  }
  if (key == '3') {
    life += 500;
    regame.rewind();
    regame.play();
  }
  if (key == 'n') {
    txtShader = !txtShader;
  }
}