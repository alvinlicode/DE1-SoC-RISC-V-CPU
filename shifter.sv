module shifter (in, shift, sout);
    input [15:0] in;
    input [1:0] shift;
    output [15:0] sout;

    reg [15:0] sout;

    always_comb begin

        case(shift) //changes sout based on shift value
        2'b00: sout = in; //no shift
        2'b01: sout = {{in[14:0]},1'b0}; //shift left with 0 bit added
        2'b10: sout = {1'b0, {in[15:1]}}; //shift right with 0 bit added
        2'b11: sout = {in[15], {in[15:1]}}; //shift right with last bit added back on
        default: sout = 16'bxxxxxxxxxxxxxxxx;
        endcase

    end

endmodule
