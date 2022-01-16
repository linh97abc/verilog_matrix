module matrix_add# (
    // khong mat thoi gian cho thuc hien phep cong khi:
    // so phep tinh cong > cycle (thoi gian thuc hien phep cong)
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
    localparam MATRIX_ADD_NEXT = N_OFFSET + 0,
                MATRIX_ADD_GET = N_OFFSET + 1,
                MATRIX_ADD_RESET = N_OFFSET + 2;   
    // add_inst
    wire add_en, add_done;
    reg add_start;
    reg [31:0] add_a, add_b;
    wire [31:0] add_result
    // fifo_inst
    wire pop;
    wire [31:0] pop_result;
    wire fifo_empty, fifo_full;

    wire done_get_add_result;
    wire get_add_result_req;

    wire areset;
    assign areset = reset | (start && (n == MATRIX_ADD_RESET));

    assign get_add_result_req = (start && (n == MATRIX_ADD_GET))? 1'b1: 1'b0;

    assign done = (start &&
                ((n == MATRIX_ADD_NEXT) ||
                (n == MATRIX_ADD_RESET)))? 1'b1:
                done_get_add_result;

    add__ add_inst(
        clk, areset, add_en,
        add_a, add_b, add_result,
        add_start, add_done 
    );

    wire un_used_fifo_write;
    fifo__#(31, FIFO_WIDTH, 0) fifo_inst(
        clk, areset,
        un_used_fifo_write,
        add_done, pop,
        add_result,
        pop_result,
        fifo_empty,
        fifo_full
    );

    assign add_en = 1'b1;

    localparam STATE_IDLE = 3'b1,
                STATE_WAIT = 3'b10,
                STATE_GET_RESULT = 3'b100;
    reg [2:0] state;

    assign {pop, done_get_add_result} = (state == STATE_GET_RESULT)? 2'b11: 2'b00;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            add_a <= 0;
            add_b <= 0;
            add_start <= 1'b0;
            state <= STATE_IDLE;
        end else begin
            if (start && (n == MATRIX_ADD_NEXT)) begin
                add_a <= dataa;
                add_b <= datab;
                add_start <= 1'b1;
            end else begin
                add_start <= 1'b0;
            end

            case (state)
                STATE_GET_RESULT: begin
                    result <= pop_result;
                    if (get_add_result_req) begin
                        state <= STATE_WAIT;
                    end else begin
                        state <= STATE_IDLE;
                    end
                end
                STATE_WAIT: begin
                    if (~fifo_empty) begin
                        state <= STATE_GET_RESULT;
                    end
                end
                default: begin
                    if (get_add_result_req) begin
                        if (fifo_empty) begin
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