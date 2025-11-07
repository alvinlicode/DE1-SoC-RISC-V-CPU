module cpu(clk,reset, mdata,in,out,N,V,Z, mem_addr, mem_cmd); //hello
    input clk, reset;
    input [15:0] in, mdata;
    output [15:0] out;
    output  N, V, Z;

    output [8:0] mem_addr;
    output reg [1:0] mem_cmd;

    wire [15:0] out;
    wire  N, V, Z;

    wire [15:0] register_out, sximm8, sximm5;
    wire [7:0] PC;
    wire [3:0] vsel;
    wire [2:0] nsel, opcode, Rn, Rd, Rm, readnum, writenum;
    wire [1:0] op, ALUop, shift;
    wire loada, loadb, loadc, loads, write, asel, bsel;

    wire [8:0] next_pc, added_pc, da_out, pc_out;
    wire reset_pc, load_pc, addr_sel, load_ir;
    
    assign PC = pc_out; 

    //load_pc MUX and Program Counter
    assign added_pc = pc_out + 9'b000000001;
    assign next_pc = reset_pc ? 9'b000000000 : added_pc;
    vDFF_load_en #(9) PROGRAM_COUNTER(clk, load_pc, next_pc, pc_out);

    //data address and addr_sel MUX
    assign mem_addr = addr_sel ? pc_out :  da_out;
    vDFF_load_en #(9) DATA_ADDRESS(clk, load_addr, out[8:0], da_out);

    vDFF_load_en #(16) instructions(clk, load_ir, in, register_out);

    //nsel from state machine
    decoder DECODER(register_out, nsel, opcode, ALUop, op, sximm8, sximm5, shift, readnum, writenum);

    state_machine STATE_MACHINE(clk, reset, op, opcode, vsel, nsel, loada, loadb, loadc, loads, write, asel, bsel, reset_pc, load_pc, addr_sel, load_ir, mem_cmd, load_addr);

    datapath DP(clk, readnum, vsel, loada, loadb, shift, asel, bsel, ALUop, loadc, loads, writenum, write, sximm8, Z, V, N, out, mdata, sximm5, PC);

endmodule



module decoder(register_out, nsel, opcode, ALUop, op, sximm8, sximm5, shift, readnum, writenum);
    input [15:0] register_out;
    input [2:0] nsel;

    output reg [1:0] ALUop, op;
    output reg [2:0] opcode;
    output reg [2:0] readnum;
    output reg [2:0] writenum;
    output reg [1:0] shift;
    output reg [15:0] sximm8;
    output reg [15:0] sximm5;


    reg [7:0] imm8;
    reg [4:0] imm5;
    reg [2:0] Rn, Rd, Rm;

    always_comb begin
        // opcode 15:13
        opcode = register_out[15:13];
        // op 12:11
        op = register_out[12:11];
        // ALUop 10:9
        ALUop = register_out[12:11];
        // Rn 10:8
        Rn = register_out[10:8];
        // Rd 7:5 
        Rd = register_out[7:5];
        // shift 4:3
        shift = register_out[4:3];
        // Rm 2:0
        Rm = register_out[2:0];

        // sximm5, from [4:0] imm5 -> convert to 16 bits
        imm8 = register_out[7:0];
        imm5 = register_out[4:0];
        sximm8 = {{8{imm8[7]}}, imm8};
        sximm5 = {{11{imm5[4]}}, imm5};

        // readnum or writenum, determined by nsel one-hot
        case (nsel)
        3'b001: begin
            readnum = Rn;
            writenum = Rn;
        end
        3'b010: begin
            readnum = Rd;
            writenum = Rd;
        end
        3'b100: begin
            readnum = Rm;
            writenum = Rm;
        end
        default: begin
            readnum = 3'b000;
            writenum = 3'b000;
        end
        endcase
    end
endmodule




