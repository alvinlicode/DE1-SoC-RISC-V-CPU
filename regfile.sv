module regfile (data_in, writenum, write, readnum, clk, data_out);
    input [15:0] data_in;
    input [2:0] writenum, readnum;
    input write, clk;
    output [15:0] data_out;

    wire [15:0] data_out;

    wire [7:0] writelocation = 1 << writenum; //3:8 decoder for writenum
    wire [7:0] readlocation = 1 << readnum; //3:8 decoder for readnum
    wire [15:0] R0, R1, R2, R3, R4, R5, R6, R7; //initialize the registers
    
    wire [7:0] load = {8{write}} & writelocation;

    vDFF_load_en #(16) reg0(clk, load[0], data_in, R0);
    vDFF_load_en #(16) reg1(clk, load[1], data_in, R1);
    vDFF_load_en #(16) reg2(clk, load[2], data_in, R2);
    vDFF_load_en #(16) reg3(clk, load[3], data_in, R3);
    vDFF_load_en #(16) reg4(clk, load[4], data_in, R4);
    vDFF_load_en #(16) reg5(clk, load[5], data_in, R5);
    vDFF_load_en #(16) reg6(clk, load[6], data_in, R6);
    vDFF_load_en #(16) reg7(clk, load[7], data_in, R7);
    //flip flops for each register when written to, controlled by the clk

    Mux8a regMux(R0, R1, R2, R3, R4, R5, R6, R7, readlocation, data_out);
    //Multiplexer for reading from a given register

endmodule

module vDFF_load_en (clk, en, in, out); //flip flop with load enable module 
    parameter n = 1;
    input clk, en;
    input [n-1:0] in;
    output [n-1:0] out;
    reg [n-1:0] out;
    wire [n-1:0] next_out;

    assign next_out = en ? in : out; //only lets out go through when en is logic high

    always_ff @(posedge clk) //updates output with rising clk edge
        out <= next_out;
    
endmodule

module Mux8a (a0,a1,a2,a3,a4,a5,a6,a7,s,b); //multiplexer module with one hot select for 8 options
    input [15:0] a0,a1,a2,a3,a4,a5,a6,a7;
    input [7:0] s;
    output [15:0] b;
    reg [15:0] b;

    always_comb begin //outputs based on s using one hot code
        case(s)
        8'b00000001: b = a0;
        8'b00000010: b = a1;
        8'b00000100: b = a2;
        8'b00001000: b = a3;
        8'b00010000: b = a4;
        8'b00100000: b = a5;
        8'b01000000: b = a6;
        8'b10000000: b = a7;
        default: b = {16{1'bx}};
        endcase
    end
endmodule