# Gyroscope

Hardware and software Platforms Project:

The aim of this project was to program in VHDL an FPGA using the DE0-NANO SoC Altera chip in order in order to read the values returned by a sensor connected on the FPGA. In our case the peripharal was a gyroscope and more precisely we used the L3GD20, a 3-axis gyroscope. 

In order to do this, we used the environement Quartus Prime 18.1 (version) to code the hardware language (VHDL). In order to drive a peripheral with the DE0-NANO SoC chip, we need a driver, to drive the peripheral and the bus between the FPGA and the device and we also need a program, (here named BLOC), in order to update the value measured by the sensor and to put it in register and to print it. You can see the link between the processor, the FPGA and the device/sensor on the figure 1.
![image](https://user-images.githubusercontent.com/84474292/118874632-69fdd400-b8eb-11eb-8465-97adf1436fb9.png)
Figure1
Figure3

After the start condition, the communication can be initiated and the data can be transferred but respecting certain conditions of transmission. The data must be transferred when they are stable which is the case on the HIGH state of the SCL signal. The value of the SDA must be updated then on the LOW state of the SCL signal. The data reading is done on the falling edge of the SCL signal.
![image](https://user-images.githubusercontent.com/84474292/118877554-e0500580-b8ee-11eb-813d-136da94b9e1f.png)

We began the project by the implementation of the I2C driver. We used the I2C driver VHDL code of Scott Larson, especially written for the use of FGPA's. This code is based on the FSM (Finite State Machine) of the I2C bus of the master. But, in order to understand well this code and to be able to then generate a good testbench of teh driver, first we read the datasheet about our sensor and all the information about the I2C bus and protocol.

I2C BUS and PROTOCOL:

The I2C bus is a half-duplex bidirectional synchronous serial bus. This means that all the devices interconnected to the bus can each in turn emit or receive data on the same bus. On the figure 2, you can see a microcontroller, connected to the I2C bus, which in this case is the master and then we have several slaves connected to the bus by two wires: SCL and SDA. We can also see a pull-up resistance which is needed if we want the slaves to be able to transmit their ACK when the master releases the bus.

![image](https://user-images.githubusercontent.com/84474292/118877318-98c97980-b8ee-11eb-9218-414f2be79eb3.png)
Figure2

In the case of the L3GD20 gyroscope peripheral, we can only have two of these devices connected to the I2C bus because there is only 1 bit for the physical address of the device permitting to distinguish two gyroscopes from each other. On the Figure 2, you can see that there are 2 bits available to distinguish the devices so in practical there would be possible for this example to connect 4 devices. 
It is also important to notice that the microcontroller that we can see on the Figure 2 would be replaced by the FPGA in our case which is the master.

The I2C protocol is governed by state transitions and conditions. There are two big conditions which permit to initiate and to stop the I2C communication which are the START and the STOP conditions.  The START condition can be detected on the bus when the master drives the SDA signal from HIGH to LOW while the SCL signal is HIGH. On the other hand the STOP condition emitted at the end of the communication between the master and the slave, can be visualize on the bus when the master drives the SDA signal from LOW to HIGH when the SCL signal is HIGH. You can visualize these two conditions on the Figure 3.
![image](https://user-images.githubusercontent.com/84474292/118877454-c282a080-b8ee-11eb-8263-b3da68c9e28f.png)
Figure3

After the start condition, the communication can be initiated and the data can be transferred but respecting certain conditions of transmission. The data must be transferred when they are stable which is the case on the HIGH state of the SCL signal. The value of the SDA must be updated then on the LOW state of the SCL signal. The data reading is done on the falling edge of the SCL signal. (see Figure 4)
![image](https://user-images.githubusercontent.com/84474292/118877721-0fff0d80-b8ef-11eb-9584-3ec30d43fe50.png)
Figure 4

The data can be transferred by byte (sequence of 8 bits) and then the receiver must send an ACK which is a zero acknowledge bit in order to tell that he has received the byte. In the case that the master is writing to the slave, after each byte the slave must send an ACK read by the master. You can see on the Figure 5 and Figure 6 the protocol of transfer on the I2C bus in this case concerning our L3GD20 gyroscope component.

When the master is reading from the slave, a single one byte, the master does not have to send an ACK, see Figure 7. However, if the master is reading multiple bytes from the slave, the master must send an ACK to the slave after each byte received in order to prevent the slave to send the next one and the register address in automatically incremented. But for the last byte of the multiple byte tram, the master does not have to send an ACK as in the case of single byte reading. The Figure 8 demonstrates a reading of multiple bytes of data by the master from the slave for a better comprehension.

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



