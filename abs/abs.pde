/*
** 		Programmierung eingebetteter Systeme
** 		ABS-Steuerung
**		M.Wörner (30137), C.Silfang (30147)
*/
const 	float MAX_ABS = 2.0; // Periode * 25 us = 2ms
const 	float BREMSE_AUF = 1.75; // Stellung Bremse Auf * 25 us = 1,75ms
const 	float BREMSE_ZU = 1.5; // Stellung Bremse Zu * 25 us = 1,5ms
	float AKTUELLER_ABS_WERT = 1.75; // Bremse am Anfang auf

// Pins
const int BREMSE_PIN_PWM = 4;
const int MOTOR_PIN_PWM = 5;

const int WELLE_INTERRUPT_PIN = 7;
const int RAD_INTERRUPT_PIN =8;

const int WELLE_INTERRUPT_NUMMER = 2;
const int RAD_INTERRUPT_NUMMER = 3;

// Geschwindigkeitsvorgaben
const int VMIN = 100; // Mindestgeschwindigkeit
const int VMAX = 200; // Höchstgeschwindigkeit

// Zähler
static int WELLE_INTERRUPT_ZAEHLER = 0;

// Rad-/Wellenverhältnis 1:8
// > Welle dreht sich 8 mal schneller als Rad
const int RAD_WELLEN_VERHAELTNIS = 8; 

// SETUP
void setup() {

	// Pins setzen
	pinMode( WELLE_INTERRUPT_PIN, INPUT );
	pinMode( RAD_INTERRUPT_PIN, INPUT );
	pinMode( BREMSE_PIN_PWM, OUTPUT );
   
	Serial.begin(9600);
   
	/*
	** Motor Beschleunigen: Start: VMIN - VMAX
	** anschließend Beschleunigen beenden
	*/
	MotorBeschleunigung( VMAX );
	delay( 5000 );
	analogWrite( MOTOR_PIN_PWM, 0 );
	delay( 100 );
   
	// Interrupt Handling
	attachInterrupt( WELLE_INTERRUPT_NUMMER, WelleInterruptHandler, RISING );//Wellenumdrehungen zählen
	attachInterrupt( RAD_INTERRUPT_NUMMER, RadInterruptHandler, RISING );//Check nach Radumdrehung
	
	// Brems-Servo Regelung
	attachCoreTimerService( bremseServoRegelung );   
}

// LOOP
void loop() {
  
}

/* 
** Funktion um Motor zu Beschleunigen.
** Die Beschleunigung beginnt bei VMIN
** und wird bei einer maximalen Geschwindigkeit *
** von VMAX beendet. 
*/
void MotorBeschleunigung( uint8_t VMAX ){
	for(int i = VMIN; i <= VMAX; i++){
		analogWrite( MOTOR_PIN_PWM, i );
		delay(100);
	}
}

/*
** Funktion um auf Wellenimpuls zu reagieren.
** Dazu wird die Zählervariable inkrementiert 
** und somit die Umdrehung der Welle gezählt.
*/
void WelleInterruptHandler(){
	WELLE_INTERRUPT_ZAEHLER++;
}

/*
** Funktion um auf Radimpuls zu reagieren.
** Dazu wird auf Rad-Blockierungen reagiert:
** 	- 1:8 Bremse zu, da Rad blockieren muss da das Verhältnis unterschritten wird
** 	- 9 > Bremse auf, da Umdrehungen größer wie das Verhältnis
*/
void RadInterruptHandler(){	
	if( WELLE_INTERRUPT_ZAEHLER > RAD_WELLEN_VERHAELTNIS ) 
		AKTUELLER_ABS_WERT = BREMSE_AUF; // Rad blockiert nicht
	else 
		AKTUELLER_ABS_WERT = BREMSE_ZU; // Rad blockiert
	WELLE_INTERRUPT_ZAEHLER = 0;
}

/*
** Funktion um den Servo für die Bremsung zu steuern.
** Steuerung wird über die Zeit mittels der CORE_TICK_RATE 
** realisiert. 
** Die Steuerung der HIGH/LOW-Phasen geschieht über toggling.
*/
uint32_t bremseServoRegelung( uint32_t time ){
	static bool b = false;
	b = !b; // toogling
	if( b ){ // HIGH -> Bremse zu
		digitalWrite( BREMSE_PIN_PWM, HIGH );
		return time + CORE_TICK_RATE / 1 * AKTUELLER_ABS_WERT;
	}
	else{ // LOW -> Bremse auf
		digitalWrite( BREMSE_PIN_PWM, LOW );
		return time + CORE_TICK_RATE / 1 * ( MAX_ABS - AKTUELLER_ABS_WERT );		
  }
}
