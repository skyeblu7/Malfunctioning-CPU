module cmp 
import rv32i_types::*;
(
    input branch_funct3_t cmpop,
    input rv32i_word in1, in2,
    output logic br_en
);

always_comb
begin
    case (cmpop)
	rv32i_types::beq: br_en = (in1 == in2);
	rv32i_types::bne: br_en = (in1!= in2);
	rv32i_types::blt:br_en = ($signed(in1) < $signed(in2));
	rv32i_types::bltu: br_en = (in1 < in2);
	rv32i_types::bge: br_en = ($signed(in1) >= $signed(in2));	
	rv32i_types::bgeu: br_en = (in1 >= in2);
    default: br_en = 1'b0;
    endcase
end
endmodule : cmp