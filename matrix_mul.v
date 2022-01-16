module matrix_mul# (
    parameter FIFO_WIDTH = 4,
    parameter N_OFFSET = 0
) (
    input [31:0] dataa,
    input [31:0] datab,
    input reg [31:0] result,
    input clk,
    input clk_en,
    input start,
    input reset,
    output done,
    input [7:0] n
);
    localparam MATRIX_MUL_START = N_OFFSET + 0,
                MATRIX_MUL_NEXT = N_OFFSET + 1,
                MATRIX_MUL_END = N_OFFSET + 2,
                MATRIX_MUL_RESET = N_OFFSET + 3;
    
    wire areset;
    assign areset = reset | (start && (n == MATRIX_MUL_RESET));

    add__ add_inst(
        clk, areset, 1'b1,
        add_a, add_b, add_result,
        add_start, add_done 
    );

    mul__ mul_inst(
        clk, areset, 1'b1,
        mul_a, mul_b, mul_result,
        mul_start, mul_done 
    );

    fifo_2 fifo_inst(
        clk, areset,
        mul_done, add_done,
        mul_result, add_result,
        add_a, add_b,
        add_start

    );

    fifo__#(31, FIFO_WIDTH) fifo_rs_inst(
        clk, areset,
        fifo_rs_write,
        push_result, pop_result,
        muladd_result_in,
        muladd_result_out,
        fifo_rs_empty,
        fifo_rs_full
    );

    reg [FIFO_WIDTH-1: 0] prog_cnt [31:0];
    reg [4:0] prog_cnt_head, prog_cnt_tail;
    wire [4:0] prog_cnt_head_next, prog_cnt_tail_next;

    assign prog_cnt_head_next = prog_cnt_head + 1'b1,
            prog_cnt_tail_next = prog_cnt_tail + 1'b1;

    assign {pop_result, done_get_result} = (state == STATE_GET_RESULT)? 2'b11: 2'b00;

    always @(posedge clk or posedge areset) begin
        if (areset) begin
            mul_a <= 0;
            mul_b <= 0;
            mul_start <= 1'b0;
            prog_cnt_head <= 0;
            prog_cnt_tail <= 1;
            prog_cnt[1] <= 0;
        end else begin
            if (start && 
                ((n == MATRIX_MUL_START) ||
                (n == MATRIX_MUL_NEXT))) begin
                mul_a <= dataa;
                mul_b <= datab;
                mul_start <= 1'b1:
            end else begin
                mul_start <= 1'b0;
            end

            if (start && (n == MATRIX_MUL_START)) begin
                prog_cnt[prog_cnt_head_next] <= 1;
                prog_cnt_head <= prog_cnt_head_next;
            end

            if (add_done && 
                start && (n == MATRIX_MUL_NEXT) &&
                (prog_cnt_head == prog_cnt_tail)) begin
                // prog_cnt khong doi
            end else begin
                if (start && (n == MATRIX_MUL_NEXT)) begin
                    prog_cnt[prog_cnt_head] <= prog_cnt[prog_cnt_head] + 1'b1;
                end

                if (add_done) begin
                    prog_cnt[prog_cnt_tail] <= prog_cnt[prog_cnt_tail] - 1'b1;
                end
            end

            

            if (add_done && (prog_cnt[prog_cnt_tail] == 2) &&
                (prog_cnt_head != prog_cnt_tail)) begin
                prog_cnt_tail <= prog_cnt_tail_next;
                push_result <= 1'b1;
                muladd_result_in <= add_result;
            end else begin
                push_result <= 1'b0;
            end

            case (state)
                STATE_GET_RESULT: begin
                    result <= muladd_result_out;
                    if (get_result_req) begin
                        state <= STATE_WAIT;
                    end else begin
                        state <= STATE_IDLE;
                    end
                end
                STATE_WAIT: begin
                    if (~fifo_rs_empty) begin
                        state <= STATE_GET_RESULT;
                    end
                end
                default: begin
                    if (get_result_req) begin
                        if (fifo_rs_empty) begin
                            state <= STATE_WAIT;
                        end else begin
                            state <= STATE_GET_RESULT;
                        end
                    end
                end
            endcase
        end
    end
endmodule