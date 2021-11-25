#include "pitches.h"  // must include open source pitches.h found online in libraries folder or make a new tab => https://www.arduino.cc/en/Tutorial/toneMelody
#define BUZZ_PIN 9

void setup() {

  Serial.begin(9600);
  randomSeed(analogRead(0));
  //launch
  // for(long freqIn = 200; freqIn < 500; freqIn = freqIn + 2){
  //   tone(BUZZ_PIN, freqIn,10);
  // }
  // delay(10);
  long blow1;
  long blow2;
  long start_f = 300;
  long stop_f = 50;

  int i = -1;
  long duration = 500;

  long steps = 10;
  long top = 1700;
  long bottom = 100;
  long offset_top = 300;
  long offset_bottom = 20;
  long offset_range = (offset_top - offset_bottom);
  long offset_decr = offset_range / steps;
  long offset = offset_top;
  long range = (top - bottom);
  long del = duration / steps;
  long decr = range / steps;
  long center = top;

  for(int k = 0; k < steps; k++){
    long freq = center + i * offset;
    long duration = del;
    Serial.println(freq);
    Serial.println(duration);
    tone(BUZZ_PIN, freq, duration);
    delay(del);
    i *= i;
    center -= decr;
    offset -= offset_decr;
  }

  delay(2000);

  //explosion
  // for(int k = 0; k < 63; k++){
  //   blow1 = random(30,300);
  //   blow2 = random(5,10);
  //   tone(BUZZ_PIN, blow1, blow2);
  //   delay(blow2);
  // }   
  
  // Play coin sound
//  tone(BUZZ_PIN,NOTE_B5,100);
//  delay(100);
//  tone(BUZZ_PIN,NOTE_E6,850);
//  delay(800);
//  noTone(8);
//  
//  delay(2000);  // pause 2 seconds
//
//  // Play 1-up sound
//  tone(BUZZ_PIN,NOTE_E6,125);
//  delay(130);
//  tone(BUZZ_PIN,NOTE_G6,125);
//  delay(130);
//  tone(BUZZ_PIN,NOTE_E7,125);
//  delay(130);
//  tone(BUZZ_PIN,NOTE_C7,125);
//  delay(130);
//  tone(BUZZ_PIN,NOTE_D7,125);
//  delay(130);
//  tone(BUZZ_PIN,NOTE_G7,125);
//  delay(125);
//  noTone(8);
//
//  delay(2000);  // pause 2 seconds
//
//  // Play Fireball sound
//  tone(BUZZ_PIN,NOTE_G4,35);
//  delay(35);
//  tone(BUZZ_PIN,NOTE_G5,35);
//  delay(35);
//  tone(BUZZ_PIN,NOTE_G6,35);
//  delay(35);
//  noTone(8);
//  
//  delay(2000);  // pause 2 seconds
}

void loop() {
  // tone(BUZZ_PIN, map(analogRead(0), 0, 1023, 30, 5000));
  delay(10);
}
