/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and MRU arrays, comparators, muxes,
logic gates and other supporting logic. */

module L2_cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 4,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input logic clk,
    input logic rst,
    input logic [31:0] address,
    input logic [255:0] cpu_wdata,
    input logic [255:0] mm_wdata,
    output logic [255:0] cacheline_o,
    output logic [31:0] mm_address,

    input logic [2:0] MRU_i,
    input logic load_MRU,
    input logic [3:0] data_i_sel, 
    input logic [3:0] load_tag, 
    input logic [3:0] dirty_i, 
    input logic [3:0] valid_i, 
    input logic load_dirty,
    input logic load_valid,
    input logic [3:0] write_en_sel, 
    input logic [1:0] cacheline_o_sel, 
    input logic mm_address_sel,


    output logic [3:0] dirty_o, 
    output logic [3:0] valid_o, 
    output logic [3:0] hit, 
    output logic [2:0] MRU_o

);

logic [255:0] data_i [0:3]; 
logic [255:0] data_o [0:3]; 
logic [31:0] write_en [0:3]; 

logic [22:0] tag_o [0:3]; 
logic [22:0] old_tag;

logic [22:0] address_tag;
logic [3:0]  rindex,windex;


assign hit[0] = ((tag_o[0] == address_tag) && valid_o[0]);
assign hit[1] = ((tag_o[1] == address_tag) && valid_o[1]);
assign hit[2] = ((tag_o[2] == address_tag) && valid_o[2]);
assign hit[3] = ((tag_o[3] == address_tag) && valid_o[3]);



L2_data_array way0(
    .clk(clk),
    .read(1'd1),
    .write_en(write_en[0]),
    .rindex(rindex),
    .windex(windex),
    .datain(data_i[0]),
    .dataout(data_o[0])
);


L2_data_array way1(
    .clk(clk),
    .read(1'd1),
    .write_en(write_en[1]),
    .rindex(rindex),
    .windex(windex),
    .datain(data_i[1]),
    .dataout(data_o[1])
);

L2_data_array way2(
    .clk(clk),
    .read(1'd1),
    .write_en(write_en[2]),
    .rindex(rindex),
    .windex(windex),
    .datain(data_i[2]),
    .dataout(data_o[2])
);


L2_data_array way3(
    .clk(clk),
    .read(1'd1),
    .write_en(write_en[3]),
    .rindex(rindex),
    .windex(windex),
    .datain(data_i[3]),
    .dataout(data_o[3])
);




L2_array #(.s_index(s_index), .width(s_tag))
tag0(
    .clk(clk),
    .rst(rst),
    .read(1'd1),
    .load(load_tag[0]),
    .rindex(rindex),
    .windex(windex),
    .datain(address_tag),
    .dataout(tag_o[0])
);

L2_array #(.s_index(s_index), .width(s_tag))
tag1(
    .clk(clk),
    .rst(rst),
    .read(1'd1),
    .load(load_tag[1]),
    .rindex(rindex),
    .windex(windex),
    .datain(address_tag),
    .dataout(tag_o[1])
);

L2_array #(.s_index(s_index), .width(s_tag))
tag2(
    .clk(clk),
    .rst(rst),
    .read(1'd1),
    .load(load_tag[2]),
    .rindex(rindex),
    .windex(windex),
    .datain(address_tag),
    .dataout(tag_o[2])
);

L2_array #(.s_index(s_index), .width(s_tag))
tag3(
    .clk(clk),
    .rst(rst),
    .read(1'd1),
    .load(load_tag[3]),
    .rindex(rindex),
    .windex(windex),
    .datain(address_tag),
    .dataout(tag_o[3])
);



L2_array #(.s_index(s_index), .width(3'd4))
dirty(
    .clk(clk),
    .rst(rst),
    .read(1'd1),
    .load(load_dirty),
    .rindex(rindex),
    .windex(windex),
    .datain(dirty_i),
    .dataout(dirty_o)
);

L2_array #(.s_index(s_index), .width(3'd4))
valid(
    .clk(clk),
    .rst(rst),
    .read(1'd1),
    .load(load_valid),
    .rindex(rindex),
    .windex(windex),
    .datain(valid_i),
    .dataout(valid_o)
);


L2_array #(.s_index(s_index), .width(2'd3))
mru( // 0 = MRU on left, 1 = MRU on right
    .clk(clk),
    .rst(rst),
    .read(1'd1),
    .load(load_MRU),
    .rindex(rindex),
    .windex(windex),
    .datain(MRU_i),
    .dataout(MRU_o)
);


always_comb begin

    //using pMRU algorithm
    unique case(MRU_o) 
      //L1-L2-L3
        3'b000: old_tag = tag_o[3];
        3'b001: old_tag = tag_o[2];
        3'b010: old_tag = tag_o[3]; 
        3'b011: old_tag = tag_o[2]; 
        3'b100: old_tag = tag_o[1]; 
        3'b101: old_tag = tag_o[1]; 
        3'b110: old_tag = tag_o[0]; 
        3'b111: old_tag = tag_o[0]; 

        default: old_tag = tag_o[0];
    endcase

    rindex = address[8:5];
    windex = address[8:5];
    address_tag = address[31:9];


    // write_en mux way0. write full line from L1 or don't write
    write_en[0] = write_en_sel[0] ? {32{1'd1}} : 32'd0;

    // write_en mux way1. write full line from L1 or don't write
    write_en[1] = write_en_sel[1] ? {32{1'd1}} : 32'd0;

    // write_en mux way2. write full line from L1 or don't write
    write_en[2] = write_en_sel[2] ? {32{1'd1}} : 32'd0;

    // write_en mux way3. write full line from L1 or don't write
    write_en[3] = write_en_sel[3] ? {32{1'd1}} : 32'd0;


 
    // cacheline_o mux
    unique case(cacheline_o_sel) 
        2'b00: cacheline_o = data_o[0];
        2'b01: cacheline_o = data_o[1];
        2'b10: cacheline_o = data_o[2];
        2'b11: cacheline_o = data_o[3];

        default: cacheline_o = data_o[0];
    endcase


    // way0 data mux
    unique case (data_i_sel[0])
        // write from cpu
        1'b0: data_i[0] = cpu_wdata;

        // write from pmem
        1'b1: data_i[0] = mm_wdata;

        default: data_i[0] = cpu_wdata;
    endcase

    // way1 data mux
    unique case (data_i_sel[1])
        // write from cpu
        1'b0: data_i[1] = cpu_wdata;

        // write from pmem
        1'b1: data_i[1] = mm_wdata;

        default: data_i[1] = cpu_wdata;
    endcase

    // way2 data mux
    unique case (data_i_sel[2])
        // write from cpu
        1'b0: data_i[2] = cpu_wdata;

        // write from pmem
        1'b1: data_i[2] = mm_wdata;

        default: data_i[2] = cpu_wdata;
    endcase

    // way3 data mux
    unique case (data_i_sel[3])
        // write from cpu
        1'b0: data_i[3] = cpu_wdata;

        // write from pmem
        1'b1: data_i[3] = mm_wdata;

        default: data_i[3] = cpu_wdata;
    endcase


    unique case (mm_address_sel)
        // use addr from cpu
        1'd0:begin            
            mm_address = {address[31:5], 5'd0};
        end
        // write back (when evicting and dirty bit)
        1'd1:begin            
            mm_address = {old_tag, address[8:5], 5'd0};
        end
        default: mm_address = {address[31:5], 5'd0};
    endcase

end
endmodule : L2_cache_datapath