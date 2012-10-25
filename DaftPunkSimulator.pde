import hypermedia.net.*;
import java.util.concurrent.*;

int lights_per_strip = 32*5;
int strips = 40;
int packet_length = strips*lights_per_strip*3 + 1;


Boolean demoMode = true;
BlockingQueue newImageQueue;

UDP udp;

ImageHud imageHud;
DemoTransmitter demoTransmitter;

int animationStep = 0;
int maxConvertedByte = 0;

int BOX1=0;
int BOX2=8;
int BOX3=16;
int BOX4=24;
int BOX5=32;

List<Segment> LeftRailSegments;
Fixture leftRail;

void setup() {
  size(1200, 800);
  colorMode(RGB, 255);
  frameRate(60);
  newImageQueue = new ArrayBlockingQueue(2);

  imageHud = new ImageHud(20, height-160-20, strips, lights_per_strip);

  udp = new UDP( this, 58082 );
  udp.listen( true );

  defineLeftRail();   // Define the rail segments by where they are in pixel space
  leftRail = new Fixture(LeftRailSegments, new PVector(0, 0));

  demoTransmitter = new DemoTransmitter();
  demoTransmitter.start();
}


int convertByte(byte b) {
  int c = (b<0) ? 256+b : b;

  if (c > maxConvertedByte) {
    maxConvertedByte = c;
    println("Max Converted Byte is now " + c);
  }  

  return c;
}

void receive(byte[] data, String ip, int port) {  
  //println(" new datas!");
  if (demoMode) {
    println("Started receiving data from " + ip + ". Demo mode disabled.");
    demoMode = false;
  }

  if (data[0] == 2) {
    // We got a new mode, so copy it out
    String modeName = new String(data);

    return;
  }

  if (data[0] != 1) {
    println("Packet header mismatch. Expected 1, got " + data[0]);
    return;
  }

  if (data.length != packet_length) {
    println("Packet size mismatch. Expected "+packet_length+", got " + data.length);
    return;
  }

  if (newImageQueue.size() > 0) {
    println("Buffer full, dropping frame!");
    return;
  }

  color[] newImage = new color[strips*lights_per_strip];

  for (int i=0; i< strips*lights_per_strip; i++) {
    // Processing doesn't like it when you call the color function while in an event
    // go figure
    newImage[i] = (int)(0xff<<24 | convertByte(data[i*3 + 1])<<16) | (convertByte(data[i*3 + 2])<<8) | (convertByte(data[i*3 + 3]));
  }
  try { 
    newImageQueue.put(newImage);
  } 
  catch( InterruptedException e ) {
    println("Interrupted Exception caught");
  }
}

color[] currentImage = null;

void draw() {
  background(0);

  if (currentImage != null) {
    leftRail.draw();
  }

  imageHud.draw();

  if (newImageQueue.size() > 0) {
    color[] newImage = (color[])newImageQueue.remove();

    imageHud.update(newImage);
    currentImage = newImage;
  }
}

