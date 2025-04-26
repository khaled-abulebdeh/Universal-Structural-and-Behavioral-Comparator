
module system_analizar ();
	reg signed_flag,CLK,CLR;
	wire [5:0]in_A, in_B;//outputs of vector generator
	wire [5:0]A, B;//outpus of (input registers)
	
	wire greater_structural,equal_structural,smaller_structural;//outputs of structural comparator
	wire greater_behavioral,equal_behavioral,smaller_behavioral;//outputs of behavioral comparator
		
	vector_generator u3(in_A, in_B,CLK,CLR);//provides set of vectors
	
	//pass inputs into registers at CLK
	register6_bit U6 (A, in_A,CLK,CLR);
	register6_bit U7 (B, in_B,CLK,CLR);
	
	behavioral_comparator u2 (greater_behavioral,equal_behavioral,smaller_behavioral,A,B,signed_flag,CLR);
	structural_comparator u1 (greater_structural,equal_structural,smaller_structural,in_A,in_B,signed_flag,CLK,CLR);
 	
	initial begin
	    // Initialize signals
	    signed_flag = 1;
	    CLK = 0;
	    CLR = 0; 
	    #1 CLR = 1; 
	    #10000 $finish;          
	end	 
	
		    
	wire error;
	assign error= (greater_structural!=greater_behavioral)|
	(equal_structural!=equal_behavioral)|(smaller_structural!=smaller_behavioral); 
	
	always #70 CLK=~CLK;
	
	always @(posedge CLK, negedge CLR)
	begin 
		 #0.00000000001
		if (error)begin
				
				$display("(A=%b,B=%b), (Signed=%d), ",A, B, signed_flag);
				$display("Unexpected results!!");
				$display("----------Test Failed--------\n");
				$finish;
			 end		 
			 else  begin	
				 $display("(A=%b,B=%b), (Signed=%d), (greater=%b, equal=%b, smaller=%b)",A, B, signed_flag,greater_behavioral, equal_behavioral, smaller_behavioral);
			 	 $display("--------Test Passed--------\n");
			 end
	end	
endmodule 

//--------------------------------------------|behavioral comparator|--------------------------------------------
module behavioral_comparator (greater, equal, smaller,in_A,in_B,signed_flag,CLR);
	output  reg greater, equal, smaller;
	input signed_flag,CLR;
	input [5:0] in_A, in_B;//unsigned  
	
	//to have signed values of A, B
	wire signed [5:0] signed_A= in_A;
	wire signed [5:0] signed_B= in_B;
	
	always @(in_A,in_B,signed_flag,CLR)
	begin
		
		if (~CLR)begin
			smaller=0;
			greater=0;
			equal=0; 
		end
		
		else if (signed_flag) begin	
			if (signed_A > signed_B)
			begin
				greater=1; smaller=0; equal=0;
			end	
			else if (signed_A < signed_B) begin 
				greater=0; smaller=1; equal=0;
			end								  
			else begin
				greater=0; smaller=0; equal=1;
			end
		end
		
		else begin //unsigned 
			 if (in_A > in_B)
			begin
				greater=1; smaller=0; equal=0;
			end	
			else if (in_A < in_B) begin 
				greater=0; smaller=1; equal=0;
			end								  
			else begin
				greater=0; smaller=0; equal=1;
			end
		end		
	end
endmodule

//--------------------------------------------|Universal Structural Comparator|--------------------------------------------
module structural_comparator(greater, equal, smaller,A,B,signed_flag, CLK,CLR);
  	output greater, equal, smaller;
	input signed_flag,CLK,CLR;
	input [5:0] A, B;
		
	wire signed_greater, signed_equal, signed_smaller; //stores signed	results
	wire unsigned_greater, unsigned_equal, unsigned_smaller; //stores unsigned results       
	
	//signed_flag=0 -> unsigned ,, signed_flag=1 -> signed
	
	signed_comparator U1(signed_greater, signed_equal, signed_smaller,A,B);
	unsigned_comparator U2(unsigned_greater, unsigned_equal, unsigned_smaller,A,B); 
		 
	wire temp_greater, temp_equal, temp_smaller; //i.e. temp_greater holds either signed_greater or unsigned_greater depending on the selection  
	
	//redirect "greater" output using mux 
	mux2x1 U3 (temp_greater, signed_flag, unsigned_greater, signed_greater);  
	register1_bit U8 (greater, temp_greater, CLK, CLR);

	//redirect "equal" output using mux
	mux2x1 U4 (temp_equal, signed_flag, unsigned_equal, signed_equal);	 
	register1_bit U9 (equal, temp_equal, CLK, CLR);
	
	//redirect "smaller" output using mux
	mux2x1 U5 (temp_smaller, signed_flag, unsigned_smaller, signed_smaller);
	register1_bit U10 (smaller, temp_smaller, CLK, CLR);	   
endmodule


