# TTK4115 Linear System theory lab
Represents the work of the contributors in the course Linear System Theory at NTNU.

### Plot plan:
lab1 - part1: plot with x and y reference with handflying. part 3: plots of interest with PD-controllers after test case.
lab2 - one plot with no integral states(with least RMS) and two with integral implemantation.
lab3 - rmse-values of each test(pillar-plot). pitch and elevation angles for test baseline, 6 and 8. Make sure the noisy signal(the estimate) is at the back for visibility.
lab4 - rmse-values of each test(pillar-plot). pitch and elevation angles for interesting tests(based on rmse). make sure the noisy signal is at the back for visibility.


### Test plan:

IMU characteristics, all measurements, including ENC, forces from IMU, calculations of states(Luenberger): p, p_dot, e, e_dot, t, t_dot, perhaps combine with test below.

Transformations: difference using euler_angles and encoder values(Luenberger)

minimum viable states: e and lambda_dot.

all tests for lab4.
