`timescale 1ns/1ps
//
// mac_rne_sat -- implement your golden solution in this file per
// docs/spec.md, and push it to your fork's mac_rne_sat_golden branch.
//
module mac_rne_sat (
    input  logic               clk,
    input  logic               rst,       // synchronous, active-high
    input  logic               en,        // accumulate a*b this cycle
    input  logic               clr,       // clear accumulator this cycle
    input  logic               rd,        // request readout snapshot this cycle
    input  logic signed [7:0]  a,
    input  logic signed [7:0]  b,
    output logic signed [15:0] res,       // rounded + saturated snapshot
    output logic               res_valid, // 1-cycle pulse, one cycle after rd
    output logic               ovf        // sticky saturation flag
);

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(1, mac_rne_sat);
     // #10000000;
        //$finish;
    end

    logic signed [15:0] p;
    logic signed [27:0] p_sig_ext;
    logic signed [27:0] acc, acc_ff;   // 28-bit accumulator. AKA snapshot.
    logic signed [19:0] q, round;
    logic signed [15:0] res_sat;
    logic [7:0] r;
    logic ovf_b;

    // Accumulator ff
    always_ff @(posedge clk) begin
        if (rst) begin
            acc_ff <= '0;
        end else begin
            acc_ff <= acc;
        end
    end

    // Accumulator logic
    always_comb begin
        p = a * b;
        p_sig_ext = p;
        acc = acc_ff;
        if(!clr && en) begin
            acc = acc_ff + p_sig_ext;
        end else if(clr && !en) begin
            acc = 0;
        end else if(clr && en) begin
            acc = p_sig_ext;
        end
    end

    // Round logic
    always_comb begin
        //q = acc_ff[27:8];  // Compilation error on iverlog :(
        q = acc_ff >> 8;
        r = acc_ff - {q, 8'b0};
        if(r > 128) begin
            round = q + 1;
        end else if(r < 128) begin
            round = q;
        end else begin
            //if(q[0]) begin // Compilation error on iverlog :(
            if(q & 20'b1) begin
            //if(q % 2 == 1) begin
                // If q is odd, round up
                round = q + 1;
            end else begin
                // If q is even, keep it
                round = q;
            end
        end
    end

    // Sat logic
    always_comb begin
        if(round > 32767) begin
            res_sat = 32767;
            ovf_b = 1;
        end else if(round < -32768) begin
            res_sat = -32768;
            ovf_b = 1;
        end else begin
            res_sat = round;
            ovf_b = 0;
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            //ovf_b <= 0;
            ovf <= 0;
            res_valid <= 0;
            res <= '0;
        end else begin
            if(rd) begin
                res_valid <= 1;
                res <= res_sat;
                ovf <= ovf_b;
            end else begin
                res_valid <= 0;
                if(clr) begin
                    ovf <= 0;
                end
            end
        end
    end



endmodule
