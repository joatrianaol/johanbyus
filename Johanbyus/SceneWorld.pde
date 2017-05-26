import java.util.ArrayList;

import processing.core.PApplet;
import processing.core.PShape;
import remixlab.bias.event.MotionEvent;
import remixlab.dandelion.constraint.AxisPlaneConstraint;
import remixlab.dandelion.constraint.WorldConstraint;
import remixlab.dandelion.geom.Vec;
import remixlab.proscene.InteractiveFrame;
import remixlab.proscene.Scene;

static class SceneWorld {

  public static InteractiveFrame[] asteroids = new InteractiveFrame[12];
  public static InteractiveFrame[] icosaedros = new InteractiveFrame[7];
  public static InteractiveFrame[] octaedros = new InteractiveFrame[8];
  public static InteractiveFrame[] dodecaedros = new InteractiveFrame[6];
  public static final Vec REMOVE = new Vec(500, 0, 0);
  public static Vec[] asteroidsVec = new Vec[asteroids.length];
  public static Vec[] icosaedroVec = new Vec[icosaedros.length];
  public static Vec[] octaedrosVec = new Vec[octaedros.length];
  public static InteractiveFrame shipScene, bullet, ship;
  
  public static SceneWorld getInstance() {
    return new SceneWorld();
  }

  public static PApplet getPAppletInstance() {
    return new PApplet();
  }

  public static void init(Scene scene) {
    scene.eyeFrame().setDamping(0);
    AxisPlaneConstraint constraints[] = new AxisPlaneConstraint[1];
    constraints[0] = new WorldConstraint();
    constraints[0].setTranslationConstraintType(AxisPlaneConstraint.Type.FORBIDDEN);
    constraints[0].setRotationConstraint(AxisPlaneConstraint.Type.AXIS, new Vec(0.0f, 0.0f, 1.0f));
    scene.setEyeConstraint(constraints[0]);
    prepareShip(scene);
    scene.setRadius(200);
    scene.showAll();
    scene.eyeFrame().setRotationSensitivity(1.3f);
    dodecaedros[0] = new InteractiveFrame(scene, Johanbyus.evilShip);
    dodecaedros[0].removeBindings();
  
  }

  public static void prepareShip(Scene scene) {
    shipScene = new InteractiveFrame(scene, scene.eyeFrame());
    shipScene.translate(120, 0, -200);
    ship = new InteractiveFrame(scene, shipScene, Johanbyus.ship.get(1));
    ship.translate(-31, 0, 30);
    ship.removeBindings();
    bullet = new InteractiveFrame(scene, shipScene, Johanbyus.ship.get(0));
    bullet.translate(0, 0, 0);
    bullet.removeBindings();
    

  }

  public static void asteroid(Scene scene) {
    circle(scene,asteroids.length,0.05f,asteroids,asteroidsVec,Johanbyus.asteroids,asteroids.length);
  }
  
  public static void icosaedros(Scene scene) {
    ArrayList<PShape> icosaedro = new ArrayList<PShape>();
    icosaedro.add(Johanbyus.icosaedro);
    circle(scene, icosaedros.length, 0.03f, icosaedros, icosaedroVec, icosaedro, 0);
  }
  
  public static void octaedros(Scene scene) {
    ArrayList<PShape> octaedro = new ArrayList<PShape>();
    octaedro.add(Johanbyus.octaedro);
    circle(scene, octaedros.length, 0.04f, octaedros, octaedrosVec, octaedro, 0);
  }
  
  public static void circle(Scene scene, int nFigures, float speed, InteractiveFrame[] figures, Vec[] vecs, ArrayList<PShape> shapes, int rand){
    AxisPlaneConstraint constraints[] = new AxisPlaneConstraint[1];
    constraints[0] = new WorldConstraint();
    constraints[0].setRotationConstraintType(AxisPlaneConstraint.Type.FORBIDDEN);
    int figure = (int) getPAppletInstance().random(rand);
    float angle = PApplet.TWO_PI / (float) nFigures;
    for (int i = 0; i < nFigures; i++) {
      int xcord = (int) (10 * PApplet.sin(angle * i));
      int ycord = (int) (10 * PApplet.cos(angle * i));
      vecs[i] = new Vec(xcord * (speed+ Johanbyus.level*0.003f), ycord * (speed+ Johanbyus.level*0.003f));
      figures[i] = new InteractiveFrame(scene, shapes.get(figure));
      figures[i].translate(xcord, ycord, 10);
      figures[i].rotateX(new MotionEvent(10, 10));
      figures[i].removeBindings();
      figures[i].setConstraint(constraints[0]);
    }
  }

}