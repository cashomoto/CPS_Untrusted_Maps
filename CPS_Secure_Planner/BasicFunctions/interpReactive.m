%%%%Written by Alexander I. Ivanov - 2017%%%%
function [a,Q] = interpReactive(velocity)
persistent velData indexVels pp

%This function provides a smooth bound to the reactive set.
%A sigmoid function is used to provide a smooth, monotonic bound.
%Any smooth C2 function should work in theroy. In practice, monotinicity 
%enables fast solution. 

if isempty(indexVels)
   indexVels = linspace(.1,1.9,19);
   
   %The following data was taken from ellipseParams and was generated
   %by using the reactive controller, and
   %reactive_set_appx_differential_drive.m
   velData = [3.52941583241453e-10,-0.181575321007161,1.28000000995233e-06,0.000359216275074815;
       -9.00971393636468e-10,-0.169361248491611,2.56062479310254e-07,0.000943716823467047;
       -3.97540084259265e-10,-0.149623563025075,2.96045802517863e-07,0.00254285533931621;
       1.46506346096999e-10,-0.123844188206536,2.00892670652839e-06,0.00582479718882070;
       1.14936306769051e-10,-0.0948043967602374,8.19352569946257e-06,0.0110712226331336;
       -1.08466876505496e-09,-0.0593194602709969,3.95544717365427e-05,0.0198164538931231;
       -6.79499470912946e-10,-0.0193866203429560,0.000196504917537513,0.0326262945366763;
       1.46312839046293e-11,0.0250236300128605,6.40000000000321e-06,0.0508902388392306;
       5.92911030317535e-10,0.0786498261593462,0.00213969775637027,0.0776507759547518;
       1.60675208710616e-08,0.138126372920431,0.00617618268587879,0.114334432291792;
       -9.00064998921065e-10,0.220479277216832,0.0494064747829253,0.176807383272560;
       -3.45801261095076e-09,0.268057475038376,0.202148193699846,0.219081691624916;
       3.77071122702573e-08,0.334266259375488,0.268700658453067,0.285445284358851;
       -3.18869599117474e-08,0.369356152219121,0.343288038586703,0.324166618236438;
       7.02494695421303e-09,0.406139231222650,0.412846065905222,0.367405708963829;
       8.67608130588548e-09,0.434009312481233,0.490523301399586,0.401968738236303;
       -4.79565655927142e-08,0.464297203401451,0.570909961570336,0.441290958251584;
       -5.10105934820879e-10,0.496269572116941,0.643095906324830,0.484791498039827;
    0,0.5,0.65,0.5]*1.3; 

    pAy = zeros(1,4); %When looking at the data, notice that fist parameter is always 
                       %near zero. This is the result of symetry and the fact that the robot
                       %was pointed alg the x axis
    %Fit sigmoids to the provided data
    pAx = sigm_fit(indexVels,  velData(:,2)', [.000359216275074815, NaN,NaN,NaN],[],0);
    pQy = sigm_fit(indexVels,  velData(:,3)', [.000196504917537513,  NaN,NaN,NaN],[],0);
    pQx = sigm_fit(indexVels,  velData(:,4)', [.000359216275074815, NaN,NaN,NaN],[],0);
    
    pAy(1) = max(pAy(1),0);
    pAx(1) = max(pAx(1),0);
    pQy(1) = max(pQy(1),0);
    pQx(1) = max(pQx(1),0);
    pp = [pAx; pAy; pQx; pQy];
    
 

end


if(velocity<0)
    velocity =0;
end
if velocity > 1.9
   velocity = 1.9; 
end

interps(1) = sigmoid(velocity, pp(1,:));
interps(2) = sigmoid(velocity, pp(2,:));
interps(3) = sigmoid(velocity, pp(3,:));
interps(4) = sigmoid(velocity, pp(4,:));
a = interps(1:2)';
Q = diag(interps(3:4));


end