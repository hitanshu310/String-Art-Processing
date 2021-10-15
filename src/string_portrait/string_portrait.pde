/* Set paramteres in the first part */

int num_pins = 263;  // Number of pins at the edge of the circumference
int [][]pins = new int[num_pins][2];  
int num_lines = 5400;  // Num of lines connecting two pins after which the code terminates
PImage img;  // Input image, sorry for the non-contextual vraiable names I am lazy to change them right now
PImage img2; // Output image that will be drawn on, sorry for the non-contextual vraiable names I am lazy to change them right now
int drawn = 0;  // variable that tracks no. of lines drawn when the drawing takes place
int start_pin = 0;  // starting pin, anything works
String fileName = "mona_cropped.jpg";
String outputFile = "mona_string.jpg"; // Path to input file, Make sure you add the image to the sketch folder if you non't want to use fully qualified path

/* Parameter setting part ends */

void setup(){ // Setup performs one time setup
  size(1000, 1000); // Set width and height of canvas
  
  img = loadImage(fileName); // Load image
  img.resize(width, height);  // resize image acc. to canvas window
  img.filter(GRAY);  // Removing color info.
  img.filter(INVERT);  // Inverting color channels white becomers black and vice versa.
  
  
  // We want to find the blackest line on the image and make it lighter. Inverting the image just makes the process easier to viuslize.   
  
  img2 = createImage(img.width, img.height, RGB); // Create an image the same size of reference image, this is where the drawing happens.
  img2.loadPixels(); // Load image pixels to memory.
  for (int i = 0; i < img.pixels.length; i++) {
    img2.pixels[i] = color(255, 255, 255); // hardcoding each pixel of new image to white
  }
  img2.updatePixels(); // Indication we are done modifying pixel values for now, Imahe can be shown on screnn now.
  
  //println("Width of image is " + img.width);
  //println("Width of image is " + img.height);
  
  /* Determine coordinates of pins */
  
  int radius = width/2;  // Setting radius to half the width of square canvas
  float inc = TWO_PI/num_pins; // Angle increment in radians to determine placement of pins
  float theta = 0.0; // Starting angle
  for(int i = 0; i < num_pins; i++){ 
    //println("Pin number " + i);
    int x_cord = int(radius + radius * cos(theta));  //Finding x and y coordinates using trigo
    int y_cord = int(radius + radius * sin(theta));
    pins[i][0] = x_cord; // setting pin coordinates
    pins[i][1] = y_cord;
    point(x_cord, y_cord);
    theta = theta + inc;
  }
  createMask(img,radius);  // Create a circular mask
}


void draw(){
  
  if (drawn < num_lines) // Keep drawing lines till we don't reach pre established number of lines
  {
  int best = best_pin(pins, img, num_pins, start_pin);  
  DDA_line_algo_weight_leighten(pins[start_pin][0], pins[start_pin][1], pins[best][0], pins[best][1], img);
  DDA_line_algo_weight_darken(pins[start_pin][0], pins[start_pin][1], pins[best][0], pins[best][1], img2);
  start_pin = best;
  drawn = drawn + 1;
  image(img2,0,0);
  
  }
  
  if (drawn % 9 == 0){ 
  saveFrame("output/mona_#####.png");   // uncomment this line to output a frame and create a movie
  }
  
  if (drawn == num_lines)
  {
    saveFrame(outputFile);  // saves final frame
    drawn = drawn+1;
  }
  image(img2,0,0); // shows last frame after new lines are not being drawn
}
  
void createMask(PImage img, int radius){  
  color white = color(255); // Color of mask
  for (int i = 0; i < img.width; i++) {
    for(int j = 0; j < img.height; j++) {
      if( sq((i - radius)) + sq((j - radius)) > sq(radius)){ // Use equation of circle to find if a point on image is inside or outside of circle
         img.set(i,j,white); // Set points on image outside of circle to white
         }
     }
  }  
}

