`include "types.sv"
`include "datapath.sv"

module Top
#(
    parameter int width = 8,
    parameter int nptrs = 2,
    parameter int pc_width = 8,
    parameter int addr_width = 8
)
(
    input clk, reset,
    input types::instr_t instr,
    output logic [pc_width-1:0] pc,
    input  logic [width-1:0] rdata [1:2],
    output logic [width-1:0] wdata,
    output logic [addr_width-1:0] addr [1:2],
    output logic wen
);

    assign wen = instr.mm.opcode[3];
    datapath #(width, nptrs, pc_width, addr_width) datapath(.*);

endmodule : Top
