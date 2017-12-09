%This code simulates a robot forward for 3 seconds using an MPC controller
global deltaT block K nx nu catXc controlIndex xStart xO rSafe
close all
T = 3;
deltaT = 0.1;
K = T/deltaT; %Number of time steps
nx = 5; %The state number [x,y, orientation, linear speed, angular speed]
nu = 2; %The number of controls [acceleration, turn rate]
rS = .8; %The sensed range of an obstacle (when should our controller activate?)
rSafe = .5;
ThetaS = pi/4; %The angular range we care about (roughly in front of us)

controlIndex = K*nx+1; %I concatinate states and controls, this is for convenience
xC = [0,0, -pi/2, 0, 0]'; %My referance point (the position I wnant to be close to)
xO = [0, rS]';            %The location of my obstacle

catXc = repmat(xC, K,1); 

R = [5 0 0 0 0;   %My state cost. Dont turn too much
    0 1 0 0 0;    %I don't care about the y so much
    0 0 1 0 0;     %How far off from the referance orientation is the robot?
    0 0 0 0 0;  %I don't care about velocities so they are 0
    0 0 0 0 0];

Q = [1 0; %%Control costs
    0 1];

terminal = blkdiag(40*eye(3), zeros(2)); %%This is a 'terminal cost'. 
                                          %How far away from the referance are you at the very end?

block = R;

for i=1:K-2;
    block = blkdiag(block, R); %Make script R
end

block = blkdiag(block, terminal);

for i=1:K-1;
    block = blkdiag(block, Q); %Add on script Q
end


nonlcon = @kinematicWrapper;
fun = @costWrapper;
A = [];
b = [];
Aeq = [];
beq = [];

xStart = [0,0,pi/2, 1, 0]'; %Where and how fast am I going?


%The optimizer needs a single vector. This is [x1, x2,....., u1,u2.....]
x0 = repmat(xStart, K,1);   %I neeed an initial guess of my trajecoty

x0 = vertcat(x0, zeros(nu*(K-1),1)); %An initial guess of my controls too

lb = zeros(nx*K+nu*(K-1),1);
ub = lb;
lb = lb-Inf; %What are the upper and lower bounds of my states and controls?
ub = ub+Inf;
lb(4:nx:end) = 0;
ub(controlIndex:2:end) = 2;  %%Bound the acceleration
lb(controlIndex:2:end) = -2;    
ub(controlIndex+1:2:end) = 1; %%Bound the turn rate
lb(controlIndex+1:2:end) = -1;


%Some options for the optimizer
opts = optimset('Display','iter','Algorithm','interior-point', 'MaxIter', 100000, 'MaxFunEvals', 100000);


%What will my controller do for a range of object detections? I assume
%the obstale will be detected at the edge of rS
sensLength = 2*cos(ThetaS);

nplot=5
objectOffset = linspace(-sensLength, sensLength, nplot)%I assume
                            %the obstale will be detected at the edge of rS

data = zeros(length(x0), 2*nplot);
hold on
for i=1:nplot
xO = [objectOffset(i), rS]';

%%Solve the thing
result = fmincon(fun,x0-.01*(rand(1)),A,b,Aeq,beq,lb,ub,nonlcon, opts);

[u,v] = pol2cart(result(3:nx:controlIndex-1-nx),result(4:nx:controlIndex-1-nx));

%%Plot the x,y solutions
quiver(result(1:nx:controlIndex-1-nx), result(2:nx:controlIndex-1-nx),u,v,'b');
axis([-1 1 -1 1])

plot(xO(1),xO(2),'rx')
viscircles(xO',rSafe) %How far away did the robot need to be from the obstacle? Plot this
data(:,i) = result;

end


%%An artifact of angle wrappin makes us only turn right. See what the
%%Robot will do if it only turns lefft 
xC = [0,0, 3*pi/2, 0, 0]'; %This is the same point as before!! (Line 14)
xO = [0, rS]';

catXc = repmat(xC, K,1);

for i=1:nplot
xO = [objectOffset(i), rS]';

result = fmincon(fun,x0-.01*(rand(1)),A,b,Aeq,beq,lb,ub,nonlcon, opts);

[u,v] = pol2cart(result(3:nx:controlIndex-1-nx),result(4:nx:controlIndex-1-nx));

quiver(result(1:nx:controlIndex-1-nx), result(2:nx:controlIndex-1-nx),u,v,'b');
axis([-1 1 -1 1])

plot(xO(1),xO(2),'rx')
viscircles(xO',rSafe)
data(:,i+nplot) = result;

end




%Now I want to fit an elipse to all of my trajectories and bound them

vectorized = [data(1:nx:controlIndex-1-nx,1), data(2:nx:controlIndex-1-nx,1)];
for i = 2:2*nplot
vectorized = vertcat(vectorized,[data(1:nx:controlIndex-1-nx,i), data(2:nx:controlIndex-1-nx,i)]);
end
hold off






global vectorized 


fun = @(x) x(3)+x(4);

A =[];
b = [];
lb = zeros(4,1);
ub = lb;
lb(1:2) = -Inf;
ub = ub+Inf;
x0 = [0,0,.1,.1];
nonlcon = @elliptic_cost;
Aeq = [];
beq = [];


elipseParams = fmincon(fun,x0,A,b,Aeq,beq,lb,ub,nonlcon, opts);

t = linspace(-pi,pi, 1000);
elipseX = cos(t);
elipseY = sin(t);

elipseCoord = horzcat(elipseX',elipseY');

Q = diag(sqrt(elipseParams(3:4)));

elipseCoord = elipseCoord*Q;

hold on 
plot(elipseCoord(:,1) + elipseParams(1), elipseCoord(:,2) + elipseParams(2),'g');
