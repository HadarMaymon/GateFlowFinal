#!/usr/bin/python
from PCA9685 import PCA9685
import time

Dir = [
    'forward',
    'backward',
]
pwm = PCA9685(0x40, debug=False)
pwm.setPWMFreq(50)

class MotorDriver():
    def __init__(self):
        # Motor A
        self.PWMA = 0
        self.AIN1 = 1
        self.AIN2 = 2
        # Motor B
        self.PWMB = 5
        self.BIN1 = 3
        self.BIN2 = 4

    def MotorRun(self, motor, index, speed):
        if speed > 100:
            return
        if(motor == 0):
            pwm.setDutycycle(self.PWMA, speed)
            if(index == Dir[0]):
                print("1")
                pwm.setLevel(self.AIN1, 0)
                pwm.setLevel(self.AIN2, 1)
            else:
                print("2")
                pwm.setLevel(self.AIN1, 1)
                pwm.setLevel(self.AIN2, 0)
        else:
            pwm.setDutycycle(self.PWMB, speed)
            if(index == Dir[0]):
                print("3")
                pwm.setLevel(self.BIN1, 0)
                pwm.setLevel(self.BIN2, 1)
            else:
                print("4")
                pwm.setLevel(self.BIN1, 1)
                pwm.setLevel(self.BIN2, 0)

    def MotorStop(self, motor):
        if (motor == 0):
            pwm.setDutycycle(self.PWMA, 0)
        else:
            pwm.setDutycycle(self.PWMB, 0)

def accountApproval():       
    Motor = MotorDriver()

   # Half rotation backward
    print("Half rotation backward 1 s")
    #Motor.MotorRun(0, 'backward', 2)
    Motor.MotorRun(1, 'backward', 10)
    time.sleep(0.10)  # Run backward for 0.15 seconds (half rotation)

    # Stop the motors
    print("Stop")
    #Motor.MotorStop(0)
    Motor.MotorStop(1)
    
    time.sleep(4)
    

     # First half rotation
    print("Half rotation forward 1 s")
    #Motor.MotorRun(0, 'forward', 2)
    Motor.MotorRun(1, 'forward', 10)
    time.sleep(0.10)  # Run forward for 0.15 seconds (half rotation)
     # Stop the motors
    print("Stop")
    #Motor.MotorStop(0)
    Motor.MotorStop(1)
# Call the function to test the motor driver
#accountApproval()

