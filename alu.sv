module ALU (Ain, Bin, ALUop, out, status);
    input [15:0] Ain, Bin;
    input [1:0] ALUop;
    output [15:0] out;
    output [2:0] status;

    reg [15:0] out;
    reg [15:0] s;
    reg Z;

    reg V;
    reg N;
    reg sub;
    reg [2:0] status;

    AddSub #(16) ADD_SUB_OVF(Ain, Bin, sub, s, V);
    //instatiates AddSub for detecting overflow

    always_comb begin //Looks at ALUop to see which operations to perform

        case(ALUop)
        2'b00: out = Ain + Bin; //addition
        2'b01: out = Ain - Bin; //subtraction
        2'b10: out = Ain & Bin; //&
        2'b11: out = ~Bin; //~
        default: out = 16'bxxxxxxxxxxxxxxxx;
        endcase

        if (ALUop == 2'b01)
            sub = 1'b1;
        else
            sub = 1'b0;
        //sets sub to 1 if ALUop is 01 (for subtracting)

        if (out == 16'b0)
            Z = 1'b1;
        else
            Z = 1'b0;
        //outputs 1 to Z if out is 0, 0 to Z otherwise

        if (out[15] == 1'b1)
            N = 1'b1;
        else
            N = 1'b0;
        //outputs 1 to N if the msb of out is 1 (negative), 0 to N otherwise

        status = {Z, V, N};
        //contains the three status bits in one

    end

endmodule

module AddSub(a, b, sub, s, ovf); //uses multibit adders, adding or subtracting a and b, checking for overflow

    parameter n = 16;
    input [n-1:0] a, b;
    input sub;
    //adds normally, subtracts if sub = 1

    output [n-1:0] s;
    output ovf; //is 1 if overflow

    wire c1, c2; //carry out of last 2 bits
    wire ovf = c1 ^ c2; //xor, overflow if the signs are not the same

    //for adding the non-sign bits
    Adder2 #(n-1) ai(a[n-2:0], b[n-2:0] ^ {n-1{sub}}, sub, c1, s[n-2:0]);

    //for adding the sign bits
    Adder2 #(1) as(a[n-1], b[n-1] ^ sub, c1, c2, s[n-1]);

endmodule

module Adder2(a, b, cin, cout, s); //adder logic for multiple bits

    parameter n = 16;
    input [n-1:0] a, b;
    input cin;
    output [n-1:0] s;
    output cout;

    wire [n-1:0] p = a ^ b;
    wire [n-1:0] g = a & b;
    wire [n:0] c = {g | (p & c[n-1:0]), cin};
    wire [n-1:0] s = p ^ c[n-1:0];
    wire cout = c[n];

endmodule
