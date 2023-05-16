module m_extension
(
    input logic clk,
    input logic rst,
    input logic [31:0] a,
    input logic [31:0] b,
    input logic m_extension_load,
    input logic [2:0] funct3,
    output logic [31:0] m_extension_out,
    output logic m_extension_resp
);

// wires for multiplier
logic multiplier_load;
logic [31:0] multiplicand;
logic [31:0] multiplier;
logic [63:0] product;
logic multiplier_resp;

// wires for divider
logic divider_load;
logic [31:0] dividend;
logic [31:0] divisor;
logic [31:0] quotient;
logic [31:0] remainder;
logic divider_resp;

assign multiplier_load = (m_extension_load && (funct3 <= 3'd3)) ? 1'b1 : 1'b0;
assign divider_load = (m_extension_load && (funct3 >= 3'd4)) ? 1'b1 : 1'b0;
assign m_extension_resp = (funct3 <= 3'd3) ? multiplier_resp : divider_resp;

multiplier mul(
    .clk(clk),
    .rst(rst),
    .multiplier_load(multiplier_load),
    .multiplicand(multiplicand),
    .multiplier(multiplier),
    .product(product),
    .multiplier_resp(multiplier_resp)
);

divider div(
    .clk(clk),
    .rst(rst),
    .divider_load(divider_load),
    .dividend(dividend),
    .divisor(divisor),
    .quotient(quotient),
    .remainder(remainder),
    .divider_resp(divider_resp)
);

function void set_defaults();
    multiplicand = 32'd0;
    multiplier   = 32'd0;
    dividend     = 32'd0;
    divisor      = 32'd0;
    m_extension_out    = 32'd0;
endfunction

always_comb begin
    set_defaults();
    unique case(funct3)
        // signed multiplication -> output product[31:0]
        3'd0: begin
            multiplicand = (a[31]) ? (~a) + 32'd1 : a;
            multiplier = (b[31]) ? (~b) + 32'd1 : b;
            m_extension_out = (a[31] ^ b[31]) ? (~product[31:0]) + 32'd1 : product[31:0];
        end
        // signed multiplication -> output product[63:32]
        3'd1: begin
            multiplicand = (a[31]) ? (~a) + 32'd1 : a;
            multiplier = (b[31]) ? (~b) + 32'd1 : b;
            m_extension_out = (a[31] ^ b[31]) ? (~product[63:32]) + 32'd1 : product[63:32];           
        end
        // signed * unsigned -> output product[63:32]
        3'd2: begin
            multiplicand = (a[31] == 1'b1) ? (~a) + 32'd1 : a;
            multiplier = b;
            m_extension_out = (a[31]) ? (~product[63:32]) + 32'd1 : product[63:32];        
        end
        // unsigned multiplication -> output product[63:32]
        3'd3: begin
            multiplicand = a;
            multiplier = b;
            m_extension_out = product[63:32];             
        end
        // signed quotient division
        3'd4: begin
            dividend = (a[31]) ? (~a) + 32'd1 : a;
            divisor = (b[31]) ? (~b) + 32'd1 : b;
            m_extension_out = (a[31] ^ b[31]) ? (~quotient) + 32'd1 : quotient;
        end
        // unsigned quotient division
        3'd5: begin
            dividend = a;
            divisor = b;
            m_extension_out = quotient;
        end
        // signed remainder division
        3'd6: begin
            dividend = (a[31]) ? (~a) + 32'd1 : a;
            divisor = (b[31]) ? (~b) + 32'd1 : b;
            m_extension_out = (a[31]) ? (~remainder) + 32'd1 : remainder;
        end
        // unsigned remainder division
        3'd7: begin
            dividend = a;
            divisor = b;
            m_extension_out = remainder;
        end
        default: ; 
    endcase
end

endmodule