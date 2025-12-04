//#*********************************************************************************************************************/
//# Software       : TSMC MEMORY COMPILER tsn28hpcpuhddpsram_2012.02.00.d.170a						*/
//# Technology     : TSMC 28nm CMOS LOGIC High Performance Compact Mobile 1P10M HKMG CU_ELK 0.9V				*/
//# Memory Type    : TSMC 28nm High Performance Compact Mobile Ultra High Density Dual Port SRAM with d127 bit cell SVT Periphery */
//# Library Name   : tsdn28hpcpuhdb512x128m4m (user specify : TSDN28HPCPUHDB512X128M4M)				*/
//# Library Version: 170a												*/
//# Generated Time : 2024/01/10, 17:23:40										*/
//#*********************************************************************************************************************/
//#															*/
//# STATEMENT OF USE													*/
//#															*/
//# This information contains confidential and proprietary information of TSMC.					*/
//# No part of this information may be reproduced, transmitted, transcribed,						*/
//# stored in a retrieval system, or translated into any human or computer						*/
//# language, in any form or by any means, electronic, mechanical, magnetic,						*/
//# optical, chemical, manual, or otherwise, without the prior written permission					*/
//# of TSMC. This information was prepared for informational purpose and is for					*/
//# use by TSMC's customers only. TSMC reserves the right to make changes in the					*/
//# information at any time and without notice.									*/
//#															*/
//#*********************************************************************************************************************/
//* Template Version : S_05_41901                                               */
//****************************************************************************** */
`resetall
`celldefine

