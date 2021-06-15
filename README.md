# Gyroscope
Contribution of Beatse Aurélie (181380@umons.ac.be) and Vidotto Benoît (172514@umons.ac.be), students in electrical engineering at the Faculty of Polytechnic of Mons (Umons link : https://web.umons.ac.be/fr/). This project was realized in the frame of the Hardware and Software Platforms course (2020-2021 academic year).   

## Code Files
The complete code folder is available in Gyro.zip. The version of the cleaned VHDLD project is available in soc_system.qar.

## Hardware and software Platforms Project:

The aim of this project was to program in VHDL an FPGA using the DE0-NANO SoC Altera chip in order to read the values returned by a sensor connected on the FPGA. In our case the peripharal was a gyroscope and more precisely we used the L3GD20, a 3-axis gyroscope. 

In order to do this, we used the environement Quartus Prime 18.1 (version) to code the hardware language (VHDL). In order to drive a peripheral with the DE0-NANO SoC chip, we need a driver, to drive the peripheral and the bus between the FPGA and the device and we also need a program, (here named BLOC), in order to update the value measured by the sensor and to put it in register and to print it. You can see the link between the processor, the FPGA and the device/sensor on the figure 1.

![image](https://user-images.githubusercontent.com/84474292/118874632-69fdd400-b8eb-11eb-8465-97adf1436fb9.png)

Figure 1


We began the project by the implementation of the I2C driver. We used the I2C driver VHDL code of Scott Larson, especially written for the use of FGPA's. This code is based on the FSM (Finite State Machine) of the I2C bus of the master. But, in order to understand well this code and to be able to then generate a good testbench of the driver, first we read the datasheet about our sensor and all the information about the I2C bus and protocol.

## I2C BUS and PROTOCOL:

The I2C bus is a half-duplex bidirectional synchronous serial bus. This means that all the devices interconnected to the bus can each in turn emit or receive data on the same bus. On the figure 2, you can see a microcontroller, connected to the I2C bus, which in this case is the master and then we have several slaves connected to the bus by two wires: SCL and SDA. We can also see a pull-up resistance which is needed if we want the slaves to be able to transmit their ACK when the master releases the bus.

![image](https://user-images.githubusercontent.com/84474292/118877318-98c97980-b8ee-11eb-9218-414f2be79eb3.png)

Figure 2


In the case of the L3GD20 gyroscope peripheral, we can only have two of these devices connected to the I2C bus because there is only 1 bit for the physical address of the device permitting to distinguish two gyroscopes from each other. On the Figure 2, you can see that there are 2 bits available to distinguish the devices so in practical there would be possible for this example to connect 4 devices. 
It is also important to notice that the microcontroller that we can see on the Figure 2 would be replaced by the FPGA in our case which is the master.

The I2C protocol is governed by state transitions and conditions. There are two big conditions which permit to initiate and to stop the I2C communication which are the START and the STOP conditions.  The START condition can be detected on the bus when the master drives the SDA signal from HIGH to LOW while the SCL signal is HIGH. On the other hand the STOP condition emitted at the end of the communication between the master and the slave, can be visualized on the bus when the master drives the SDA signal from LOW to HIGH when the SCL signal is HIGH. You can visualize these two conditions on the Figure 3.

![image](https://user-images.githubusercontent.com/84474292/118877454-c282a080-b8ee-11eb-8263-b3da68c9e28f.png)

Figure 3


After the start condition, the communication can be initiated and the data can be transferred but respecting certain conditions of transmission. The data must be transferred when they are stable which is the case on the HIGH state of the SCL signal. The value of the SDA must be updated then on the LOW state of the SCL signal. The data reading is done on the falling edge of the SCL signal. (see Figure 4)

![image](https://user-images.githubusercontent.com/84474292/118877721-0fff0d80-b8ef-11eb-9584-3ec30d43fe50.png)

Figure 4


The data can be transferred by byte (sequence of 8 bits) and then the receiver must send an ACK which is a zero acknowledge bit in order to tell that he has received the byte. In the case that the master is writing to the slave, after each byte the slave must send an ACK read by the master. You can see on the Figure 5 and Figure 6 the protocol of transfer on the I2C bus in this case concerning our L3GD20 gyroscope component.

When the master is reading from the slave, a single one byte, the master does not have to send an ACK, see Figure 7. However, if the master is reading multiple bytes from the slave, the master must send an ACK to the slave after each byte received in order to prevent the slave to send the next one and the register address in automatically incremented. But for the last byte of the multiple byte frame, the master does not have to send an ACK as in the case of single byte reading. The Figure 8 demonstrates a reading of multiple bytes of data by the master from the slave for a better comprehension.

![image](https://user-images.githubusercontent.com/84474292/118877851-37ee7100-b8ef-11eb-834e-832c9df42e20.png)

Figure 5


![image](https://user-images.githubusercontent.com/84474292/118877892-45a3f680-b8ef-11eb-8734-738811144a43.png)

Figure 6


![image](https://user-images.githubusercontent.com/84474292/118877930-50f72200-b8ef-11eb-965c-bb2c9b153fa3.png)

Figure 7


![image](https://user-images.githubusercontent.com/84474292/118877959-59e7f380-b8ef-11eb-8b66-bf84605893d3.png)

Figure 8


On the figures above, you can see that the address of the slave is always followed of a bit which can be equal to 0 or 1 depending if the master is going to read(1) or to write(0). If the master want to write to the slave, the last bit of the address of the slave will be a 0-bit and when the master want to do a reading from the slave the slave-address will be ended by a 1-bit. The way the address of the peripheral is structured is really important to understand. 

On the Figure 9, you can see the structure of the peripheral address. The complete address is composed of 8 bits with the last bit consecrated to the read/write function. Then, starting from the right, after the read/write bit, we have the bits which are used to distinguish the different peripherals on the bus. In function of the number of bits attributed for the distinction of device, it will fix the number of devices possible to connect on the I2C bus. As said before, with the L3GD20 gyroscope sensor, there is only 1 address-bit dedicated for the distinction of the devices, meaning that maximum 2 gyroscopes could be connected on the bus. Here the value of that bit is fixed at 1 for our device. Finally, the 6 left bits are fixed for one type of peripheral. For example, for the L3GD20 these bits are equal to “110101”. To resume, the command byte to send for a reading operation will be “11010111” and for a writing operation it will be “11010110”.

![image](https://user-images.githubusercontent.com/84474292/118878074-771cc200-b8ef-11eb-8b16-0df309359566.png)

Figure 9


The code of our I2C driver is based on the I2C finite-state machine (FSM) which is represented on the Figure 10. This FSM represents each state of the I2C transmission of the master. 

![image](https://user-images.githubusercontent.com/84474292/118878177-91ef3680-b8ef-11eb-8759-1ce5c7b8624b.png)

Figure 10 


## TESTBENCH I2C:
Simulation of signals with ModelSim Intel FPGA Starter Edition 10.5b

![image](https://user-images.githubusercontent.com/84474292/118880698-70dc1500-b8f2-11eb-8160-ddf8dc441639.png)

Figure 11


You can see on the Figure 11 the simulation of the I2C_driver_testbench VHDL code. We showed some signals like the SCL, SDA of the I2C bus, I2C_m_addr_wr, IC_m_data_wr. We can see on this screenshot the start condition of the I2C bus, we can also see that the I2C_m_addr_wr contained the value of the address of the device(L3GD20) and I2C_m_data_wr first contain the value of the CTRL_REG1 and then the value to enter in this register in order to activate the POWER mode of the peripheral and to enable the 3 axis of the gyroscope.

We can also see two signal state: the first one represents the state of the testbench of the I2C_driver needed to make a writing in the control register and then to make a reading of the 6 registers containing the values of the X-Y-Z axis. The second one signal named state is the one declared in the I2C VHDL code which represents the states of the I2C FSM of the transmission of the master.

![image](https://user-images.githubusercontent.com/84474292/118881589-8dc51800-b8f3-11eb-9ce4-695341d1ae24.png)

Figure 12


We can see here on Figure 12 the stop condition of the I2C bus and also the slave ACK.
we can also read the value on the SDA on the falling edge of the SCl signal and we can see that it corresponds to the value of the data_wr that the master writes to the slave.


Then, we implemented the program in VHDL which permit to update the values read by the sensor and to store them in 3 registers: REG1, REG2, REG3. We also did a testbench of the BLOC code and a simulation with Modelsim.

We know that we expect the values in the registers to be updated to 1 because we saw on the I2C test_bench that when the master was reading the data's returned by the slave, the values were always equal to 1 as you can see on the Figure 13.

![image](https://user-images.githubusercontent.com/84474292/118885943-a7b52980-b8f8-11eb-8265-0cc93e37a5da.png)

Figure 13


The Figure 14 shows the testbench of the BLOC :

![image](https://user-images.githubusercontent.com/84474292/118886237-f95db400-b8f8-11eb-8250-83a5870b29fc.png)

Figure 14


As predicted with the testbench of the I2C_driver, we can see that the register will be folded by 1-values. 

Finally, we had to implement the last part of the project which was the C_code to make the link between the hps/arm-processor and the FPGA and to print the values returned by the FPGA and the I2C bus. This code is available in the main.c.


## Programming the FGPA

To program the FPGA, we need to follow some steps. For this, we will need to use PuTTY, EDS shell and the Programmer tool in Quartus.

### 1st step is turning on the FPGA and obtaining the IP address : 
* Make sure that the board is connected to Ethernet, to the USB of the FPGA  (both ports ideally) of your computer and that your computer is also connected to internet (you may have to use a switch). Do not connect the power supply yet.
* In the 'Gestionnaire de périphériques', fetch the number COM of the board. For this, head to COM ports and pick the (probably) only one there.
* Open PuTTY, make sure that your in Serial Mode and not in SSH mode
* Enter your COM number and for speed 115200. (It coresponds to the UART baudrate)
* Once the console is opened, connect the power supply to the FPGA.
* For login, enter 'root', then fetch the IP address with the command 'udhcpc'.
![185836075_483187579674855_8464576346386183196_n](https://user-images.githubusercontent.com/81262129/118947703-e4643d80-b957-11eb-9e09-75d2a809d9ce.png)

### Quartus Programmer
* In Quartus, open Programmer (Tools>Programmer).
* Check in Hardware Setup that the FPGA is well detected. If not, make sure that the USB blaster is well connected.
* Press auto-detect.
* Add file 'soc_system.sof' in your project repository.
* You may have to delete the duplicates.
* Start and wait for completion.

### In EDS Shell
* Type 'cd ' and the path of your project's repository. Use "" if your path has spaces (accents are not supported either). You need to change the '\\' by '/'.
* Type 'make' to create your file (the name of the generated file is specified in main.c). For us, the generated file is called 'Gyroscope'.
* Type 'scp Gyroscope root@IP:/home/root'. The IP has been fetched in PuTTY.
* Default password is terasic.

### In PuTTY
* Final step, type 'ls' to check if 'Gyroscope' is present then './gyroscope'.

## YouTube video
Finally, you can find the tutorial video here.

[![IMAGE ALT TEXT HERE](https://img.youtube.com/vi/rdNWCPZHlRg/0.jpg)](https://www.youtube.com/watch?v=rdNWCPZHlRg)




