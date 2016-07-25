

#include <LiquidCrystal.h>
#include <math.h>


LiquidCrystal lcd(7, 8, 9, 10, 11, 12);
int backLight = 13;    // pin 13 will control the backlight



void setup(void) {
  pinMode(backLight, OUTPUT);
  digitalWrite(backLight, HIGH); // turn backlight on. Replace 'HIGH' with 'LOW' to turn it off.
  lcd.begin(16, 2);              // rows, columns.  use 16,2 for a 16x2 LCD, etc.
  lcd.clear();                   // start with a blank screen
  lcd.setCursor(0,0);            // set cursor to column 0, row 0
}

double Thermister(int RawADC) {
  double Temp;
  // Guarda http://en.wikipedia.org/wiki/Thermistor per la spiegazione della formula
  Temp = log(((10240000/RawADC) - 10));
  Temp = 1 / (0.001129148 + (0.000234125 * Temp) + (0.0000000876741 * Temp * Temp * Temp));

  Temp = Temp - 273.15;           // Converti Kelvin in Celcius
  return Temp;
}

void printTemp(void) {
  double fTemp;
  double temp = Thermister(analogRead(0));  // Leggi il sensore
  lcd.clear();
  lcd.setCursor(0,0);
  lcd.print("Temperatura e':");
  lcd.setCursor(0,1);
  lcd.print(temp);
  lcd.print(" C / ");
  fTemp = (temp * 1.8) + 32.0;    // Converti in fahrenheit
  lcd.print(fTemp);
  lcd.print(" F");
  if (fTemp > 68 && fTemp < 78) {
    lcd.setCursor(0,3);
    lcd.print("Very comfortable");
  }
}

void loop(void) {
  printTemp();
  delay(1000);
}


