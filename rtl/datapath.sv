`ifndef DATAPATH_SV
`define DATAPATH_SV
`include "types.sv"
`include "alu.sv"

module datapath
#(
    parameter int width,
    parameter int nptrs,
    parameter int pc_width,
    parameter int addr_width
)
(
    input clk,
    input reset,
    input logic [width-1:0] rdata [1:2],
    output logic [width-1:0] wdata,
    output logic [addr_width-1:0] addr [1:2],
    output logic [addr_width-1:0] pc,
    input types::instr_t instr
);
    typedef logic [width-1:0] word_t;
    typedef union packed {
        logic [addr_width-1:0] a;
        struct packed {
            logic [$clog2(nptrs)-1:0] ptr;
            logic [addr_width-$clog2(nptrs)-1:0] addr;
        } c;
    } addr_t;

    // Registers
    addr_t _bar [1:nptrs-1];
    addr_t PC;
    types::flags_t flags;


    addr_t BAR [nptrs];

    always_comb begin
        BAR[0].a = 8'b0;
        for (int i = 1; i < nptrs; ++i)
            BAR[i].a = _bar[i].a;
    end

    addr_t instops [1:2];
    assign instops[1] = addr_t'(instr.mm.addr1);
    assign instops[2] = addr_t'(instr.mm.addr2);

    // Wires
    types::flags_t flags_out;
    types::flags_t flags_inv_mux_out;
    logic reduced_flags;
    logic pc_mux_sel;
    addr_t pc_mux_out;
    word_t  imm1, alu_out;

    for (genvar i = 1; i <= 2; ++i) begin : address_resolution
        assign addr[i] = instops[i].c.addr + BAR[instops[i].c.ptr].a;
    end

    assign pc = PC.a;
    assign imm1 = signed'(instr.store.imm1);
    assign reduced_flags = |(flags_inv_mux_out & instr.branch.bflags);
    assign pc_mux_sel = reduced_flags & (instr.mm.opcode inside
                                            {types::op_br, types::op_brn});
    assign pc_mux_out.a = pc_mux_sel ?  addr[1] : PC.a + 8'd1;
    assign wdata = instr.store.opcode == types::op_store ?  imm1 : alu_out;
    assign flags_inv_mux_out = instr.mm.opcode[0] ? flags_out : ~flags_out;

    // Muxes
    alu #(.width(width)) alu(
        .opcode (instr.mm.opcode),
        .bmask  (instr.mm.bmask),
        .arg1   (rdata[1]),
        .arg2   (rdata[2]),
        .f      (flags),
        .dout   (alu_out), 
        .fout   (flags_out)
    );

    always_ff @(posedge clk) begin
        if (reset) begin
            PC <= 8'd0;
            for (int i = 1; i < nptrs; ++i)
                _bar[i] <= 8'd0;
            flags <= 4'd0;
        end
        else begin
            if ((instr.mm.opcode inside {types::op_setbar}) & instops[1].c.ptr)
                _bar[instops[1].c.ptr].a <= rdata[1];
            PC <= pc_mux_out.a;
            flags <= flags_out;
        end
    end

endmodule : datapath
`endif
