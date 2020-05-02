`ifndef ALU_SV
`define ALU_SV
`include "types.sv"
module alu
#(
    parameter int width
)
(
    input types::opcode_t opcode,
    input types::ctl_t bmask,
    input logic [width-1:0] arg1,
    input logic [width-1:0] arg2,
    input types::flags_t f,
    output logic [width-1:0] dout,
    output types::flags_t fout
);
    localparam logic [width-1:0] zeros = {width{1'b0}};

    logic [width:0] _dout, _arg1, _arg2, fc, fc_inv, maskC_ext;

    assign _arg1 = {1'b0, arg1};
    assign _arg2 = {1'b0, arg2};

    assign fc = {zeros, f.C};
    assign fc_inv = {zeros, ~f.C};
    assign maskC_ext = {zeros, bmask.C};

    assign dout = _dout[width-1:0];

    assign fout.S = dout[width-1];
    assign fout.Z = dout == zeros;
    assign fout.C = _dout[width];
    assign fout.V = ~(arg1[width-1] ^ arg2[width-1]) ^ dout[width-1];

    always_comb begin : _dout_calc
        unique case (opcode)
            types::op_add: begin
                unique casex (bmask)
                    4'b1x0x: _dout = _arg1 + _arg2 + (maskC_ext & fc);
                    4'b1x1x: _dout = _arg1 + (~_arg2) + (maskC_ext & fc_inv);
                endcase
            end
            types::op_and: _dout = _arg1 & _arg2;
            types::op_or: _dout = _arg1 | _arg2;
            types::op_xor: _dout = _arg1 ^ _arg2;
            types::op_not: _dout = ~_arg2;
            types::op_rl: _dout = {arg1[width-1], arg1[width-2:0],
                                                    bmask.C ? f.C : 1'b0};
            types::op_rr:
                begin
                    _dout[width] = arg1[0]; // Rotated out
                    _dout[width-2:0] = arg1[width-1:1]; // Rotated right
                    unique casex ({bmask.C, bmask.S})
                        2'b1x: _dout[width-1] = f.C;  // Rotate w carry
                        2'b01: _dout[width-1] = arg1[width-1]; // Rotate w sign
                        2'b00: _dout[width-1] = 1'b0; // Rotate w/out sign
                    endcase
                end
            default: _dout = {1'b0, zeros};
        endcase
    end

endmodule : alu
`endif
