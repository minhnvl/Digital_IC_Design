    module AS(sel, A, B, S, O);
        input [3:0] A, B;
        input sel;
        output [3:0] S;
        output O;

        wire ripple0,ripple1,ripple2,ripple3;

        assign O = ripple2^ripple3;

        Single_State s0( .a( A[0] ), .b(sel^B[0]), .cin( sel ),     .s( S[0]), .cout( ripple0 ) );
        Single_State s1( .a( A[1] ), .b(sel^B[1]), .cin( ripple0 ), .s( S[1]), .cout( ripple1 ) );
        Single_State s2( .a( A[2] ), .b(sel^B[2]), .cin( ripple1 ), .s( S[2]), .cout( ripple2 ) );
        Single_State s3( .a( A[3] ), .b(sel^B[3]), .cin( ripple2 ), .s( S[3]), .cout( ripple3 ) );
        
endmodule

module Single_State(
    input a,
    input b,
    input cin,
    output  s,
    output cout );

    assign s    = a ^ b ^ cin;
    assign cout = (a & b)  |  (a & cin)  |  (b & cin);
endmodule

