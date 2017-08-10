# Camera2LCDscreen
Reading OV7670 camera data using FPGA. Output on 7" LCD screen from Olinuxino 

FPGA: Intel Cyclone V SoC

Board: Terasic DE1-SoC

Linux: No

Used: GPIO_0 and GPIO_1 headers, LEDs, 7-segment displays for frames counting, onboard SDRAM for the frame buffer

Number of frame buffers: 1

Camera initialisation: using i2c module with FSM 


My modules: i2c, camera_init, camera reader, lcd writer, management.

Ready modules: SDRAM controller by Altera, DCFIFO megafunctions

SDRAM clock: 143 MHz

Camera clock: 25 MHz

LCD clock: 33 MHz

Camera resolution: 640x480@30fps

LCD resolution: 800x480@60fps
