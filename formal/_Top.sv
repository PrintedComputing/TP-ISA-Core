module _Top
#(
    parameter int width = 8,
    parameter int nptrs = 2,
    parameter int pc_width = 8,
    parameter int addr_width = 8
)
(
    input clk, reset,
    input var types::instr_t instr,
    output logic [pc_width-1:0] pc,
    input  var logic [width-1:0] rdata [1:2],
    output logic [width-1:0] wdata,
    output logic [addr_width-1:0] addr [1:2],
    output logic wen
);

    Top#(8, 2, 8, 8) dut(.*);

    // \TP-ISA-Checker chkr(.*);
    localparam addr_msb = addr_width-1;
    logic [7:0] checker_bar = 8'b0;

    default clocking @(posedge clk);
    endclocking
    default disable iff (reset);

    op_add_bmask: assume property (
        instr.mm.opcode == types::op_add |-> instr.mm.bmask inside
            {
                4'b1000 // ADD
               ,4'b1100 // ADC
               ,4'b1010 // SUB
               ,4'b0010 // CMP
            }
    );

    op_and_bmask: assume property (
        instr.mm.opcode === types::op_and |-> instr.mm.bmask inside
            {
                 4'b1000 // AND
                ,4'b000  // TEST
            }
    );

    op_xor_or_bmask: assume property (
        instr.mm.opcode inside {types::op_or, types::op_xor, types::op_not} |->
            instr.mm.bmask === 4'b1000
    );

    op_rl_bmask: assume property (
        instr.mm.opcode === types::op_rl |-> instr.mm.bmask inside
            {4'b1100, 4'b1000}
    );

    op_rr_bmask: assume property (
        instr.mm.opcode === types::op_rr |-> instr.mm.bmask inside
            {4'b1100, 4'b1000, 4'b1010}
    );

    op_store_bmask: assume property (
        instr.mm.opcode === types::op_store |-> instr.mm.bmask === 4'b1000
    );

    op_setbar_bmask: assume property (
        instr.mm.opcode === types::op_setbar |-> (instr.mm.bmask === 4'b0000)
                                             && (instr.mm.addr1[7] === 1'b1)
    );

    op_branch_bmask: assume property (
        instr.mm.opcode === types::op_br |-> (instr.branch.bmask === 4'b0001)
                                         && (instr.branch.rsvrd === 4'b0000)
    );

    op_branchn_bmask: assume property (
        instr.mm.opcode === types::op_brn |-> (instr.branch.bmask === 4'b0011)
                                          && (instr.branch.rsvrd === 4'b0000)
    );

    legal_insts: assume property (
        instr.mm.opcode inside {
            types::op_add, types::op_and, types::op_or, types::op_xor,
            types::op_not, types::op_rl, types::op_rr, types::op_store,
            types::op_setbar, types::op_br, types:: op_brn
        }
    );

    next_pc_no_branch: assert property (
        !(instr.mm.opcode inside {types::op_br, types::op_brn}) |=>
            pc === ($past(pc) + 1'b1)
    );

    property next_pc_br_prop(types::opcode_t br_t, logic [3:0] flags);
        logic taken;
        logic [pc_width-1:0] target_address;
        (
            instr.mm.opcode === br_t,
            taken = |(instr.branch.bflags & flags),
            target_address = addr[1]
        ) |=> pc === (taken ? target_address : $past(pc) + 1'b1)
    endproperty

    next_pc_br: assert property (
        next_pc_br_prop(types::op_br, dut.datapath.flags)
    );

    next_pc_brn: assert property (
        next_pc_br_prop(types::op_brn, ~dut.datapath.flags)
    );

    setbar_results: assert property (
        instr.mm.opcode === types::op_setbar |=>
            (dut.datapath._bar[1].a === $past(rdata[2]))
    );

    store_results: assert property (
        instr.mm.opcode === types::op_store |-> wdata === instr.store.imm1
    );

    rr_results: assert property (
        (instr.mm.opcode === types::op_rr) && (instr.mm.bmask === 4'b1000) |->
            wdata === {1'b0, rdata[1][width-1:1]}
    );

    rrc_results: assert property (
        (instr.mm.opcode === types::op_rr) && (instr.mm.bmask === 4'b1100) |->
            wdata === {dut.datapath.flags.C, rdata[1][width-1:1]}
    );

    rra_results: assert property (
        (instr.mm.opcode === types::op_rr) && (instr.mm.bmask === 4'b1010) |->
            wdata === {rdata[1][width-1], rdata[1][width-1:1]}
    );

    rl_results: assert property (
        (instr.mm.opcode === types::op_rl) && (instr.mm.bmask === 4'b1000) |->
            wdata === {rdata[1][width-2:0], 1'b0}
    );

    rlc_results: assert property (
        (instr.mm.opcode === types::op_rl) && (instr.mm.bmask === 4'b1100) |->
            wdata === {rdata[1][width-2:0], dut.datapath.flags.C}
    );

    not_result: assert property (
        instr.mm.opcode === types::op_not |-> wdata === ~rdata[2]
    );

    or_result: assert property (
        instr.mm.opcode === types::op_or |-> wdata === rdata[1] | rdata[2]
    );

    xor_result: assert property (
        instr.mm.opcode === types::op_xor |-> wdata === rdata[1] ^ rdata[2]
    );

    add_result: assert property (
        (instr.mm.opcode == types::op_add && instr.mm.bmask == 4'b1000) |->
            wdata == rdata[1] + rdata[2]
    );

    addc_result: assert property (
        (instr.mm.opcode == types::op_add && instr.mm.bmask == 4'b1100) |->
            wdata == rdata[1] + rdata[2] + dut.datapath.flags.C
    );

    and_result: assert property (
        (instr.mm.opcode === types::op_and) |->
            wdata === (rdata[1] & rdata[2])
    );

    wen_check: assert property (
        wen === (
                    (instr.mm.opcode === types::op_add) &&
                    (instr.mm.bmask !== 4'b0010)
                ) || (
                    (instr.mm.opcode === types::op_and) &&
                    (instr.mm.bmask !== 4'b0000)
                ) || (
                    instr.mm.opcode inside {
                        types::op_or, types::op_xor, types::op_not,
                        types::op_rl, types::op_rr, types::op_store
                    }
                )
    );

    sub_result: assert property (
        (instr.mm.opcode == types::op_add && instr.mm.bmask == 4'b1010) |->
            wdata === rdata[1] - rdata[2]
    );

    addr1: assert property (
        !(instr.mm.opcode inside {types::op_setbar}) |->
            addr[1] === {1'b0, instr.mm.addr1[addr_msb-1:0]} + 
                        dut.datapath.BAR[instr.mm.addr1[addr_msb]]
    );

    addr2: assert property (
        !(instr.mm.opcode inside {types::op_setbar}) |->
            addr[2] === {1'b0, instr.mm.addr2[addr_msb-1:0]} +
                        dut.datapath.BAR[instr.mm.addr2[addr_msb]]
    );

endmodule : _Top

