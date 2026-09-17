clear;
clc;


load("largeAoaArray.mat","aoaArray")
load("cuboidV1SatCDArray.mat","cdArray")
cdArray1 = abs(cdArray);
load("cuboidV2SatCDArray.mat","cdArray")
cdArray2 = abs(cdArray);
load("circularSatCDArray.mat","cdArray")
cdArray3 = abs(cdArray);

maxCDOne = max(cdArray1);
maxCDTwo = max(cdArray2);
maxCDThree = max(cdArray3);

cuboidCD = maxCDTwo;
cylindricalCD = maxCDThree;
