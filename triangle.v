module triangle (clk, reset, nt, xi, yi, busy, po, xo, yo);
input clk, reset, nt;
input [2:0] xi, yi;
output busy, po;
output [2:0] xo, yo;
reg [2:0] xo,yo;
reg po;
wire ok;
reg [2:0] x1, x2, x3, y1, y2, y3;
reg [2:0]x_shift,y_shift; //x1 y_shift
reg [2:0]x_shift2,y_shift2;
localparam S0=3'd0,S1=3'd1,S2=3'd2,S3=3'd3;
reg [1:0]next_state;
reg [1:0]present_state;
reg [1:0]cnt;
reg first;
wire [2:0]q12,r12,q23,r23;
wire [2:0]q_shift,r_shift,q_shift2,r_shift2;
wire [2:0]linex12,liney12,linex23,liney23;
assign linex12=(x2>x1)?x2-x1:x1-x2;
assign liney12=y2-y1;
assign liney23=y3-y2;
assign linex23=(x2>x3)?x2-x3:x3-x2;
reg algo12,algo23,algo13;
assign ok=(xo==x1 && (yo==y1 ||yo==y3) )?1: 	algo12&algo23&algo13; //edge 2 points
assign busy=(present_state==S1)? 1:0;
div L12(.din1(linex12),.din2(liney12),.q(q12),.r(r12));
div L23(.din1(linex23),.din2(liney23),.q(q23),.r(r23));
div shift(.din1(x_shift),.din2(y_shift),.q(q_shift),.r(r_shift));
div shift2(.din1(x_shift2),.din2(y_shift2),.q(q_shift2),.r(r_shift2));
always@(posedge clk)begin
	case(present_state)
		S0:
			if(nt==1)
				first<=1;
		S1:
			first<=0;
	endcase
end
always@(*)begin
	case(present_state)
		S0:
			begin
				xo=x1;
				yo=y1;
			end
		S1:
			if(x2>x1)begin
				xo=x1+x_shift;
				yo=y1+y_shift;
			end
			else	begin
				xo=x1-x_shift;
				yo=y1+y_shift;
			end
		default:begin
			xo=0;
			yo=0;
		end
		endcase
end
always@(*)begin
	if(x2>x1)begin
		if(xo==x1 ||q_shift< q12)
			algo12=1;
		else if(q_shift== q12 && r_shift>=r12)
			algo12=1;
		else
			algo12=0;
	end
	else	begin
		if(q_shift< q12)
			algo12=1;
		else if(q_shift==q12 )begin
			if(r_shift<=r12)
				algo12=1;
			else
				algo12=0;
		end
		else
			algo12=0;
	end
end
always@(*)begin
	if(x2>x1)begin
		if(xo>=x1)
			algo13=1;
		else
			algo13=0;
	end
	else	begin
		if(xo<=x1)
			algo13=1;
		else
			algo13=0;
	end
end
always@(*)begin
	if(x2>x1)begin
		if(yo<=y2)
			algo23=1;
		else if(q_shift2> q23 )
			algo23=1;
		else if(q_shift2==q23 && r_shift2>r23)
			algo23=1;
		else if(q_shift2==q23 & r_shift2==r23 &y_shift2<liney23)
			algo23=1;
		else
			algo23=0;
	end
	else	begin
		if(yo<=y2 || q_shift2>q23)
			algo23=1;
		else if(q_shift2 == q23 &&r_shift2>r23)
			algo23=1;
		else if(q_shift2==q23 &r_shift2==r23&y_shift2 <liney23)
			algo23=1;
		else
			algo23=0;
	end
end
always@(posedge clk)begin
	if(reset)
		present_state<=S0;
	else
		present_state <= next_state;
end
always@(*)begin
	if(reset)
		next_state=S0;
	else	begin
		case(present_state)
			S0:
				if(cnt==2)
					next_state=S1;
				else
					next_state=S0;
			S1:
				if(yo==y3)
					next_state=S0;
				else
					next_state=S1;
			default:
				next_state=S0;
		endcase
	end 
