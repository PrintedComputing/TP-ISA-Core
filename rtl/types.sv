`ifndef TYPES_SV
`define TYPES_SV
package types;
    typedef enum bit {
        dms_imm1,
        dms_alu_out
    } dmem_mux_sel_t;

    typedef enum bit {
        fim_normal,
        fim_inverted
    } flags_inv_mux_sel_t;

    typedef enum logic [3:0] {
        op_add    = 4'b0000,
        op_and    = 4'b0001,
        op_or     = 4'b0010,
        op_xor    = 4'b0011,
        op_not    = 4'b0100,
        op_rl     = 4'b0101,
        op_rr     = 4'b0110,
        op_store  = 4'b0111,
        op_setbar = 4'b1111,
        op_br     = 4'b1000,
        op_brn    = 4'b1001,
        op_bp     = 4'b1010
    } opcode_t;

    typedef struct packed {
        logic [3:3] S;
        logic [2:2] Z;
        logic [1:1] C;
        logic [0:0] V;
    } flags_t;

    typedef struct packed {
        logic [3:3] W;
        logic [2:2] C;
        logic [1:1] S;
        logic [0:0] B;
    } ctl_t;

    typedef logic [7:0] addr_t;
    localparam addr_t start_addr = 8'b0;


    typedef union packed {
        logic [23:0] instr;
        struct packed {
            opcode_t opcode;
            ctl_t bmask;
            addr_t addr1;
            addr_t addr2;
        } mm;
        struct packed {
            opcode_t opcode;
            ctl_t bmask;
            addr_t addr1;
            addr_t imm1;
        } store;
        struct packed {
            opcode_t opcode;
            ctl_t bmask;
            addr_t addr1;
            logic [7:4] rsvrd;
            flags_t bflags;     // Used to indicate which flags to consider
        } branch;
    } instr_t;
    localparam instr_t nop = 24'b0;

endpackage
`endif
