`timescale 1ns / 10ps
module div(out, in1, in2, dbz);
parameter width = 8;
input  	[width-1:0] in1; // Dividend
input  	[width-1:0] in2; // Divisor
output  [width-1:0] out; // Quotient
output dbz;

    wire     carry;
    wire     [width-1:0] AC;
    wire     [width:0] Ne_in2;
    wire     [width:0] Po_in2;
    reg     [width-1:0] temp_out;
    
    wire    [16:0] division0,division1,division2,division3,division4,division5,division6,last_division;

    assign dbz = (in2 == 8'b0)?1'b1:1'b0;

    assign AC = 8'b0;
    assign carry = 1'b0;
    assign Po_in2 = {1'b0,in2};
    assign Ne_in2 = ~({1'b0,in2}) + 1;

    assign out[7:0] = (in1==in2)?8'b1:(in1<in2)?8'b0:last_division[8:0]; 

    Full_Division d1 (.inDivision({carry,AC,in1}), .Po_in2(Po_in2), .Ne_in2(Ne_in2),.outDivision(division0));
    Full_Division d2 (.inDivision(division0),      .Po_in2(Po_in2), .Ne_in2(Ne_in2),.outDivision(division1));
    Full_Division d3 (.inDivision(division1),      .Po_in2(Po_in2), .Ne_in2(Ne_in2),.outDivision(division2));
    Full_Division d4 (.inDivision(division2),      .Po_in2(Po_in2), .Ne_in2(Ne_in2),.outDivision(division3));
    Full_Division d5 (.inDivision(division3),      .Po_in2(Po_in2), .Ne_in2(Ne_in2),.outDivision(division4));
    Full_Division d6 (.inDivision(division4),      .Po_in2(Po_in2), .Ne_in2(Ne_in2),.outDivision(division5));
    Full_Division d7 (.inDivision(division5),      .Po_in2(Po_in2), .Ne_in2(Ne_in2),.outDivision(division6));
    Full_Division d8 (.inDivision(division6),      .Po_in2(Po_in2), .Ne_in2(Ne_in2),.outDivision(last_division));

    

endmodule

module Full_Division(
    input [16:0] inDivision,
    input [8:0]    Po_in2,
    input   [8:0]   Ne_in2,
    output [16:0]    outDivision
);

    reg [16:0] Input_shift;

    always @(*) begin
        Input_shift = inDivision << 1;
        Input_shift[16:8] = Input_shift[16:8] + Ne_in2;
        if (Input_shift[16] == 1) begin
            Input_shift[16:8] = Input_shift[16:8] + Po_in2;
            Input_shift[0] = 1'b0;
        end
        else Input_shift[0] = 1'b1;
    
        Input_shift[16] = 1'b0;
    end
    assign outDivision[16:0] = Input_shift[16:0];

endmodule


