`define MREAD 2'b01
`define MWRITE 2'b10
`define MNONE 2'b00

module lab7_top(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
    input [3:0] KEY;
    input [9:0] SW;
    output [9:0] LEDR;
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
        
    
    
    wire [8:0] mem_addr;
    wire [1:0] mem_cmd;

    wire [15:0] read_data, write_data;
    wire N, V, Z;
    wire [15:0] mdata;
    wire [15:0] dout;
    wire write;
    reg wsel, rsel, msel;

    //Switches and LEDs
    reg LED_en, SW_en;
                        
            //clk    //reset  //mdata    //in
    cpu CPU(~KEY[0],~KEY[1],read_data,read_data, write_data,N,V,Z,mem_addr, mem_cmd);
    
    RAM MEM(~KEY[0],mem_addr[7:0],mem_addr[7:0],write,write_data,dout);

    //RAM tristate Driver 
    assign read_data = (rsel & msel) ? dout : {16{1'bz}};

    //msel
    assign msel = mem_addr[8] ? 1'b0 : 1'b1; 
    //write AND gate
    assign write = wsel & msel;
    //comparators
    always_comb begin
        case(mem_cmd)
            `MREAD: begin
                rsel = 1'b1;
                wsel = 1'b0;
            end
            `MWRITE: begin
                rsel = 1'b0;
                wsel = 1'b1;
            end
            `MNONE: begin
                rsel = 1'b0;
                wsel = 1'b0;
            end
            default: begin
                rsel = 1'bx;
                wsel = 1'bx;
            end
        endcase
    end

    //SW
    always_comb begin
      if ((mem_cmd == `MREAD) && (mem_addr == 9'h140))
        SW_en = 1'b1;
      else
        SW_en = 1'b0;
    end

    assign read_data[15:8] = SW_en ? 8'h00 : {16{1'bz}}; //15:8
    assign read_data[7:0] = SW_en ? SW[7:0] : {16{1'bz}}; //7:0

    //LEDs
    vDFF_load_en #(8) LED_CONTROL(~KEY[0], LED_en, write_data[7:0], LEDR[7:0]);
    always_comb begin
        if((mem_cmd == `MWRITE) && (mem_addr == 9'h100))
            LED_en = 1'b1;
        else
            LED_en = 1'b0;
    end  

    
endmodule


module RAM (clk,read_address,write_address,write,din,dout);
  parameter data_width = 16; 
  parameter addr_width = 8;
  parameter filename = "data.txt";

  input clk;
  input [addr_width-1:0] read_address, write_address;
  input write;
  input [data_width-1:0] din;
  output [data_width-1:0] dout;
  reg [data_width-1:0] dout;

  reg [data_width-1:0] mem [2**addr_width-1:0];

  initial $readmemb(filename, mem);

  always @ (posedge clk) begin
    if (write)
      mem[write_address] <= din;
    dout <= mem[read_address];
                               
  end 
endmodule

