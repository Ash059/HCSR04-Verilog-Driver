# HCSR04-Verilog-Driver
An interface driver for the HCSR04 Ultrasonic Sensor, Written in Verilog.

All the counter ticks are Hardcoded assuming a 50 Mhz clock.  
60ms between each Trigger got better results as opposed to 12ms recommended by the datasheet.  
Available port:  
    input  clk,             // Assumed 50 Mhz  
    input  reset,           // active LOW reset  
    input  echo_rx,         // Echo port, to be connected to the echo pin on the HCSR04  
    output reg trig,        // Trig port, to be connected to the trig pin on the HCSR04  
    output op,              // Goes active if the reported distance is less than 70mm  
    output wire [15:0] distance_out   // 16bit distance reading in mm  
