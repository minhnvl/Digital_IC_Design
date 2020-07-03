`timescale 1ns/10ps
module CS(Y, X, reset, clk);

    input           clk, reset; 
    input 	[7:0]   X;
    output 	[9:0]   Y;

    reg     [71:0]  ValX;
    reg     [11:0]  add_sum;
    reg     [7:0]   Xapp_compare1;
    reg     [7:0]   Xapp_compare2;
    reg     [71:0]  Last_X;
    reg     [7:0]   Xapp;
    
    wire    [11:0]  sum;
    wire    [7:0]   Xavg;
    integer         i;

    assign Y    = (add_sum + 9*Xapp)/8;
    assign sum  = add_sum + {4'b0, X} - {4'b0, ValX[71:64]} ;
    assign Xavg = add_sum/9;
    
    always @(posedge clk) begin
        if (reset == 1) begin
            ValX        <= 0;
            add_sum     <=0;
        end
        else begin
            ValX        <= ValX << 8;
            ValX[7:0]   <= X[7:0];
            add_sum     <= sum; 
                  
        end
    end
    
    always @(*) begin
        Xapp        = 0; 
        Last_X      = ValX;
        for(i=0; i<9; i = i+1) begin
            if  (i) Last_X = Last_X >> 8;
            if  (Xavg >= Last_X[7:0]) 
                Xapp_compare1   = Xavg  - Last_X[7:0];
                Xapp_compare2   = Xavg  - Xapp;
                Xapp            = (Xapp_compare1 < Xapp_compare2) ? Last_X[7:0]:Xapp;  
        end        
    end

endmodule