end
always@(*)begin
	if(reset)
		po=0;
	else begin
		case(present_state)
			S0:
				if(cnt==2)
					po=1;
				else
					po=0;
			S1:
					po=ok;
			default:
				po=0;
		endcase
	end
end
always@(posedge clk)begin
	if(reset)
		cnt<=0;
	else begin
		case(present_state)
			S0:
				if(first||nt)
					cnt<=cnt+1;
				else if(cnt==2)
					cnt<=0;
			S1:
				if(yo==y3 )
					cnt<=0;
				else
					cnt<=cnt;
			default:
				cnt<=cnt;
		endcase
	end
end
always@(posedge clk)begin
	if(reset)begin
		x1<=0;
		x2<=0;
		x3<=0;
		y1<=0;
		y2<=0;
		y3<=0;
	end
	else begin
		case(present_state)
			S0:begin
				if(cnt==0)begin
					x1<=xi;
					y1<=yi;
				end
				else if(cnt==1)begin
					x2<=xi;
					y2<=yi;
				end
				else if(cnt==2)begin
					x3<=xi;
					y3<=yi;
				end
			end
			default:begin
				x1<=x1;
				x2<=x2;
				x3<=x3;
				y1<=y1;
				y2<=y2;
				y3<=y3;
			end
		endcase
	end
end
always@(posedge clk)begin
	begin
		case(present_state)
			S0:
				if(x2>x1)
					x_shift<=0;
				else
					x_shift<=x1-x2;
			S1:
				if(x2>x1)begin
					if(x_shift==linex12)
						x_shift<=0;
					else
						x_shift<=x_shift+1;
				end
				else begin
					if(y_shift==y3-2 &&x_shift==0)
						x_shift<=0;
					else	if(x_shift==0)
						x_shift<=x1-x2;
					else
						x_shift<=x_shift-1;
				end
			default:
				x_shift<=x_shift;
		endcase
	end
end
always@(posedge clk)begin
	begin
		case(present_state)
			S0:
				y_shift<=1;
			S1:
				if(x2>x1)begin
					if(x_shift==linex12)
						y_shift<=y_shift+1;
					else
						y_shift<=y_shift;
				end
				else	begin
					if(x_shift==0)
						y_shift<=y_shift+1;
					else
						y_shift<=y_shift;
				end
			default:
				y_shift<=y_shift;
		endcase
	end
end
always@(posedge clk)begin
		case(present_state)
			S0:
				y_shift2<=1; //fix 1
			S1:
				if(x2>x1)begin
					if(y_shift==1)
						y_shift2<=0;
					else if(x_shift2==0)
						y_shift2<=y_shift2+1;
					else
						y_shift2<=y_shift2;
				end
				else	begin
					if(yo==y2)
							y_shift2<=1;
					else if(x_shift2==x1)
							y_shift2<=y_shift2+1;
				end
			default:
				y_shift2<=y_shift2;
		endcase
end
always@(posedge clk)begin
	begin
		case(present_state)
			S0:
				if(x2>x1)
					x_shift2<=linex12;
				else
					x_shift2<=0;
			S1:
				if(x2>x1)begin
					if(x_shift2==0)
						x_shift2<=linex12;
					else
						x_shift2<=x_shift2-1;
				end
				else
					if(x_shift2==x1)
						x_shift2<=0;
					else
						x_shift2<=x_shift2+1;
			default:
				x_shift2<=x_shift2;
		endcase
	end
end
endmodule
module div(
input [2:0]din1,
input [2:0]din2,
output reg [2:0]q,
output reg [2:0]r
);
always@(*)begin
	if(din2>din1)begin
		q=0;	r=din1;
	end
	else begin
		case(din2)
			0:	begin
				q=0;	r=0;
				end
			1:	begin
				q=din1;	r=0;
				end
			2:	begin
				q=din1[2:1];	r=din1[0];
				end
			3:
				if(din1==6)begin
					q=2;	r=0;
				end
				else	begin
					q=1;	r=din1-din2;
				end
			4:	begin
					q=1;	r=din1-din2;
				end
			5:
				begin
					q=1;	r=din1-din2;
				end
			6:	begin
					q=1;	r=0;
				end
			default:begin
				q=0;
				r=0;
			end
		endcase
	end
end
endmodule