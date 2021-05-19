# Gyroscope

Hardware and software Platforms Project:
The aim of this project was to program in VHDL an FPGA using the DE0-NANO SoC Altera chip in order in order to read the values returned by a sensor connected on the FPGA. In our case the peripharal was a gyroscope and more precisely we used the L3GD20, a 3-axis gyroscope. 

In order to do this, we used the environement Quartus Prime 18.1 (version) to code the hardware language (VHDL). In order to drive a peripheral with the DE0-NANO SoC chip, we need a driver, to drive the peripheral and the bus between the FPGA and the device and we also need a program, (here named BLOC), in order to update the value measured by the sensor and to put it in register and to print it. You can see the link between the processor, the FPGA and the device/sensor on the figure 1.
![image](https://user-images.githubusercontent.com/84474292/118874632-69fdd400-b8eb-11eb-8465-97adf1436fb9.png)