`timescale 1ns/1ps

module TSDN28HPCPUHDB512X128M4M (
            CLK, 
	    CEBA, WEBA, CEBB, WEBB,
            AA, DA, AB, DB,
            RTSEL,
            WTSEL,
            PTSEL,
            QA, QB);

parameter numWord = 512;
parameter numBit = 128;
parameter numWordAddr = 9;

//=== IO Ports ===//
// Normal Mode Input
input CLK;
input CEBA, CEBB;
input WEBA, WEBB;

input [numWordAddr-1:0] AA, AB;
input [numBit-1:0] DA, DB;

// BIST Mode Input

// Test Mode
input [1:0] RTSEL;
input [1:0] WTSEL;
input [1:0] PTSEL;

// Data Output
output [numBit-1:0] QA, QB;


//=== Data Structure ===//
wire [numBit-1:0] QA_bistx;
wire [numBit-1:0] QB_bistx;
wire [numBit-1:0] QA_tmp;
wire [numBit-1:0] QB_tmp;
wire [numBit-1:0] QA_ram;
wire [numBit-1:0] QB_ram;

wire [numWordAddr-1:0] iAA = AA;
wire [numWordAddr-1:0] iAB = AB;
wire iCEBA = CEBA;
wire iCEBB = CEBB;
wire iWEBA = WEBA;
wire iWEBB = WEBB;
wire [numBit-1:0] iDA = DA;
wire [numBit-1:0] iDB = DB;

//=== Operation ===//
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO0 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[0],
	iDB[0],
	QA_ram[0],
	QB_ram[0]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO1 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[1],
	iDB[1],
	QA_ram[1],
	QB_ram[1]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO2 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[2],
	iDB[2],
	QA_ram[2],
	QB_ram[2]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO3 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[3],
	iDB[3],
	QA_ram[3],
	QB_ram[3]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO4 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[4],
	iDB[4],
	QA_ram[4],
	QB_ram[4]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO5 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[5],
	iDB[5],
	QA_ram[5],
	QB_ram[5]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO6 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[6],
	iDB[6],
	QA_ram[6],
	QB_ram[6]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO7 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[7],
	iDB[7],
	QA_ram[7],
	QB_ram[7]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO8 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[8],
	iDB[8],
	QA_ram[8],
	QB_ram[8]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO9 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[9],
	iDB[9],
	QA_ram[9],
	QB_ram[9]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO10 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[10],
	iDB[10],
	QA_ram[10],
	QB_ram[10]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO11 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[11],
	iDB[11],
	QA_ram[11],
	QB_ram[11]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO12 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[12],
	iDB[12],
	QA_ram[12],
	QB_ram[12]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO13 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[13],
	iDB[13],
	QA_ram[13],
	QB_ram[13]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO14 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[14],
	iDB[14],
	QA_ram[14],
	QB_ram[14]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO15 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[15],
	iDB[15],
	QA_ram[15],
	QB_ram[15]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO16 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[16],
	iDB[16],
	QA_ram[16],
	QB_ram[16]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO17 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[17],
	iDB[17],
	QA_ram[17],
	QB_ram[17]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO18 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[18],
	iDB[18],
	QA_ram[18],
	QB_ram[18]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO19 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[19],
	iDB[19],
	QA_ram[19],
	QB_ram[19]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO20 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[20],
	iDB[20],
	QA_ram[20],
	QB_ram[20]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO21 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[21],
	iDB[21],
	QA_ram[21],
	QB_ram[21]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO22 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[22],
	iDB[22],
	QA_ram[22],
	QB_ram[22]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO23 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[23],
	iDB[23],
	QA_ram[23],
	QB_ram[23]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO24 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[24],
	iDB[24],
	QA_ram[24],
	QB_ram[24]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO25 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[25],
	iDB[25],
	QA_ram[25],
	QB_ram[25]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO26 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[26],
	iDB[26],
	QA_ram[26],
	QB_ram[26]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO27 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[27],
	iDB[27],
	QA_ram[27],
	QB_ram[27]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO28 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[28],
	iDB[28],
	QA_ram[28],
	QB_ram[28]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO29 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[29],
	iDB[29],
	QA_ram[29],
	QB_ram[29]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO30 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[30],
	iDB[30],
	QA_ram[30],
	QB_ram[30]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO31 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[31],
	iDB[31],
	QA_ram[31],
	QB_ram[31]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO32 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[32],
	iDB[32],
	QA_ram[32],
	QB_ram[32]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO33 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[33],
	iDB[33],
	QA_ram[33],
	QB_ram[33]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO34 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[34],
	iDB[34],
	QA_ram[34],
	QB_ram[34]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO35 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[35],
	iDB[35],
	QA_ram[35],
	QB_ram[35]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO36 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[36],
	iDB[36],
	QA_ram[36],
	QB_ram[36]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO37 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[37],
	iDB[37],
	QA_ram[37],
	QB_ram[37]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO38 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[38],
	iDB[38],
	QA_ram[38],
	QB_ram[38]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO39 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[39],
	iDB[39],
	QA_ram[39],
	QB_ram[39]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO40 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[40],
	iDB[40],
	QA_ram[40],
	QB_ram[40]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO41 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[41],
	iDB[41],
	QA_ram[41],
	QB_ram[41]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO42 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[42],
	iDB[42],
	QA_ram[42],
	QB_ram[42]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO43 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[43],
	iDB[43],
	QA_ram[43],
	QB_ram[43]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO44 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[44],
	iDB[44],
	QA_ram[44],
	QB_ram[44]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO45 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[45],
	iDB[45],
	QA_ram[45],
	QB_ram[45]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO46 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[46],
	iDB[46],
	QA_ram[46],
	QB_ram[46]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO47 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[47],
	iDB[47],
	QA_ram[47],
	QB_ram[47]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO48 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[48],
	iDB[48],
	QA_ram[48],
	QB_ram[48]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO49 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[49],
	iDB[49],
	QA_ram[49],
	QB_ram[49]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO50 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[50],
	iDB[50],
	QA_ram[50],
	QB_ram[50]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO51 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[51],
	iDB[51],
	QA_ram[51],
	QB_ram[51]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO52 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[52],
	iDB[52],
	QA_ram[52],
	QB_ram[52]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO53 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[53],
	iDB[53],
	QA_ram[53],
	QB_ram[53]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO54 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[54],
	iDB[54],
	QA_ram[54],
	QB_ram[54]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO55 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[55],
	iDB[55],
	QA_ram[55],
	QB_ram[55]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO56 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[56],
	iDB[56],
	QA_ram[56],
	QB_ram[56]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO57 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[57],
	iDB[57],
	QA_ram[57],
	QB_ram[57]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO58 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[58],
	iDB[58],
	QA_ram[58],
	QB_ram[58]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO59 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[59],
	iDB[59],
	QA_ram[59],
	QB_ram[59]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO60 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[60],
	iDB[60],
	QA_ram[60],
	QB_ram[60]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO61 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[61],
	iDB[61],
	QA_ram[61],
	QB_ram[61]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO62 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[62],
	iDB[62],
	QA_ram[62],
	QB_ram[62]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO63 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[63],
	iDB[63],
	QA_ram[63],
	QB_ram[63]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO64 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[64],
	iDB[64],
	QA_ram[64],
	QB_ram[64]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO65 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[65],
	iDB[65],
	QA_ram[65],
	QB_ram[65]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO66 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[66],
	iDB[66],
	QA_ram[66],
	QB_ram[66]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO67 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[67],
	iDB[67],
	QA_ram[67],
	QB_ram[67]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO68 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[68],
	iDB[68],
	QA_ram[68],
	QB_ram[68]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO69 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[69],
	iDB[69],
	QA_ram[69],
	QB_ram[69]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO70 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[70],
	iDB[70],
	QA_ram[70],
	QB_ram[70]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO71 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[71],
	iDB[71],
	QA_ram[71],
	QB_ram[71]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO72 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[72],
	iDB[72],
	QA_ram[72],
	QB_ram[72]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO73 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[73],
	iDB[73],
	QA_ram[73],
	QB_ram[73]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO74 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[74],
	iDB[74],
	QA_ram[74],
	QB_ram[74]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO75 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[75],
	iDB[75],
	QA_ram[75],
	QB_ram[75]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO76 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[76],
	iDB[76],
	QA_ram[76],
	QB_ram[76]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO77 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[77],
	iDB[77],
	QA_ram[77],
	QB_ram[77]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO78 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[78],
	iDB[78],
	QA_ram[78],
	QB_ram[78]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO79 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[79],
	iDB[79],
	QA_ram[79],
	QB_ram[79]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO80 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[80],
	iDB[80],
	QA_ram[80],
	QB_ram[80]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO81 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[81],
	iDB[81],
	QA_ram[81],
	QB_ram[81]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO82 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[82],
	iDB[82],
	QA_ram[82],
	QB_ram[82]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO83 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[83],
	iDB[83],
	QA_ram[83],
	QB_ram[83]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO84 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[84],
	iDB[84],
	QA_ram[84],
	QB_ram[84]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO85 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[85],
	iDB[85],
	QA_ram[85],
	QB_ram[85]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO86 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[86],
	iDB[86],
	QA_ram[86],
	QB_ram[86]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO87 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[87],
	iDB[87],
	QA_ram[87],
	QB_ram[87]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO88 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[88],
	iDB[88],
	QA_ram[88],
	QB_ram[88]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO89 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[89],
	iDB[89],
	QA_ram[89],
	QB_ram[89]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO90 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[90],
	iDB[90],
	QA_ram[90],
	QB_ram[90]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO91 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[91],
	iDB[91],
	QA_ram[91],
	QB_ram[91]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO92 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[92],
	iDB[92],
	QA_ram[92],
	QB_ram[92]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO93 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[93],
	iDB[93],
	QA_ram[93],
	QB_ram[93]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO94 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[94],
	iDB[94],
	QA_ram[94],
	QB_ram[94]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO95 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[95],
	iDB[95],
	QA_ram[95],
	QB_ram[95]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO96 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[96],
	iDB[96],
	QA_ram[96],
	QB_ram[96]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO97 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[97],
	iDB[97],
	QA_ram[97],
	QB_ram[97]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO98 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[98],
	iDB[98],
	QA_ram[98],
	QB_ram[98]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO99 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[99],
	iDB[99],
	QA_ram[99],
	QB_ram[99]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO100 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[100],
	iDB[100],
	QA_ram[100],
	QB_ram[100]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO101 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[101],
	iDB[101],
	QA_ram[101],
	QB_ram[101]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO102 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[102],
	iDB[102],
	QA_ram[102],
	QB_ram[102]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO103 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[103],
	iDB[103],
	QA_ram[103],
	QB_ram[103]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO104 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[104],
	iDB[104],
	QA_ram[104],
	QB_ram[104]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO105 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[105],
	iDB[105],
	QA_ram[105],
	QB_ram[105]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO106 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[106],
	iDB[106],
	QA_ram[106],
	QB_ram[106]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO107 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[107],
	iDB[107],
	QA_ram[107],
	QB_ram[107]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO108 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[108],
	iDB[108],
	QA_ram[108],
	QB_ram[108]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO109 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[109],
	iDB[109],
	QA_ram[109],
	QB_ram[109]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO110 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[110],
	iDB[110],
	QA_ram[110],
	QB_ram[110]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO111 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[111],
	iDB[111],
	QA_ram[111],
	QB_ram[111]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO112 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[112],
	iDB[112],
	QA_ram[112],
	QB_ram[112]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO113 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[113],
	iDB[113],
	QA_ram[113],
	QB_ram[113]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO114 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[114],
	iDB[114],
	QA_ram[114],
	QB_ram[114]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO115 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[115],
	iDB[115],
	QA_ram[115],
	QB_ram[115]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO116 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[116],
	iDB[116],
	QA_ram[116],
	QB_ram[116]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO117 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[117],
	iDB[117],
	QA_ram[117],
	QB_ram[117]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO118 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[118],
	iDB[118],
	QA_ram[118],
	QB_ram[118]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO119 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[119],
	iDB[119],
	QA_ram[119],
	QB_ram[119]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO120 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[120],
	iDB[120],
	QA_ram[120],
	QB_ram[120]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO121 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[121],
	iDB[121],
	QA_ram[121],
	QB_ram[121]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO122 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[122],
	iDB[122],
	QA_ram[122],
	QB_ram[122]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO123 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[123],
	iDB[123],
	QA_ram[123],
	QB_ram[123]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO124 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[124],
	iDB[124],
	QA_ram[124],
	QB_ram[124]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO125 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[125],
	iDB[125],
	QA_ram[125],
	QB_ram[125]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO126 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[126],
	iDB[126],
	QA_ram[126],
	QB_ram[126]);
TSDN28HPCPUHDB512X128M4M_RAM_1bit sram_IO127 (
	CLK,
	iCEBA,
	iCEBB,
	iWEBA,
	iWEBB,
	iAA,
	iAB,
	iDA[127],
	iDB[127],
	QA_ram[127],
	QB_ram[127]);

wire power_down = 1'b0;

//  QA bypass
assign QA_tmp = QA_ram;
assign QA_bistx = QA_tmp;
//  Output QA
assign QA = power_down ? {numBit{1'b0}} : QA_bistx;

//  QB bypass
assign QB_tmp = QB_ram;
assign QB_bistx = QB_tmp;
//  Output QB
assign QB = power_down ? {numBit{1'b0}} : QB_bistx;

endmodule



// 1 bit SRAM 
module TSDN28HPCPUHDB512X128M4M_RAM_1bit (
	CLK_i,
	CEBA_i,
	CEBB_i,
	WEBA_i,
	WEBB_i,
	AA_i,
	AB_i,
	DA_i,
	DB_i,
	QA_i,
	QB_i);

parameter numWord = 512;
parameter numWordAddr = 9;

input CLK_i;
input CEBA_i;
input CEBB_i;
input WEBA_i;
input WEBB_i;
input [numWordAddr-1:0] AA_i, AB_i;
input DA_i, DB_i;

output QA_i, QB_i;

reg QA_i, QB_i;
reg MEMORY [numWord-1:0];

wire WBA, WBB, RBA, RBB;
wire [numWordAddr-1:0] AcomB;
wire AeqB, sc_AwBw;
event WRITE_A;

//---- compare AA to AB
xor u_comAddr0 (AcomB[0], AA_i[0], AB_i[0]);
xor u_comAddr1 (AcomB[1], AA_i[1], AB_i[1]);
xor u_comAddr2 (AcomB[2], AA_i[2], AB_i[2]);
xor u_comAddr3 (AcomB[3], AA_i[3], AB_i[3]);
xor u_comAddr4 (AcomB[4], AA_i[4], AB_i[4]);
xor u_comAddr5 (AcomB[5], AA_i[5], AB_i[5]);
xor u_comAddr6 (AcomB[6], AA_i[6], AB_i[6]);
xor u_comAddr7 (AcomB[7], AA_i[7], AB_i[7]);
xor u_comAddr8 (AcomB[8], AA_i[8], AB_i[8]);
nor u_eqA (AeqB, AcomB[0], AcomB[1], AcomB[2], AcomB[3], AcomB[4], AcomB[5], AcomB[6], AcomB[7], AcomB[8]);
and u_con_AwBw (sc_AwBw, AeqB, WBB);

// Write Mode
and u_wa_0 (	WBA,
		!sc_AwBw,
		!WEBA_i,
		!CEBA_i) ;

and u_wb_0 (	WBB,
		!WEBB_i,
		!CEBB_i) ;



always @ (posedge CLK_i)
  if (WBA) begin
    MEMORY[AA_i] = DA_i;
    #0; -> WRITE_A;
  end

always @(posedge CLK_i)
  if (WBB) begin
    MEMORY[AB_i] = DB_i;
  end

// READ Mode
and u_ra_0 (	RBA,
		WEBA_i,
		!CEBA_i) ;

and u_rb_0 (	RBB,
		WEBB_i,
		!CEBB_i) ;

always @(posedge CLK_i)
  if (RBA) begin
    QA_i = MEMORY[AA_i];
  end

always @(CLK_i or RBB or AB_i or WRITE_A)
  if (CLK_i && RBB) begin
    QB_i = MEMORY[AB_i];
  end

endmodule
`endcelldefine
