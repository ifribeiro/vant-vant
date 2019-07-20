clc; clear all; close all; warning off;

%Tempo de simulação ms
tfin=20;
%Amostragem
To=0.1;
%Tempo
t= [0:To:tfin]; 
a=0.2;

%ks
k1 = 5;
k2 = 0.3;
k3 = 5.5;
k4 = 0.2;
k5 = 0.55;
k6 = 0.7;
k7 = 1.45;
k8 = 0.7;

kpx = 3;
kpy = 3;
kpz = 0.5;
kpphi = 3;
kdx = 2;
kdy = 2.5;
kdz = 2;
kdphi = 0.5;

%kp
kp = diag([kpx kpy kpz kpphi]);
%kd
kd = diag([kdx kdy kdz kdphi]);

%Formação desejada
Xd = transpose([2 1 1.5 0]);

%Formalção desejada
qdes = [2 1 1.5 1 0 0]';




%Condições iniciais
%Drone 1
x(1) = 0;
y(1) = 0;
z(1) = 0.75;
phi(1) = 0;

%Condições iniciais
%Drone 2
x2 = -2*ones(length(t), 1);
y2 = 1*ones(length(t), 1);
z2 = 0.75*ones(length(t),1);
phi2 = zeros(length(t),1);
phid = 0;

ganho = 0.4;

%
pos = zeros(3,length(t));

%%
%CONTROLADOR

for i=1: length(t)
    %trajetória
    %Xd = transpose([sin(0.5*t(k)) cos(0.5*t(k)) 0.5 0]);
    
    %Erros de controle
    X = transpose([x(i) y(i) z(i) phi(i)]);    
    Xtio = Xd - X;
    
    f1 = [k1*cos(phi(i)) -k3*sin(phi(i)) 0 0;...
          k1*sin(phi(i)) k3*cos(phi(i)) 0 0;...
          0 0 k5 0;...
          0 0 0 k7];
    
    U{i} = ((f1^-1)*(Xd*To + kp*(tanh(kd*Xtio))))*ganho;
           
    %Define a nova posicão do drone1
    x(i+1) = x(i)+To*U{i}(1);
    y(i+1) = y(i)+To*U{i}(2);
    z(i+1) = z(i)+To*U{i}(3);
    phi(i+1) = phi(i)+To*U{i}(4);
    
    
    %Pega a posicao atual do drone1
    pos(1,i) = x(i);
    pos(2,i) = y(i);
    pos(3,i) = z(i);
    
    %Controlador da formação
    xf = pos(1,i); % valor de x
    yf = pos(2,i); % valor de y
    zf = pos(3,i); % valor de z
    
    %Distancia entre os drones
    rhof = sqrt((x2(i) - pos(1,i))^2 + (y2(i) - pos(2,i))^2 + (z2(i) - pos(3,i))^2);    
    %alfaf
    alphaf =  atan2((y2(i) - pos(2,i)), (x2(i)-pos(1,i)));
    
    %betaf
    betaf = atan2((z2(i) - pos(3,i)),sqrt((x2(i) - pos(1,i))^2 + (y2(i) - pos(2,i))^2));
    %q
    q = [xf yf zf rhof betaf alphaf];
    
    qtil(:,i) = qdes - q';
    
    
    %Ganhos
    L1 = 0.2*eye(6);
    L2 = 0.4*eye(6);
    
    %Para a tarefa de posicionamento, qdesp = 0
    
    qrefp = L1*tanh(L2*qtil(:,i));
    %qRefPonto = L*tanh(inv(L)*kp*qTil(:,i));
    
    %qrefp = L1*tanh(inv(L1)*L2*qtil(:,i));
    
    
    
    
%     jacob = [ 1, 0, 0, 0, 0, 0; ...
%               0, 1, 0, 0, 0, 0; ...
%               0, 0, 1, 0, 0, 0; ...
%               1, 0, 0, cos(alphaf)*cos(betaf), -rhof*sin(alphaf)*cos(betaf), -rhof*cos(alphaf)*sin(betaf); ...
%               0, 1, 0, cos(betaf)*sin(alphaf), rhof*cos(alphaf)*cos(betaf),  -rhof*sin(alphaf)*sin(betaf); ...
%               0, 0, 1, sin(betaf), 0, rhof*cos(betaf)];


    jacob = [ 1, 0, 0, 0, 0, 0; ...
              0, 1, 0, 0, 0, 0; ...
              0, 0, 1, 0, 0, 0; ...
              1, 0, 0, cos(alphaf)*cos(betaf), -rhof*cos(alphaf)*sin(betaf), -rhof*cos(betaf)*sin(alphaf); ...
              0, 1, 0, cos(betaf)*sin(alphaf), -rhof*sin(alphaf)*sin(betaf),  rhof*cos(alphaf)*cos(betaf); ...
              0, 0, 1, sin(betaf), rhof*cos(betaf), 0];
          
    xrefp = jacob*qrefp;
    
    K = [cos(pos(3,i)) sin(pos(3,i)) 0 0 0 0; ...
         -sin(pos(3,i))/a cos(pos(3,i))/a 0 0 0 0; ...
         0 0 1 0 0 0; ...
         0 0 0 cos(phid) -sin(phid) 0; ...
         0 0 0 sin(phid) cos(phid) 0; ...
         0 0 0 0 0 1];
    
    v{i} = K*xrefp; 
    
    x2(i+1) = x2(i)+To*v{i}(4);
    y2(i+1) = y2(i)+To*v{i}(5);
    z2(i+1) = z2(i)+To*v{i}(6);
    phid = 0;
    
    
    
    
end

paso=2; axis 'equal'

H1 = plot3(x(1),y(1),z(1),'yo','LineWidth',2,'MarkerEdgeColor','k',...
        'MarkerFaceColor','y','MarkerSize',8);
H2 = plot3(x(1),y(1),z(1),'*m'); 

H1_D2 = plot3(x2(1), y2(1), z2(1), 'yo', 'LineWidth',2, 'MarkerEdgeColor','k','MarkerFaceColor','y','MarkerSize',8);
H2_D2 = plot3(x2(1),y2(1),z2(1),'*m'); hold on



for i=1:paso:length(t)
    
    %delete(Ho)
    delete(H1)
    delete(H2)
    
    delete(H1_D2)
    delete(H2_D2)
    
    axis([-4 4 -4 4 0 4]);  
    view([50.0,20.0]);
    H1 = plot3(x(i),y(i),z(i),'yo','LineWidth',1,'MarkerEdgeColor','k',...
        'MarkerFaceColor','y','MarkerSize',9);
    H2 = plot3(x(1:i),y(1:i),z(1:i) ,'--g');hold on
    
  
    H1_D2 = plot3(x2(i),y2(i),z2(i),'yo','LineWidth',1,'MarkerEdgeColor','k',...
        'MarkerFaceColor','y','MarkerSize',9);
    H2_D2 = plot3(x2(1:i),y2(1:i),z2(1:i) ,'--r');hold on
    
    
    grid on;
    pause(To)
end

