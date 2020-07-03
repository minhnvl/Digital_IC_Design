
`timescale 1ns/10ps

module  SOBEL(clk,reset,busy,ready,iaddr,idata,cdata_rd,cdata_wr,caddr_rd,caddr_wr,cwr,crd,csel	);
	input				clk;
	input				reset;
	output				busy;	
	input				ready;	
	output 	[16:0]		iaddr;
	input  	[7:0]		idata;	
	input	[7:0]		cdata_rd;
	output	[7:0]		cdata_wr;
	output 	[15:0]		caddr_rd;
	output 	[15:0]		caddr_wr;
	output				cwr,crd;
	output 	[1:0]		csel;
	
	parameter		K0_1 = 1,
					K0_2 = 0,
					K0_3 = -1,
					K0_4 = 2,
					K0_5 = 0,
					K0_6 = -2,
					K0_7 = 1,
					K0_8 = 0,
					K0_9 = -1;
	parameter		K1_1 = 1,
					K1_2 = 2,
					K1_3 = 1,
					K1_4 = 0,
					K1_5 = 0,
					K1_6 = 0,
					K1_7 = -1,
					K1_8 = -2,
					K1_9 = -1;

	parameter [3:0] State_Init 		= 4'b0000, 
					State_Weight_1 	= 4'b0001,
					State_Weight_2	= 4'b0010,
					State_Weight_3	= 4'b0011,
					State_Weight_4	= 4'b0100,
					State_Weight_5 	= 4'b0101,
					State_Weight_6 	= 4'b0110,
					State_Weight_7 	= 4'b0111,
					State_Weight_8 	= 4'b1000,
					State_Weight_9 	= 4'b1001;
					

	reg 	[16:0] 	Addr_data;
	
	reg		[16:0]	Input_Count,Counter, Input_addr;
	reg     [17:0] 	Count_Write;
	reg		[15:0]	ConvX1,ConvX2,ConvX3,ConvX4,ConvX5,ConvX6,ConvX7,ConvX8,ConvX9;
	reg		[15:0]	ConvY1,ConvY2,ConvY3,ConvY4,ConvY5,ConvY6,ConvY7,ConvY8,ConvY9;
	// reg     [7:0]	Input_data;	
	reg   	[3:0]	CurrentState,NextState;	
	reg		[15:0]	SobelX, SobelY, SobelCombine;
	reg 	[7:0] 	Count_row;
	reg 			Check_SobelX,Check_SobelY, Check_Combine;
	reg     		busy;
	reg 	[1:0]	csel;
	reg 	[7:0]	cdata_wr;
	wire	[16:0]	Temp_Count;
	wire 	[7:0]	Result_SobelX,Result_SobelY,Result_Combine;
	wire 	[7:0]	Temp_Result_X,Temp_Result_Y;
	assign Result_SobelX 		= 	(SobelX[15:8] >= 8'b1) ? (SobelX[15:12]== 4'hf)? 0 : 8'hff:SobelX[7:0] ;
	assign Result_SobelY 		= 	(SobelY[15:8] >= 8'b1) ? (SobelY[15:12]== 4'hf)? 0 : 8'hff:SobelY[7:0] ;
	assign Result_Combine[7:0] 	= 	(SobelCombine[0] == 0)?SobelCombine[8:1]:SobelCombine[8:1] + 1;
	assign iaddr 				= 	Addr_data;
	assign caddr_wr 			= 	Count_Write - 1;
	assign cwr 					= 	1'b1;
	assign Temp_Count 			= 	(Input_Count < 255)?255:255+258*Count_row;
	assign Temp_Result_X		= 	(Check_SobelY)?Result_SobelX:Temp_Result_X;
	assign Temp_Result_Y		= 	(Check_SobelY)?Result_SobelY:Temp_Result_Y;


	initial begin 
		busy 		 <= 1'b0; 
	end

	always@(posedge clk or posedge reset) begin
		if(reset) begin
			Input_Count <= 0;
			Count_Write <= 0;
			Count_row 	<= 0;
			CurrentState <= State_Init;
			Counter 	 <= 0;
			busy 		 <= 1'b0; 

		end
		else begin
			Input_Count <= (Check_SobelX)?(Input_Count == Temp_Count)?Input_Count + 3:Input_Count + 1:Input_Count;
			Count_Write <= (CurrentState == State_Weight_8)?Count_Write+1:Count_Write;
			Count_row 	<= (Check_SobelX && Input_Count > 0 && Input_Count%258 == 8'b0)?Count_row+1:Count_row;
			busy 			<= (ready)?1'b1:(Check_SobelX && Count_Write > 65536)?1'b0:busy;
			CurrentState 	<= (ready)?State_Init:NextState;
			Counter 		<= (Check_SobelX)?0:Counter + 1;
		end
	end

	always @(CurrentState) begin
		case(CurrentState)
			State_Init:		NextState <= State_Weight_1;
			State_Weight_1: NextState <= State_Weight_2;
			State_Weight_2: NextState <= State_Weight_3;
			State_Weight_3: NextState <= State_Weight_4;
			State_Weight_4: NextState <= State_Weight_5;
			State_Weight_5: NextState <= State_Weight_6;
			State_Weight_6: NextState <= State_Weight_7;
			State_Weight_7: NextState <= State_Weight_8;
			State_Weight_8: NextState <= State_Weight_9;
			State_Weight_9: NextState <= State_Init;
		
		endcase
	end	

	always @(CurrentState) begin
		csel			<= 2'b00;
		case(CurrentState)
			State_Init: begin
				Addr_data 		<= Input_Count + Counter;
				// csel			<= 2'b01;
				// cdata_wr		<= Result_SobelX;
				Check_SobelX	<= 1'b0;
				csel			<= 2'b01;
				cdata_wr		<= Temp_Result_X;
				
			end
			State_Weight_1: begin
				csel			<= 2'b11;
				cdata_wr		<= Result_Combine;
				
				Check_SobelY  	<= 1'b0;
				Check_Combine 	<= 1'b1;
				Addr_data 		<= Input_Count + Counter;
				// Input_data		<= idata;
				ConvX1 			<= idata * K0_1;
				ConvY1 			<= idata * K1_1;
			end
			State_Weight_2: begin
				csel			<= 2'b10;
				cdata_wr		<= Temp_Result_Y;
				Check_Combine 	<= 1'b0;
				Addr_data 		<= Input_Count + Counter;
				// Input_data		<= idata;

				ConvX2 			<= idata * K0_2;
				ConvY2 			<= idata * K1_2;
			end
			State_Weight_3: begin
				// csel			<= 2'b00;

				Addr_data 		<= Input_Count + 258;
				// Input_data		<= idata;

				ConvX3 			<= idata * K0_3;
				ConvY3 			<= idata * K1_3;
			end
			State_Weight_4: begin
				// csel			<= 2'b00;
				Addr_data 		<= Input_Count + 259;
				// Input_data		<= idata;

				ConvX4 			<= idata * K0_4;
				ConvY4 			<= idata * K1_4;
			end
			State_Weight_5: begin
				// csel			<= 2'b00;
				Addr_data 		<= Input_Count + 260;
				// Input_data		<= idata;

				ConvX5			<= idata * K0_5;
				ConvY5 			<= idata * K1_5;
			end
			State_Weight_6: begin
				Addr_data 		<= Input_Count + 516;
				// Input_data		<= idata;

				ConvX6 			<= idata * K0_6;
				ConvY6 			<= idata * K1_6;
			end
			State_Weight_7: begin
				Addr_data 		<= Input_Count + 517;
				// Input_data		<= idata;

				ConvX7 			<= idata * K0_7;
				ConvY7 			<= idata * K1_7;
			end
			State_Weight_8: begin
				Addr_data 		<= Input_Count + 518;
				// Input_data		<= idata;

				ConvX8 			<= idata * K0_8;
				ConvY8 			<= idata * K1_8;
			end
			State_Weight_9: begin
				Check_SobelX 	<= 1'b1;
				Check_SobelY 	<= 1'b1;
				ConvX9 			<= idata * K0_9;
				ConvY9 			<= idata * K1_9;
				// Input_data		<= idata;
				
			end
		endcase
	end

	always @(*) begin
		SobelX 		 <= (Check_SobelX == 1'b1)?(((ConvX1 + ConvX2) +(ConvX3 +  ConvX4)) + ((ConvX5 + ConvX6) + (ConvX7 + ConvX8))) + ConvX9:SobelX;
	end
	always @(*) begin
		SobelY 		 <= (Check_SobelX == 1'b1)?(((ConvY1 + ConvY2) +(ConvY3 +  ConvY4)) + ((ConvY5 + ConvY6) + (ConvY7 + ConvY8))) + ConvY9:SobelY;
	end
	always @(*) begin
		SobelCombine <= (Check_SobelX == 1'b1)?Result_SobelX + Result_SobelY:SobelCombine;
	end

endmodule

