#include <FastPID.h>
#define DEBUG false
#define RATIO_FOLLOWER false // secondary from setpoint or primary

#define PRESSURESENSOR_PRIMARY 5
#define PRESSURESENSOR_SECONDARY 4
#define FAN_PRIMARY 3
#define FAN_SECONDARY 6
#define SETPOINT_PIN 3
#define RPM_DELAY 100
#define PASCALS_PER_BIT 10.4
#define ZERO_OFFSET 40
#define A1 3
#define A2 1
#define DENSITY_OF_AIR 1.27
#define INSIDE_TERM (2/DENSITY_OF_AIR)*(1-(A2/A1)*(A2/A1))
#define SIDE_TERM (DENSITY_OF_AIR/2)*(1-(A2/A1)*(A2/A1))
#define RATIO 1.5


//float Kp=0.1, Ki=0.5, Kd=0, Hz=10;
//float Kp=0.1, Ki=0.5, Kd=0.1, Hz=10;
float Kp=0.2, Ki=0.01, Kd=2, Hz=1;


int output_bits = 8;
bool output_signed = false;

double setPoint;
double primaryPressureSensor;
double primaryPower;
double primaryPressureDrop;
double primaryFlowRate;
double secondaryPressureSensor;
double secondaryPower;
double secondaryFlowRate;
double secondaryPressureDrop;
int primaryOffset;
int secondaryOffset;
int i;

FastPID primaryPID(Kp, Ki, Kd, Hz, output_bits, output_signed);
FastPID secondaryPID(Kp, Ki, Kd, Hz, output_bits, output_signed);


void setup() {
  pinMode(PRESSURESENSOR_PRIMARY, INPUT);
  pinMode(FAN_PRIMARY, OUTPUT);
  pinMode(PRESSURESENSOR_SECONDARY, INPUT);
  pinMode(FAN_SECONDARY, OUTPUT);
  pinMode(SETPOINT_PIN, INPUT);

  Serial.begin(115200);
  Serial.println();
  Serial.println("Calibrating zero offset");

  analogWrite(FAN_PRIMARY, 0);
  analogWrite(FAN_SECONDARY, 0);

  delay(1000);
  primaryOffset=1023;
  secondaryOffset=1023;
  primaryPressureSensor=0;
  secondaryPressureSensor=0;
  for(i=0; i < 10; i++) {
    primaryPressureSensor = analogRead(PRESSURESENSOR_PRIMARY);
    if (primaryPressureSensor < primaryOffset) {
      primaryOffset = primaryPressureSensor;
    }
    delay(200);
  }
  Serial.print("primaryOffset:");
  Serial.println(primaryOffset);
  for(i=0; i < 10; i++) {
    secondaryPressureSensor = analogRead(PRESSURESENSOR_SECONDARY);
    if (secondaryPressureSensor < secondaryOffset) {
      secondaryOffset = secondaryPressureSensor;
    }
    delay(200);
  }

  Serial.print("secondaryOffset:");
  Serial.println(secondaryOffset);

}
 
void loop ()
{

  
// Read the setpoint pot and map it

analogRead(SETPOINT_PIN); // prime
setPoint=map(analogRead(SETPOINT_PIN),0,1023,0,20);

analogRead(PRESSURESENSOR_PRIMARY); //prime
primaryPressureSensor = analogRead(PRESSURESENSOR_PRIMARY);
// Run the PID to figure out what the power should be
uint8_t primaryPower = primaryPID.step(setPoint, primaryPressureSensor-primaryOffset);

// Write the power value to the PWM output
analogWrite(FAN_PRIMARY, primaryPower);

if (RATIO_FOLLOWER) {
  // Secondary from primary actual
  primaryPressureDrop = (primaryPressureSensor-primaryOffset) * PASCALS_PER_BIT;
}
else {
  // Secondary from setpoint
  primaryPressureDrop = setPoint * PASCALS_PER_BIT;
}

if( primaryPressureDrop < 0) primaryPressureDrop = 0;

primaryFlowRate = A2*sqrt(INSIDE_TERM*primaryPressureDrop);

secondaryFlowRate = primaryFlowRate * RATIO;
secondaryPressureDrop = ((secondaryFlowRate/A2)*(secondaryFlowRate/A2)*SIDE_TERM)/PASCALS_PER_BIT;


analogRead(PRESSURESENSOR_SECONDARY); //prime
secondaryPressureSensor = analogRead(PRESSURESENSOR_SECONDARY);
// Run the PID to figure out what the power should be
uint8_t secondaryPower = secondaryPID.step(secondaryPressureDrop, secondaryPressureSensor-secondaryOffset);
// Write the power value to the PWM output
analogWrite(FAN_SECONDARY, secondaryPower);

if (DEBUG) {
// Serial info
Serial.print ("set:");
Serial.print (setPoint);

Serial.print ("\tPRIMARY dp:");
Serial.print ((int) primaryPressureSensor-primaryOffset);

Serial.print ("\tQ:");
Serial.print ((int) primaryFlowRate);

Serial.print ("\tPwr:");
Serial.print (primaryPower);
//Serial.println ();

Serial.print ("\t\tSECONDARY dp(r):");
Serial.print ((int) secondaryPressureDrop);

Serial.print ("\tdp:");
Serial.print ((int) secondaryPressureSensor-secondaryOffset);


Serial.print ("\tQ:");
Serial.print ((int) secondaryFlowRate);

Serial.print ("\tPwr:");
Serial.print (secondaryPower);
Serial.println ();
}
//delay(2);
} 
