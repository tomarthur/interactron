/* 
  Gyro Otter Example
  April 25 2015
  Theme Park of Everyday
  http://www.themeparkofeveryday.com
  
  In this example, you can rotate your device to make the otter hide
  or pop out of the grass.
  
  ///////////////////////////////////////////////////////
  Expected Values from Pocket Park for Gyro
 
  Range between 0 and 180
 
  ///////////////////////////////////////////////////////
 
  This example also shows how to troubleshoot, the LED changes red when data
  from a user device is received. 
  
  Tom Arthur
  NYU ITP
  
  This project is enabled by the LightBlue Bean.
  https://punchthrough.com/bean/
  
   Contains code adapted from:
     'Facebook Flagger' (Bean Notifications)
     Release r1-0
     by Colin Karpfinger, Punch Through Design LLC
     Released under MIT license.
   
   and
   
     enableWakeOnConnect() function example.
     This example code is in the public domain.
 
 */


#include <Servo.h>
#define OTTER_SERVO_PIN 0

Servo otterServo;

///////////////////////////////////////////////////////
// Required variables for Theme Park of Everyday Installations

// Store values received by device
long scratchNumber = 0;   
long lastScratchNumber = 0;

// Track BLE connection
bool connected;

///////////////////////////////////////////////////////

void setup() 
{
  Serial.begin(57600);

  // Only wakeup Arduino if a user device is connected. This saves battery life.
  Bean.enableWakeOnConnect(true);
}

void loop() 
{ 
  // Check to see if the LightBlue Bean is connected to a user device
  connected = Bean.getConnectionState();

  if (connected)
  {
    // Set the LightBlue Bean LED to Green so you know PocketPark has connected.
    Bean.setLed(0, 255, 0);
    // Read the scratch number. This is how a user's device talks to your Installation.
    scratchNumber = Bean.readScratchNumber(1);

    // for this example, the expected values are between 0 and 180 which match the servo
    // there is no need to constrain or map values in this case
    
    if (scratchNumber != lastScratchNumber) {
      // TROUBLESHOOTING: show that data has come in from the user device
      Bean.setLed(0, 0, 255);
      
      otterServo.attach(OTTER_SERVO_PIN);
      otterServo.write(scratchNumber);
      lastScratchNumber = scratchNumber;
    }

    Bean.sleep(50);

  } 
  else {
    // when disconnected from the user device, turn the installation off.
    
    // reset the location of the servo
    otterServo.write(150);
    delay(1000);
    otterServo.detach();

    resetInstallation();
  }
}

///////////////////////////////////////////////////////
// Required functions for Theme Park of Everyday Installations

void resetInstallation() {
    // Reset the scratch number, prevents unexpected behavior on the next connection
    Bean.setScratchNumber(1, 0);
    // Turn the LightBlue Bean LED off so you know PocketPark has disconnected
    Bean.setLed(0, 0, 0);
    Bean.sleep(0xFFFFFFFF);
}

///////////////////////////////////////////////////////