/// funtion to find best pin
int best_pin(int[][] pins, PImage img, int num_pins, int current_pin){
  float max_weight = 0;
  int best_pin = 0;
  for(int to_pin = (current_pin + 1) % num_pins; to_pin != current_pin; to_pin = (to_pin + 1) % num_pins) { // A bunch of code which means look over all pins except current one   
    if (abs(to_pin - current_pin) <= 15){ // Ignore 30 neighbouring pins. so we don't get stuck moving between close by pins
      continue;
    }    
    float weight = DDA_line_algo_weight(pins[current_pin][0], pins[current_pin][1], pins[to_pin][0], pins[to_pin][1], img);  // Calculates how black a line drawn between two points on an image is
    if (weight > max_weight) {
      max_weight = weight;
      best_pin = to_pin;
    }
  }
  //println("Weight is "+max_weight);
  //println("Best pin is "+best_pin);
  return best_pin;  // Finds darkest line on image
}

/* Variant of DDA line drawing algorithm that finds how dark a line is on the bg. image 
*/


float DDA_line_algo_weight(int x0, int y0, int x1, int y1, PImage img)
{
  float weight = 0;
  
  int dx = x1 - x0;
  int dy = y1 - y0;
  int steps = abs(dx) > abs(dy) ? abs(dx) : abs(dy);
  
  float xInc = dx / float(steps);
  float yInc = dy / float(steps);
  
  float x = x0;
  float y = y0;
  
  for (int i = 0; i < steps; i++)  // For every point of image on line joining (x0, y0) and (x1, y1), darkness is calculated and added for each point that is a part of line
  {  
    float red = red(img.get(floor(x),floor(y)));  // All channels are equal because image is greyscale

    weight = weight + sq(red);
    x = x + xInc;
    y = y + yInc;
  }
  img.updatePixels();
  return weight / steps;  // Total darkness of line is divided by length of line, to get avg.
}

/* Variant of DDA line drawing algorithm that lightens bg. image 
along a line joining two points on the image
Lightens image by 55, hardcoded but this can be paramterised.

We need a dedicated algo. to do this
Can't use build in line drawing fn 
as we want the line to not be uniformly dark but look like pencil strokes,
Where if two lines intersect we get a darker point.
*/

void DDA_line_algo_weight_leighten(int x0, int y0, int x1, int y1, PImage img)
{
  img.loadPixels();
  int dx = x1 - x0;
  int dy = y1 - y0;
  int steps = abs(dx) > abs(dy) ? abs(dx) : abs(dy);
  
  float xInc = dx / float(steps);
  float yInc = dy / float(steps);
  
  float x = x0;
  float y = y0;
  
  for (int i = 0; i < steps; i++)  // Every point of image on line joining (x0, y0) and (x1, y1) is lightened.
  {  
    float red = red(img.get(floor(x),floor(y)));
    if (red >= 55)
      img.set(round(x), round(y),color(red-55));
    else
      img.set(round(x), round(y),color(0));

    x = x + xInc;
    y = y + yInc;
  }
  img.updatePixels();

}

/*

We need a dedicated algo. to do this
Can't use build in line drawing fn 
as we want the line to not be uniformly dark but look like pencil strokes,
Where if two lines intersect we get a darker point.

*/

void DDA_line_algo_weight_darken(int x0, int y0, int x1, int y1, PImage img)
{
  img.loadPixels();
  int dx = x1 - x0;
  int dy = y1 - y0;
  int steps = abs(dx) > abs(dy) ? abs(dx) : abs(dy);
  
  float xInc = dx / float(steps);
  float yInc = dy / float(steps);
  
  float x = x0;
  float y = y0;
  
  for (int i = 0; i < steps; i++)  // Every point of image on line joining (x0, y0) and (x1, y1) is darkened.
  { 
    float red = red(img.get(floor(x),floor(y)));
    if (red >= 55)
      img.set(round(x), round(y),color(red - 55));
    else
      img.set(round(x), round(y),color(red - 0));
    x = x + xInc;
    y = y + yInc;
  }
  img.updatePixels();

}