`define IF1           6'b000000
`define decode        6'b000001
`define two           6'b000010
`define three         6'b000011
`define four          6'b000100
`define five          6'b000101
`define six           6'b000110
`define seven         6'b000111
`define eight         6'b001000
`define nine          6'b001001
`define ten           6'b001010
`define eleven        6'b001011
`define twelve        6'b001100
`define thirteen      6'b001101
`define fourteen      6'b001110
`define fifteen       6'b001111
`define sixteen       6'b010000
`define seventeen     6'b010001
`define eighteen      6'b010010
`define nineteen      6'b010011
`define update_pc     6'b010100
`define IF2           6'b010101
`define RST           6'b010110
`define HALT          6'b010111
`define twenty        6'b100000
`define twenty_one    6'b011000
`define twenty_two    6'b011001
`define twenty_three  6'b011010
`define twenty_four   6'b011011
`define twenty_five   6'b011100
`define twenty_six    6'b011101
`define twenty_seven  6'b011110
`define twenty_eight  6'b011111
`define twenty_nine   6'b111111

`define MREAD 2'b01
`define MWRITE 2'b10
`define MNONE 2'b00


module state_machine(clk, rst, op, opcode, vsel, nsel, loada, loadb, loadc, loads, write, asel, bsel, reset_pc, load_pc, addr_sel, load_ir, mem_cmd, load_addr);
    input rst, clk;
    input [2:0] opcode;
    input [1:0] op;

    output reg [3:0] vsel;
    output reg [2:0] nsel;
    output reg loada, loadb, loadc, loads, write, asel, bsel;

    output reg reset_pc, load_pc, addr_sel, load_ir, load_addr; //new lab7 variables
    output reg [1:0] mem_cmd;


    reg [5:0] present_state;

    always_ff @(posedge clk) begin

        if (rst) begin
	
	        present_state = `RST;
	
	    end else begin

            case(present_state)
            `RST: present_state = `IF1;
            `IF1: present_state = `IF2;
            `IF2: present_state = `update_pc;
            `update_pc: present_state = `decode;

            `decode: begin //decode state, determines which path based on opcode and op
                if ({opcode, op} == {3'b110, 2'b10})
                    present_state = `two;
                else if ({opcode, op} == {3'b110, 2'b00})
                    present_state = `three;
                else if ({opcode, op} == {3'b101, 2'b00})
                    present_state = `six;
                else if ({opcode, op} == {3'b101, 2'b01})
                    present_state = `ten;
                else if ({opcode, op} == {3'b101, 2'b10})
                    present_state = `thirteen;
                else if ({opcode, op} == {3'b101, 2'b11})
                    present_state = `seventeen;
                else if ({opcode, op} == {3'b011, 2'b00})
                    present_state = `twenty;
                else if ({opcode, op} == {3'b100, 2'b00})
                    present_state = `twenty_four;
                else if ({opcode, op} == {3'b111, 2'bxx})
                    present_state = `HALT;
                else
                    present_state = `IF1;
            end

            `two: present_state = `IF1;

            `three: present_state = `four;
            `four: present_state = `five;
            `five: present_state = `IF1;

            `six: present_state = `seven;
            `seven: present_state = `eight;
            `eight: present_state = `nine;
            `nine: present_state = `IF1;

            `ten: present_state = `eleven;
            `eleven: present_state = `twelve;
            `twelve: present_state = `IF1;

            `thirteen: present_state = `fourteen;
            `fourteen: present_state = `fifteen;
            `fifteen: present_state = `sixteen;
            `sixteen: present_state = `IF1;

            `seventeen: present_state = `eighteen;
            `eighteen: present_state = `nineteen;
            `nineteen: present_state = `IF1;

            `twenty: present_state = `twenty_one;
            `twenty_one: present_state = `twenty_two;
            `twenty_two: present_state = `twenty_three;
            `twenty_three: present_state = `twenty_nine;
            `twenty_nine: present_state = `IF1;

            `twenty_four: present_state = `twenty_five;
            `twenty_five: present_state = `twenty_six;
            `twenty_six: present_state = `twenty_seven;
            `twenty_seven: present_state = `twenty_eight;
            `twenty_eight: present_state = `IF1;
            //state transitions with no coniditions (paths for each operation)



            default: present_state = `IF1; //default state is the IF1 state
            endcase

        end

    end


    always_comb begin
        //decode stage
        case(present_state)
            `RST: begin
                vsel = 4'b0000; nsel = 3'b000; loada = 1'b0; loadb = 1'b0; loadc = 1'b0; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b1; load_pc = 1'b1; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `IF1: begin //IF1 state
                vsel = 4'b0000; nsel = 3'b000; loada = 1'b0; loadb = 1'b0; loadc = 1'b0; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b1; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b01;
            end
            `IF2: begin
                vsel = 4'b0000; nsel = 3'b000; loada = 1'b0; loadb = 1'b0; loadc = 1'b0; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b1; load_ir = 1'b1; load_addr = 1'b0; mem_cmd = 2'b01;
            end
            `update_pc: begin
                vsel = 4'b0000; nsel = 3'b000; loada = 1'b0; loadb = 1'b0; loadc = 1'b0; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b1; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `decode: begin //decoder output
                vsel = 4'b0001; nsel = 3'b001; loada = 1'b0; loadb = 1'b0; loadc = 1'b0; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `two: begin //writing sximm8 into reg A
                vsel = 4'b0100; nsel = 3'b001; loada = 1'b0; loadb = 1'b0; loadc = 1'b0; write = 1'b1; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `three: begin //loading Rm into b
                vsel = 4'b0000; nsel = 3'b100; loada = 1'b0; loadb = 1'b1; loadc = 1'b0; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `four: begin //Shifting Rm
                vsel = 4'b0000; nsel = 3'b000; loada = 1'b0; loadb = 1'b0; loadc = 1'b1; write = 1'b0; asel = 1'b1; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `five: begin //Writing Rm into Rd
                vsel = 4'b0001; nsel = 3'b010; loada = 1'b0; loadb = 1'b0; loadc = 1'b0; write = 1'b1; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `six: begin //loading Rn into A
                vsel = 4'b0000; nsel = 3'b001; loada = 1'b1; loadb = 1'b0; loadc = 1'b0; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `seven: begin //loading Rn into A
                vsel = 4'b0000; nsel = 3'b100; loada = 1'b0; loadb = 1'b1; loadc = 1'b0; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `eight: begin //Rn + sh_Rm
                vsel = 4'b0000; nsel = 3'b000; loada = 1'b0; loadb = 1'b0; loadc = 1'b1; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `nine: begin //writing Rm into Rd
                vsel = 4'b0001; nsel = 3'b010; loada = 1'b0; loadb = 1'b0; loadc = 1'b0; write = 1'b1; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `ten: begin //loading Rn into A
                vsel = 4'b0000; nsel = 3'b001; loada = 1'b1; loadb = 1'b0; loadc = 1'b0; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `eleven: begin //loading Rm into B
                vsel = 4'b0000; nsel = 3'b100; loada = 1'b0; loadb = 1'b1; loadc = 1'b0; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `twelve: begin //Rm - sh_Rm
                vsel = 4'b0000; nsel = 3'b000; loada = 1'b0; loadb = 1'b0; loadc = 1'b1; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b1; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `thirteen: begin //Loading Rn into A
                vsel = 4'b0000; nsel = 3'b001; loada = 1'b1; loadb = 1'b0; loadc = 1'b0; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `fourteen: begin //Loading Rm into B
                vsel = 4'b0000; nsel = 3'b100; loada = 1'b0; loadb = 1'b1; loadc = 1'b0; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `fifteen: begin //Doing Rn & sh_Rm
                vsel = 4'b0000; nsel = 3'b000; loada = 1'b0; loadb = 1'b0; loadc = 1'b1; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `sixteen: begin //writing Rm into Rd
                vsel = 4'b0001; nsel = 3'b010; loada = 1'b0; loadb = 1'b0; loadc = 1'b0; write = 1'b1; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `seventeen: begin //loading Rm into B
                vsel = 4'b0000; nsel = 3'b100; loada = 1'b0; loadb = 1'b1; loadc = 1'b0; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `eighteen: begin //loadc for ~sh_Rm
                vsel = 4'b0000; nsel = 3'b000; loada = 1'b0; loadb = 1'b0; loadc = 1'b1; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `nineteen: begin //writing Rm into Rd
                vsel = 4'b0001; nsel = 3'b010; loada = 1'b0; loadb = 1'b0; loadc = 1'b0; write = 1'b1; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end

    //Load path
            `twenty: begin //Loading Rn into A
                vsel = 4'b0000; nsel = 3'b001; loada = 1'b1; loadb = 1'b0; loadc = 1'b0; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `twenty_one: begin //adding Rn + sximm5
                vsel = 4'b0000; nsel = 3'b000; loada = 1'b0; loadb = 1'b0; loadc = 1'b1; write = 1'b0; asel = 1'b0; bsel = 1'b1; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b01;
            end
            `twenty_two: begin //loading address
                vsel = 4'b0000; nsel = 3'b010; loada = 1'b0; loadb = 1'b0; loadc = 1'b0; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b1; mem_cmd = 2'b01;
            end
            `twenty_three: begin //writing into Rd
                vsel = 4'b1000; nsel = 3'b010; loada = 1'b0; loadb = 1'b0; loadc = 1'b0; write = 1'b1; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b01;
            end
            `twenty_nine: begin //writing into Rd
                vsel = 4'b1000; nsel = 3'b010; loada = 1'b0; loadb = 1'b0; loadc = 1'b0; write = 1'b1; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b01;
            end

    //STR path
            `twenty_four: begin //Loading Rn into A
                vsel = 4'b0000; nsel = 3'b001; loada = 1'b1; loadb = 1'b0; loadc = 1'b0; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;
            end
            `twenty_five: begin //Rn + sximm5
                vsel = 4'b0000; nsel = 3'b000; loada = 1'b0; loadb = 1'b0; loadc = 1'b1; write = 1'b0; asel = 1'b0; bsel = 1'b1; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;            
            end
             `twenty_six: begin //Load Rd into B, while also loading address
                vsel = 4'b0000; nsel = 3'b010; loada = 1'b0; loadb = 1'b1; loadc = 1'b0; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b1; mem_cmd = 2'b00;            
            end
             `twenty_seven: begin //passing Rd to datapath out
                vsel = 4'b0000; nsel = 3'b000; loada = 1'b0; loadb = 1'b0; loadc = 1'b1; write = 1'b0; asel = 1'b1; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;            
            end
             `twenty_eight: begin //writing to address Rn + sximm5
                vsel = 4'b0000; nsel = 3'b000; loada = 1'b0; loadb = 1'b0; loadc = 1'b0; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b10;            
            end
            




            `HALT: begin //HALT state
                vsel = 4'b0000; nsel = 3'b000; loada = 1'b0; loadb = 1'b0; loadc = 1'b0; write = 1'b0; asel = 1'b0; bsel = 1'b0; loads = 1'b0; reset_pc = 1'b0; load_pc = 1'b0; addr_sel = 1'b0; load_ir = 1'b0; load_addr = 1'b0; mem_cmd = 2'b00;            
            end
            default: begin //default case
                vsel = 4'bxxxx; nsel = 3'bxxx; loada = 1'bx; loadb = 1'bx; loadc = 1'bx; write = 1'bx; asel = 1'bx; bsel = 1'bx; loads = 1'bx; reset_pc = 1'bx; load_pc = 1'bx; addr_sel = 1'bx; load_ir = 1'bx; load_addr = 1'bx; mem_cmd = 2'bxx;
            end
        endcase
    end



endmodule