/* Semplice gioco di corse con un 16x2 LCD display 
   Puoi usare un qualsiasi schermo compatibile all'Hitachi HD44780 LCD.
   I collegamenti vengono spiegati http://www.arduino.cc/en/Tutorial/LiquidCrystal
   C'è anche lo sterzo tramite un potenziometro collegato nell'analog input 1,
   e un piezo sul pin 3 (digit).
   
   Ringrazio @TheRealDod
   @GinoWT, 10 Luglio 2011   http://ginowt.blogspot.com
  
*/
#include <LiquidCrystal.h> 
// Includiamo la libreria per gli schermi LCD

LiquidCrystal lcd(7, 8, 9, 10, 11, 12); //Questi sono i digital pin per lcd


const int POTPIN = 1;
// Ingresso analogico per il potenziometro che ha la funzione di sterzo
const int MAXPOT = 800;
// Questo è per dire che non serve girare tutto il potenziometro

const int SPEAKERPIN = 3; //Pin digitale per il piezo

const int PINNULLO = 0;//Un pin che non è collegato a nulla

const int MAXPASSO = 300; //Velocità di partenza del camion 
const int MINPASSO = 100; //Velocità massima che può raggiungere

const int NPIXEL = 6;

byte pixel[NPIXEL][8] = {
    //Camion nostro sopra 
  { B11110,
    B11110,
    B11111,
    B01010,
    B00000,
    B00000,
    B00000,
    B00000}
   //Camion nostro sotto
  ,{B00000,
    B00000,
    B00000,
    B11110,
    B11110,
    B11111,
    B01010,
    B00000}
   //Auto avversaria sopra 
  ,{B00000,
    B01110,
    B11111,
    B01010,
    B00000,
    B00000,
    B00000,
    B00000}
   //Auto avversaria sot
  ,{B00000,
    B00000,
    B00000,
    B00000,
    B01110,
    B11111,
    B01010,
    B00000}
    
    //Incidente sopra
  ,{B10101,
    B01110,
    B01110,
    B10101,
    B00000,
    B00000,
    B00000,
    B00000}
  // Incidente sotto
  ,{B00000,
    B00000,
    B00000,
    B10101,
    B01110,
    B01110,
    B10101,
    B00000}

};

const int NPOSIZIONEAUTO  = 4;


const char VUOTO=32;
char camion[NPOSIZIONEAUTO][2] = {
  {1,VUOTO},{2,VUOTO},{VUOTO,1},{VUOTO,2}
};
char autoavv [NPOSIZIONEAUTO][2] = {
  {3,VUOTO},{4,VUOTO},{VUOTO,3},{VUOTO,4}
};
char incidente [NPOSIZIONEAUTO][2] = {
  {5,VUOTO},{6,VUOTO},{VUOTO,5},{VUOTO,6}
};

const int LUNGHEZZASTRADA = 15; //Lunghezza LCD senza contare il nostro camion
int strada[LUNGHEZZASTRADA];  //Posizione delle auto
char line_buff[2+LUNGHEZZASTRADA]; //Strada
int strada_index;
int cam_pos;

//Determina la probabilità di icnontrare più auto in una colonna
const int MAXRPOSTRADA = 3*NPOSIZIONEAUTO; // Significa 1/3 di probabilità
int durata_passo;

int schianto; 
unsigned int schiantotempo; //Mostra il tempo di percorrenza
const int CRASHSOUNDDURATION = 250; //Durata del suono allo schianto

const char *INTRO1="Race and crash"; 
const char *INTRO2="Designby GinoWT";
const int DURATAINTRO = 3000; //Durata di 3 secondi per l'intro

void setup()
{
  schianto = schiantotempo = strada_index = 0;
  durata_passo = MAXPASSO;
  line_buff[1+LUNGHEZZASTRADA] = '\0';
  randomSeed(analogRead(PINNULLO));
  for (int i=0; i<NPIXEL; i++) {
    lcd.createChar(i+1,pixel[i]);
  }
  for (int i=0; i<LUNGHEZZASTRADA; i++) {
    strada[i]=-1;
  }
  pinMode(SPEAKERPIN,OUTPUT);
  analogWrite(SPEAKERPIN,0);
  lcd.begin(16,2);
  getSteeringWheel();
  drawRoad();
  lcd.setCursor(1,0);
  lcd.print(INTRO1);
  lcd.setCursor(1,1);
  lcd.print(INTRO2);
  delay(DURATAINTRO);
}

void loop() {
  unsigned long now = millis()-DURATAINTRO;
  if (!schianto) {
    getSteeringWheel();
    schianto = (cam_pos==strada[strada_index]);
  }
  if (schianto) {
    if (!schiantotempo) {
      schiantotempo=now;
      drawRoad();
      
     
      lcd.setCursor(1,0);
      lcd.print("Schiantato dopo");
      lcd.setCursor(2,1);
      lcd.print(now/1000);
      lcd.print(" secondi.");
      //Testo di game over
    }
    if ((now-schiantotempo)<CRASHSOUNDDURATION) {
      analogWrite(SPEAKERPIN,random(255)); //Suono
    } 
    else {
      analogWrite(SPEAKERPIN,0); 
    }
    delay(100); 
  } 
  else {

    int posizione_precedente = strada[(strada_index-1)%LUNGHEZZASTRADA];
    int posizione_adesso = random(MAXRPOSTRADA);
    while (abs(posizione_adesso-posizione_precedente)<2) { 
      posizione_adesso = random(MAXRPOSTRADA);
    }
    strada[strada_index] = posizione_adesso;
    strada_index = (strada_index+1)%LUNGHEZZASTRADA;
    drawRoad();
    delay(durata_passo);
    if (durata_passo>MINPASSO) {
      durata_passo--; //Aumento velocità
    }
  }
}
void getSteeringWheel() {
  cam_pos = map(analogRead(POTPIN),0,1024,0,NPOSIZIONEAUTO);
}

void drawRoad() {
  for (int i=0; i<2; i++) {
    if (schianto) {
      line_buff[0]=incidente[cam_pos][i];
    } 
    else {
      line_buff[0]=camion[cam_pos][i];
    }
    for (int j=0; j<LUNGHEZZASTRADA; j++) {
      int pos = strada[(j+strada_index)%LUNGHEZZASTRADA];
      line_buff[j+1] = pos>=0 && pos<NPOSIZIONEAUTO ? autoavv[pos][i] : VUOTO;
    }
    lcd.setCursor(0,i);
    lcd.print(line_buff);
  }
}

