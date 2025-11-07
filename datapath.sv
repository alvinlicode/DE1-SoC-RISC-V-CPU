module datapath(clk, readnum, vsel, loada, loadb, shift, asel, bsel, ALUop, loadc, loads, writenum, write, sximm8, Z, V, N, datapath_out, mdata, sximm5, PC);
//hello
    input [15:0] sximm8;
    input [2:0] writenum, readnum;
    input write, clk, asel, bsel, loada, loadb, loadc, loads;
    input [1:0] shift, ALUop;
    output [15:0] datapath_out;
    output Z;
    output V;
    output N;

    input [15:0] mdata, sximm5;
    input [7:0] PC;
    input [3:0] vsel;

    wire [15:0] datapath_out;
    wire [2:0] status_out;

    wire [15:0] data_out, sout, data_in, piperegA_out, in, Ain, Bin, out;
    wire [2:0] status;

    regfile REGFILE (.data_in(data_in), .writenum(writenum), .write(write), .readnum(readnum), .clk(clk), .data_out(data_out)); //instatiates regfile

    vDFF_load_en #(16) piperegA(clk, loada, data_out, piperegA_out);
    vDFF_load_en #(16) piperegB(clk, loadb, data_out, in);
    //flip flops with load enable for the pipeline registers A and B

    shifter SHIFTER (.in(in), .shift(shift), .sout(sout)); //shifter instantiation
    Mux2a muxA(piperegA_out, 16'b0, asel, Ain);
    Mux2a muxB(sout, sximm5, bsel, Bin);
    //two option multiplexer for asel and bsel

    ALU ALU(.Ain(Ain), .Bin(Bin), .ALUop(ALUop), .out(out), .status(status)); //ALU instatiation

    vDFF_load_en #(16) piperegC(clk, loadc, out, datapath_out);
    //flip flop with load enable for pipeline register C

    vDFF_load_en #(3) statusreg(clk,loads,status,status_out);
    //flip flop with load enable for status register

    assign Z = status_out[2];
    assign V = status_out[1];
    assign N = status_out[0];
    //assigns status bits from 3 bit status_out

    Mux4a writebackMux(datapath_out, {8'b0, PC}, sximm8, mdata, vsel, data_in);
    //four option multiplexer for writing back

endmodule

module Mux2a (a0,a1,s,b); //two option multiplexer that uses 1 bit selection
    input [15:0] a0,a1;
    input s;
    output [15:0] b;
    reg [15:0] b;

    always_comb begin //outputs selection based on 1 bit s
        case(s)
        1'b0: b = a0;
        1'b1: b = a1;
        default: b = {16{1'bx}};
        endcase
    end
endmodule

module Mux4a (a0,a1,a2,a3,s,b); //multiplexer module with one hot select for 4 options
    input [15:0] a0,a1,a2,a3;
    input [3:0] s;
    output [15:0] b;
    reg [15:0] b;

    always_comb begin //outputs based on s using one hot code
        case(s)
        4'b0001: b = a0;
        4'b0010: b = a1;
        4'b0100: b = a2;
        4'b1000: b = a3;
        default: b = {16{1'bx}};
        endcase
    end
endmodule