//--------------------------------------------|Unsigned Strucrutal Comparator|--------------------------------------------
module unsigned_comparator (greater, equal, smaller, A,B);
	/*
	Gi= (Ai).(!Bi) , a bit is greater than the corresponding
	Ei= !(Ai Xor Bi) , a bit equals the corresponding
	Li= !(Gi + Ei) , a bit is less than the corresponding
	*/	
	output greater, equal, smaller;
	input [5:0] A, B;

	wire [5:0] bit_greater, bit_equal, bit_smaller;
	genvar i;  
	   
	//to compare each bit with the corresponding one
	generate
	for (i=0; i<6; i+=1)
		begin 	
			and #6 (bit_greater[i], A[i], ~B[i]);//Gi
			and #6 (bit_smaller[i], ~A[i], B[i]);//Li  
			xnor #8 (bit_equal[i], A[i], B[i]);
		end
	endgenerate	  
	
	//to find the final greater output
	wire [5:0] GT_terms, LT_terms;
	
	//construct Greater output
	buf (GT_terms[5], bit_greater[5]);
	and #6 (GT_terms[4],bit_equal[5], bit_greater[4]); 
	and #6 (GT_terms[3],bit_equal[5] ,bit_equal[4], bit_greater[3]);
	and #6 (GT_terms[2],bit_equal[5] ,bit_equal[4], bit_equal[3], bit_greater[2]);
	and #6 (GT_terms[1],bit_equal[5] ,bit_equal[4], bit_equal[3], bit_equal[2], bit_greater[1]);
	and #6 (GT_terms[0],bit_equal[5] ,bit_equal[4], bit_equal[3], bit_equal[2], bit_equal[1], bit_greater[0]); 
	or #6(greater, GT_terms[5], GT_terms[4], GT_terms[3], GT_terms[2], GT_terms[1], GT_terms[0]);
	
	//construct smaller output
	and #6 (LT_terms[5], bit_smaller[5]);
	and #6 (LT_terms[4], bit_equal[5], bit_smaller[4]);
	and #6 (LT_terms[3], bit_equal[5], bit_equal[4], bit_smaller[3]);
	and #6 (LT_terms[2], bit_equal[5], bit_equal[4], bit_equal[3], bit_smaller[2]);
	and #6 (LT_terms[1], bit_equal[5], bit_equal[4], bit_equal[3], bit_equal[2], bit_smaller[1]);
	and #6 (LT_terms[0], bit_equal[5], bit_equal[4], bit_equal[3], bit_equal[2], bit_equal[1], bit_smaller[0]);
	or #6(smaller, LT_terms[5], LT_terms[4], LT_terms[3], LT_terms[2], LT_terms[1], LT_terms[0]);
	
	//construct equal output
	xnor #8 (equal, smaller, greater);
	
endmodule	


//--------------------------------------------|Signed Strucrutal Comparator|--------------------------------------------
module signed_comparator (greater, equal, smaller, A, B);
	
	//Gi= (Ai).(!Bi) , a bit is greater than the corresponding
	//Ei= !(Ai Xor Bi) , a bit equals the corresponding
	//Li= !(Gi + Ei) , a bit is less than the corresponding
		
	output greater, equal, smaller;
	input [5:0] A, B;
	
	wire [5:0] bit_greater, bit_equal, bit_smaller;
		
	//construct outputs
	wire temp_greater, temp_equal, temp_smaller;
	unsigned_comparator U1 (temp_greater, temp_equal, temp_smaller, {1'b0, A[4:0]}, {1'b0, B[4:0]});
	
	//construct greater output
	wire [2:0] temporary1;
	and #6 (temporary1[0], temp_greater, ~A[5], ~B[5]);//if both +ve, compare all bits
	and #6 (temporary1[1], ~A[5], B[5]);//greater if the first is +ve, the other is -ve
	and #6 (temporary1[2], temp_greater, A[5], B[5]);//if both -ve, compare the remaining bits and invert the result
	or #6 (greater, temporary1[0],temporary1[1],temporary1[2]);
	
	//construct smaller output
	wire [2:0] temporary2;
	and #6 (temporary2[0], temp_smaller, ~A[5], ~B[5]);//if both +ve, compare all bits
	and #6 (temporary2[1], A[5], ~B[5]);//smaller if the first is -ve, the other is +ve
	and #6 (temporary2[2], temp_smaller, A[5], B[5]);//if both -ve, compare the remaining bits and invert the result 
	or #6 (smaller, temporary2[0],temporary2[1],temporary2[2]);
	 
	//construct equal output
	xnor #8 (equal, smaller, greater);
endmodule


//--------------------------------------------|vector generator|--------------------------------------------
module vector_generator (A,B,CLK,CLR);
	
	//an LFSR implementation for 6 bit 
	// FLSR uses (X^6) + (X^5) +1
	
	output reg [5:0] A,B;
	input CLK,CLR;
	reg XORed_bit_A, XORed_bit_B;
	
	always @(posedge CLK, negedge CLR)
	begin
		if (~CLR)begin
			//initial values
			A=6'b010101;
			B=6'b101010;
		end	
		else begin 
			XORed_bit_A= A[5]^A[4];
			XORed_bit_B= B[5]^B[4];
			A= {A[4:0], XORed_bit_A} ;
			B= {B[4:0] ,XORed_bit_B};	  	
		end	
	end
endmodule

 
//--------------------------------------------|Registers|--------------------------------------------
module register6_bit (out_Y, in_X, CLK, CLR);
	input CLK, CLR; //clock and clear
	input [5:0] in_X;
	output reg [5:0] out_Y;	
	
	always @(posedge CLK or negedge CLR)
	begin 
		if (~CLR)
			out_Y=0;
		else
		begin
			out_Y= in_X;
		end	
	end
endmodule 

module register1_bit (out_Y, in_X, CLK, CLR);
	input CLK, CLR; //clock and clear
	input  in_X;
	output reg out_Y;
				   
	always @(posedge CLK or negedge CLR)
	begin 
		if (~CLR)
			out_Y=0;
		else
		begin
			out_Y= in_X;;
		end	
	end
endmodule

//--------------------------------------------|Mux|--------------------------------------------
module mux2x1 (y, selection, x0,x1); 
	
	output y;
	input selection, x0,x1;
	
	wire [1:0] temp;

	and #6 (temp[0], ~selection, x0);	
	and #6 (temp[1], selection, x1);
	or #6 (y, temp[0], temp[1]); 
	
endmodule


